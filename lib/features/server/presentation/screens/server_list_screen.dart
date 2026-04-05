import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/core/constants/app_constants.dart';
import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/core/utils/clipboard_helper.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/share_link_parser.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/server_list_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/empty_server_state.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/import_fab.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/server_card.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/widgets/server_group_header.dart';

/// Server list screen — primary interaction screen for Phase 1.
///
/// Displays imported servers as grouped cards with protocol badges,
/// tap-to-select active server, expandable import FAB, and delete
/// confirmation dialog.
class ServerListScreen extends ConsumerWidget {
  const ServerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final serversAsync = ref.watch(serverListProvider);
    final activeServer = ref.watch(activeServerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.servers,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: serversAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Gap(16),
              FilledButton(
                onPressed: () => ref.invalidate(serverListProvider),
                child: Text(l10n.retryAction),
              ),
            ],
          ),
        ),
        data: (servers) {
          if (servers.isEmpty) {
            return EmptyServerState(
              onImportTap: () => _importFromClipboard(context, ref),
            );
          }

          return _buildGroupedList(context, ref, servers, activeServer);
        },
      ),
      floatingActionButton: const ImportFab(),
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    WidgetRef ref,
    List<ServerConfig> servers,
    ServerConfig? activeServer,
  ) {
    // Group servers by groupName
    final groups = <String, List<ServerConfig>>{};
    for (final server in servers) {
      groups.putIfAbsent(server.groupName, () => []).add(server);
    }

    final groupEntries = groups.entries.toList();

    // Build flat list of widgets: headers + cards with spacing
    final items = <Widget>[];
    for (var i = 0; i < groupEntries.length; i++) {
      if (i > 0) {
        items.add(const Gap(24));
      }
      final entry = groupEntries[i];
      items.add(ServerGroupHeader(groupName: entry.key));
      items.add(const Gap(4));
      for (var j = 0; j < entry.value.length; j++) {
        if (j > 0) {
          items.add(const Gap(8));
        }
        final server = entry.value[j];
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ServerCard(
              server: server,
              isSelected: server.id == activeServer?.id,
              onTap: () {
                HapticFeedback.selectionClick();
                ref
                    .read(activeServerProvider.notifier)
                    .selectServer(server);
              },
              onLongPress: () =>
                  _showDeleteDialog(context, ref, server),
            ),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      children: items,
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    ServerConfig server,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteServerTitle),
        content: Text(l10n.deleteServerBody(server.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.deleteCancel),
          ),
          TextButton(
            onPressed: () {
              final activeServer = ref.read(activeServerProvider);
              ref.read(serverListProvider.notifier).deleteServer(server.id);
              if (activeServer?.id == server.id) {
                ref.read(activeServerProvider.notifier).selectServer(null);
              }
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.deleteConfirm),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromClipboard(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final text = await ClipboardHelper.getText();

    if (!context.mounted) return;

    if (text == null || text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.parseErrorEmptyClipboard),
          duration: AppConstants.snackBarDurationLong,
        ),
      );
      return;
    }

    final config = ShareLinkParser.parse(text);
    if (config == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.parseErrorInvalidLink),
          duration: AppConstants.snackBarDurationLong,
        ),
      );
      return;
    }

    // Check for duplicates by address + port + protocol
    final servers = await ref.read(serverListProvider.future);
    if (!context.mounted) return;

    final isDuplicate = servers.any(
      (s) =>
          s.address == config.address &&
          s.port == config.port &&
          s.protocol == config.protocol,
    );

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.duplicateServer),
          duration: AppConstants.snackBarDurationDefault,
        ),
      );
      return;
    }

    await ref.read(serverListProvider.notifier).addServer(config);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${l10n.importSuccess} — ${config.name}'),
        duration: AppConstants.snackBarDurationDefault,
        backgroundColor: Colors.green.shade700,
        action: SnackBarAction(
          label: l10n.viewAction,
          onPressed: () {},
        ),
      ),
    );
  }
}
