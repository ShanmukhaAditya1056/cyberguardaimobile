import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/services/screenshot_scam_classifier.dart';
import '../../../data/services/screenshot_scan_service.dart';

class ScreenshotState {
  final bool isScanning;
  final String? imagePath;
  final ScreenshotScanResult? result;
  final String? error;

  const ScreenshotState({
    this.isScanning = false,
    this.imagePath,
    this.result,
    this.error,
  });

  ScreenshotState copyWith({
    bool? isScanning,
    String? imagePath,
    ScreenshotScanResult? result,
    String? error,
    bool clear = false,
  }) =>
      ScreenshotState(
        isScanning: isScanning ?? this.isScanning,
        imagePath: clear ? null : (imagePath ?? this.imagePath),
        result: clear ? null : (result ?? this.result),
        error: error,
      );
}

class ScreenshotNotifier extends StateNotifier<ScreenshotState> {
  final ScreenshotScanService _service;
  final ImagePicker _picker;

  ScreenshotNotifier(this._service, [ImagePicker? picker])
      : _picker = picker ?? ImagePicker(),
        super(const ScreenshotState());

  Future<void> pickAndScan(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked == null) return;
      state = state.copyWith(
          isScanning: true, imagePath: picked.path, error: null);
      final result = await _service.scanImage(picked.path);
      state = state.copyWith(isScanning: false, result: result);
    } catch (e) {
      state = state.copyWith(isScanning: false, error: e.toString());
    }
  }

  void clear() => state = const ScreenshotState();
}

final screenshotScanServiceProvider = Provider((_) => ScreenshotScanService());

final screenshotProvider =
    StateNotifierProvider<ScreenshotNotifier, ScreenshotState>(
  (ref) => ScreenshotNotifier(ref.read(screenshotScanServiceProvider)),
);
