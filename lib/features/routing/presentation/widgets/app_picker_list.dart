import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/routing/presentation/providers/installed_apps_provider.dart';
import 'package:arma_proxy_vpn_client/features/routing/presentation/providers/routing_settings_provider.dart';

/// Searchable list of installed Android apps with checkboxes.
///
/// Renders app icons from base64-encoded PNG data with error fallback.
/// Search filters by app name (case-insensitive).
/// Uses [ConstrainedBox] with maxHeight 400 to prevent layout overflow.
class AppPickerList extends ConsumerStatefulWidget {
  const AppPickerList({super.key});

  @override
  ConsumerState<AppPickerList> createState() => _AppPickerListState();
}

class _AppPickerListState extends ConsumerState<AppPickerList> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(routingSettingsProvider);
    final appsAsync = ref.watch(installedAppsProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SearchBar(
            leading: const Icon(Icons.search),
            hintText: l10n.searchApps,
            hintStyle: WidgetStatePropertyAll(theme.textTheme.bodyMedium),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        // Selected count
        Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              l10n.appsSelectedCount(settings.selectedApps.length),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        // App list
        appsAsync.when(
          loading: () => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  l10n.loadingApps,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $e', style: theme.textTheme.bodyMedium),
          ),
          data: (apps) {
            final filtered = _searchQuery.isEmpty
                ? apps
                : apps
                    .where(
                      (a) => a.appName
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()),
                    )
                    .toList();

            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final app = filtered[index];
                  final selected =
                      settings.selectedApps.contains(app.packageName);

                  Widget leading;
                  if (app.iconBase64.isNotEmpty) {
                    try {
                      leading = ClipOval(
                        child: Image.memory(
                          base64Decode(app.iconBase64),
                          width: 32,
                          height: 32,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.android, size: 32),
                        ),
                      );
                    } catch (_) {
                      leading = const Icon(Icons.android, size: 32);
                    }
                  } else {
                    leading = const Icon(Icons.android, size: 32);
                  }

                  return SizedBox(
                    height: 56,
                    child: ListTile(
                      leading: leading,
                      title: Text(
                        app.appName,
                        style: theme.textTheme.titleMedium,
                      ),
                      trailing: Checkbox(
                        value: selected,
                        onChanged: (_) => ref
                            .read(routingSettingsProvider.notifier)
                            .toggleApp(app.packageName),
                      ),
                      onTap: () => ref
                          .read(routingSettingsProvider.notifier)
                          .toggleApp(app.packageName),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
