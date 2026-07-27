/// Feature 3 — pure text-based scam classifier.
///
/// Takes OCR-extracted text from a screenshot and scores how likely it is a
/// scam page (fake bank / UPI / OTP / login / KYC / lottery / investment /
/// support). Kept dependency-free so it is fully unit-testable without the
/// ML Kit OCR engine.
///
/// Language-agnostic: it emits [ScamCategory] / [ScamReason] enums and the
/// raw matched substrings. The UI maps these to localized text — no English
/// is baked into the result.
library;

enum ScamCategory {
  fakeBank,
  fakeUpi,
  fakeOtp,
  fakeLogin,
  fakeKyc,
  fakeLottery,
  fakeInvestment,
  fakeSupport,
  none,
}

/// Kind of indicator behind a [ScamReason].
enum ScamReasonType {
  categoryHit, // a category's keyword matched ([category] + [matched])
  brand, // a brand name was referenced ([matched])
  urgency, // pressure/urgency wording ([matched])
  noIndicators, // nothing suspicious found
  noText, // OCR found no readable text
}

/// One structured reason. [matched] holds the raw text fragment from the image
/// (kept as-is — it is the user's content, not translatable).
class ScamReason {
  final ScamReasonType type;
  final ScamCategory? category;
  final String? matched;
  const ScamReason(this.type, {this.category, this.matched});
}

class ScreenshotScanResult {
  final int scamProbability; // 0-100
  final bool isScam;
  final ScamCategory category;
  final String? detectedBrand;
  final List<ScamReason> reasons;
  final String textPreview;

  const ScreenshotScanResult({
    required this.scamProbability,
    required this.isScam,
    required this.category,
    required this.detectedBrand,
    required this.reasons,
    required this.textPreview,
  });

  factory ScreenshotScanResult.empty() => const ScreenshotScanResult(
        scamProbability: 0,
        isScam: false,
        category: ScamCategory.none,
        detectedBrand: null,
        reasons: [ScamReason(ScamReasonType.noText)],
        textPreview: '',
      );
}

class ScamClassifier {
  const ScamClassifier();

  static const _brands = [
    'sbi', 'state bank', 'hdfc', 'icici', 'axis', 'kotak', 'paytm',
    'phonepe', 'google pay', 'gpay', 'amazon', 'flipkart', 'jio', 'airtel',
    'aadhaar', 'pan card', 'irctc', 'lic', 'income tax',
  ];

  /// Category → (keywords, weight). Each matched group adds its weight.
  static const Map<ScamCategory, (List<String>, int)> _signals = {
    ScamCategory.fakeOtp: (
      ['enter otp', 'one time password', 'otp code', 'share otp', 'verify otp'],
      35
    ),
    ScamCategory.fakeUpi: (
      ['upi pin', 'enter upi', 'collect request', 'pay ₹', 'payment failed', 'refund processing'],
      30
    ),
    ScamCategory.fakeBank: (
      ['net banking', 'account suspended', 'account blocked', 'card number', 'cvv', 'debit card', 'credit card'],
      30
    ),
    ScamCategory.fakeKyc: (
      ['kyc', 'complete your kyc', 'kyc pending', 'kyc expired', 'update kyc', 're-kyc'],
      30
    ),
    ScamCategory.fakeLogin: (
      ['enter password', 'sign in to continue', 'login to verify', 'username and password', 'password expired'],
      25
    ),
    ScamCategory.fakeLottery: (
      ['you have won', 'congratulations', 'lottery', 'lucky winner', 'claim your prize', 'reward of'],
      45
    ),
    ScamCategory.fakeInvestment: (
      ['double your money', 'guaranteed returns', 'invest now', 'profit daily', 'trading signal'],
      42
    ),
    ScamCategory.fakeSupport: (
      ['customer care', 'helpline number', 'call now', 'support executive', 'toll free'],
      18
    ),
  };

  static const _urgency = [
    'urgent', 'immediately', 'within 24 hours', 'expire', 'last warning',
    'account will be', 'click here', 'act now',
  ];

  ScreenshotScanResult classify(String rawText) {
    final text = rawText.toLowerCase();
    if (text.trim().length < 3) return ScreenshotScanResult.empty();

    final reasons = <ScamReason>[];
    int score = 0;
    ScamCategory top = ScamCategory.none;
    int topWeight = 0;

    _signals.forEach((category, sig) {
      final (keywords, weight) = sig;
      final hit = keywords.firstWhere(text.contains, orElse: () => '');
      if (hit.isNotEmpty) {
        score += weight;
        reasons.add(
            ScamReason(ScamReasonType.categoryHit, category: category, matched: hit));
        if (weight > topWeight) {
          topWeight = weight;
          top = category;
        }
      }
    });

    // Brand impersonation amplifies the score.
    final brand = _brands.firstWhere(text.contains, orElse: () => '');
    String? detectedBrand;
    if (brand.isNotEmpty) {
      detectedBrand = brand;
      if (score > 0) {
        score += 15;
        reasons.add(ScamReason(ScamReasonType.brand, matched: brand));
      }
    }

    // Urgency / pressure language.
    final urgent = _urgency.firstWhere(text.contains, orElse: () => '');
    if (urgent.isNotEmpty) {
      score += 10;
      reasons.add(ScamReason(ScamReasonType.urgency, matched: urgent));
    }

    final probability = score.clamp(0, 100);
    if (reasons.isEmpty) {
      reasons.add(const ScamReason(ScamReasonType.noIndicators));
    }

    return ScreenshotScanResult(
      scamProbability: probability,
      isScam: probability >= 40,
      category: top,
      detectedBrand: detectedBrand,
      reasons: reasons,
      textPreview:
          rawText.length > 280 ? '${rawText.substring(0, 280)}…' : rawText,
    );
  }
}
