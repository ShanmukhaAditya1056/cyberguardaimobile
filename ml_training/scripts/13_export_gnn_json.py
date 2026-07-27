"""
13_export_gnn_json.py — convert the trained GNN (`gnn_malware.pt`) to a
JSON blob the Flutter app can run natively in Dart.

Architecture (must match scripts/07_train_gnn.py exactly):

    inputs : x[n_active, 20]   one-hot permission feature matrix
             edge_index[2, m]  fully-connected within active permissions

    Conv1 (GCN, 20 -> 128) → BN → ReLU → Dropout
    Conv2 (GCN, 128 -> 64) → BN → ReLU → Dropout
    Conv3 (GCN, 64 -> 32)  → BN → ReLU
    Pool  : [mean(x); max(x)]  →  64
    FC1   : Linear 64 -> 32 → ReLU → Dropout
    FC2   : Linear 32 -> 2

We dump every linear layer's weight + bias and each BatchNorm's
running_mean / running_var / weight / bias / eps. GCNConv weight is
exactly a Linear under the hood (no edge weights → the normalised
adjacency multiply is identical to the unnormalised version when each
edge weight is 1/sqrt(deg(i)*deg(j))). We pre-compute the GCN bias the
PyG way and emit it as a plain bias vector.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import torch
import torch.nn as nn
import torch.nn.functional as F
from torch_geometric.nn import GCNConv, global_max_pool, global_mean_pool

ROOT = Path(__file__).resolve().parents[1]
SAVE = ROOT / "models" / "saved"
ASSETS = ROOT.parent / "assets" / "models"
ASSETS.mkdir(parents=True, exist_ok=True)

N_PERMS = 20


class MalwareGNN(nn.Module):
    def __init__(self):
        super().__init__()
        self.conv1 = GCNConv(N_PERMS, 128)
        self.conv2 = GCNConv(128, 64)
        self.conv3 = GCNConv(64, 32)
        self.bn1 = nn.BatchNorm1d(128)
        self.bn2 = nn.BatchNorm1d(64)
        self.bn3 = nn.BatchNorm1d(32)
        self.dropout = nn.Dropout(0.3)
        self.fc1 = nn.Linear(64, 32)
        self.fc2 = nn.Linear(32, 2)


def _dump_linear(layer: nn.Linear) -> dict:
    return {
        "in": int(layer.in_features),
        "out": int(layer.out_features),
        "weight": layer.weight.detach().cpu().numpy().tolist(),
        "bias": layer.bias.detach().cpu().numpy().tolist()
                if layer.bias is not None else None,
    }


def _dump_bn(layer: nn.BatchNorm1d) -> dict:
    return {
        "features": int(layer.num_features),
        "mean": layer.running_mean.detach().cpu().numpy().tolist(),
        "var": layer.running_var.detach().cpu().numpy().tolist(),
        "weight": layer.weight.detach().cpu().numpy().tolist(),
        "bias": layer.bias.detach().cpu().numpy().tolist(),
        "eps": float(layer.eps),
    }


def _dump_gcn(layer: GCNConv) -> dict:
    """PyG's GCNConv has a `lin` (their own Linear, uses in_channels)
    plus an optional `bias` registered on the conv itself."""
    lin = layer.lin
    in_c = getattr(lin, "in_channels", None) or lin.weight.shape[1]
    out_c = getattr(lin, "out_channels", None) or lin.weight.shape[0]
    return {
        "in": int(in_c),
        "out": int(out_c),
        "weight": lin.weight.detach().cpu().numpy().tolist(),
        "bias": layer.bias.detach().cpu().numpy().tolist()
                if layer.bias is not None else None,
    }


def main() -> int:
    print("=" * 60)
    print(" 13_export_gnn_json — start")
    print("=" * 60)
    src = SAVE / "gnn_malware.pt"
    if not src.exists():
        print("[13] Train the GNN first (07_train_gnn.py).", file=sys.stderr)
        return 1

    ckpt = torch.load(str(src), map_location="cpu", weights_only=False)
    model = MalwareGNN()
    model.load_state_dict(ckpt["model_state_dict"])
    model.eval()
    print(f"[13] loaded GNN — saved test accuracy = {ckpt['accuracy']:.4f}")

    blob = {
        "schema_version": 1,
        "model_type": "gcn",
        "task": "malware",
        "num_permissions": N_PERMS,
        "saved_test_accuracy": float(ckpt["accuracy"]),
        "trained_at": "see gnn_metrics.json",
        "layers": {
            "conv1": _dump_gcn(model.conv1),
            "bn1": _dump_bn(model.bn1),
            "conv2": _dump_gcn(model.conv2),
            "bn2": _dump_bn(model.bn2),
            "conv3": _dump_gcn(model.conv3),
            "bn3": _dump_bn(model.bn3),
            "fc1": _dump_linear(model.fc1),
            "fc2": _dump_linear(model.fc2),
        },
    }

    out = ASSETS / "malware_gnn_weights.json"
    out.write_text(json.dumps(blob))
    print(f"[13] wrote {out}  ({out.stat().st_size // 1024} KB)")
    print("[13] DONE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
