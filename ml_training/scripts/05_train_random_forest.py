"""
05_train_random_forest.py — malware Random Forest classifier.

Runs end-to-end on the synthetic dataset produced by
04_prepare_malware_data.py.  Exports:

  * models/saved/random_forest_malware.pkl  (joblib)
  * models/saved/rf_confusion_matrix.png
  * models/saved/rf_feature_importance.png
  * models/saved/rf_shap_summary.png   (best-effort; skipped if shap missing)
  * models/saved/rf_metrics.json
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import joblib
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (accuracy_score, classification_report,
                             confusion_matrix, roc_auc_score)
from sklearn.model_selection import (StratifiedKFold, cross_val_score,
                                     train_test_split)

ROOT = Path(__file__).resolve().parents[1]
PROC = ROOT / "data" / "processed"
SAVE = ROOT / "models" / "saved"
SAVE.mkdir(parents=True, exist_ok=True)


def main() -> int:
    print("=" * 60)
    print(" 05_train_random_forest — start")
    print("=" * 60)
    src = PROC / "malware_train.csv"
    if not src.exists():
        print("[05] Run 04_prepare_malware_data.py first.", file=sys.stderr)
        return 1

    df = pd.read_csv(src).fillna(0)
    X = df.drop(columns=["label"])
    y = df["label"]
    feature_names = X.columns.tolist()
    print(f"[05] shape={df.shape}  classes=\n{y.value_counts()}")

    X_tr, X_te, y_tr, y_te = train_test_split(
        X, y, test_size=0.20, stratify=y, random_state=42)

    # Smaller, ship-friendly Random Forest: caps trees + depth so the JSON
    # export stays under ~500 KB while still beating 99 % accuracy on the
    # synthetic malware dataset.
    rf = RandomForestClassifier(
        n_estimators=60, max_depth=8, min_samples_split=4,
        min_samples_leaf=2, max_features="sqrt", bootstrap=True,
        class_weight="balanced", random_state=42, n_jobs=-1, verbose=0,
    )
    rf.fit(X_tr, y_tr)

    y_pred = rf.predict(X_te)
    y_prob = rf.predict_proba(X_te)[:, 1]
    acc = accuracy_score(y_te, y_pred)
    auc = roc_auc_score(y_te, y_prob)
    print(classification_report(y_te, y_pred,
                                target_names=["benign", "malware"]))
    print(f"[05] accuracy={acc:.4f}  auc={auc:.4f}")

    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
    cv_scores = cross_val_score(rf, X, y, cv=cv, scoring="accuracy", n_jobs=-1)
    print(f"[05] 5-fold CV accuracy = {cv_scores.mean():.4f} "
          f"± {cv_scores.std():.4f}")

    # Confusion matrix
    cm = confusion_matrix(y_te, y_pred)
    plt.figure(figsize=(5, 4))
    sns.heatmap(cm, annot=True, fmt="d", cmap="Blues",
                xticklabels=["benign", "malware"],
                yticklabels=["benign", "malware"])
    plt.title("Random Forest — Confusion Matrix")
    plt.tight_layout()
    plt.savefig(SAVE / "rf_confusion_matrix.png", dpi=150)
    plt.close()

    # Feature importance
    order = np.argsort(rf.feature_importances_)[::-1][:20]
    plt.figure(figsize=(8, 6))
    plt.barh(range(len(order)), rf.feature_importances_[order][::-1])
    plt.yticks(range(len(order)),
               [feature_names[i] for i in order][::-1])
    plt.title("Top-20 feature importance")
    plt.tight_layout()
    plt.savefig(SAVE / "rf_feature_importance.png", dpi=150)
    plt.close()

    # SHAP (optional — skip if not installed / fails)
    try:
        import shap
        explainer = shap.TreeExplainer(rf)
        shap_values = explainer.shap_values(X_te.iloc[:200])
        # SHAP changed shape conventions for binary classifiers across
        # versions; normalise to a 2-D (n_samples, n_features) array of
        # contributions for the positive class.
        if isinstance(shap_values, list):
            sv = shap_values[1]
        elif hasattr(shap_values, "ndim") and shap_values.ndim == 3:
            # newer shap returns (n_samples, n_features, n_classes)
            sv = shap_values[:, :, 1]
        else:
            sv = shap_values
        shap.summary_plot(sv, X_te.iloc[:200],
                          feature_names=feature_names, show=False)
        plt.tight_layout()
        plt.savefig(SAVE / "rf_shap_summary.png", dpi=150)
        plt.close()
        mean_abs = np.abs(sv).mean(axis=0)
        top = np.argsort(mean_abs)[::-1][:5]
        print("[05] Top-5 SHAP features:",
              [feature_names[i] for i in top])
    except Exception as exc:
        print(f"[05] SHAP step skipped: {exc}")

    joblib.dump(rf, SAVE / "random_forest_malware.pkl")
    (SAVE / "rf_metrics.json").write_text(json.dumps({
        "accuracy": acc, "auc": auc,
        "cv_mean": float(cv_scores.mean()),
        "cv_std": float(cv_scores.std()),
        "confusion_matrix": cm.tolist(),
        "top_features": [feature_names[i] for i in order[:10]],
    }, indent=2))
    print(f"[05] DONE  saved to {SAVE / 'random_forest_malware.pkl'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
