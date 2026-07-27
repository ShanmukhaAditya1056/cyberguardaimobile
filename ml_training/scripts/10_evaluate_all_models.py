"""
10_evaluate_all_models.py — aggregate every per-model metrics JSON
into models/saved/evaluation_report.json and produce a master chart.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SAVE = ROOT / "models" / "saved"
TFL = ROOT / "models" / "tflite"

PER_MODEL = {
    "phishing_distilbert":
        ("distilbert_phishing_metrics.json", "phishing_model.tflite"),
    "malware_random_forest":
        ("rf_metrics.json", "rf_malware.tflite"),
    "malware_lightgbm":
        ("lgbm_metrics.json", "lgbm_malware.tflite"),
    "malware_gnn":
        ("gnn_metrics.json", "gnn_malware.tflite"),
    "wifi_isolation_forest":
        ("wifi_metrics.json", "wifi_model.tflite"),
}


def _kb(p: Path) -> float:
    return p.stat().st_size / 1024 if p.exists() else 0.0


def main() -> int:
    print("=" * 60)
    print(" 10_evaluate_all_models — start")
    print("=" * 60)
    report = {}
    table = []
    for name, (mfile, tfile) in PER_MODEL.items():
        m = SAVE / mfile
        t = TFL / tfile
        entry: dict = {"model_size_kb": _kb(t)}
        if m.exists():
            entry.update(json.loads(m.read_text()))
        report[name] = entry
        acc = entry.get("accuracy", 0.0)
        auc = entry.get("auc", 0.0)
        status = "READY" if t.exists() else "NO TFLITE"
        table.append((name, acc, auc, _kb(t), status))

    # Optional ensemble metric: average of RF+LGBM+GNN if all present
    rf = report["malware_random_forest"].get("accuracy")
    lg = report["malware_lightgbm"].get("accuracy")
    gn = report["malware_gnn"].get("accuracy")
    if rf and lg and gn:
        report["malware_ensemble"] = {
            "accuracy": (rf * 0.35 + lg * 0.40 + gn * 0.25),
            "ensemble_method": "weighted_average_35_40_25",
        }
    (SAVE / "evaluation_report.json").write_text(json.dumps(report, indent=2))

    # Master comparison chart
    names = [t[0] for t in table]
    accs = [t[1] for t in table]
    sizes = [t[3] for t in table]
    fig, axs = plt.subplots(1, 2, figsize=(12, 4.5))
    axs[0].barh(names, accs, color="#1A73E8")
    axs[0].set_xlim(0, 1.0); axs[0].set_title("Test accuracy")
    axs[1].scatter(sizes, accs, c="#E23744", s=120)
    for n, s, a in zip(names, sizes, accs):
        axs[1].annotate(n, (s, a), fontsize=8,
                        xytext=(5, 5), textcoords="offset points")
    axs[1].set_xlabel("Model size (KB)"); axs[1].set_ylabel("Accuracy")
    axs[1].set_title("Size vs accuracy")
    plt.tight_layout()
    plt.savefig(SAVE / "master_evaluation_chart.png", dpi=150)
    plt.close()

    print(f"{'Model':24s} {'Acc':8s} {'AUC':8s} {'KB':>8s}  Status")
    for n, a, u, k, st in table:
        print(f"{n:24s} {a:7.4f} {u:7.4f} {k:8.1f}  {st}")
    print(f"[10] DONE  written {SAVE / 'evaluation_report.json'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
