"""
12_export_json.py — convert trained sklearn / lightgbm artefacts into
the tiny JSON blobs the Flutter app loads at runtime.

This is the **no-TensorFlow path** that works on Python 3.13/3.14 where
the TFLite pipeline (script 09) cannot run.

Produces:
  * assets/models/malware_rf_weights.json
  * assets/models/malware_lgbm_weights.json
  * assets/models/wifi_isoforest_weights.json
"""

from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

import joblib
import lightgbm as lgb
import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest, RandomForestClassifier
from sklearn.metrics import (accuracy_score, confusion_matrix, f1_score,
                             precision_score, recall_score, roc_auc_score)
from sklearn.model_selection import train_test_split

ROOT = Path(__file__).resolve().parents[1]
PROC = ROOT / "data" / "processed"
SAVE = ROOT / "models" / "saved"
ASSETS = ROOT.parent / "assets" / "models"
ASSETS.mkdir(parents=True, exist_ok=True)


# ─── RF ──────────────────────────────────────────────────────────────────

def export_rf() -> None:
    rf: RandomForestClassifier = joblib.load(SAVE / "random_forest_malware.pkl")
    print(f"[12] RF estimators={len(rf.estimators_)}  n_features={rf.n_features_in_}")

    df = pd.read_csv(PROC / "malware_train.csv").fillna(0)
    X = df.drop(columns=["label"]); y = df["label"]
    _, X_te, _, y_te = train_test_split(
        X, y, test_size=0.20, stratify=y, random_state=42)
    y_pred = rf.predict(X_te)
    metrics = _metrics(y_te, y_pred, rf.predict_proba(X_te)[:, 1])

    trees: list[list[dict]] = []
    for est in rf.estimators_:
        t = est.tree_
        nodes: list[dict] = []
        for i in range(t.node_count):
            leaf = t.children_left[i] == t.children_right[i]
            if leaf:
                v = t.value[i][0]
                p1 = float(v[1] / v.sum()) if v.sum() else 0.0
                nodes.append({"feature": -1, "threshold": 0.0,
                              "left": -1, "right": -1, "value": p1})
            else:
                nodes.append({
                    "feature": int(t.feature[i]),
                    "threshold": float(t.threshold[i]),
                    "left": int(t.children_left[i]),
                    "right": int(t.children_right[i]),
                    "value": 0.0,
                })
        trees.append(nodes)

    out = {
        "schema_version": 1,
        "model_type": "random_forest",
        "task": "malware",
        "feature_count": int(rf.n_features_in_),
        "feature_names": list(X.columns),
        "trained_at": datetime.now(timezone.utc).isoformat(),
        "test_metrics": metrics,
        "model": {"kind": "random_forest", "trees": trees},
    }
    p = ASSETS / "malware_rf_weights.json"
    p.write_text(json.dumps(out))
    print(f"[12] wrote {p}  ({p.stat().st_size // 1024} KB)")


# ─── LGBM ────────────────────────────────────────────────────────────────

def export_lgbm() -> None:
    booster = lgb.Booster(model_file=str(SAVE / "lightgbm_malware.txt"))
    dump = booster.dump_model()
    print(f"[12] LGBM trees={len(dump['tree_info'])}")

    df = pd.read_csv(PROC / "malware_train.csv").fillna(0)
    X = df.drop(columns=["label"]); y = df["label"]
    _, X_te, _, y_te = train_test_split(
        X, y, test_size=0.20, stratify=y, random_state=42)
    y_prob = booster.predict(X_te)
    y_pred = (y_prob >= 0.5).astype(int)
    metrics = _metrics(y_te, y_pred, y_prob)

    # Flatten every tree to {feature, threshold, left, right, leaf_value}.
    trees: list[list[dict]] = []
    for ti in dump["tree_info"]:
        nodes: list[dict] = []
        _flatten_lgbm_node(ti["tree_structure"], nodes)
        trees.append(nodes)

    out = {
        "schema_version": 1,
        "model_type": "lightgbm",
        "task": "malware",
        "feature_count": int(booster.num_feature()),
        "feature_names": booster.feature_name(),
        "objective": dump.get("objective", "binary"),
        "trained_at": datetime.now(timezone.utc).isoformat(),
        "test_metrics": metrics,
        "model": {"kind": "lightgbm", "trees": trees},
    }
    p = ASSETS / "malware_lgbm_weights.json"
    p.write_text(json.dumps(out))
    print(f"[12] wrote {p}  ({p.stat().st_size // 1024} KB)")


def _flatten_lgbm_node(node: dict, out: list[dict]) -> int:
    idx = len(out)
    out.append({})  # placeholder, fill in below
    if "leaf_value" in node:
        out[idx] = {
            "feature": -1, "threshold": 0.0,
            "left": -1, "right": -1,
            "value": float(node["leaf_value"]),
        }
        return idx
    left = _flatten_lgbm_node(node["left_child"], out)
    right = _flatten_lgbm_node(node["right_child"], out)
    # LightGBM uses <= for left when decision_type == "no_greater"
    out[idx] = {
        "feature": int(node["split_feature"]),
        "threshold": float(node["threshold"]),
        "left": left,
        "right": right,
        "value": 0.0,
    }
    return idx


# ─── Isolation Forest ────────────────────────────────────────────────────

def export_isoforest() -> None:
    iso: IsolationForest = joblib.load(SAVE / "isolation_forest_wifi.pkl")
    scaler = joblib.load(SAVE / "wifi_scaler.pkl")
    print(f"[12] IsoForest estimators={len(iso.estimators_)}  "
          f"features={iso.n_features_in_}")

    trees: list[list[dict]] = []
    for est, feats in zip(iso.estimators_, iso.estimators_features_):
        t = est.tree_
        nodes: list[dict] = []
        for i in range(t.node_count):
            leaf = t.children_left[i] == t.children_right[i]
            if leaf:
                # Use n_node_samples as the depth estimator's terminal weight.
                nodes.append({
                    "feature": -1, "threshold": 0.0,
                    "left": -1, "right": -1,
                    "value": float(t.n_node_samples[i]),
                })
            else:
                # Map tree's local feature index back to the global index.
                global_feat = int(feats[int(t.feature[i])])
                nodes.append({
                    "feature": global_feat,
                    "threshold": float(t.threshold[i]),
                    "left": int(t.children_left[i]),
                    "right": int(t.children_right[i]),
                    "value": 0.0,
                })
        trees.append(nodes)

    out = {
        "schema_version": 1,
        "model_type": "isolation_forest",
        "task": "wifi_anomaly",
        "feature_count": int(iso.n_features_in_),
        "feature_names": ["rssi", "encryption_code", "is_public",
                          "dns_response_ms", "beacon_interval",
                          "bssid_changes", "rssi_variance", "frequency_ghz"],
        "n_estimators": len(iso.estimators_),
        "max_samples": int(iso.max_samples_),
        "trained_at": datetime.now(timezone.utc).isoformat(),
        "scaler": {
            "mean": scaler.mean_.tolist(),
            "scale": scaler.scale_.tolist(),
        },
        "offset": float(iso.offset_),
        "model": {"kind": "isolation_forest", "trees": trees},
    }
    p = ASSETS / "wifi_isoforest_weights.json"
    p.write_text(json.dumps(out))
    print(f"[12] wrote {p}  ({p.stat().st_size // 1024} KB)")


def _metrics(y_true, y_pred, y_prob) -> dict:
    return {
        "accuracy": float(accuracy_score(y_true, y_pred)),
        "precision": float(precision_score(y_true, y_pred, zero_division=0)),
        "recall": float(recall_score(y_true, y_pred, zero_division=0)),
        "f1": float(f1_score(y_true, y_pred, zero_division=0)),
        "auc": float(roc_auc_score(y_true, y_prob)),
        "confusion_matrix": confusion_matrix(y_true, y_pred).tolist(),
    }


def main() -> int:
    print("=" * 60)
    print(" 12_export_json — start")
    print("=" * 60)
    export_rf()
    export_lgbm()
    export_isoforest()
    print("[12] DONE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
