import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arma_proxy_vpn_client/core/constants/app_constants.dart';
import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/core/utils/clipboard_helper.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/share_link_parser.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/subscription_parser.dart';
import 'package:arma_proxy_vpn_client/features/server/data/services/subscription_service.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/subscription.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/server_list_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/screens/qr_scanner_screen.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/add_subscription_dialog.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/paste_config_dialog.dart';

/// Expandable floating action button for server import options.
///
/// Displays three sub-options when expanded:
/// 1. **Scan QR** — placeholder showing "coming soon" snackbar
/// 2. **Paste Config** — opens full-screen dialog for manual input
/// 3. **Clipboard** — reads clipboard and parses share link
///
/// The main FAB icon rotates 45° when expanded.
class ImportFab extends ConsumerStatefulWidget {
  const ImportFab({super.key});

  @override
  ConsumerState<ImportFab> createState() => _ImportFabState();
}

class _ImportFabState extends ConsumerState<ImportFab>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _animationController;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _importFromClipboard(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    // Clear any existing snackbars so they don't block the FAB
    messenger.clearSnackBars();

    final text = await ClipboardHelper.getText();

    if (!context.mounted) return;

    if (text == null || text.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.parseErrorEmptyClipboard),
          duration: AppConstants.snackBarDurationDefault,
        ),
      );
      return;
    }

    final trimmed = text.trim();

    // Auto-detect: subscription URL (http/https)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      await _importSubscriptionUrl(context, ref, trimmed);
      return;
    }

    // Try single share link first
    final singleConfig = ShareLinkParser.parse(trimmed);
    if (singleConfig != null) {
      await _addSingleServer(context, ref, singleConfig);
      return;
    }

    // Try multi-line / base64 content (multiple share links)
    final multiConfigs = SubscriptionParser.parseBody(trimmed);
    if (multiConfigs.isNotEmpty) {
      await _addMultipleServers(context, ref, multiConfigs);
      return;
    }

    // Nothing matched
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.parseErrorInvalidLink),
        duration: AppConstants.snackBarDurationDefault,
      ),
    );
  }

  /// Fetches a subscription URL from clipboard and imports servers.
  Future<void> _importSubscriptionUrl(
    BuildContext context,
    WidgetRef ref,
    String url,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    // Show loading indicator
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Fetching subscription...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final subscription = Subscription(
        id: 'clipboard-import',
        name: 'Clipboard',
        url: url,
        lastUpdated: DateTime.now(),
        addedAt: DateTime.now(),
      );

      final result = await SubscriptionService().fetch(subscription);

      if (!context.mounted) return;
      messenger.clearSnackBars();

      if (result.servers.isEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.parseErrorInvalidLink),
            duration: AppConstants.snackBarDurationDefault,
          ),
        );
        return;
      }

      await _addMultipleServers(context, ref, result.servers);
    } catch (_) {
      if (!context.mounted) return;
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.subscriptionFetchError),
          duration: AppConstants.snackBarDurationDefault,
        ),
      );
    }
  }

  /// Adds a single server, checking for duplicates.
  Future<void> _addSingleServer(
    BuildContext context,
    WidgetRef ref,
    ServerConfig config,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final servers = await ref.read(serverListProvider.future);
    final isDuplicate = servers.any(
      (s) =>
          s.address == config.address &&
          s.port == config.port &&
          s.protocol == config.protocol,
    );

    if (!context.mounted) return;

    if (isDuplicate) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.duplicateServer),
          duration: AppConstants.snackBarDurationDefault,
        ),
      );
      return;
    }

    await ref.read(serverListProvider.notifier).addServer(config);

    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text('${l10n.importSuccess} — ${config.name}'),
        duration: AppConstants.snackBarDurationDefault,
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  /// Adds multiple servers, skipping duplicates.
  Future<void> _addMultipleServers(
    BuildContext context,
    WidgetRef ref,
    List<ServerConfig> configs,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final existingServers = await ref.read(serverListProvider.future);

    // Filter out duplicates
    final newConfigs = configs.where((config) {
      return !existingServers.any(
        (s) =>
            s.address == config.address &&
            s.port == config.port &&
            s.protocol == config.protocol,
      );
    }).toList();

    if (!context.mounted) return;

    if (newConfigs.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.duplicateServer),
          duration: AppConstants.snackBarDurationDefault,
        ),
      );
      return;
    }

    for (final config in newConfigs) {
      await ref.read(serverListProvider.notifier).addServer(config);
    }

    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.importedServersCount(newConfigs.length)),
        duration: AppConstants.snackBarDurationDefault,
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  void _openPasteDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => const PasteConfigDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mini-FAB options (visible when expanded)
        FadeTransition(
          opacity: _expandAnimation,
          child: ScaleTransition(
            scale: _expandAnimation,
            alignment: Alignment.bottomRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _MiniFabOption(
                  icon: Icons.qr_code_scanner,
                  label: l10n.scanQr,
                  onTap: () {
                    _toggle();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const QrScannerScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _MiniFabOption(
                  icon: Icons.rss_feed,
                  label: l10n.addSubscription,
                  onTap: () {
                    _toggle();
                    showDialog<void>(
                      context: context,
                      builder: (_) => const AddSubscriptionDialog(),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _MiniFabOption(
                  icon: Icons.edit_note,
                  label: l10n.pasteConfig,
                  onTap: () {
                    _toggle();
                    _openPasteDialog(context);
                  },
                ),
                const SizedBox(height: 8),
                _MiniFabOption(
                  icon: Icons.content_paste,
                  label: l10n.clipboard,
                  onTap: () {
                    _toggle();
                    _importFromClipboard(context, ref);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        // Main FAB
        FloatingActionButton.extended(
          onPressed: _toggle,
          icon: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
          label: Text(l10n.importServer),
        ),
      ],
    );
  }
}

/// A mini floating action button option displayed in the expanded FAB menu.
class _MiniFabOption extends StatelessWidget {
  const _MiniFabOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          height: 40,
          child: FloatingActionButton.small(
            heroTag: null,
            onPressed: onTap,
            child: Icon(icon),
          ),
        ),
      ],
    );
  }
}
