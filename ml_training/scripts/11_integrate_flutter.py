"""
11_integrate_flutter.py — verify the assets are present, sized, and
referenced by pubspec.yaml.

Adds the `assets/models/tflite/` directory to pubspec.yaml if missing.
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1].parent
ASSETS = ROOT / "assets" / "models" / "tflite"
PUBSPEC = ROOT / "pubspec.yaml"

EXPECTED = [
    "phishing_model.tflite",
    "rf_malware.tflite",
    "lgbm_malware.tflite",
    "gnn_malware.tflite",
    "wifi_model.tflite",
]


def main() -> int:
    print("=" * 60)
    print(" 11_integrate_flutter — start")
    print("=" * 60)
    missing = []
    oversized = []
    for name in EXPECTED:
        p = ASSETS / name
        if not p.exists():
            missing.append(name); continue
        kb = p.stat().st_size / 1024
        ok = "PASS" if kb < 2048 else "OVERSIZE"
        print(f"  {name:24s}  {kb:8.1f} KB  {ok}")
        if kb >= 2048:
            oversized.append(name)

    if missing:
        print(f"[11] MISSING artefacts: {missing}")
    if oversized:
        print(f"[11] OVERSIZED (>2 MB): {oversized}")

    # pubspec.yaml: ensure 'assets/models/tflite/' is listed
    txt = PUBSPEC.read_text(encoding="utf-8")
    if "assets/models/tflite/" not in txt:
        lines = txt.splitlines()
        for i, line in enumerate(lines):
            if "assets:" in line and line.strip().endswith("assets:"):
                indent = line[: line.index("assets:")]
                lines.insert(i + 1,
                             f"{indent}  - assets/models/tflite/")
                break
        PUBSPEC.write_text("\n".join(lines), encoding="utf-8")
        print("[11] added 'assets/models/tflite/' to pubspec.yaml")
    else:
        print("[11] pubspec.yaml already references the TFLite asset dir")

    print("[11] Checklist:")
    print("  1. Run `flutter pub get` to refresh the bundle.")
    print("  2. Hot-restart the app — TFLiteService picks up the models.")
    print("  3. If any model is OVERSIZED, re-train with smaller params.")
    return 0 if not missing else 1


if __name__ == "__main__":
    sys.exit(main())
