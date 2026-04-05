import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/log/presentation/providers/log_provider.dart';

/// Log viewer screen with monospace log display, level filtering, search,
/// auto-scroll, and export.
///
/// Accessible from Settings → View Logs. Shows real-time Xray-core debug logs
/// from [LogService] via [LogLinesNotifier].
///
/// UI-SPEC §10:
/// - Monospace font, 12sp, color-coded by level (error=red, warning=orange)
/// - Filter dropdown (All/Info/Warning/Error)
/// - Search text field for substring matching
/// - Auto-scroll to bottom for new entries (disables when user scrolls up)
/// - Bottom status bar with line count and auto-scroll toggle
/// - Export via AppBar action (share_plus share sheet)
class LogViewerScreen extends ConsumerStatefulWidget {
  const LogViewerScreen({super.key});

  @override
  ConsumerState<LogViewerScreen> createState() => _LogViewerScreenState();
}

enum _LogFilter { all, info, warning, error }

class _LogViewerScreenState extends ConsumerState<LogViewerScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  _LogFilter _selectedFilter = _LogFilter.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // Disable auto-scroll when user scrolls up more than 50px from bottom
    if (position.pixels < position.maxScrollExtent - 50) {
      if (_autoScroll) {
        setState(() => _autoScroll = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  List<String> _filterLines(List<String> allLines) {
    var filtered = allLines;

    // Apply level filter
    switch (_selectedFilter) {
      case _LogFilter.all:
        break;
      case _LogFilter.info:
        // Info = exclude warn/error lines
        filtered = filtered
            .where((line) =>
                !_isWarningLine(line) && !_isErrorLine(line))
            .toList();
      case _LogFilter.warning:
        filtered = filtered.where(_isWarningLine).toList();
      case _LogFilter.error:
        filtered = filtered.where(_isErrorLine).toList();
    }

    // Apply search text filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((line) => line.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  bool _isErrorLine(String line) {
    final lower = line.toLowerCase();
    return lower.contains('err') || lower.contains('error');
  }

  bool _isWarningLine(String line) {
    final lower = line.toLowerCase();
    return lower.contains('warn') || lower.contains('warning');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final allLines = ref.watch(logLinesProvider);
    final filteredLines = _filterLines(allLines);

    // Auto-scroll when new lines arrive
    if (_autoScroll && filteredLines.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.viewLogs),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: l10n.exportLogs,
            onPressed: () {
              ref.read(logServiceProvider).exportAndShare();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Level filter dropdown
                DropdownButton<_LogFilter>(
                  value: _selectedFilter,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(
                      value: _LogFilter.all,
                      child: Text(l10n.logFilterAll),
                    ),
                    DropdownMenuItem(
                      value: _LogFilter.info,
                      child: Text(l10n.logFilterInfo),
                    ),
                    DropdownMenuItem(
                      value: _LogFilter.warning,
                      child: Text(l10n.logFilterWarning),
                    ),
                    DropdownMenuItem(
                      value: _LogFilter.error,
                      child: Text(l10n.logFilterError),
                    ),
                  ],
                  onChanged: (filter) {
                    if (filter != null) {
                      setState(() => _selectedFilter = filter);
                    }
                  },
                ),
                const SizedBox(width: 12),
                // Search field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '${l10n.logFilterAll}...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: theme.textTheme.bodyMedium,
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Log list
          Expanded(
            child: filteredLines.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.noLogsYet,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.noLogsBody,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: filteredLines.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final line = filteredLines[index];
                      return _LogLineWidget(
                        line: line,
                        colorScheme: colorScheme,
                        isError: _isErrorLine(line),
                        isWarning: _isWarningLine(line),
                      );
                    },
                  ),
          ),

          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Text(
                  l10n.linesCount(filteredLines.length),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.autoScroll,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Switch(
                  value: _autoScroll,
                  onChanged: (value) {
                    setState(() => _autoScroll = value);
                    if (value) _scrollToBottom();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual log line widget with color-coding.
///
/// - Error lines (containing "err"/"error"): [ColorScheme.error] color
/// - Warning lines (containing "warn"/"warning"): [Colors.orange] color
/// - Timestamp prefix (text before first `]`): [ColorScheme.onSurfaceVariant]
/// - Normal lines: default [ColorScheme.onSurface]
class _LogLineWidget extends StatelessWidget {
  const _LogLineWidget({
    required this.line,
    required this.colorScheme,
    required this.isError,
    required this.isWarning,
  });

  final String line;
  final ColorScheme colorScheme;
  final bool isError;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    // Split timestamp prefix from message
    final closingBracket = line.indexOf(']');
    final hasTimestamp = closingBracket > 0;

    final Color messageColor;
    if (isError) {
      messageColor = colorScheme.error;
    } else if (isWarning) {
      messageColor = Colors.orange;
    } else {
      messageColor = colorScheme.onSurface;
    }

    if (hasTimestamp) {
      final timestamp = line.substring(0, closingBracket + 1);
      final message = line.substring(closingBracket + 1);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: timestamp,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              TextSpan(
                text: message,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: messageColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        line,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: messageColor,
        ),
      ),
    );
  }
}
