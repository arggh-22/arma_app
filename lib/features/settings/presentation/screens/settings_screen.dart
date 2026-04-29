import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import 'package:arma_proxy_vpn_client/core/constants/app_constants.dart';
import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/log/presentation/providers/log_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/anti_censorship_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/dns_settings_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/engine_settings_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/locale_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/ui_preferences_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/xray_version_provider.dart';
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
    final uiPreferences = ref.watch(uiPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings, style: theme.textTheme.titleLarge),
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
            title: Text(l10n.themeTitle, style: theme.textTheme.titleMedium),
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
                  ref.read(themeProvider.notifier).setThemeMode(values.first);
                },
              ),
            ),
          ),

          // Language selector
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.languageTitle, style: theme.textTheme.titleMedium),
            trailing: Text(
              localeDisplayNames[currentLocale.languageCode] ?? 'English',
              style: theme.textTheme.bodyMedium,
            ),
            onTap: () => _showLanguageSheet(context, ref),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.connectionDisplaySection,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),

          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: Text(
              l10n.detailedNotification,
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(
              l10n.detailedNotificationSubtitle,
              style: theme.textTheme.bodyMedium,
            ),
            value: uiPreferences.showDetailedNotification,
            onChanged: (value) {
              ref
                  .read(uiPreferencesProvider.notifier)
                  .setShowDetailedNotification(value);
            },
          ),

          SwitchListTile(
            secondary: const Icon(Icons.speed_outlined),
            title: Text(
              l10n.dashboardStatistics,
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(
              l10n.dashboardStatisticsSubtitle,
              style: theme.textTheme.bodyMedium,
            ),
            value: uiPreferences.showDashboardStatistics,
            onChanged: (value) {
              ref
                  .read(uiPreferencesProvider.notifier)
                  .setShowDashboardStatistics(value);
            },
          ),

          const Divider(),

          // DNS section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            title: Text(l10n.dnsProtocol, style: theme.textTheme.titleMedium),
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
            title: Text(l10n.remoteDns, style: theme.textTheme.titleMedium),
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                dnsSettings.remoteDns,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            onTap: () => _showDnsPicker(context, ref, isRemote: true),
          ),

          // Direct DNS
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text(l10n.directDns, style: theme.textTheme.titleMedium),
            trailing: Text(
              dnsSettings.directDns,
              style: theme.textTheme.bodyMedium,
            ),
            onTap: () => _showDnsPicker(context, ref, isRemote: false),
          ),

          // FakeIP DNS toggle
          SwitchListTile(
            secondary: const Icon(Icons.dns),
            title: Text('FakeIP DNS', style: theme.textTheme.titleMedium),
            subtitle: const Text('Use fake IP addresses for DNS resolution'),
            value: dnsSettings.fakeIpEnabled,
            onChanged: (value) {
              ref.read(dnsSettingsProvider.notifier).setFakeIpEnabled(value);
            },
          ),

          // FakeIP CIDR field (visible when FakeIP enabled)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: dnsSettings.fakeIpEnabled
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            secondChild: const SizedBox.shrink(),
            firstChild: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: TextEditingController(text: dnsSettings.fakeIpCidr),
                decoration: const InputDecoration(
                  labelText: 'CIDR',
                  hintText: '198.18.0.0/15',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    ref.read(dnsSettingsProvider.notifier).setFakeIpCidr(value);
                  }
                },
              ),
            ),
          ),

          const Divider(),

          // Engine Settings section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            title: Text(l10n.sniffing, style: theme.textTheme.titleMedium),
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
            title: Text(l10n.mux, style: theme.textTheme.titleMedium),
            subtitle: Text(l10n.muxSubtitle, style: theme.textTheme.bodyMedium),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            title: Text(l10n.profile, style: theme.textTheme.titleMedium),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'none', label: Text(l10n.profileNone)),
                  ButtonSegment(value: 'light', label: Text(l10n.profileLight)),
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
            title: Text(l10n.fragment, style: theme.textTheme.titleMedium),
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
                            initialValue: acSettings.fragmentMin.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '10',
                              isDense: true,
                            ),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null) {
                                ref
                                    .read(antiCensorshipProvider.notifier)
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
                            initialValue: acSettings.fragmentMax.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '100',
                              isDense: true,
                            ),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null) {
                                ref
                                    .read(antiCensorshipProvider.notifier)
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
                            initialValue: acSettings.sleepMin.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '1',
                              isDense: true,
                            ),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null) {
                                ref
                                    .read(antiCensorshipProvider.notifier)
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
                            initialValue: acSettings.sleepMax.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '50',
                              isDense: true,
                            ),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null) {
                                ref
                                    .read(antiCensorshipProvider.notifier)
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
            title: Text(l10n.padding, style: theme.textTheme.titleMedium),
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
            title: Text(l10n.mixedSniCase, style: theme.textTheme.titleMedium),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            onTap: () => _showClearCacheDialog(context, ref),
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
            title: Text(l10n.version, style: theme.textTheme.titleMedium),
            trailing: Text(
              AppConstants.appVersion,
              style: theme.textTheme.bodyMedium,
            ),
          ),

          // Xray version
          Consumer(
            builder: (context, ref, _) {
              final xrayVersion = ref.watch(xrayVersionProvider);
              return xrayVersion.when(
                data: (version) {
                  return ListTile(
                    title: Text(
                      'Xray Version',
                      style: theme.textTheme.titleMedium,
                    ),
                    trailing: Text(
                      version,
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                },
                loading: () {
                  return ListTile(
                    title: Text(
                      'Xray Version',
                      style: theme.textTheme.titleMedium,
                    ),
                    trailing: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                error: (err, _) {
                  return ListTile(
                    title: Text(
                      'Xray Version',
                      style: theme.textTheme.titleMedium,
                    ),
                    trailing: Text(
                      'Unknown',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                },
              );
            },
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
                  localeDisplayNames[locale.languageCode] ??
                  locale.languageCode;
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
                        AppLocalizations.of(
                          context,
                        )!.languageChanged(displayName),
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
    final currentDns = isRemote ? dnsSettings.remoteDns : dnsSettings.directDns;
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

  void _showClearCacheDialog(BuildContext context, WidgetRef ref) {
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
              final messenger = ScaffoldMessenger.of(context);
              if (context.mounted) {
                try {
                  final deletedCount = await _clearCachedData(ref);
                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        deletedCount > 0
                            ? '${l10n.cachedDataCleared} ($deletedCount files)'
                            : l10n.cachedDataCleared,
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to clear cache: $e'),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: Text(l10n.clearCacheConfirm),
          ),
        ],
      ),
    );
  }

  Future<int> _clearCachedData(WidgetRef ref) async {
    var deletedCount = 0;

    // Clear in-memory log buffer.
    ref.read(logServiceProvider).clear();

    final documentsDir = await getApplicationDocumentsDirectory();
    final supportDir = await getApplicationSupportDirectory();
    final tempDir = await getTemporaryDirectory();

    Future<void> deleteIfExists(FileSystemEntity entity) async {
      if (!await entity.exists()) return;
      await entity.delete(recursive: true);
      deletedCount++;
    }

    // Clear exported log files from documents directory.
    await for (final entity in documentsDir.list(followLinks: false)) {
      if (entity is File &&
          entity.path.contains('/arma_vpn_log_') &&
          entity.path.endsWith('.txt')) {
        await deleteIfExists(entity);
      }
    }

    // Clear geo assets cache copied by native XrayCoreManager.
    await deleteIfExists(Directory('${supportDir.path}/xray-assets'));

    // Clear temporary cache recursively.
    await for (final entity in tempDir.list(followLinks: false)) {
      await deleteIfExists(entity);
    }

    // Clear stale temporary geo files if present in docs dir.
    await for (final entity in documentsDir.list(followLinks: false)) {
      if (entity is File &&
          (entity.path.endsWith('.dat') || entity.path.endsWith('.dat.new'))) {
        await deleteIfExists(entity);
      }
    }

    return deletedCount;
  }
}
