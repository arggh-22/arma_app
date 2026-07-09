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
  bool _selectedOnly = false;
  bool _showSystemApps = false;

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChip(
                label: const Text('Selected only'),
                selected: _selectedOnly,
                onSelected: (v) => setState(() => _selectedOnly = v),
              ),
              FilterChip(
                label: const Text('Show system apps'),
                selected: _showSystemApps,
                onSelected: (v) => setState(() => _showSystemApps = v),
              ),
              TextButton.icon(
                onPressed: () => ref.invalidate(installedAppsProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh list'),
              ),
            ],
          ),
        ),
        // Selected count
        Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              l10n.appsSelectedCount(settings.selectedApps.length),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $e', style: theme.textTheme.bodyMedium),
          ),
          data: (apps) {
            final selectedSet = settings.selectedApps.toSet();
            final query = _searchQuery.trim();
            final filtered = apps.where((a) {
              if (_selectedOnly && !selectedSet.contains(a.packageName)) {
                return false;
              }
              if (!_showSystemApps && a.isSystem) return false;
              return _matchesQuery(a, query);
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: filtered.isEmpty
                            ? null
                            : () async {
                                final merged = {
                                  ...selectedSet,
                                  ...filtered.map((e) => e.packageName),
                                }.toList();
                                await ref
                                    .read(routingSettingsProvider.notifier)
                                    .setSelectedApps(merged);
                              },
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const Text('Select shown'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: settings.selectedApps.isEmpty
                            ? null
                            : () => ref
                                  .read(routingSettingsProvider.notifier)
                                  .setSelectedApps([]),
                        child: const Text('Clear all'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${filtered.length} shown · ${apps.length} total',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No apps found. Try enabling "Show system apps" or clearing search.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.55,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final app = filtered[index];
                        final selected = selectedSet.contains(app.packageName);

                        Widget leading;
                        if (app.iconBase64.isNotEmpty) {
                          try {
                            leading = ClipOval(
                              child: Image.memory(
                                base64Decode(app.iconBase64),
                                width: 32,
                                height: 32,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.android, size: 32),
                              ),
                            );
                          } catch (_) {
                            leading = const Icon(Icons.android, size: 32);
                          }
                        } else {
                          leading = const Icon(Icons.android, size: 32);
                        }

                        return ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(vertical: -1),
                          leading: leading,
                          title: Text(
                            app.appName,
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            app.packageName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: selected
                              ? Icon(
                                  Icons.check_circle,
                                  color: colorScheme.primary,
                                )
                              : const Icon(Icons.radio_button_unchecked),
                          onTap: () => ref
                              .read(routingSettingsProvider.notifier)
                              .toggleApp(app.packageName),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  bool _matchesQuery(InstalledApp app, String query) {
    if (query.isEmpty) return true;
    final rawQuery = query.toLowerCase();
    final rawName = app.appName.toLowerCase();
    final rawPkg = app.packageName.toLowerCase();
    if (rawName.contains(rawQuery) || rawPkg.contains(rawQuery)) return true;

    final q = _normalizeForSearch(query);
    final name = _normalizeForSearch(app.appName);
    final pkg = _normalizeForSearch(app.packageName);
    if (q.isEmpty) return false;

    if (name.contains(q) || pkg.contains(q)) return true;
    if (_containsSubsequence(name, q) || _containsSubsequence(pkg, q)) {
      return true;
    }
    return false;
  }

  String _normalizeForSearch(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  bool _containsSubsequence(String text, String pattern) {
    if (pattern.isEmpty) return true;
    var i = 0;
    for (var j = 0; j < text.length && i < pattern.length; j++) {
      if (text.codeUnitAt(j) == pattern.codeUnitAt(i)) i++;
    }
    return i == pattern.length;
  }
}
