import 'package:flutter/material.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';

/// DNS preset data for the picker sheet.
///
/// Each preset maps to a well-known public DNS provider with
/// DoH, DoT, and plain IP addresses.
const dnsPresets = [
  {
    'name': 'Cloudflare',
    'ip': '1.1.1.1',
    'doh': 'https://1.1.1.1/dns-query',
    'dot': 'tls://1.1.1.1',
  },
  {
    'name': 'Google',
    'ip': '8.8.8.8',
    'doh': 'https://dns.google/dns-query',
    'dot': 'tls://8.8.8.8',
  },
  {
    'name': 'Quad9',
    'ip': '9.9.9.9',
    'doh': 'https://dns.quad9.net/dns-query',
    'dot': 'tls://9.9.9.9',
  },
  {
    'name': 'AdGuard',
    'ip': '94.140.14.14',
    'doh': 'https://dns.adguard-dns.com/dns-query',
    'dot': 'tls://94.140.14.14',
  },
  {
    'name': 'Electro',
    'ip': '78.157.42.100',
    'doh': 'https://electrotel.ir/dns-query',
    'dot': 'tls://78.157.42.100',
  },
];

/// Bottom sheet for selecting a DNS server from presets or entering a custom one.
///
/// Displays DNS presets as RadioListTile items with the URL/IP
/// varying based on the active protocol (DoH/DoT/Plain).
/// The last option is "Custom..." which reveals a TextField.
class DnsPickerSheet extends StatefulWidget {
  /// Currently selected DNS value.
  final String currentDns;

  /// Active DNS protocol: 'doh', 'dot', or 'plain'.
  final String protocol;

  /// Callback invoked when a DNS value is selected.
  final ValueChanged<String> onSelected;

  const DnsPickerSheet({
    super.key,
    required this.currentDns,
    required this.protocol,
    required this.onSelected,
  });

  @override
  State<DnsPickerSheet> createState() => _DnsPickerSheetState();
}

class _DnsPickerSheetState extends State<DnsPickerSheet> {
  late String _selected;
  bool _isCustom = false;
  final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.currentDns;

    // Check if current DNS matches any preset
    final matchesPreset = dnsPresets.any(
      (p) => _dnsForProtocol(p) == widget.currentDns,
    );
    if (!matchesPreset) {
      _isCustom = true;
      _customController.text = widget.currentDns;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  /// Returns the DNS address for the given preset based on active protocol.
  String _dnsForProtocol(Map<String, String> preset) {
    return switch (widget.protocol) {
      'doh' => preset['doh']!,
      'dot' => preset['dot']!,
      _ => preset['ip']!,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.selectDnsServer,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),

            // Preset items + custom, wrapped in RadioGroup
            RadioGroup<String>(
              groupValue: _isCustom ? '__custom__' : _selected,
              onChanged: (value) {
                if (value == '__custom__') {
                  setState(() {
                    _isCustom = true;
                  });
                } else if (value != null) {
                  widget.onSelected(value);
                  Navigator.pop(context);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...dnsPresets.map((preset) {
                    final dnsValue = _dnsForProtocol(preset);
                    return RadioListTile<String>(
                      value: dnsValue,
                      title: Text(
                        preset['name']!,
                        style: theme.textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        dnsValue,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }),

                  // Custom option
                  RadioListTile<String>(
                    value: '__custom__',
                    title: Text(
                      l10n.customDns,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),

            // Custom input field — visible when custom is selected
            if (_isCustom)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customController,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          hintText: l10n.enterDnsAddress,
                          isDense: true,
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            widget.onSelected(value);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () {
                        final value = _customController.text.trim();
                        if (value.isNotEmpty) {
                          widget.onSelected(value);
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
