import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../provider/phishing_provider.dart';

/// Scans a QR code with the camera and immediately runs the decoded URL
/// through the phishing engine. Pops back with the verdict on the
/// PhishingScreen so the user lands on the existing result UI.
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  late final MobileScannerController _controller;
  bool _handled = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.normal,
    );
    _ensurePermission();
  }

  Future<void> _ensurePermission() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final l = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final XFile? picked =
        await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final result = await _controller.analyzeImage(picked.path);
    if (!mounted) return;
    final code = result?.barcodes.firstWhere(
      (b) => b.rawValue != null && b.rawValue!.isNotEmpty,
      orElse: () => const Barcode(),
    );
    final raw = code?.rawValue;
    if (raw == null || raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.qrNoCodeInImage)),
      );
      return;
    }
    // Reuse the same handling path as live camera scans.
    await _processRawCode(raw);
  }

  Future<void> _processRawCode(String raw) async {
    final l = AppLocalizations.of(context)!;
    setState(() => _handled = true);
    HapticFeedback.mediumImpact();
    await _controller.stop();

    final isUrl = RegExp(r'^https?://', caseSensitive: false).hasMatch(raw) ||
        raw.contains('.');
    if (!isUrl) {
      _showResultSheet(
        title: l.qrNotAUrl,
        body: '${l.qrNotAUrlBody}\n\n$raw',
        isPhishing: false,
      );
      return;
    }

    final url = raw.startsWith('http') ? raw : 'https://$raw';
    await ref.read(phishingProvider.notifier).scanUrl(url);
    if (!mounted) return;
    final result = ref.read(phishingProvider).result;
    final isPhishing = result?.isPhishing ?? false;
    _showResultSheet(
      title: isPhishing ? l.qrPhishingDetected : l.qrSafeLink,
      body: url,
      isPhishing: isPhishing,
      confidence: result?.confidence,
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final code = capture.barcodes.firstWhere(
      (b) => b.rawValue != null && b.rawValue!.isNotEmpty,
      orElse: () => const Barcode(),
    );
    final raw = code.rawValue;
    if (raw == null || raw.isEmpty) return;
    await _processRawCode(raw);
  }

  void _showResultSheet({
    required String title,
    required String body,
    required bool isPhishing,
    int? confidence,
  }) {
    final color = isPhishing ? AppColors.danger : AppColors.safe;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPhishing
                        ? Icons.warning_amber_rounded
                        : Icons.verified_user_rounded,
                    color: color,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              if (confidence != null) ...[
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.qrConfidence(confidence),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textMedium,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  body,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: AppColors.textOn(context),
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        setState(() => _handled = false);
                        _controller.start();
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(AppLocalizations.of(context)!.qrScanAnother),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.pop();
                      },
                      child: Text(AppLocalizations.of(context)!.qrViewDetails),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          l.qrScanTitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          IconButton(
            tooltip: l.qrUploadFromGallery,
            icon: const Icon(Icons.photo_library_outlined,
                color: Colors.white),
            onPressed: _pickFromGallery,
          ),
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white),
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_outlined,
                color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (ctx, err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.no_photography_outlined,
                        color: Colors.white70, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      err.errorDetails?.message ?? l.qrCameraUnavailable,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70, fontFamily: 'Inter'),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        await openAppSettings();
                      },
                      child: Text(l.qrOpenSettings),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // viewfinder overlay
          IgnorePointer(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.blue.withValues(alpha: 0.9),
                    width: 3,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l.qrPointAtCode,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
