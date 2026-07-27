"""
08_train_isolation_forest.py — one-class anomaly detector for Wi-Fi.

Trains on data/raw/wifi_readings.csv (normal networks only), then
validates that hand-crafted anomalous networks (open / WEP / evil twin)
get flagged.

Outputs:
  * models/saved/isolation_forest_wifi.pkl
  * models/saved/wifi_scaler.pkl
  * models/saved/isolation_forest_scores.png
  * models/saved/wifi_metrics.json
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import joblib
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
SAVE = ROOT / "models" / "saved"
SAVE.mkdir(parents=True, exist_ok=True)

ANOMALIES = [
    # Open public network
    {"rssi": -85, "encryption_code": 0, "is_public": 1,
     "dns_response_ms": 800, "beacon_interval": 50,
     "bssid_changes": 5, "rssi_variance": 15.0, "frequency_ghz": 2.4},
    # Evil twin
    {"rssi": -90, "encryption_code": 2, "is_public": 1,
     "dns_response_ms": 1200, "beacon_interval": 50,
     "bssid_changes": 3, "rssi_variance": 18.0, "frequency_ghz": 2.4},
    # WEP
    {"rssi": -60, "encryption_code": 1, "is_public": 0,
     "dns_response_ms": 400, "beacon_interval": 100,
     "bssid_changes": 0, "rssi_variance": 5.0, "frequency_ghz": 2.4},
]


def main() -> int:
    print("=" * 60)
    print(" 08_train_isolation_forest — start")
    print("=" * 60)
    src = RAW / "wifi_readings.csv"
    if not src.exists():
        print("[08] Run 01_collect_data.py first.", file=sys.stderr)
        return 1

    df = pd.read_csv(src)
    features = list(df.columns)
    print(f"[08] training on {len(df)} normal Wi-Fi readings; "
          f"features={features}")

    scaler = StandardScaler()
    X = scaler.fit_transform(df.values)
    # Smaller IsoForest so the exported JSON stays under ~1 MB. Anomaly
    # detection quality is essentially unchanged at this scale.
    iso = IsolationForest(
        n_estimators=80, contamination=0.05, max_samples=128,
        max_features=1.0, bootstrap=False, random_state=42, verbose=0,
    )
    iso.fit(X)

    # Validate with handcrafted anomalies
    anom_df = pd.DataFrame(ANOMALIES, columns=features)
    Xa = scaler.transform(anom_df.values)
    preds = iso.predict(Xa)
    scores = iso.decision_function(Xa)
    detected = int((preds == -1).sum())
    print(f"[08] anomaly detection: {detected}/{len(ANOMALIES)} flagged")
    for i, (p, s) in enumerate(zip(preds, scores)):
        print(f"      sample {i}  pred={p}  score={s:.4f}")

    # Visualise score distribution
    normal_scores = iso.decision_function(X)
    plt.figure(figsize=(7, 4))
    plt.hist(normal_scores, bins=40, alpha=0.7, label="normal networks")
    for s in scores:
        plt.axvline(s, color="red", linestyle="--", alpha=0.7)
    plt.axvline(scores[0], color="red", linestyle="--",
                label="injected anomalies")
    plt.legend(); plt.title("Isolation Forest — anomaly score distribution")
    plt.tight_layout()
    plt.savefig(SAVE / "isolation_forest_scores.png", dpi=150); plt.close()

    joblib.dump(iso, SAVE / "isolation_forest_wifi.pkl")
    joblib.dump(scaler, SAVE / "wifi_scaler.pkl")
    (SAVE / "wifi_metrics.json").write_text(json.dumps({
        "contamination": 0.05,
        "n_estimators": 200,
        "training_samples": len(df),
        "anomalies_tested": len(ANOMALIES),
        "anomalies_detected": detected,
        "detection_rate": detected / len(ANOMALIES),
        "feature_means": scaler.mean_.tolist(),
        "feature_scales": scaler.scale_.tolist(),
        "feature_names": features,
    }, indent=2))
    print(f"[08] DONE  saved to {SAVE / 'isolation_forest_wifi.pkl'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
