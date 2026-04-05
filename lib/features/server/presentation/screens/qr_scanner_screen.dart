import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/share_link_parser.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/server_list_provider.dart';

/// Full-screen camera QR scanner screen (UI-SPEC §7).
///
/// Auto-detects scanned content (D-07):
/// - Known proxy share link (vless://, vmess://, etc.) → import as server
/// - HTTP/HTTPS URL → prompt to add as subscription
/// - Unknown content → show error snackbar
///
/// Provides flash toggle (bottom-right) and camera switch (bottom-left)
/// controls overlaid on the camera feed.
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _hasDetected = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.scanQrTitle,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: (capture) => _onDetect(capture, l10n),
          ),

          // Semi-transparent overlay with cutout
          CustomPaint(
            painter: _ScanOverlayPainter(
              borderColor: colorScheme.primary,
            ),
            size: Size.infinite,
          ),

          // Instruction text below cutout
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height / 2 - 170,
            child: Text(
              l10n.scanQrInstruction,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white),
            ),
          ),

          // Flash toggle — bottom right
          Positioned(
            bottom: 48,
            right: 24,
            child: SizedBox(
              width: 48,
              height: 48,
              child: ValueListenableBuilder(
                valueListenable: _controller,
                builder: (context, state, _) {
                  final torchOn = state.torchState == TorchState.on;
                  return IconButton(
                    onPressed: () => _controller.toggleTorch(),
                    icon: Icon(
                      torchOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),

          // Camera switch — bottom left
          Positioned(
            bottom: 48,
            left: 24,
            child: SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                onPressed: () => _controller.switchCamera(),
                icon: const Icon(
                  Icons.cameraswitch,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handles barcode detection — auto-detects content type (D-07).
  ///
  /// T-03-12: Only processes known URI schemes.
  void _onDetect(BarcodeCapture capture, AppLocalizations l10n) {
    if (_hasDetected) return;
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.isEmpty) return;

    _hasDetected = true;

    // 1. Try parsing as a proxy share link
    final config = ShareLinkParser.parse(value);
    if (config != null) {
      ref.read(serverListProvider.notifier).addServer(config);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.importSuccess)),
      );
      return;
    }

    // 2. Check if it's an HTTP/HTTPS URL (potential subscription)
    final uri = Uri.tryParse(value);
    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty) {
      _showSubscriptionPrompt(value, l10n);
      return;
    }

    // 3. Unrecognized content
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.qrUnrecognized)),
    );
    // Allow re-scanning after unrecognized
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _hasDetected = false);
    });
  }

  /// Shows a dialog asking if the scanned HTTP URL should be added
  /// as a subscription.
  void _showSubscriptionPrompt(String url, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addSubscription),
        content: Text(l10n.qrSubscriptionPrompt),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Allow re-scanning
              setState(() => _hasDetected = false);
            },
            child: Text(l10n.notNow),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Pop scanner and return URL for subscription flow
              Navigator.of(context).pop(url);
            },
            child: Text(l10n.addSubscription),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the scan overlay: semi-transparent black background
/// with a 250×250dp transparent cutout centered, bordered by a rounded
/// rectangle in the primary color.
class _ScanOverlayPainter extends CustomPainter {
  final Color borderColor;
  const _ScanOverlayPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    const cutoutSize = 250.0;
    const borderRadius = 12.0;
    const borderWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final cutoutRect = Rect.fromCenter(
      center: center,
      width: cutoutSize,
      height: cutoutSize,
    );

    // Draw semi-transparent overlay with cutout
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        cutoutRect,
        const Radius.circular(borderRadius),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black54,
    );

    // Draw border around cutout
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        cutoutRect,
        const Radius.circular(borderRadius),
      ),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter oldDelegate) =>
      borderColor != oldDelegate.borderColor;
}
