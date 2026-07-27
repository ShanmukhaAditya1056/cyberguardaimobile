"""
03_train_distilbert.py
Fine-tune `distilbert-base-multilingual-cased` for phishing-URL
classification.

Inputs : data/processed/phishing_train.csv, phishing_test.csv
Outputs: models/saved/distilbert_phishing/ (HuggingFace dir)
         models/saved/distilbert_phishing_metrics.json
         models/saved/distilbert_confusion_matrix.png
         models/saved/distilbert_training_curves.png

Requires: Python 3.10-3.12 with the deps in requirements.txt (`pip
install -r ml_training/requirements.txt`).  GPU strongly recommended:
~2-4 hours on a single consumer GPU, much longer on CPU.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
import torch
from sklearn.metrics import (accuracy_score, classification_report,
                             confusion_matrix, roc_auc_score)
from torch.utils.data import Dataset
from transformers import (DistilBertForSequenceClassification,
                          DistilBertTokenizer, EarlyStoppingCallback,
                          Trainer, TrainingArguments)

ROOT = Path(__file__).resolve().parents[1]
PROC = ROOT / "data" / "processed"
SAVE = ROOT / "models" / "saved"
SAVE.mkdir(parents=True, exist_ok=True)


class PhishingDataset(Dataset):
    def __init__(self, texts, labels, tokenizer, max_length: int = 128):
        self.enc = tokenizer(list(texts), truncation=True,
                             padding="max_length", max_length=max_length,
                             return_tensors="pt")
        self.labels = torch.tensor(list(labels), dtype=torch.long)

    def __len__(self):
        return len(self.labels)

    def __getitem__(self, idx):
        return {
            "input_ids": self.enc["input_ids"][idx],
            "attention_mask": self.enc["attention_mask"][idx],
            "labels": self.labels[idx],
        }


def compute_metrics(pred):
    labels = pred.label_ids
    preds = pred.predictions.argmax(-1)
    return {"accuracy": accuracy_score(labels, preds)}


def plot_confusion(cm: np.ndarray, path: Path) -> None:
    plt.figure(figsize=(5, 4))
    sns.heatmap(cm, annot=True, fmt="d", cmap="Blues",
                xticklabels=["Safe", "Phishing"],
                yticklabels=["Safe", "Phishing"])
    plt.xlabel("Predicted")
    plt.ylabel("True")
    plt.title("DistilBERT — Confusion Matrix")
    plt.tight_layout()
    plt.savefig(path, dpi=150)
    plt.close()


def plot_curves(log_history, path: Path) -> None:
    train_loss = [h["loss"] for h in log_history if "loss" in h]
    eval_loss = [h["eval_loss"] for h in log_history if "eval_loss" in h]
    eval_acc = [h["eval_accuracy"] for h in log_history
                if "eval_accuracy" in h]
    fig, axs = plt.subplots(1, 2, figsize=(10, 4))
    axs[0].plot(train_loss, label="train"); axs[0].plot(eval_loss, label="eval")
    axs[0].legend(); axs[0].set_title("Loss")
    axs[1].plot(eval_acc); axs[1].set_title("Eval accuracy")
    plt.tight_layout()
    plt.savefig(path, dpi=150)
    plt.close()


def main() -> int:
    print("=" * 60)
    print(" 03_train_distilbert — start")
    print("=" * 60)

    train_csv = PROC / "phishing_train.csv"
    test_csv = PROC / "phishing_test.csv"
    if not train_csv.exists():
        print("[03] Run 02_prepare_phishing_data.py first.", file=sys.stderr)
        return 1

    # The 02 script writes feature rows, not raw URLs — re-attach raw URLs
    # by re-extracting them from the raw CSVs in collection order. For
    # final use, you should source the URL text from your data pipeline.
    raw_phish = pd.read_csv(ROOT / "data" / "raw" / "phishing_urls.csv")
    raw_safe = pd.read_csv(ROOT / "data" / "raw" / "safe_urls.csv")
    all_urls = pd.concat([raw_phish, raw_safe], ignore_index=True)
    all_urls = all_urls.sample(frac=1.0, random_state=42).reset_index(drop=True)

    # 80/20 stratified split on the URL strings (same seed as 02)
    from sklearn.model_selection import train_test_split
    tr, te = train_test_split(all_urls, test_size=0.20,
                              stratify=all_urls["label"], random_state=42)
    print(f"[03] train={len(tr)}  test={len(te)}")
    print(tr["label"].value_counts())

    tokenizer = DistilBertTokenizer.from_pretrained(
        "distilbert-base-multilingual-cased")
    model = DistilBertForSequenceClassification.from_pretrained(
        "distilbert-base-multilingual-cased", num_labels=2)

    train_ds = PhishingDataset(tr["url"].tolist(),
                               tr["label"].tolist(), tokenizer)
    test_ds = PhishingDataset(te["url"].tolist(),
                              te["label"].tolist(), tokenizer)

    # Tuned for an RTX 3050 (4 GB VRAM): batch=8 with fp16 fits.
    #
    # `save_strategy="no"` because:
    #   1. The synthetic phishing dataset reaches eval-accuracy 1.0
    #      after epoch 1, so checkpointing doesn't help us pick a
    #      better model.
    #   2. Hugging Face's `Trainer` save uses an os.rename of a temp
    #      dir, which is racey on Windows when AV / Defender holds an
    #      open handle to a new file. Skipping it sidesteps the
    #      WinError-5 we hit on the previous run.
    # We still call `trainer.save_model(...)` after the loop finishes,
    # which uses a plain `save_pretrained` and works fine on Windows.
    args = TrainingArguments(
        output_dir=str(SAVE / "distilbert_checkpoints"),
        num_train_epochs=2,
        per_device_train_batch_size=8,
        per_device_eval_batch_size=16,
        gradient_accumulation_steps=2,
        warmup_steps=100,
        weight_decay=0.01,
        logging_dir=str(SAVE / "logs"),
        logging_steps=50,
        evaluation_strategy="epoch",
        save_strategy="no",
        load_best_model_at_end=False,
        report_to="none",
        fp16=torch.cuda.is_available(),
    )

    trainer = Trainer(
        model=model, args=args,
        train_dataset=train_ds, eval_dataset=test_ds,
        compute_metrics=compute_metrics,
        # Early-stopping callbacks rely on `save_strategy != 'no'`. We're
        # only training 2 epochs and the model already hits 1.0 eval
        # accuracy at epoch 1, so there's nothing to early-stop from.
    )
    trainer.train()

    preds = trainer.predict(test_ds)
    y_true = preds.label_ids
    y_pred = preds.predictions.argmax(-1)
    y_prob = torch.softmax(torch.tensor(preds.predictions), dim=1)[:, 1].numpy()

    acc = accuracy_score(y_true, y_pred)
    auc = roc_auc_score(y_true, y_prob)
    print(classification_report(y_true, y_pred, target_names=["safe", "phishing"]))
    print(f"[03] accuracy={acc:.4f}  auc={auc:.4f}")

    cm = confusion_matrix(y_true, y_pred)
    plot_confusion(cm, SAVE / "distilbert_confusion_matrix.png")
    plot_curves(trainer.state.log_history,
                SAVE / "distilbert_training_curves.png")

    (SAVE / "distilbert_phishing_metrics.json").write_text(json.dumps({
        "accuracy": acc, "auc": auc,
        "confusion_matrix": cm.tolist(),
        "classification_report": classification_report(
            y_true, y_pred, target_names=["safe", "phishing"],
            output_dict=True),
    }, indent=2))

    trainer.save_model(str(SAVE / "distilbert_phishing"))
    tokenizer.save_pretrained(str(SAVE / "distilbert_phishing"))
    print(f"[03] DONE  model saved to {SAVE / 'distilbert_phishing'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
