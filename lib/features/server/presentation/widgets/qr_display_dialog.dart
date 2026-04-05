import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/share_link_generator.dart';

/// Modal bottom sheet displaying a server config as a QR code with
/// copy and share actions (UI-SPEC §8, D-18, D-19).
///
/// Shows:
/// - Title: "Share Server"
/// - 220×220 QR code of the generated share link
/// - Share link preview text (truncated)
/// - Copy Link button (copies to clipboard)
/// - Share Link button (opens system share sheet)
class QrDisplayDialog {
  QrDisplayDialog._();

  /// Shows the QR display modal bottom sheet for the given [server].
  static void show(BuildContext context, ServerConfig server) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _QrDisplayContent(server: server),
    );
  }
}

class _QrDisplayContent extends StatelessWidget {
  final ServerConfig server;
  const _QrDisplayContent({required this.server});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shareLink = ShareLinkGenerator.generate(server);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Text(
            l10n.shareServer,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // QR code
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: shareLink,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Share link preview
          Text(
            shareLink,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              // Copy Link
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: shareLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.linkCopied)),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.copy, size: 18),
                      const SizedBox(width: 8),
                      Text(l10n.copyLink),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Share Link
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {
                    SharePlus.instance.share(
                      ShareParams(text: shareLink),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.share, size: 18),
                      const SizedBox(width: 8),
                      Text(l10n.shareLink),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
