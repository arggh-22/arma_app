import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/xray/xray_config_builder.dart';

/// Debug-only screen that shows the full Xray JSON config generated for a
/// server. Accessible only when [kDebugMode] is true.
///
/// Displays two tabs:
/// - **VPN Config** — the full config passed to `StartLoop()` (with inbounds,
///   routing, DNS, stats, etc.)
/// - **Latency Test** — the minimal config used by `MeasureDelay()`
///
/// Provides a copy-to-clipboard button for each config.
class ServerXrayConfigScreen extends StatefulWidget {
  const ServerXrayConfigScreen({super.key, required this.server});

  final ServerConfig server;

  @override
  State<ServerXrayConfigScreen> createState() => _ServerXrayConfigScreenState();
}

class _ServerXrayConfigScreenState extends State<ServerXrayConfigScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final String _vpnConfig;
  late final String _latencyConfig;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _vpnConfig = _prettyJson(XrayConfigBuilder.build(widget.server));
    _latencyConfig = _prettyJson(
      XrayConfigBuilder.buildForLatencyTest(widget.server),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static String _prettyJson(String raw) {
    try {
      final obj = jsonDecode(raw);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(obj);
    } catch (_) {
      return raw;
    }
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Safety guard — this screen must never appear in release builds
    assert(kDebugMode, 'ServerXrayConfigScreen must only be used in debug mode');

    final theme = Theme.of(context);
    final server = widget.server;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xray Config [DEBUG]',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              server.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'VPN Config'),
            Tab(text: 'Latency Test'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Server info summary card
          _ServerInfoCard(server: server),

          // Config tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ConfigView(
                  config: _vpnConfig,
                  onCopy: () => _copyToClipboard(context, _vpnConfig),
                ),
                _ConfigView(
                  config: _latencyConfig,
                  onCopy: () => _copyToClipboard(context, _latencyConfig),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerInfoCard extends StatelessWidget {
  const _ServerInfoCard({required this.server});

  final ServerConfig server;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          _InfoChip(label: 'Protocol', value: server.protocol.label),
          _InfoChip(label: 'Network', value: server.network),
          _InfoChip(label: 'Security', value: server.security),
          _InfoChip(label: 'Address', value: '${server.address}:${server.port}'),
          if (server.network == 'xhttp' || server.network == 'splithttp')
            _InfoChip(label: 'XHTTP Mode', value: server.xhttpMode),
          if (server.sni != null)
            _InfoChip(label: 'SNI', value: server.sni!),
          if (server.path != null)
            _InfoChip(label: 'Path', value: server.path!),
          if (server.host != null)
            _InfoChip(label: 'Host', value: server.host!),
          if (server.flow != null && server.flow!.isNotEmpty)
            _InfoChip(label: 'Flow', value: server.flow!),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodySmall,
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigView extends StatelessWidget {
  const _ConfigView({required this.config, required this.onCopy});

  final String config;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // Scrollable JSON text
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 72),
            child: SelectableText(
              config,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ),

        // Floating copy button
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'xray-config-copy-fab',
            onPressed: onCopy,
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy JSON'),
          ),
        ),
      ],
    );
  }
}
