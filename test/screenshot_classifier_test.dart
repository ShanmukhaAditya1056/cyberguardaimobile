import 'package:cyberguard_ai/data/services/screenshot_scam_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const c = ScamClassifier();

  group('ScamClassifier.classify', () {
    test('empty / too-short text → empty result', () {
      expect(c.classify('').scamProbability, 0);
      expect(c.classify('hi').category, ScamCategory.none);
    });

    test('benign text is not flagged', () {
      final r = c.classify('Welcome to my photo gallery. Sunset at the beach.');
      expect(r.isScam, isFalse);
      expect(r.scamProbability, lessThan(40));
    });

    test('fake bank OTP page is flagged with brand + category', () {
      final r = c.classify(
        'SBI NetBanking: your account is suspended. Enter OTP and card number '
        'to verify immediately or it will expire.',
      );
      expect(r.isScam, isTrue);
      expect(r.scamProbability, greaterThanOrEqualTo(40));
      expect(r.detectedBrand, isNotNull);
      // OTP carries the strongest weight, so it should win the category.
      expect(r.category, ScamCategory.fakeOtp);
    });

    test('lottery scam is detected', () {
      final r = c.classify(
        'Congratulations! You have won a lottery of ₹25,00,000. Claim your prize now.',
      );
      expect(r.isScam, isTrue);
      expect(r.category, ScamCategory.fakeLottery);
    });

    test('text preview is truncated for long input', () {
      final long = 'kyc update required ' * 40;
      final r = c.classify(long);
      expect(r.textPreview.length, lessThanOrEqualTo(281));
    });
  });
}
