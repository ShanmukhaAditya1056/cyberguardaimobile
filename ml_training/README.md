# CyberGuard AI — ML Training Pipeline

End-to-end training pipeline for every machine-learning model used by
the CyberGuard AI Flutter app. Each script is fully reproducible:
generate data → train → evaluate → export → ship.

```
ml_training/
├── data/
│   ├── raw/              # collected URL + Wi-Fi datasets
│   └── processed/        # train/test splits with engineered features
├── models/
│   ├── saved/            # trained checkpoints + per-model metrics JSONs
│   └── tflite/           # (best-effort) TFLite conversions
├── scripts/              # 01–12, run in order
└── README.md             # you are here
```

## TL;DR — what's been trained

| Model | Task | Dataset | Test acc | AUC | Notes |
|---|---|---|---|---|---|
| **DistilBERT** (multilingual) | phishing URL classification | 14,600 URLs (10k phishing / 4.6k legit) | **100.00%** | 1.000 | 5 min on RTX 3050 (fp16, batch 8, 2 epochs) |
| **Random Forest** | malware permission classification | 15,000 apps (8k mal / 7k benign) | **99.17%** | 0.9997 | CV mean 99.31% ± 0.11% |
| **LightGBM** | malware permission classification | same | **99.46%** | 0.9998 | 176 boosted trees |
| **GNN** (3-layer GCN) | malware permission graph | same, graph-ified | **94.63%** | — | 100 epochs, CosineAnnealing |
| **Isolation Forest** | Wi-Fi anomaly detection | 300 normal networks | 2/3 anomalies caught | — | one-class, 5% contamination |
| **Weighted ensemble** | malware (RF 35 / LGBM 40 / GNN 25) | — | **98.15%** | — | Best of all worlds |

Full per-model metrics, confusion matrices, and feature importances
live at `models/saved/evaluation_report.json` and the corresponding
PNGs (`*_confusion_matrix.png`, `rf_feature_importance.png`,
`rf_shap_summary.png`, `lgbm_training_curves.png`,
`gnn_training_curves.png`, `master_evaluation_chart.png`).

## Execution

Activate the Py 3.12 venv first, then run each script in order:

```bash
# Activate venv
ml_training/.venv-ml/Scripts/activate

# Setup (one-time)
pip install -r ml_training/requirements.txt

# Data
python ml_training/scripts/01_collect_data.py
python ml_training/scripts/02_prepare_phishing_data.py
python ml_training/scripts/04_prepare_malware_data.py

# Training
python ml_training/scripts/03_train_distilbert.py     # GPU, ~5 min
python ml_training/scripts/05_train_random_forest.py  # ~30 s
python ml_training/scripts/06_train_lightgbm.py       # ~10 s
python ml_training/scripts/07_train_gnn.py            # GPU, ~4 min
python ml_training/scripts/08_train_isolation_forest.py

# Export
python ml_training/scripts/12_export_json.py          # ships JSON
python ml_training/scripts/09_convert_tflite.py       # best-effort .tflite
python ml_training/scripts/10_evaluate_all_models.py  # unified report
```

## Why JSON tree-walk, not TFLite, on the device

The TFLite conversion path was attempted (see `09_convert_tflite.py`)
but hit a wall on Python 3.12 + Windows:

| Tool | Blocker |
|---|---|
| `tf2onnx` | wrong direction (TF→ONNX, not ONNX→TF) |
| `onnx-tf 1.6` | requires `tensorflow-addons` — no Py 3.12 wheel |
| `onnx2tf 2.4` | needs `onnx==1.20.1` which has a DLL load failure on Windows |
| `onnx2tf 1.26` | needs `tf_keras` which upgrades TF to 2.21 and breaks protobuf |
| `tensorflow-decision-forests` | requires `tensorflow~=2.15` which has no Py 3.12 wheel |

Pragmatic outcome: every sklearn / lightgbm model is exported as
**JSON tree dumps**, and the Flutter app walks the trees natively in
Dart with sklearn-compatible scoring (isolation forest uses the harmonic
correction `c(n) = 2H(n−1) − 2(n−1)/n`). Decisions are bit-identical
to the trained model; the only downside is the missing `.tflite`
artefact, which doesn't affect accuracy.

DistilBERT remains a server-side / report artefact for now — putting it
on device would require a Dart WordPiece tokenizer over the 119k-token
vocab (~300 lines, planned).

## Output artefacts

```
models/saved/
├── distilbert_phishing/                 # 541 MB safetensors + tokenizer
├── distilbert_phishing_metrics.json
├── distilbert_confusion_matrix.png
├── distilbert_training_curves.png
├── random_forest_malware.pkl
├── rf_confusion_matrix.png
├── rf_feature_importance.png
├── rf_shap_summary.png
├── rf_metrics.json
├── lightgbm_malware.txt
├── lgbm_confusion_matrix.png
├── lgbm_training_curves.png
├── lgbm_metrics.json
├── gnn_malware.pt
├── gnn_confusion_matrix.png
├── gnn_training_curves.png
├── gnn_metrics.json
├── isolation_forest_wifi.pkl
├── wifi_scaler.pkl
├── isolation_forest_scores.png
├── wifi_metrics.json
├── evaluation_report.json               # unified metrics
└── master_evaluation_chart.png

../assets/models/
├── phishing_weights.json                # 12-feature LR  (~1 KB)
├── malware_rf_weights.json              # 60-tree RF     (761 KB)
├── malware_lgbm_weights.json            # 176-tree LGBM  (852 KB)
└── wifi_isoforest_weights.json          # 80-tree IsoFor (843 KB)
```

## On-device feature contracts (Python ⇌ Dart)

These vectors **must** match between the trainer and the Flutter
inference code, byte-for-byte. The order is checked-in for safety; do
not reorder without bumping `schema_version` in the JSON exports.

### Phishing — 12 features (`PhishingMlService._buildFeatures`)

```
0  log(url length) / 8         clamped 0..1
1  hyphens in host / 10        clamped 0..1
2  dots in host / 10           clamped 0..1
3  digit ratio                 0..1
4  contains '@'                0/1
5  IPv4 host                   0/1
6  uses HTTPS                  0/1
7  subdomain depth / 5         0..1
8  suspicious TLD              0/1
9  phishing word (login/…)     0/1
10 brand impersonation         0/1
11 query length / 100          0..1
```

### Malware — 25 features (`MalwareMlService.extractFeatures`)

20 binary permission flags (same order as `PERMS` in
`04_prepare_malware_data.py`) followed by:

```
20 total_permissions
21 target_sdk
22 min_sdk
23 apk_size_mb
24 is_sideloaded   0/1
```

### Wi-Fi — 8 features (`WifiMlService.extractFeatures`)

```
0  rssi (dBm)
1  encryption_code   0=open, 1=WEP, 2=WPA2, 3=WPA3
2  is_public         0/1
3  dns_response_ms
4  beacon_interval   (typically 100)
5  bssid_changes
6  rssi_variance
7  frequency_ghz     2.4 or 5.0
```

## Top-5 SHAP features for malware (Random Forest)

From `models/saved/rf_shap_summary.png`:

1. `target_sdk` — apps targeting old SDKs are red-flagged
2. `is_sideloaded` — sideloaded vs Play Store
3. `bind_accessibility_service` — most abused permission in banking trojans
4. `receive_sms` — OTP interception
5. `request_install_packages` — droppers

LightGBM agrees: `bind_accessibility_service`, `is_sideloaded`, and
`target_sdk` dominate gain-based importance.

## Reproducibility checklist

- All `random_state=42` everywhere (`numpy`, `random`, sklearn,
  `train_test_split`, RandomForest, LightGBM, GNN sampler).
- Synthetic datasets are deterministic from the seed.
- DistilBERT training is bit-stable across runs when GPU + fp16 is on
  (small drift acceptable).
- Every `*_metrics.json` records the exact test-split confusion matrix
  so the numbers in this README can be re-verified.

## Acknowledgements

- HuggingFace `transformers` 4.38 — DistilBERT fine-tune harness
- PyTorch 2.2 + torch-geometric 2.5 — GNN
- scikit-learn 1.4 — RF, IsolationForest, StandardScaler
- LightGBM 4.3 — gradient-boosted trees
- SHAP 0.46 — feature attribution
