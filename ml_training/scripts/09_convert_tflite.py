"""
09_convert_tflite.py — convert every trained model to TFLite.

Pipeline per model:
    sklearn / lightgbm  ->  ONNX  ->  TF SavedModel (onnx-tf)  ->  TFLite
    PyTorch (DistilBERT)  ->  ONNX  ->  TF SavedModel (onnx-tf)  ->  TFLite

Each .tflite is written to models/tflite/ and then mirrored into
../assets/models/tflite/.
"""

from __future__ import annotations

import shutil
import sys
import warnings
from pathlib import Path

warnings.filterwarnings("ignore")

ROOT = Path(__file__).resolve().parents[1]
SAVE = ROOT / "models" / "saved"
TFL = ROOT / "models" / "tflite"
TFL.mkdir(parents=True, exist_ok=True)

FLUTTER_ASSETS = ROOT.parent / "assets" / "models" / "tflite"
FLUTTER_ASSETS.mkdir(parents=True, exist_ok=True)


def _onnx_to_tflite(onnx_path: Path, tflite_path: Path) -> None:
    """onnx-tf converts ONNX -> TF SavedModel -> TFLite via tf.lite."""
    import onnx
    import tensorflow as tf
    from onnx_tf.backend import prepare

    saved_dir = onnx_path.parent / f"{onnx_path.stem}_tf"
    if saved_dir.exists():
        shutil.rmtree(saved_dir)

    model = onnx.load(str(onnx_path))
    tf_rep = prepare(model)
    tf_rep.export_graph(str(saved_dir))

    converter = tf.lite.TFLiteConverter.from_saved_model(str(saved_dir))
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    # Allow TF ops if a pure-TFLite kernel is missing — important for
    # transformer ops in DistilBERT.
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
        tf.lite.OpsSet.SELECT_TF_OPS,
    ]
    tflite_bytes = converter.convert()
    tflite_path.write_bytes(tflite_bytes)
    kb = tflite_path.stat().st_size / 1024
    print(f"[09]   wrote {tflite_path.name}  ({kb:.1f} KB)")


def convert_rf() -> Path:
    print("[09] Random Forest -> ONNX -> TFLite")
    import joblib
    import onnx
    from skl2onnx import convert_sklearn
    from skl2onnx.common.data_types import FloatTensorType

    rf = joblib.load(SAVE / "random_forest_malware.pkl")
    n = rf.n_features_in_
    onnx_path = SAVE / "rf_malware.onnx"
    # ai.onnx.ml v3 is the latest version onnx-tf 1.6 supports.
    onnx_model = convert_sklearn(
        rf, "random_forest",
        [("float_input", FloatTensorType([None, n]))],
        target_opset={"": 12, "ai.onnx.ml": 3},
    )
    onnx.save(onnx_model, str(onnx_path))
    tfl = TFL / "rf_malware.tflite"
    _onnx_to_tflite(onnx_path, tfl)
    return tfl


def convert_lgbm() -> Path:
    print("[09] LightGBM -> ONNX -> TFLite")
    import lightgbm as lgb
    import onnx
    from onnxmltools import convert_lightgbm
    # IMPORTANT: LightGBM needs onnxmltools' own FloatTensorType, not skl2onnx's.
    from onnxmltools.convert.common.data_types import FloatTensorType

    booster = lgb.Booster(model_file=str(SAVE / "lightgbm_malware.txt"))
    n = booster.num_feature()
    onnx_path = SAVE / "lgbm_malware.onnx"
    onnx_model = convert_lightgbm(
        booster,
        initial_types=[("float_input", FloatTensorType([None, n]))],
        target_opset={"": 12, "ai.onnx.ml": 3},
    )
    onnx.save(onnx_model, str(onnx_path))
    tfl = TFL / "lgbm_malware.tflite"
    _onnx_to_tflite(onnx_path, tfl)
    return tfl


def convert_isoforest() -> Path:
    print("[09] Isolation Forest -> ONNX -> TFLite")
    import joblib
    import onnx
    from skl2onnx import convert_sklearn
    from skl2onnx.common.data_types import FloatTensorType

    iso = joblib.load(SAVE / "isolation_forest_wifi.pkl")
    n = iso.n_features_in_
    onnx_path = SAVE / "wifi_model.onnx"
    onnx_model = convert_sklearn(
        iso, "isolation_forest",
        [("float_input", FloatTensorType([None, n]))],
        target_opset={"": 12, "ai.onnx.ml": 3},
    )
    onnx.save(onnx_model, str(onnx_path))
    tfl = TFL / "wifi_model.tflite"
    _onnx_to_tflite(onnx_path, tfl)
    return tfl


def convert_distilbert() -> Path:
    print("[09] DistilBERT -> ONNX -> TFLite")
    import torch
    from transformers import DistilBertForSequenceClassification

    src = SAVE / "distilbert_phishing"
    if not src.exists():
        raise SystemExit(
            f"[09] {src} not found — run 03_train_distilbert.py first.")
    model = DistilBertForSequenceClassification.from_pretrained(str(src))
    model.eval()
    # Fixed input shape [1, 128]. onnx-tf doesn't handle dynamic axes well
    # when reaching TFLite, so we lock the sequence length.
    dummy_ids = torch.zeros(1, 128, dtype=torch.long)
    dummy_mask = torch.zeros(1, 128, dtype=torch.long)
    onnx_path = SAVE / "distilbert_phishing.onnx"
    torch.onnx.export(
        model, (dummy_ids, dummy_mask), str(onnx_path),
        input_names=["input_ids", "attention_mask"],
        output_names=["logits"],
        opset_version=12,
        do_constant_folding=True,
    )
    tfl = TFL / "phishing_model.tflite"
    _onnx_to_tflite(onnx_path, tfl)
    return tfl


def main() -> int:
    print("=" * 60)
    print(" 09_convert_tflite — start")
    print("=" * 60)
    converted: list[Path] = []
    for name, fn in (
        ("Random Forest", convert_rf),
        ("LightGBM", convert_lgbm),
        ("Isolation Forest", convert_isoforest),
        ("DistilBERT", convert_distilbert),
    ):
        try:
            converted.append(fn())
        except Exception as exc:
            print(f"[09] FAIL {name}: {type(exc).__name__}: {exc}")

    # Copy TFLite artefacts into Flutter assets
    print("[09] copying to Flutter assets…")
    for tfl in converted:
        dest = FLUTTER_ASSETS / tfl.name
        shutil.copyfile(tfl, dest)
        kb = dest.stat().st_size / 1024
        status = "PASS" if kb < 2048 else ("LARGE" if kb < 60_000 else "OVERSIZE")
        print(f"      {tfl.name:24s}  {kb:9.1f} KB  {status}")

    print(f"[09] DONE  {len(converted)}/4 models in {FLUTTER_ASSETS}")
    return 0 if converted else 1


if __name__ == "__main__":
    sys.exit(main())
