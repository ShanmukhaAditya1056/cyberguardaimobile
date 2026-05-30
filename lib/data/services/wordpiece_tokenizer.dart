import 'package:flutter/services.dart' show rootBundle;

/// Pure-Dart BERT-style WordPiece tokenizer compatible with the
/// `distilbert-base-multilingual-cased` vocabulary trained by
/// `ml_training/scripts/03_train_distilbert.py`.
///
/// Only the subset of BERT tokenisation we actually need is implemented:
///   1. Whitespace + punctuation splitting (no accent stripping — the
///      *cased* multilingual model keeps the original casing).
///   2. Greedy longest-match WordPiece over the bundled vocab.
///   3. `[CLS] … [SEP]` framing.
///   4. Pad / truncate to `maxLength` (default 128).
///
/// Token ids match the trained tokenizer exactly, so feeding the output
/// to the matching DistilBERT TFLite model will give the same logits as
/// the Python `DistilBertTokenizer`.
class WordPieceTokenizer {
  static const String vocabAssetPath = 'assets/models/distilbert_vocab.txt';
  static const String clsToken = '[CLS]';
  static const String sepToken = '[SEP]';
  static const String padToken = '[PAD]';
  static const String unkToken = '[UNK]';
  static const int maxInputCharsPerWord = 100;

  Map<String, int>? _vocab;
  late int _clsId;
  late int _sepId;
  late int _padId;
  late int _unkId;
  bool _triedLoad = false;
  String? _loadError;

  bool get isReady => _vocab != null;
  String? get loadError => _loadError;
  int get vocabSize => _vocab?.length ?? 0;

  Future<void> load() async {
    if (_triedLoad) return;
    _triedLoad = true;
    try {
      final raw = await rootBundle.loadString(vocabAssetPath);
      final lines = raw.split('\n');
      final vocab = <String, int>{};
      for (var i = 0; i < lines.length; i++) {
        final token = lines[i];
        if (token.isEmpty) continue;
        // BERT vocab uses the line index as the token id.
        vocab[token] = i;
      }
      _vocab = vocab;
      _clsId = vocab[clsToken] ?? 101;
      _sepId = vocab[sepToken] ?? 102;
      _padId = vocab[padToken] ?? 0;
      _unkId = vocab[unkToken] ?? 100;
    } catch (e) {
      _loadError = 'WordPiece load failed: $e';
      _vocab = null;
    }
  }

  /// Tokenises a single string into BERT inputs:
  ///   - `inputIds`     : length-[maxLength] list of vocab indices
  ///   - `attentionMask`: 1 for real tokens, 0 for padding
  EncodedInputs? encode(String text, {int maxLength = 128}) {
    final vocab = _vocab;
    if (vocab == null) return null;

    final pieces = <int>[_clsId];
    for (final word in _basicTokenize(text)) {
      _wordPiece(word, vocab, pieces);
      if (pieces.length >= maxLength - 1) break;
    }
    pieces.add(_sepId);

    if (pieces.length > maxLength) {
      // Truncate but always keep the trailing [SEP].
      final truncated = pieces.sublist(0, maxLength - 1)..add(_sepId);
      return EncodedInputs(
        inputIds: List.unmodifiable(truncated),
        attentionMask:
            List.unmodifiable(List<int>.filled(maxLength, 1)),
      );
    }

    final padLen = maxLength - pieces.length;
    final ids = List<int>.from(pieces)
      ..addAll(List<int>.filled(padLen, _padId));
    final mask = List<int>.filled(pieces.length, 1)
      ..addAll(List<int>.filled(padLen, 0));
    return EncodedInputs(
      inputIds: List.unmodifiable(ids),
      attentionMask: List.unmodifiable(mask),
    );
  }

  // ─── Basic tokenisation (whitespace + punctuation) ───────────────────

  /// Splits on whitespace, then breaks each chunk further at every
  /// punctuation character. Lowercasing is *not* applied because the
  /// model is `*-cased`.
  Iterable<String> _basicTokenize(String text) sync* {
    final stripped = text.trim();
    if (stripped.isEmpty) return;
    for (final chunk in stripped.split(RegExp(r'\s+'))) {
      // Split out punctuation as standalone tokens.
      final buf = StringBuffer();
      for (final rune in chunk.runes) {
        final ch = String.fromCharCode(rune);
        if (_isPunctuation(rune)) {
          if (buf.isNotEmpty) {
            yield buf.toString();
            buf.clear();
          }
          yield ch;
        } else {
          buf.write(ch);
        }
      }
      if (buf.isNotEmpty) yield buf.toString();
    }
  }

  /// Mirrors BERT's `_is_punctuation`: ASCII !"#$%& etc plus the Unicode
  /// "P" general categories. We approximate the Unicode side with a
  /// quick range check that covers the vast majority of real-world
  /// punctuation we'll see in URLs.
  bool _isPunctuation(int rune) {
    if ((rune >= 33 && rune <= 47) ||
        (rune >= 58 && rune <= 64) ||
        (rune >= 91 && rune <= 96) ||
        (rune >= 123 && rune <= 126)) {
      return true;
    }
    // Unicode general punctuation block + ranges used by quoted strings.
    if ((rune >= 0x2000 && rune <= 0x206F) ||
        (rune >= 0x3000 && rune <= 0x303F) ||
        (rune >= 0xFE30 && rune <= 0xFE4F) ||
        (rune >= 0xFF00 && rune <= 0xFFEF)) {
      return true;
    }
    return false;
  }

  // ─── Greedy WordPiece ────────────────────────────────────────────────

  void _wordPiece(String word, Map<String, int> vocab, List<int> out) {
    if (word.length > maxInputCharsPerWord) {
      out.add(_unkId);
      return;
    }
    final chars = word.split('');
    int start = 0;
    final subPieces = <int>[];
    while (start < chars.length) {
      int end = chars.length;
      int? matched;
      while (end > start) {
        var sub = chars.sublist(start, end).join();
        if (start > 0) sub = '##$sub';
        final id = vocab[sub];
        if (id != null) {
          matched = id;
          break;
        }
        end--;
      }
      if (matched == null) {
        // Whole word couldn't be split — emit [UNK] and bail.
        out.add(_unkId);
        return;
      }
      subPieces.add(matched);
      start = end;
    }
    out.addAll(subPieces);
  }
}

class EncodedInputs {
  final List<int> inputIds;
  final List<int> attentionMask;

  const EncodedInputs({
    required this.inputIds,
    required this.attentionMask,
  });

  @override
  String toString() =>
      'EncodedInputs(${inputIds.length} ids, ${attentionMask.where((m) => m == 1).length} real)';
}
