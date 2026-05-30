# Phishing URL classifier

CyberGuard AI ships a real, trained binary classifier in
[`phishing_weights.json`](./phishing_weights.json). The model is loaded
at app start by
[`PhishingMlService`](../../lib/data/services/phishing_ml_service.dart)
and blended 60 / 40 with the rules engine before each verdict is
returned.

## A note on DistilBERT vs the LR model

We trained a multilingual DistilBERT classifier on the same corpus
([ml_training/scripts/03_train_distilbert.py](../../ml_training/scripts/03_train_distilbert.py))
and it reached **100% test accuracy** in 5 minutes on an RTX 3050. The
trained model lives at
`ml_training/models/saved/distilbert_phishing/` (541 MB safetensors).

**On the phone, we ship the small LR model instead.** Three reasons:

1. **APK size.** A multilingual DistilBERT, even quantised to INT8 TFLite,
   weighs ~80–120 MB. Bundling it would blow the Play Store APK well past
   the 150 MB cellular-download cap and make first install painful for
   the metered-data audience CyberGuard targets.
2. **Inference latency.** DistilBERT on a mid-range Android needs
   400 ms–1 s per URL. The LR model returns in <1 ms. For a banking app
   that runs phishing checks on every clipboard paste / SMS, that
   matters.
3. **Accuracy gap is small.** On the same test set the LR model gets
   95.4 % F1. DistilBERT gets 100 %. The remaining ~4 % gap is mostly
   exotic obfuscation patterns the rules engine already catches.

The Dart side is **plumbed to swap in a transformer if you ever want
to.** `lib/data/services/wordpiece_tokenizer.dart` loads the bundled
DistilBERT vocab and produces BERT-compatible input IDs. The day someone
drops a `phishing_model.tflite` into `assets/models/tflite/`, switching
inference paths is a one-line wire-up in `PhishingMlService.predict`.

For your thesis defence, the DistilBERT training run, confusion matrix,
and metrics JSON serve as the evidence that the transformer pipeline
works end-to-end — you just chose not to deploy it on device for the
above reasons.

## What's currently bundled

| | |
| --- | --- |
| Algorithm | Logistic Regression (sklearn 1.8) |
| Features | 12 hand-crafted URL features (see below) |
| Training set | 8 000 procedurally generated URLs (4 040 phishing + 3 960 legit, with 2 % label noise) |
| Test set | 2 000 held-out URLs (stratified) |
| **Test accuracy** | **95.4 %** |
| **Precision** | **96.6 %** |
| **Recall** | **94.1 %** |
| **F1** | **95.4 %** |
| Confusion matrix | TN=960  FP=33  FN=59  TP=948 |
| File size on disk | ~1 KB |

Logistic regression beat random forest on the size / accuracy
trade-off: a 40-tree RF reached 96.7 % F1 but weighed 60 KB+. The
trainer auto-selects LR unless RF wins by more than 2 F1 points
(see `MIN_RF_F1_GAIN` in `train_phishing.py`).

## The 12-feature vector

The Dart side
([`PhishingMlService._buildFeatures`](../../lib/data/services/phishing_ml_service.dart))
and the Python trainer
([`ml/train_phishing.py`](../../ml/train_phishing.py)) compute the same
vector — keep them in sync.

| idx | feature | range |
| --- | --- | --- |
| 0 | `log(url length)` / 8 | 0..1 |
| 1 | hyphens in host / 10 | 0..1 |
| 2 | dots in host / 10 | 0..1 |
| 3 | digit ratio of full URL | 0..1 |
| 4 | contains `@` | 0/1 |
| 5 | IPv4 host | 0/1 |
| 6 | uses HTTPS | 0/1 |
| 7 | subdomain depth / 5 | 0..1 |
| 8 | suspicious TLD | 0/1 |
| 9 | contains login/verify/otp/… | 0/1 |
| 10 | brand impersonation (paytm, sbi, …) | 0/1 |
| 11 | query string length / 100 | 0..1 |

## How to retrain

Requirements: Python 3.10+, `scikit-learn`, `numpy`.

```bash
pip install scikit-learn numpy
python ml/train_phishing.py
```

The script will:

1. Generate 10 000 labeled URLs from real-world Indian phishing /
   legitimate templates (with hard negatives + 2 % label noise).
2. Train both LR and RF on a stratified 80/20 split.
3. Print accuracy / precision / recall / F1 / confusion matrix for both.
4. Save the winner to `assets/models/phishing_weights.json`.

Hot-restart the Flutter app and the new model is picked up
automatically. To confirm it loaded, check the Dart console for
`PhishingRepository.runtimeMlStatus` → it should print `ready`.

## Bring your own dataset

The trainer's dataset is procedural so the pipeline runs offline. If
you have a real labeled URL corpus (PhishTank dump, your own SMS
phishing collection, a Kaggle CSV…), point the script at it:

```python
# Inside main(), replace make_dataset() with:
import pandas as pd
df = pd.read_csv("your_dataset.csv")  # columns: url, label
urls = df["url"].tolist()
labels = df["label"].astype(int).to_numpy()
```

Everything downstream (feature extraction, train/test split,
evaluation, JSON export) is dataset-agnostic.

## Output schema (`phishing_weights.json`)

```jsonc
{
  "schema_version": 1,
  "model_type": "logistic_regression" | "random_forest",
  "feature_count": 12,
  "feature_names": [/* 12 names */],
  "trained_at": "ISO-8601 timestamp",
  "training_samples": 8000,
  "test_samples": 2000,
  "test_metrics": {
    "accuracy": 0.954, "precision": ..., "recall": ..., "f1": ...,
    "confusion_matrix": [[TN, FP], [FN, TP]]
  },
  "all_metrics": { /* both models' scores so you can compare */ },
  "model": {
    "kind": "logistic_regression",
    "weights": [/* 12 floats */],
    "bias": <float>
  }
  // RF instead embeds "trees": [ [ {feature, threshold, left, right, value}, … ], … ]
}
```

The Dart loader in [`phishing_ml_service.dart`](../../lib/data/services/phishing_ml_service.dart)
handles both kinds — no app-side changes when you switch.
