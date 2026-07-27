"""
07_train_gnn.py — Graph Neural Network over the per-app permission graph.

Each app becomes a fully-connected graph over its active permissions.
Nodes are one-hot permission embeddings; the GCN aggregates them and a
two-layer MLP predicts {benign, malware}.

Requires torch + torch-geometric (install on Py 3.10-3.12). GPU optional.
Outputs:
  * models/saved/gnn_malware.pt
  * models/saved/gnn_confusion_matrix.png
  * models/saved/gnn_training_curves.png
  * models/saved/gnn_metrics.json
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
import torch
import torch.nn as nn
import torch.nn.functional as F
from sklearn.metrics import (accuracy_score, classification_report,
                             confusion_matrix)
from sklearn.model_selection import train_test_split
from torch_geometric.data import Data
from torch_geometric.loader import DataLoader
from torch_geometric.nn import GCNConv, global_max_pool, global_mean_pool

ROOT = Path(__file__).resolve().parents[1]
PROC = ROOT / "data" / "processed"
SAVE = ROOT / "models" / "saved"
SAVE.mkdir(parents=True, exist_ok=True)

PERMS = [
    "read_sms", "send_sms", "receive_sms", "record_audio", "camera",
    "read_contacts", "write_contacts", "read_call_log",
    "process_outgoing_calls", "bind_accessibility_service",
    "bind_device_admin", "request_install_packages",
    "receive_boot_completed", "foreground_service",
    "read_external_storage", "write_external_storage",
    "access_fine_location", "access_coarse_location",
    "use_biometric", "use_fingerprint",
]
N_PERMS = len(PERMS)


def build_graph(row: dict, label: int) -> Data:
    active = [i for i, p in enumerate(PERMS) if int(row.get(p, 0)) == 1]
    if not active:
        active = [0]
    n = len(active)
    x = torch.eye(N_PERMS)[active].float()
    if n > 1:
        src, dst = [], []
        for i in range(n):
            for j in range(n):
                if i != j:
                    src.append(i); dst.append(j)
        edge_index = torch.tensor([src, dst], dtype=torch.long)
    else:
        edge_index = torch.zeros((2, 0), dtype=torch.long)
    return Data(x=x, edge_index=edge_index,
                y=torch.tensor([label], dtype=torch.long))


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

    def forward(self, x, edge_index, batch):
        x = F.relu(self.bn1(self.conv1(x, edge_index))); x = self.dropout(x)
        x = F.relu(self.bn2(self.conv2(x, edge_index))); x = self.dropout(x)
        x = F.relu(self.bn3(self.conv3(x, edge_index)))
        x_mean = global_mean_pool(x, batch)
        x_max = global_max_pool(x, batch)
        x = torch.cat([x_mean, x_max], dim=1)
        x = F.relu(self.fc1(x)); x = self.dropout(x)
        return self.fc2(x)


def main() -> int:
    print("=" * 60)
    print(" 07_train_gnn — start")
    print("=" * 60)
    src = PROC / "malware_train.csv"
    if not src.exists():
        print("[07] Run 04_prepare_malware_data.py first.", file=sys.stderr)
        return 1

    df = pd.read_csv(src).fillna(0)
    print(f"[07] dataset shape={df.shape}")
    train_df, test_df = train_test_split(
        df, test_size=0.20, stratify=df["label"], random_state=42)

    train_graphs = [build_graph(r.to_dict(), int(r["label"]))
                    for _, r in train_df.iterrows()]
    test_graphs = [build_graph(r.to_dict(), int(r["label"]))
                   for _, r in test_df.iterrows()]
    train_loader = DataLoader(train_graphs, batch_size=64, shuffle=True)
    test_loader = DataLoader(test_graphs, batch_size=128)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = MalwareGNN().to(device)
    opt = torch.optim.Adam(model.parameters(), lr=1e-3, weight_decay=1e-5)
    sched = torch.optim.lr_scheduler.CosineAnnealingLR(opt, T_max=100)

    losses, accs = [], []
    best_acc, best_state = 0.0, None
    for epoch in range(1, 101):
        model.train()
        epoch_loss = 0.0
        for batch in train_loader:
            batch = batch.to(device)
            opt.zero_grad()
            out = model(batch.x, batch.edge_index, batch.batch)
            loss = F.cross_entropy(out, batch.y)
            loss.backward(); opt.step()
            epoch_loss += loss.item() * batch.num_graphs
        sched.step()

        # eval
        model.eval()
        correct = total = 0
        with torch.no_grad():
            for batch in test_loader:
                batch = batch.to(device)
                pred = model(batch.x, batch.edge_index,
                             batch.batch).argmax(dim=1)
                correct += (pred == batch.y).sum().item()
                total += batch.num_graphs
        acc = correct / total
        losses.append(epoch_loss / len(train_graphs))
        accs.append(acc)
        if acc > best_acc:
            best_acc = acc
            best_state = {k: v.cpu().clone()
                          for k, v in model.state_dict().items()}
        if epoch % 10 == 0 or epoch == 1:
            print(f"[07] epoch {epoch:3d}  loss={losses[-1]:.4f}  acc={acc:.4f}")

    if best_state is not None:
        model.load_state_dict(best_state)

    # Final eval
    model.eval()
    y_true, y_pred = [], []
    with torch.no_grad():
        for batch in test_loader:
            batch = batch.to(device)
            pred = model(batch.x, batch.edge_index,
                         batch.batch).argmax(dim=1)
            y_true.extend(batch.y.cpu().tolist())
            y_pred.extend(pred.cpu().tolist())

    acc = accuracy_score(y_true, y_pred)
    cm = confusion_matrix(y_true, y_pred)
    print(classification_report(y_true, y_pred,
                                target_names=["benign", "malware"]))
    print(f"[07] best test accuracy = {best_acc:.4f}")

    plt.figure(figsize=(5, 4))
    sns.heatmap(cm, annot=True, fmt="d", cmap="Purples",
                xticklabels=["benign", "malware"],
                yticklabels=["benign", "malware"])
    plt.title("GNN — Confusion Matrix")
    plt.tight_layout()
    plt.savefig(SAVE / "gnn_confusion_matrix.png", dpi=150); plt.close()

    fig, axs = plt.subplots(1, 2, figsize=(10, 4))
    axs[0].plot(losses); axs[0].set_title("Loss")
    axs[1].plot(accs); axs[1].set_title("Eval accuracy")
    plt.tight_layout()
    plt.savefig(SAVE / "gnn_training_curves.png", dpi=150); plt.close()

    torch.save({
        "model_state_dict": model.state_dict(),
        "accuracy": acc,
        "num_permissions": N_PERMS,
    }, SAVE / "gnn_malware.pt")
    (SAVE / "gnn_metrics.json").write_text(json.dumps({
        "accuracy": acc, "best_accuracy": best_acc,
        "confusion_matrix": cm.tolist(),
    }, indent=2))
    print(f"[07] DONE  saved to {SAVE / 'gnn_malware.pt'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
