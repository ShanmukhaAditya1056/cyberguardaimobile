import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'screenshot_scam_classifier.dart';

/// Feature 3 — on-device OCR + scam classification.
///
/// Runs Google ML Kit text recognition entirely on-device (no network), then
/// hands the extracted text to the pure [ScamClassifier]. The image never
/// leaves the phone.
class ScreenshotScanService {
  final ScamClassifier _classifier;

  ScreenshotScanService([ScamClassifier? classifier])
      : _classifier = classifier ?? const ScamClassifier();

  /// OCR the image at [imagePath] and classify the extracted text.
  Future<ScreenshotScanResult> scanImage(String imagePath) async {
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
