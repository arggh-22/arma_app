import 'package:flutter/material.dart';

import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/core/theme/app_colors.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/sort_filter_provider.dart';

/// Search + quick-filter controls for a server list (design: Servers
/// Management screen §2).
///
/// - Pill-shaped search field ("Search servers...")
/// - Protocol quick-filter chips: All, VLESS, VMess, Trojan, SS, Hysteria2
/// - Status chips: Working, Failed
/// - Sort menu (Default, Name, Latency, Protocol)
///
/// Provider-agnostic: callers pass the current [state] and mutation callbacks,
/// so the same bar drives both the Servers tab and the home default servers
/// list from their own independent providers.
class SortFilterBar extends StatefulWidget {
  const SortFilterBar({
    super.key,
    required this.state,
    required this.onSort,
    required this.onFilter,
    required this.onQuery,
    required this.onProtocol,
  });

  final SortFilterState state;
  final ValueChanged<SortCriteria> onSort;
  final ValueChanged<FilterCriteria> onFilter;
  final ValueChanged<String> onQuery;
  final ValueChanged<ProtocolType?> onProtocol;

  @override
  State<SortFilterBar> createState() => _SortFilterBarState();
}

class _SortFilterBarState extends State<SortFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sortFilter = widget.state;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pill search field with trailing sort menu.
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('server-search-field'),
                  controller: _searchController,
                  onChanged: widget.onQuery,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.searchServersHint,
                    prefixIcon: Icon(
                      Icons.search,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    suffixIcon: sortFilter.query.isEmpty
                        ? null
                        : IconButton(
                            key: const Key('server-search-clear'),
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              widget.onQuery('');
                            },
                          ),
                    isDense: true,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(999),
                      ),
                      borderSide: BorderSide(
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(999),
                      ),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<SortCriteria>(
                key: const Key('server-sort-menu'),
                icon: Icon(Icons.tune, color: colorScheme.onSurfaceVariant),
                tooltip: l10n.sortByDefault,
                initialValue: sortFilter.sort,
                onSelected: widget.onSort,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: SortCriteria.defaultOrder,
                    child: Text(l10n.sortByDefault),
                  ),
                  PopupMenuItem(
                    value: SortCriteria.name,
                    child: Text(l10n.sortByName),
                  ),
                  PopupMenuItem(
                    value: SortCriteria.latency,
                    child: Text(l10n.sortByLatency),
                  ),
                  PopupMenuItem(
                    value: SortCriteria.protocol,
                    child: Text(l10n.sortByProtocol),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Protocol quick-filters + status chips.
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip(
                  key: const Key('protocol-filter-all'),
                  label: l10n.filterAll,
                  selected: sortFilter.protocol == null,
                  accent: colorScheme.primary,
                  onTap: () => widget.onProtocol(null),
                ),
                for (final protocol in ProtocolType.values)
                  _filterChip(
                    key: Key('protocol-filter-${protocol.name}'),
                    label: protocol.label,
                    selected: sortFilter.protocol == protocol,
                    accent: AppColors.protocolColor(protocol),
                    onTap: () => widget.onProtocol(
                      sortFilter.protocol == protocol ? null : protocol,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: VerticalDivider(
                    width: 1,
                    indent: 8,
                    endIndent: 8,
                    color: colorScheme.outlineVariant,
                  ),
                ),
                _filterChip(
                  key: const Key('status-filter-working'),
                  label: l10n.filterWorking,
                  selected: sortFilter.filter == FilterCriteria.working,
                  accent: colorScheme.primary,
                  onTap: () => widget.onFilter(
                    sortFilter.filter == FilterCriteria.working
                        ? FilterCriteria.all
                        : FilterCriteria.working,
                  ),
                ),
                _filterChip(
                  key: const Key('status-filter-failed'),
                  label: l10n.filterFailed,
                  selected: sortFilter.filter == FilterCriteria.failed,
                  accent: colorScheme.error,
                  onTap: () => widget.onFilter(
                    sortFilter.filter == FilterCriteria.failed
                        ? FilterCriteria.all
                        : FilterCriteria.failed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required Key key,
    required String label,
    required bool selected,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        key: key,
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: accent.withValues(alpha: 0.18),
        side: selected
            ? BorderSide(color: accent.withValues(alpha: 0.6))
            : null,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
