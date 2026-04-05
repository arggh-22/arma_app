import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:arma_proxy_vpn_client/core/constants/app_constants.dart';
import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/locale_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';

/// Settings screen with functional theme toggle and language selector.
///
/// Theme: SegmentedButton with System/Light/Dark — persists via SharedPreferences.
/// Language: ModalBottomSheet with 4 languages — persists via SharedPreferences.
/// About: Version and open source licenses.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentThemeMode = ref.watch(themeProvider);
    final currentLocale = ref.watch(localeProvider);

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
}
