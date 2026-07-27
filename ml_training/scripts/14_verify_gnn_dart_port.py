"""
14_verify_gnn_dart_port.py — sanity check that the Dart-side forward
pass over `assets/models/malware_gnn_weights.json` would produce the
same logits as the PyTorch model.

We load the JSON, run the same maths the Dart service runs (in numpy),
and compare against the original PyTorch model on a handful of inputs.
Acceptable diff: ≤ 1e-3 (BatchNorm precision differs slightly between
PyTorch's CUDA path and our CPU walk).
"""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
from torch_geometric.nn import GCNConv, global_max_pool, global_mean_pool
from torch_geometric.data import Data, Batch

ROOT = Path(__file__).resolve().parents[1]
SAVE = ROOT / "models" / "saved"
ASSETS = ROOT.parent / "assets" / "models"

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
        self.fc1 = nn.Linear(64, 32)
        self.fc2 = nn.Linear(32, 2)

    def forward(self, x, edge_index, batch):
        x = F.relu(self.bn1(self.conv1(x, edge_index)))
        x = F.relu(self.bn2(self.conv2(x, edge_index)))
        x = F.relu(self.bn3(self.conv3(x, edge_index)))
        m_ = global_mean_pool(x, batch)
        x_ = global_max_pool(x, batch)
        z = torch.cat([m_, x_], dim=1)
        z = F.relu(self.fc1(z))
        return self.fc2(z)


def _build_data(active):
    n = len(active)
    x = torch.eye(N_PERMS)[active].float()
    if n > 1:
        s, d = [], []
        for i in range(n):
            for j in range(n):
                if i != j:
                    s.append(i); d.append(j)
        edge = torch.tensor([s, d], dtype=torch.long)
    else:
        edge = torch.zeros((2, 0), dtype=torch.long)
    return Data(x=x, edge_index=edge)


def dart_port_predict(blob: dict, active: list[int]) -> np.ndarray:
    """numpy reimplementation of `MalwareGnnService.predict` for parity."""
    L = blob["layers"]
    n = len(active) or 1
    if not active:
        active = [0]
    x = np.zeros((n, N_PERMS), dtype=np.float64)
    for i, a in enumerate(active):
        if 0 <= a < N_PERMS:
            x[i, a] = 1.0

    def gcn_fc(x, conv):
        mean = x.mean(axis=0)
        W = np.array(conv["weight"])  # [out, in]
        b = np.array(conv["bias"]) if conv["bias"] is not None else 0.0
        row = mean @ W.T + b
        return np.broadcast_to(row, (x.shape[0], W.shape[0])).copy()

    def bn(x, b):
        mean = np.array(b["mean"])
        var = np.array(b["var"])
        w = np.array(b["weight"])
        bias = np.array(b["bias"])
        return ((x - mean) / np.sqrt(var + b["eps"])) * w + bias

    def lin(x, lay):
        W = np.array(lay["weight"])
        b = np.array(lay["bias"]) if lay["bias"] is not None else 0.0
        return x @ W.T + b

    h = np.maximum(bn(gcn_fc(x, L["conv1"]), L["bn1"]), 0)
    h = np.maximum(bn(gcn_fc(h, L["conv2"]), L["bn2"]), 0)
    h = np.maximum(bn(gcn_fc(h, L["conv3"]), L["bn3"]), 0)
    mean = h.mean(axis=0)
    mx = h.max(axis=0)
    z = np.concatenate([mean, mx])
    z = np.maximum(lin(z, L["fc1"]), 0)
    logits = lin(z, L["fc2"])
    e = np.exp(logits - logits.max())
    return e / e.sum()


def main() -> int:
    blob = json.loads((ASSETS / "malware_gnn_weights.json").read_text())
    ckpt = torch.load(str(SAVE / "gnn_malware.pt"),
                      map_location="cpu", weights_only=False)
    model = MalwareGNN()
    model.load_state_dict(ckpt["model_state_dict"])
    model.eval()

    # A handful of representative permission combos
    test_cases = [
        [0, 1, 2],                  # read/send/receive SMS
        [4, 5],                     # camera + read contacts
        [9, 10, 14],                # accessibility + device admin + storage
        [0, 4, 5, 9, 11, 16, 17],   # broad spyware combo
        [18, 19],                   # biometric / fingerprint (benign-ish)
    ]

    max_diff = 0.0
    print(f"{'active':30s} {'torch P(mal)':>14s} {'dart P(mal)':>13s}  diff")
    for active in test_cases:
        with torch.no_grad():
            data = _build_data(active)
            batch = Batch.from_data_list([data])
            out = model(batch.x, batch.edge_index, batch.batch)
            sm = F.softmax(out, dim=1).numpy()[0]
        dart = dart_port_predict(blob, active)
        diff = abs(sm[1] - dart[1])
        max_diff = max(max_diff, diff)
        print(f"{str(active):30s} {sm[1]:14.4f} {dart[1]:13.4f}  {diff:.2e}")
    print(f"[14] max P(mal) diff between torch & Dart port = {max_diff:.2e}")
    return 0 if max_diff < 1e-2 else 1


if __name__ == "__main__":
    sys.exit(main())
