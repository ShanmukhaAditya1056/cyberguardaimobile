import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../core/platform/app_platform.dart';
import 'screenshot_scam_classifier.dart';

/// Feature 3 — on-device OCR + scam classification.
///
/// Runs Google ML Kit text recognition entirely on-device (no network), then
/// hands the extracted text to the pure [ScamClassifier]. The image never
/// leaves the phone.
///
/// ML Kit is a mobile SDK, and that constraint is why the web build does not
/// share this code: uploading a screenshot — the one input most likely to
/// contain a bank balance or an OTP — to a cloud OCR service would contradict
/// the whole point of the module. The browser asks for the text instead and
/// runs the same [ScamClassifier] over it.
class ScreenshotScanService {
  final ScamClassifier _classifier;

  ScreenshotScanService([ScamClassifier? classifier])
      : _classifier = classifier ?? const ScamClassifier();

  static bool get isSupported => AppPlatform.canRunOcr;

  /// OCR the image at [imagePath] and classify the extracted text.
  Future<ScreenshotScanResult> scanImage(String imagePath) async {
    if (!isSupported) {
      throw UnsupportedError(
        'Screenshot scanning needs on-device OCR, which this host does not '
        'provide.',
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
