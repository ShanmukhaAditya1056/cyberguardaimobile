/**
 * Port of `lib/data/services/malware_gnn_service.dart`.
 *
 * Replicates the 3-layer GCN trained by `ml_training/scripts/07_train_gnn.py`:
 *
 *   Conv1 (20 → 128) → BN → ReLU
 *   Conv2 (128 → 64) → BN → ReLU
 *   Conv3 (64 → 32)  → BN → ReLU
 *   Pool [mean; max] → 64
 *   FC1 (64 → 32) → ReLU
 *   FC2 (32 → 2) → softmax
 *
 * The input graph is fully connected over the app's *active* permissions, and
 * that structure is what makes this tractable in plain JavaScript. With self
 * loops added, every node of a fully-connected graph has degree n, so GCN's
 * symmetric normalisation D^-1/2 (A+I) D^-1/2 gives every pair the same 1/n
 * weight — and the propagation collapses to "average the input rows once".
 * Each output row is then identical, so one row is computed and reused instead
 * of materialising an n×n adjacency matrix.
 */

const NUM_PERMISSIONS = 20;

export function gnnPredict(layers, permissionIndices) {
  if (!layers) return null;

  // The trainer feeds a single dummy node rather than an empty graph, so an
  // app declaring none of the 20 tracked permissions still produces a score.
  const active = permissionIndices.length > 0 ? permissionIndices : [0];
  const n = active.length;

  // One-hot rows over the active permissions.
  const x0 = active.map((idx) => {
    const row = new Array(NUM_PERMISSIONS).fill(0);
    if (idx >= 0 && idx < NUM_PERMISSIONS) row[idx] = 1;
    return row;
  });

  let h = relu2d(batchNorm(gcn(x0, layers.conv1), layers.bn1));
  h = relu2d(batchNorm(gcn(h, layers.conv2), layers.bn2));
  h = relu2d(batchNorm(gcn(h, layers.conv3), layers.bn3));

  const pooled = [...columnMean(h), ...columnMax(h)];

  const f1 = relu1d(linear(pooled, layers.fc1));
  const logits = linear(f1, layers.fc2);

  // Softmax over two classes, shifted by the max for numerical stability.
  const m = Math.max(logits[0], logits[1]);
  const e0 = Math.exp(logits[0] - m);
  const e1 = Math.exp(logits[1] - m);
  return e1 / (e0 + e1);
}

/** One GCN layer over a fully-connected graph with self loops. */
function gcn(x, conv) {
  const n = x.length;
  const inDim = conv.in;
  const outDim = conv.out;

  const meanIn = new Array(inDim).fill(0);
  for (const row of x) {
    for (let j = 0; j < inDim; j++) meanIn[j] += row[j];
  }
  for (let j = 0; j < inDim; j++) meanIn[j] /= n;

  const yRow = new Array(outDim).fill(0);
  for (let k = 0; k < outDim; k++) {
    let sum = 0;
    const wk = conv.weight[k];
    for (let j = 0; j < inDim; j++) sum += wk[j] * meanIn[j];
    if (conv.bias) sum += conv.bias[k];
    yRow[k] = sum;
  }

  // Every row is identical by the argument in the file header, but the copies
  // are real: the pooling step takes a column-wise max, which would read a
  // shared reference as one row rather than n.
  return Array.from({ length: n }, () => [...yRow]);
}

/** BatchNorm1d in eval mode, using the running statistics from training. */
function batchNorm(x, bn) {
  const dim = bn.features;
  return x.map((row) => {
    const out = new Array(dim);
    for (let j = 0; j < dim; j++) {
      const norm = (row[j] - bn.mean[j]) / Math.sqrt(bn.var[j] + bn.eps);
      out[j] = norm * bn.weight[j] + bn.bias[j];
    }
    return out;
  });
}

function relu2d(m) {
  for (const row of m) {
    for (let j = 0; j < row.length; j++) if (row[j] < 0) row[j] = 0;
  }
  return m;
}

function relu1d(v) {
  for (let i = 0; i < v.length; i++) if (v[i] < 0) v[i] = 0;
  return v;
}

function columnMean(m) {
  if (m.length === 0) return [];
  const dim = m[0].length;
  const out = new Array(dim).fill(0);
  for (const row of m) {
    for (let j = 0; j < dim; j++) out[j] += row[j];
  }
  for (let j = 0; j < dim; j++) out[j] /= m.length;
  return out;
}

function columnMax(m) {
  if (m.length === 0) return [];
  const out = [...m[0]];
  for (let i = 1; i < m.length; i++) {
    for (let j = 0; j < out.length; j++) {
      if (m[i][j] > out[j]) out[j] = m[i][j];
    }
  }
  return out;
}

function linear(x, layer) {
  const out = new Array(layer.out).fill(0);
  for (let k = 0; k < layer.out; k++) {
    let s = layer.bias ? layer.bias[k] : 0;
    const wk = layer.weight[k];
    for (let j = 0; j < layer.in; j++) s += wk[j] * x[j];
    out[k] = s;
  }
  return out;
}
