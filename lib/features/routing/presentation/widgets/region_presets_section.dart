import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/routing/presentation/providers/routing_settings_provider.dart';

/// Filter chips for region bypass presets (Iran, China, Russia).
///
/// When a region is enabled, its geosite/geoip rules are applied
/// to route domestic traffic directly (bypassing the proxy).
class RegionPresetsSection extends ConsumerWidget {
  const RegionPresetsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(routingSettingsProvider);

    final regions = [
      {'id': 'iran', 'label': l10n.regionIran},
      {'id': 'china', 'label': l10n.regionChina},
      {'id': 'russia', 'label': l10n.regionRussia},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FilterChips — horizontally scrollable
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: regions.map((r) {
              final selected = settings.enabledRegions.contains(r['id']);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(r['label']!),
                  selected: selected,
                  selectedColor: colorScheme.primary,
                  labelStyle: TextStyle(
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                  onSelected: (_) => ref
                      .read(routingSettingsProvider.notifier)
                      .toggleRegion(r['id']!),
                ),
              );
            }).toList(),
          ),
        ),
        // Bundled rules note
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            l10n.bundledRulesNote,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
        // Update Rules button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextButton.icon(
            onPressed: () {
              // TODO: Download community rules from GitHub
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.rulesUpdated),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.download),
            label: Text(l10n.updateRules),
          ),
        ),
      ],
    );
  }
}
