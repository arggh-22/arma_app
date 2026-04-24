import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/routing/data/services/rules_update_service.dart';
import 'package:arma_proxy_vpn_client/features/routing/presentation/providers/routing_settings_provider.dart';

/// Filter chips for region bypass presets (Iran, China, Russia).
///
/// When a region is enabled, its geosite/geoip rules are applied
/// to route domestic traffic directly (bypassing the proxy).
class RegionPresetsSection extends ConsumerStatefulWidget {
  const RegionPresetsSection({super.key});

  @override
  ConsumerState<RegionPresetsSection> createState() => _RegionPresetsSectionState();
}

class _RegionPresetsSectionState extends ConsumerState<RegionPresetsSection> {
  bool _isUpdatingRules = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(routingSettingsProvider);

    final regions = [
      {
        'id': 'iran',
        'label': l10n.regionIran,
        'domainRule': 'geosite:category-ir',
        'ipRule': 'geoip:ir',
      },
      {
        'id': 'china',
        'label': l10n.regionChina,
        'domainRule': 'geosite:cn',
        'ipRule': 'geoip:cn',
      },
      {
        'id': 'russia',
        'label': l10n.regionRussia,
        'domainRule': 'geosite:category-ru',
        'ipRule': 'geoip:ru',
      },
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
        // Regional preset configurations
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'Regional preset configurations',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: regions.map((r) {
                final selected = settings.enabledRegions.contains(r['id']);
                final statusColor = selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    selected ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18,
                    color: statusColor,
                  ),
                  title: Text(
                    r['label']!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Domain: ${r['domainRule']}  •  IP: ${r['ipRule']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
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
            onPressed: _isUpdatingRules
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _isUpdatingRules = true);
                    try {
                      final updatedCount = await RulesUpdateService().updateRules();
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            '$updatedCount files updated. ${l10n.rulesUpdated}',
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Rules update failed: $e'),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _isUpdatingRules = false);
                      }
                    }
                  },
            icon: _isUpdatingRules
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: Text(l10n.updateRules),
          ),
        ),
      ],
    );
  }
}
