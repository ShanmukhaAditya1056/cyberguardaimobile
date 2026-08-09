/**
 * Tree-walking primitives shared by every JSON model in `assets/models/`.
 *
 * Ports the private `_RandomForest` / `_LightGbmTrees` / `_IsolationForest`
 * classes from the Dart ML services. The exported JSON stores each tree as a
 * flat array of nodes; a node with `feature < 0` is a leaf and carries the
 * value. Walking that array is the whole of inference — no runtime, no
 * native extension, and identical arithmetic to the Dart implementation.
 */

/** Averaged leaf values across the forest — scikit-learn's `predict_proba`. */
export function randomForestProba(trees, features) {
  if (!trees || trees.length === 0) return 0;
  let sum = 0;
  for (const tree of trees) sum += walk(tree, features);
  return sum / trees.length;
}

/** LightGBM's binary objective: sigmoid of the summed raw leaf scores. */
export function lightGbmProba(trees, features) {
  if (!trees || trees.length === 0) return 0;
  let raw = 0;
  for (const tree of trees) raw += walk(tree, features);
  return sigmoid(raw);
}

export function sigmoid(z) {
  // Saturating early keeps `Math.exp` off values that overflow to Infinity and
  // turn the result into NaN. Matches the Dart guard exactly.
  if (z >= 50) return 1;
  if (z <= -50) return 0;
  return 1 / (1 + Math.exp(-z));
}

function walk(tree, features) {
  let idx = 0;
  // Bounded so a malformed export (a cycle, an out-of-range child index)
  // fails fast instead of hanging the request thread.
  for (let steps = 0; steps <= tree.length; steps++) {
    const node = tree[idx];
    if (!node) return 0;
    if (node.feature < 0) return node.value;
    idx = features[node.feature] <= node.threshold ? node.left : node.right;
  }
  throw new Error('Malformed decision tree: no leaf reached');
}

/**
 * scikit-learn's `IsolationForest.score_samples`.
 *
 * The anomaly score is the average leaf depth across the forest, normalised by
 * the expected depth for the training sample size. Points that land in shallow
 * leaves — reachable with few splits — are the isolated ones.
 */
export function isolationForestScore(trees, features, nSamples) {
  if (!trees || trees.length === 0) return 0;
  let sumDepth = 0;
  for (const tree of trees) sumDepth += walkDepth(tree, features);
  const avgDepth = sumDepth / trees.length;
  const cn = averagePathLength(nSamples);
  if (cn <= 0) return 0;
  return -Math.pow(2, -avgDepth / cn);
}

function walkDepth(tree, features) {
  let idx = 0;
  let depth = 0;
  for (let steps = 0; steps <= tree.length; steps++) {
    const node = tree[idx];
    if (!node) return depth;
    if (node.feature < 0) {
      // A leaf holding more than one training sample stands in for a subtree
      // that was never grown, so its expected depth is added back.
      return depth + averagePathLength(Math.round(node.value));
    }
    idx = features[node.feature] <= node.threshold ? node.left : node.right;
    depth++;
  }
  throw new Error('Malformed isolation tree: no leaf reached');
}

/** Expected path length of an unsuccessful BST search over n points. */
function averagePathLength(n) {
  if (n <= 1) return 0;
  const EULER = 0.5772156649015329;
  const h = Math.log(n - 1) + EULER;
  return 2 * h - (2 * (n - 1)) / n;
}
