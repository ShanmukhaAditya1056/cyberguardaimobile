import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../core/platform/app_platform.dart';
import 'screenshot_scam_classifier.dart';

/// Feature 3 — on-device OCR + scam classification.
///
/// Runs Google ML Kit text recognition entirely on-device (no network), then
/// hands the extracted text to the pure [ScamClassifier]. The image never
/// leaves the phone.
///
/// ML Kit is a mobile SDK: Google ships Android and iOS builds of it and
/// nothing else. There is no desktop OCR engine that could be substituted
/// without either a native dependency per platform or an upload to a cloud
/// service, and uploading a screenshot — the one input most likely to contain
/// a bank balance or an OTP — would contradict the whole point of the module.
/// So on desktop the feature is withheld rather than reimplemented, and
/// [isSupported] is what the router and dashboard check.
class ScreenshotScanService {
  final ScamClassifier _classifier;

  ScreenshotScanService([ScamClassifier? classifier])
      : _classifier = classifier ?? const ScamClassifier();

  static bool get isSupported => AppPlatform.canRunOcr;

  /// OCR the image at [imagePath] and classify the extracted text.
  Future<ScreenshotScanResult> scanImage(String imagePath) async {
    if (!isSupported) {
      throw UnsupportedError(
        'Screenshot scanning needs on-device OCR, which is only available on '
        'Android and iOS.',
      );
    }
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(imagePath);
      final recognized = await recognizer.processImage(input);
      return _classifier.classify(recognized.text);
    } finally {
      await recognizer.close();
    }
  }
}
