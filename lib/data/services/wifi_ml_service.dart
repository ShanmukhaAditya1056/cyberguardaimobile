import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;

/// On-device Wi-Fi anomaly detector — loads an Isolation Forest trained
/// by `ml_training/scripts/08_train_isolation_forest.py` and exported as
/// JSON by `ml_training/scripts/12_export_json.py`.
///
/// Inference replicates `sklearn.ensemble.IsolationForest.score_samples`:
///   1. Standardise the 8-feature vector with the bundled scaler
///      (mean / scale arrays from training).
///   2. For each tree, walk to a leaf and record the depth + the
///      harmonic correction `c(node_samples)` used by sklearn.
///   3. Normalise the average depth by `c(n_samples)`.
///   4. score = -2^(-avg_depth / c(n_samples)) − offset.
///      Negative => anomalous; positive => normal.
class WifiMlService {
  static const String assetPath =
      'assets/models/wifi_isoforest_weights.json';
  static const int kFeatureCount = 8;

  _IsolationForest? _model;
  List<double>? _scalerMean;
  List<double>? _scalerScale;
  double _offset = 0.0;
  int _maxSamples = 128;
  bool _triedLoad = false;
  String? _loadError;
  Map<String, dynamic>? _metadata;

  bool get isReady => _model != null;
  String? get loadError => _loadError;
  Map<String, dynamic>? get metadata => _metadata;

  Future<void> load() async {
    if (_triedLoad) return;
    _triedLoad = true;
    try {
      final raw = await rootBundle.loadString(assetPath);
      final json = await compute(jsonDecode, raw) as Map<String, dynamic>;
      _model = _IsolationForest.fromJson(
          (json['model'] as Map).cast<String, dynamic>());
      final scaler = (json['scaler'] as Map).cast<String, dynamic>();
      _scalerMean = (scaler['mean'] as List)
          .cast<num>()
          .map((e) => e.toDouble())
          .toList();
      _scalerScale = (scaler['scale'] as List)
          .cast<num>()
          .map((e) => e.toDouble())
          .toList();
      _offset = (json['offset'] as num).toDouble();
      _maxSamples = (json['max_samples'] as num).toInt();
      _metadata = {
        'n_estimators': json['n_estimators'],
        'trained_at': json['trained_at'],
      };
    } catch (e) {
      _loadError = 'Wi-Fi model load failed: $e';
      _model = null;
    }
  }

  /// Returns `null` when the model isn't loaded.
  WifiAnomalyResult? predict(List<double> features) {
    final m = _model;
    if (m == null) return null;
    if (features.length != kFeatureCount) return null;
    if (_scalerMean == null || _scalerScale == null) return null;

    final scaled = List<double>.generate(features.length, (i) {
      final s = _scalerScale![i];
      return s == 0 ? 0.0 : (features[i] - _scalerMean![i]) / s;
    });

    final score = m.scoreSample(scaled, _maxSamples);
    final adjusted = score - _offset;
    return WifiAnomalyResult(
      anomalyScore: adjusted,
      isAnomaly: adjusted < 0,
      trustScore: _toTrustScore(adjusted),
    );
  }

  static int _toTrustScore(double score) {
    final clamped = score.clamp(-0.5, 0.5);
    final normalised = (clamped + 0.5) / 1.0;
    return (normalised * 100).round();
  }

  /// Match column order with `08_train_isolation_forest.py`:
  /// [rssi, encryption_code, is_public, dns_response_ms,
  ///  beacon_interval, bssid_changes, rssi_variance, frequency_ghz]
  static List<double> extractFeatures({
    required int rssi,
    required int encryptionCode,
    required bool isPublic,
    required int dnsResponseMs,
    int beaconInterval = 100,
    int bssidChanges = 0,
    double rssiVariance = 1.0,
    required double frequencyGhz,
  }) {
    return <double>[
      rssi.toDouble(),
      encryptionCode.toDouble(),
      isPublic ? 1.0 : 0.0,
      dnsResponseMs.toDouble(),
      beaconInterval.toDouble(),
      bssidChanges.toDouble(),
      rssiVariance,
      frequencyGhz,
    ];
  }
}

class WifiAnomalyResult {
  final double anomalyScore;
  final bool isAnomaly;
  final int trustScore;

  const WifiAnomalyResult({
    required this.anomalyScore,
    required this.isAnomaly,
    required this.trustScore,
  });
}

class _IfNode {
  final int feature;
  final double threshold;
  final int left;
  final int right;
  final double leafSamples;
  _IfNode({
    required this.feature,
    required this.threshold,
    required this.left,
    required this.right,
    required this.leafSamples,
  });
  factory _IfNode.fromJson(Map<String, dynamic> j) => _IfNode(
        feature: (j['feature'] as num).toInt(),
        threshold: (j['threshold'] as num).toDouble(),
        left: (j['left'] as num).toInt(),
        right: (j['right'] as num).toInt(),
        leafSamples: (j['value'] as num).toDouble(),
      );
}

class _IsolationForest {
  final List<List<_IfNode>> trees;
  _IsolationForest(this.trees);

  factory _IsolationForest.fromJson(Map<String, dynamic> json) {
    final raw = (json['trees'] as List).cast<List<dynamic>>();
    return _IsolationForest(raw
        .map((tree) => tree
            .cast<Map<String, dynamic>>()
            .map(_IfNode.fromJson)
            .toList(growable: false))
        .toList(growable: false));
  }

  double scoreSample(List<double> features, int nSamples) {
    if (trees.isEmpty) return 0.0;
    double sumDepth = 0;
    for (final tree in trees) {
      sumDepth += _walkDepth(tree, features);
    }
    final avgDepth = sumDepth / trees.length;
    final cn = _averagePathLength(nSamples);
    if (cn <= 0) return 0.0;
    return -math.pow(2, -avgDepth / cn).toDouble();
  }

  double _walkDepth(List<_IfNode> tree, List<double> features) {
    int idx = 0;
    int depth = 0;
    while (true) {
      final node = tree[idx];
      if (node.feature < 0) {
        return depth + _averagePathLength(node.leafSamples.round());
      }
      idx = features[node.feature] <= node.threshold
          ? node.left
          : node.right;
      depth++;
    }
  }

  double _averagePathLength(int n) {
    if (n <= 1) return 0.0;
    const euler = 0.5772156649015329;
    final h = math.log(n - 1) + euler;
    return 2 * h - (2 * (n - 1) / n);
  }
}
