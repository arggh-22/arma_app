import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/sort_filter_provider.dart';

/// Horizontal bar with a sort dropdown and filter chips for the server list.
///
/// - Sort dropdown: Name, Latency, Protocol
/// - Filter chips: All (default), Working, Failed — single-select
class SortFilterBar extends ConsumerWidget {
  const SortFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sortFilter = ref.watch(sortFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 48,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Sort dropdown
              Icon(Icons.sort, size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              DropdownButton<SortCriteria>(
                value: sortFilter.sort,
                underline: const SizedBox.shrink(),
                style: theme.textTheme.bodyMedium,
                items: [
                  DropdownMenuItem(
                    value: SortCriteria.defaultOrder,
                    child: Text(l10n.sortByDefault),
                  ),
                  DropdownMenuItem(
                    value: SortCriteria.name,
                    child: Text(l10n.sortByName),
                  ),
                  DropdownMenuItem(
                    value: SortCriteria.latency,
                    child: Text(l10n.sortByLatency),
                  ),
                  DropdownMenuItem(
                    value: SortCriteria.protocol,
                    child: Text(l10n.sortByProtocol),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(sortFilterProvider.notifier)
                        .setSort(value);
                  }
                },
              ),
              const SizedBox(width: 12),

              // Filter chips
              FilterChip(
                label: Text(l10n.filterAll),
                selected: sortFilter.filter == FilterCriteria.all,
                selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                checkmarkColor: colorScheme.primary,
                onSelected: (_) => ref
                    .read(sortFilterProvider.notifier)
                    .setFilter(FilterCriteria.all),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(l10n.filterWorking),
                selected: sortFilter.filter == FilterCriteria.working,
                selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                checkmarkColor: colorScheme.primary,
                onSelected: (_) => ref
                    .read(sortFilterProvider.notifier)
                    .setFilter(FilterCriteria.working),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(l10n.filterFailed),
                selected: sortFilter.filter == FilterCriteria.failed,
                selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                checkmarkColor: colorScheme.primary,
                onSelected: (_) => ref
                    .read(sortFilterProvider.notifier)
                    .setFilter(FilterCriteria.failed),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
