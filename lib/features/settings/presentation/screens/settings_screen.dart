import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:arma_proxy_vpn_client/core/constants/app_constants.dart';
import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/dns_settings_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/engine_settings_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/locale_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/widgets/dns_picker_sheet.dart';

/// Settings screen with theme, language, DNS, engine, and more.
///
/// Sections: General, DNS, Engine Settings, Diagnostics, About.
/// All settings auto-save to SharedPreferences on change.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentThemeMode = ref.watch(themeProvider);
    final currentLocale = ref.watch(localeProvider);
    final dnsSettings = ref.watch(dnsSettingsProvider);
    final engineSettings = ref.watch(engineSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.settings,
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: ListView(
        children: [
          // General section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.generalSection,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),

          // Theme selector
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: Text(
              l10n.themeTitle,
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.themeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.themeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l10n.themeDark),
                  ),
                ],
                selected: {currentThemeMode},
                onSelectionChanged: (values) {
                  ref
                      .read(themeProvider.notifier)
                      .setThemeMode(values.first);
                },
              ),
            ),
          ),

          // Language selector
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(
              l10n.languageTitle,
              style: theme.textTheme.titleMedium,
            ),
            trailing: Text(
              localeDisplayNames[currentLocale.languageCode] ?? 'English',
              style: theme.textTheme.bodyMedium,
            ),
            onTap: () => _showLanguageSheet(context, ref),
          ),

          const Divider(),

          // DNS section header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Text(
              l10n.dnsSection,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),

          // DNS Protocol — SegmentedButton
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: Text(
              l10n.dnsProtocol,
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'doh', label: Text('DoH')),
                  ButtonSegment(value: 'dot', label: Text('DoT')),
                  ButtonSegment(value: 'plain', label: Text('Plain')),
                ],
                selected: {dnsSettings.protocol},
                onSelectionChanged: (values) {
                  ref
                      .read(dnsSettingsProvider.notifier)
                      .setProtocol(values.first);
                },
              ),
            ),
          ),

          // Remote DNS
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: Text(
              l10n.remoteDns,
              style: theme.textTheme.titleMedium,
            ),
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                dnsSettings.remoteDns,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            onTap: () => _showDnsPicker(
              context,
              ref,
              isRemote: true,
            ),
          ),

          // Direct DNS
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text(
              l10n.directDns,
              style: theme.textTheme.titleMedium,
            ),
            trailing: Text(
              dnsSettings.directDns,
              style: theme.textTheme.bodyMedium,
            ),
            onTap: () => _showDnsPicker(
              context,
              ref,
              isRemote: false,
            ),
          ),

          const Divider(),

          // Engine Settings section header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Text(
              l10n.engineSettingsSection,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),

          // Sniffing toggle — default ON (D-09)
          SwitchListTile(
            secondary: const Icon(Icons.visibility_outlined),
            title: Text(
              l10n.sniffing,
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(
              l10n.sniffingSubtitle,
              style: theme.textTheme.bodyMedium,
            ),
            value: engineSettings.sniffingEnabled,
            onChanged: (v) =>
                ref.read(engineSettingsProvider.notifier).setSniffing(v),
          ),

          // Mux toggle — default OFF (D-09)
          SwitchListTile(
            secondary: const Icon(Icons.merge_type),
            title: Text(
              l10n.mux,
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(
              l10n.muxSubtitle,
              style: theme.textTheme.bodyMedium,
            ),
            value: engineSettings.muxEnabled,
            onChanged: (v) =>
                ref.read(engineSettingsProvider.notifier).setMux(v),
          ),

          // Mux concurrency — visible only when mux ON, with AnimatedSize
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: engineSettings.muxEnabled
                ? ListTile(
                    leading: const Icon(Icons.tune),
                    title: Text(
                      l10n.concurrency,
                      style: theme.textTheme.titleMedium,
                    ),
                    trailing: Text(
                      '${engineSettings.muxConcurrency}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    subtitle: Slider(
                      value: engineSettings.muxConcurrency.toDouble(),
                      min: 1,
                      max: 8,
                      divisions: 7,
                      label: engineSettings.muxConcurrency.toString(),
                      onChanged: (v) => ref
                          .read(engineSettingsProvider.notifier)
                          .setMuxConcurrency(v.round()),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const Divider(),

          // Diagnostics section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.diagnosticsSection,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),

          // View Logs
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: Text(l10n.viewLogs, style: theme.textTheme.titleMedium),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/logs'),
          ),

          const Divider(),

          // About section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.aboutSection,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),

          // Version
          ListTile(
            title: Text(
              l10n.version,
              style: theme.textTheme.titleMedium,
            ),
            trailing: Text(
              AppConstants.appVersion,
              style: theme.textTheme.bodyMedium,
            ),
          ),

          // Open source licenses
          ListTile(
            title: Text(
              l10n.openSourceLicenses,
              style: theme.textTheme.titleMedium,
            ),
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppConstants.appName,
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: supportedLocales.map((locale) {
              final displayName =
                  localeDisplayNames[locale.languageCode] ?? locale.languageCode;
              final isSelected =
                  locale.languageCode == currentLocale.languageCode;

              return ListTile(
                title: Text(displayName),
                trailing: isSelected
                    ? Icon(
                        Icons.radio_button_checked,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : const Icon(Icons.radio_button_unchecked),
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(locale);
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!
                            .languageChanged(displayName),
                      ),
                      duration: AppConstants.snackBarDurationShort,
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showDnsPicker(
    BuildContext context,
    WidgetRef ref, {
    required bool isRemote,
  }) {
    final dnsSettings = ref.read(dnsSettingsProvider);
    final currentDns =
        isRemote ? dnsSettings.remoteDns : dnsSettings.directDns;
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DnsPickerSheet(
          currentDns: currentDns,
          protocol: dnsSettings.protocol,
          onSelected: (dns) {
            if (isRemote) {
              ref.read(dnsSettingsProvider.notifier).setRemoteDns(dns);
            } else {
              ref.read(dnsSettingsProvider.notifier).setDirectDns(dns);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.dnsUpdated),
                duration: AppConstants.snackBarDurationShort,
              ),
            );
          },
        );
      },
    );
  }
}
