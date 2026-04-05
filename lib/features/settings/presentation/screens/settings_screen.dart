import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import 'package:arma_proxy_vpn_client/core/constants/app_constants.dart';
import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/anti_censorship_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/dns_settings_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/engine_settings_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/locale_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/widgets/dns_picker_sheet.dart';

/// Settings screen with theme, language, DNS, engine, anti-censorship, and more.
///
/// Sections: General, DNS, Engine Settings, Anti-Censorship, Diagnostics, Data, About.
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
    final acSettings = ref.watch(antiCensorshipProvider);

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

          // Anti-Censorship section header (D-10, D-11)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Text(
              l10n.antiCensorshipSection,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),

          // Profile selector — SegmentedButton with 4 options
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text(
              l10n.profile,
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'none',
                    label: Text(l10n.profileNone),
                  ),
                  ButtonSegment(
                    value: 'light',
                    label: Text(l10n.profileLight),
                  ),
                  ButtonSegment(
                    value: 'moderate',
                    label: Text(l10n.profileModerate),
                  ),
                  ButtonSegment(
                    value: 'aggressive',
                    label: Text(l10n.profileAggressive),
                  ),
                ],
                selected: {acSettings.profile},
                onSelectionChanged: (v) => ref
                    .read(antiCensorshipProvider.notifier)
                    .setProfile(v.first),
              ),
            ),
          ),

          // Profile description — only visible when not 'none'
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: acSettings.profile != 'none'
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Text(
                      switch (acSettings.profile) {
                        'light' => l10n.profileLightDesc,
                        'moderate' => l10n.profileModerateDesc,
                        'aggressive' => l10n.profileAggressiveDesc,
                        _ => '',
                      },
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Fragment toggle
          SwitchListTile(
            secondary: const Icon(Icons.broken_image_outlined),
            title: Text(
              l10n.fragment,
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(
              l10n.fragmentSubtitle,
              style: theme.textTheme.bodyMedium,
            ),
            value: acSettings.fragmentEnabled,
            onChanged: (v) =>
                ref.read(antiCensorshipProvider.notifier).setFragment(v),
          ),

          // Fragment size range — visible when fragment ON
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: acSettings.fragmentEnabled
                ? ListTile(
                    title: Text(
                      l10n.fragmentSize,
                      style: theme.textTheme.titleMedium,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            initialValue:
                                acSettings.fragmentMin.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '10',
                              isDense: true,
                            ),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null) {
                                ref
                                    .read(
                                      antiCensorshipProvider.notifier,
                                    )
                                    .setFragmentMin(n);
                              }
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('—'),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            initialValue:
                                acSettings.fragmentMax.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '100',
                              isDense: true,
                            ),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null) {
                                ref
                                    .read(
                                      antiCensorshipProvider.notifier,
                                    )
                                    .setFragmentMax(n);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Sleep range — visible when fragment ON
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: acSettings.fragmentEnabled
                ? ListTile(
                    title: Text(
                      l10n.sleepMs,
                      style: theme.textTheme.titleMedium,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            initialValue:
                                acSettings.sleepMin.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '1',
                              isDense: true,
                            ),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null) {
                                ref
                                    .read(
                                      antiCensorshipProvider.notifier,
                                    )
                                    .setSleepMin(n);
                              }
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('—'),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            initialValue:
                                acSettings.sleepMax.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '50',
                              isDense: true,
                            ),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null) {
                                ref
                                    .read(
                                      antiCensorshipProvider.notifier,
                                    )
                                    .setSleepMax(n);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Padding toggle
          SwitchListTile(
            secondary: const Icon(Icons.expand),
            title: Text(
              l10n.padding,
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(
              l10n.paddingSubtitle,
              style: theme.textTheme.bodyMedium,
            ),
            value: acSettings.paddingEnabled,
            onChanged: (v) =>
                ref.read(antiCensorshipProvider.notifier).setPadding(v),
          ),

          // Mixed SNI toggle
          SwitchListTile(
            secondary: const Icon(Icons.text_fields),
            title: Text(
              l10n.mixedSniCase,
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(
              l10n.mixedSniSubtitle,
              style: theme.textTheme.bodyMedium,
            ),
            value: acSettings.mixedSniEnabled,
            onChanged: (v) =>
                ref.read(antiCensorshipProvider.notifier).setMixedSni(v),
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

          // Data section header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Text(
              l10n.dataSection,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),

          // Clear cached data
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: Text(
              l10n.clearCachedData,
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(
              l10n.clearCacheSubtitle,
              style: theme.textTheme.bodyMedium,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showClearCacheDialog(context),
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

  void _showClearCacheDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearCacheTitle),
        content: Text(l10n.clearCacheBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.keepData),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _clearCachedData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.cachedDataCleared),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
            child: Text(l10n.clearCacheConfirm),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCachedData() async {
    try {
      // Clear geo rule cache files
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = await getTemporaryDirectory();

      // Delete .dat files in app directory (downloaded geo rules)
      final appFiles = appDir.listSync();
      for (final f in appFiles) {
        if (f is File &&
            (f.path.endsWith('.dat') ||
                f.path.endsWith('.dat.new'))) {
          await f.delete();
        }
      }

      // Clear temporary cache directory
      if (cacheDir.existsSync()) {
        final cacheFiles = cacheDir.listSync();
        for (final f in cacheFiles) {
          if (f is File) await f.delete();
        }
      }

      // Note: subscription cache and logs cleared via temp dir.
      // Server configs and preferences are NOT touched (per D-15).
    } catch (e) {
      debugPrint('Clear cache error: $e');
    }
  }
}
