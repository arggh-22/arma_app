import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/routing/domain/entities/domain_rule.dart';
import 'package:arma_proxy_vpn_client/features/routing/presentation/providers/routing_settings_provider.dart';
import 'package:arma_proxy_vpn_client/features/routing/presentation/widgets/add_domain_rule_dialog.dart';
import 'package:arma_proxy_vpn_client/features/routing/presentation/widgets/domain_rule_row.dart';
import 'package:arma_proxy_vpn_client/features/routing/presentation/widgets/app_picker_list.dart';
import 'package:arma_proxy_vpn_client/features/routing/presentation/widgets/region_presets_section.dart';

/// Full routing configuration screen with 3 collapsible sections:
/// 1. Region Presets — filter chips for Iran/China/Russia bypass
/// 2. Domain Rules — custom per-domain proxy/direct/block rules
/// 3. Per-App Proxy — blacklist/whitelist with searchable app picker
class RoutingScreen extends ConsumerStatefulWidget {
  const RoutingScreen({super.key});

  @override
  ConsumerState<RoutingScreen> createState() => _RoutingScreenState();
}

class _RoutingScreenState extends ConsumerState<RoutingScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(routingSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routing, style: theme.textTheme.titleLarge),
      ),
      body: ListView(
        children: [
          // Bypass LAN toggle (now using Riverpod instead of setState)
          SwitchListTile(
            title: Text(
              l10n.bypassLan,
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(
              l10n.bypassLanSubtitle,
              style: theme.textTheme.bodyMedium,
            ),
            value: settings.bypassLan,
            onChanged: (v) =>
                ref.read(routingSettingsProvider.notifier).setBypassLan(v),
          ),
          const Divider(),

          // Region Presets — ExpansionTile, initially expanded
          ExpansionTile(
            leading: const Icon(Icons.public),
            title: Text(
              l10n.regionPresets,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: colorScheme.primary),
            ),
            initiallyExpanded: true,
            children: const [RegionPresetsSection()],
          ),
          const Divider(),

          // Domain Rules — ExpansionTile, initially collapsed
          ExpansionTile(
            leading: const Icon(Icons.domain),
            title: Text(
              l10n.domainRules,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: colorScheme.primary),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (settings.customRules.isNotEmpty)
                  Text(
                    '${settings.customRules.length}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.expand_more),
              ],
            ),
            children: [
              if (settings.customRules.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      l10n.noRulesYet,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                ...settings.customRules.asMap().entries.map((entry) {
                  final index = entry.key;
                  final rule = entry.value;
                  return DomainRuleRow(
                    rule: rule,
                    onActionChanged: (action) => ref
                        .read(routingSettingsProvider.notifier)
                        .updateRuleAction(index, action),
                    onDelete: () {
                      final deletedRule = rule;
                      ref
                          .read(routingSettingsProvider.notifier)
                          .deleteRule(index);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.ruleRemoved),
                          duration: const Duration(seconds: 3),
                          action: SnackBarAction(
                            label: l10n.undo,
                            onPressed: () => ref
                                .read(routingSettingsProvider.notifier)
                                .insertRule(index, deletedRule),
                          ),
                        ),
                      );
                    },
                  );
                }),
              // Add Rule button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final rule = await showDialog<DomainRule>(
                        context: context,
                        builder: (_) => const AddDomainRuleDialog(),
                      );
                      if (rule != null) {
                        ref
                            .read(routingSettingsProvider.notifier)
                            .addRule(rule);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addRule),
                  ),
                ),
              ),
            ],
          ),
          const Divider(),

          // Per-App Proxy — ExpansionTile, initially collapsed (D-04, D-05)
          ExpansionTile(
            leading: const Icon(Icons.apps),
            title: Text(
              l10n.perAppProxy,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: colorScheme.primary),
            ),
            children: [
              // Enable toggle
              SwitchListTile(
                title: Text(
                  l10n.enablePerAppProxy,
                  style: theme.textTheme.titleMedium,
                ),
                value: settings.perAppEnabled,
                onChanged: (v) => ref
                    .read(routingSettingsProvider.notifier)
                    .setPerAppEnabled(v),
              ),
              // Mode selector + app list — visible only when enabled
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: settings.perAppEnabled
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Blacklist / Whitelist SegmentedButton
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: SegmentedButton<String>(
                              segments: [
                                ButtonSegment(
                                  value: 'blacklist',
                                  label: Text(l10n.blacklistMode),
                                ),
                                ButtonSegment(
                                  value: 'whitelist',
                                  label: Text(l10n.whitelistMode),
                                ),
                              ],
                              selected: {settings.perAppMode},
                              onSelectionChanged: (v) {
                                ref
                                    .read(routingSettingsProvider.notifier)
                                    .setPerAppMode(v.first);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text(l10n.switchedToMode(v.first)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Mode description
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Text(
                              settings.perAppMode == 'blacklist'
                                  ? l10n.blacklistDescription
                                  : l10n.whitelistDescription,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          // App picker list
                          const AppPickerList(),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),

          // Bottom padding for nav bar clearance
          const SizedBox(height: 88),
        ],
      ),
    );
  }
}
