import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import 'wordpiece_tokenizer.dart';

/// On-device phishing URL classifier — runs a model trained by
/// `ml/train_phishing.py`. We ship the learned weights as JSON
/// (`assets/models/phishing_weights.json`) and execute the forward pass
/// directly in Dart so there is no heavyweight ML runtime to drag along.
///
/// Supports two model kinds, both produced by the trainer:
///   * `logistic_regression`  – 12 weights + bias  (~1 KB on disk)
///   * `random_forest`        – list of decision trees  (~50–100 KB)
///
/// In addition it eagerly loads a [WordPieceTokenizer] compatible with
/// the trained DistilBERT model (vocab.txt is bundled at
/// `assets/models/distilbert_vocab.txt`). The tokenizer is exposed via
/// [tokenizer] so a future TFLite-bundled DistilBERT can be plugged in
/// without touching anything else.
///
/// Returns `null` from [predict] until [load] succeeds; callers
/// (PhishingRepository) fall back to the rules engine while the service
/// is unavailable.
class PhishingMlService {
  static const String assetPath = 'assets/models/phishing_weights.json';
  static const int kFeatureCount = 12;
  static const double kPhishingThreshold = 0.5;

  _ModelBlob? _model;
  bool _triedLoad = false;
  String? _loadError;
  Map<String, dynamic>? _metadata;
  final WordPieceTokenizer _tokenizer = WordPieceTokenizer();

  bool get isReady => _model != null;
  String? get loadError => _loadError;
  Map<String, dynamic>? get metadata => _metadata;

  /// BERT-compatible tokenizer, lazily loaded alongside the JSON model.
  /// Use it to build the `inputIds` / `attentionMask` for any future
  /// TFLite-bundled DistilBERT-style classifier.
  WordPieceTokenizer get tokenizer => _tokenizer;

  /// Lazily load the bundled JSON model.
  Future<void> load() async {
    if (_triedLoad) return;
    _triedLoad = true;
    try {
      final raw = await rootBundle.loadString(assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final model = json['model'] as Map<String, dynamic>?;
      if (model == null) {
        _loadError = 'phishing_weights.json missing `model` block';
        return;
      }
      switch (model['kind']) {
        case 'logistic_regression':
          _model = _LogReg.fromJson(model);
          break;
        case 'random_forest':
          _model = _RandomForest.fromJson(model);
          break;
        default:
          _loadError = 'Unknown model kind: ${model['kind']}';
          return;
      }
      _metadata = {
        'model_type': json['model_type'],
        'trained_at': json['trained_at'],
        'training_samples': json['training_samples'],
        'test_metrics': json['test_metrics'],
      };
    } catch (e) {
      _loadError = 'Model load failed: $e';
      _model = null;
    }

    // Eagerly load the BERT tokenizer too. It's optional — if it fails
    // the LR model still works fine.
    await _tokenizer.load();
  }

  /// Probability the URL is phishing (0..1) or `null` if the model isn't
  /// loaded.
  double? predict(String url) {
    final m = _model;
    if (m == null) return null;
    final features = _buildFeatures(url);
    return m.predictProba(features);
  }

  // ─── 12-feature vector — must stay in sync with ml/train_phishing.py ────

  List<double> _buildFeatures(String rawUrl) {
    final url = rawUrl.trim().toLowerCase();
    final hostOnly = url
        .replaceFirst(RegExp(r'^https?://'), '')
        .split('/')
        .first
        .split('?')
        .first;

    int count(String s, String pat) => pat.allMatches(s).length;
    final digitRatio = url.isEmpty
        ? 0.0
        : url.runes.where((r) => r >= 0x30 && r <= 0x39).length / url.length;

    final hasIp = RegExp(r'^\d{1,3}(\.\d{1,3}){3}').hasMatch(hostOnly);
    final hasHttps = url.startsWith('https://');
    final subdomainDepth = math.max(0, count(hostOnly, '.') - 1);

    const suspiciousTlds = [
      '.xyz', '.tk', '.ml', '.ga', '.cf', '.click', '.top',
      '.loan', '.gq', '.pw', '.buzz', '.fun', '.link',
    ];
    final hasBadTld = suspiciousTlds.any((t) => hostOnly.endsWith(t));

    const phishingWords = [
      'login', 'verify', 'otp', 'kyc', 'aadhaar',
      'update', 'secure', 'confirm', 'reward', 'recharge',
    ];
    final hasPhishingWord = phishingWords.any(url.contains);

    const brands = [
      'paytm', 'phonepe', 'gpay', 'sbi', 'hdfc',
      'icici', 'amazon', 'flipkart', 'jio', 'airtel',
    ];
    final hasBrandSpoof = brands.any((b) =>
        url.contains(b) &&
        !hostOnly.endsWith('$b.com') &&
        !hostOnly.endsWith('$b.in'));

    final queryLen = url.contains('?')
        ? url.substring(url.indexOf('?') + 1).length
        : 0;

    double clamp01(num v) => v.toDouble().clamp(0.0, 1.0);

    return <double>[
      clamp01(url.isEmpty ? 0.0 : math.log(url.length) / 8.0),
      clamp01(count(hostOnly, '-') / 10),
      clamp01(count(hostOnly, '.') / 10),
      clamp01(digitRatio),
      url.contains('@') ? 1.0 : 0.0,
      hasIp ? 1.0 : 0.0,
      hasHttps ? 1.0 : 0.0,
      clamp01(subdomainDepth / 5),
      hasBadTld ? 1.0 : 0.0,
      hasPhishingWord ? 1.0 : 0.0,
      hasBrandSpoof ? 1.0 : 0.0,
      clamp01(queryLen / 100),
    ];
  }
}

// ─── Model blob implementations ───────────────────────────────────────────

abstract class _ModelBlob {
  double predictProba(List<double> features);
}

class _LogReg implements _ModelBlob {
  final List<double> weights;
  final double bias;
  _LogReg(this.weights, this.bias);

  factory _LogReg.fromJson(Map<String, dynamic> json) {
    final w = (json['weights'] as List).cast<num>().map((e) => e.toDouble()).toList();
    final b = (json['bias'] as num).toDouble();
    return _LogReg(w, b);
  }

  @override
  double predictProba(List<double> features) {
    double z = bias;
    final n = math.min(features.length, weights.length);
    for (var i = 0; i < n; i++) {
      z += features[i] * weights[i];
    }
    // sigmoid
    if (z >= 50) return 1.0;
    if (z <= -50) return 0.0;
    return 1.0 / (1.0 + math.exp(-z));
  }
}

class _RandomForest implements _ModelBlob {
  final List<List<_RfNode>> trees;
  _RandomForest(this.trees);

  factory _RandomForest.fromJson(Map<String, dynamic> json) {
    final raw = (json['trees'] as List).cast<List<dynamic>>();
    final trees = raw
        .map((tree) => tree
            .cast<Map<String, dynamic>>()
            .map(_RfNode.fromJson)
            .toList())
        .toList();
    return _RandomForest(trees);
  }

  @override
  double predictProba(List<double> features) {
    if (trees.isEmpty) return 0.0;
    double sum = 0;
    for (final tree in trees) {
      sum += _walk(tree, features);
    }
    return sum / trees.length;
  }

  double _walk(List<_RfNode> tree, List<double> features) {
    int idx = 0;
    while (true) {
      final node = tree[idx];
      if (node.feature < 0) return node.value;
      if (features[node.feature] <= node.threshold) {
        idx = node.left;
      } else {
        idx = node.right;
      }
    }
  }
}

class _RfNode {
  final int feature;
  final double threshold;
  final int left;
  final int right;
  final double value;

  _RfNode({
    required this.feature,
    required this.threshold,
    required this.left,
    required this.right,
    required this.value,
  });

  factory _RfNode.fromJson(Map<String, dynamic> j) => _RfNode(
        feature: (j['feature'] as num).toInt(),
        threshold: (j['threshold'] as num).toDouble(),
        left: (j['left'] as num).toInt(),
        right: (j['right'] as num).toInt(),
        value: (j['value'] as num).toDouble(),
      );
}
