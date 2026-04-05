import 'package:flutter/material.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/routing/domain/entities/domain_rule.dart';

/// Dialog for adding a new custom domain routing rule.
///
/// Shows a TextField for the domain and a SegmentedButton for
/// choosing the action (proxy / direct / block).
/// Validates domain input: must not be empty, no spaces, must contain a dot.
/// Automatically strips http:// and https:// prefixes.
class AddDomainRuleDialog extends StatefulWidget {
  const AddDomainRuleDialog({super.key});

  @override
  State<AddDomainRuleDialog> createState() => _AddDomainRuleDialogState();
}

class _AddDomainRuleDialogState extends State<AddDomainRuleDialog> {
  final _controller = TextEditingController();
  String _action = 'proxy';
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isValidDomain(String s) {
    if (s.isEmpty || s.contains(' ')) return false;
    // Strip protocol prefix if user accidentally added it
    final cleaned = s.replaceAll(RegExp(r'^https?://'), '');
    return cleaned.isNotEmpty && cleaned.contains('.');
  }

  String _cleanDomain(String s) =>
      s.replaceAll(RegExp(r'^https?://'), '').trim();

  void _submit() {
    final domain = _cleanDomain(_controller.text);
    if (!_isValidDomain(domain)) {
      setState(() => _error = AppLocalizations.of(context)!.invalidDomain);
      return;
    }
    Navigator.pop(context, DomainRule(domain: domain, action: _action));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.addDomainRule),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: l10n.domainHint,
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'proxy', label: Text(l10n.proxy)),
              ButtonSegment(value: 'direct', label: Text(l10n.direct)),
              ButtonSegment(value: 'block', label: Text(l10n.block)),
            ],
            selected: {_action},
            onSelectionChanged: (v) => setState(() => _action = v.first),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.discardRule),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.addRule)),
      ],
    );
  }
}
