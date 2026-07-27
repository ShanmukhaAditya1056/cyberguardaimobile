"""
06_train_lightgbm.py — gradient-boosted classifier on the same malware
features as the Random Forest pipeline.

Outputs: models/saved/lightgbm_malware.txt
         models/saved/lgbm_confusion_matrix.png
         models/saved/lgbm_training_curves.png
         models/saved/lgbm_metrics.json
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import lightgbm as lgb
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from sklearn.metrics import (accuracy_score, classification_report,
                             confusion_matrix, roc_auc_score)
from sklearn.model_selection import train_test_split

ROOT = Path(__file__).resolve().parents[1]
PROC = ROOT / "data" / "processed"
SAVE = ROOT / "models" / "saved"
SAVE.mkdir(parents=True, exist_ok=True)


def main() -> int:
    print("=" * 60)
    print(" 06_train_lightgbm — start")
    print("=" * 60)
    src = PROC / "malware_train.csv"
    if not src.exists():
        print("[06] Run 04_prepare_malware_data.py first.", file=sys.stderr)
        return 1

    df = pd.read_csv(src).fillna(0)
    X = df.drop(columns=["label"])
    y = df["label"]
    feature_names = X.columns.tolist()
    X_tr, X_te, y_tr, y_te = train_test_split(
        X, y, test_size=0.20, stratify=y, random_state=42)

    train_ds = lgb.Dataset(X_tr, label=y_tr)
    valid_ds = lgb.Dataset(X_te, label=y_te, reference=train_ds)

    params = {
        "objective": "binary",
        "metric": ["binary_logloss", "auc"],
        "boosting_type": "gbdt",
        "num_leaves": 63,
        "learning_rate": 0.05,
        "feature_fraction": 0.9,
        "bagging_fraction": 0.8,
        "bagging_freq": 5,
        "min_child_samples": 20,
        "lambda_l1": 0.1,
        "lambda_l2": 0.1,
        "is_unbalance": True,
        "verbose": -1,
        "random_state": 42,
    }

    eval_result: dict = {}
    callbacks = [
        lgb.early_stopping(stopping_rounds=50, verbose=True),
        lgb.log_evaluation(period=100),
        lgb.record_evaluation(eval_result),
    ]
    model = lgb.train(
        params, train_ds, num_boost_round=1000,
        valid_sets=[train_ds, valid_ds],
        valid_names=["train", "valid"],
        callbacks=callbacks,
    )

    y_prob = model.predict(X_te)
    y_pred = (y_prob >= 0.5).astype(int)
    acc = accuracy_score(y_te, y_pred)
    auc = roc_auc_score(y_te, y_prob)
    print(classification_report(y_te, y_pred,
                                target_names=["benign", "malware"]))
    print(f"[06] accuracy={acc:.4f}  auc={auc:.4f}")

    cm = confusion_matrix(y_te, y_pred)
    plt.figure(figsize=(5, 4))
    sns.heatmap(cm, annot=True, fmt="d", cmap="Greens",
                xticklabels=["benign", "malware"],
                yticklabels=["benign", "malware"])
    plt.title("LightGBM — Confusion Matrix")
    plt.tight_layout()
    plt.savefig(SAVE / "lgbm_confusion_matrix.png", dpi=150)
    plt.close()

    # Training curve
    plt.figure(figsize=(7, 4))
    for name in ("train", "valid"):
        for metric, values in eval_result.get(name, {}).items():
            plt.plot(values, label=f"{name}/{metric}")
    plt.legend(); plt.title("LightGBM — training curves")
    plt.tight_layout()
    plt.savefig(SAVE / "lgbm_training_curves.png", dpi=150)
    plt.close()

    model.save_model(str(SAVE / "lightgbm_malware.txt"))
    (SAVE / "lgbm_metrics.json").write_text(json.dumps({
        "accuracy": acc, "auc": auc,
        "confusion_matrix": cm.tolist(),
        "feature_importance":
            dict(zip(feature_names,
                     model.feature_importance(importance_type="gain").tolist())),
    }, indent=2))
    print(f"[06] DONE  saved to {SAVE / 'lightgbm_malware.txt'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
