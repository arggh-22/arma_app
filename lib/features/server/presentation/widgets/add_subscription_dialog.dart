import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/subscription_provider.dart';

/// Dialog for adding a new subscription (UI-SPEC §9).
///
/// Contains:
/// - URL field (required, autofocus, TextInputType.url)
/// - Name field (optional)
/// - User-Agent field (optional, helper text)
/// - Auto-update toggle (default: true)
/// - Dismiss / Add buttons with loading state
///
/// Calls [SubscriptionNotifier.addSubscription] on submit.
class AddSubscriptionDialog extends ConsumerStatefulWidget {
  /// Optional pre-filled URL (e.g., from QR scanner).
  final String? initialUrl;

  const AddSubscriptionDialog({super.key, this.initialUrl});

  /// Shows the dialog as a modal AlertDialog.
  static Future<void> show(BuildContext context, {String? initialUrl}) {
    return showDialog(
      context: context,
      builder: (_) => AddSubscriptionDialog(initialUrl: initialUrl),
    );
  }

  @override
  ConsumerState<AddSubscriptionDialog> createState() =>
      _AddSubscriptionDialogState();
}

class _AddSubscriptionDialogState extends ConsumerState<AddSubscriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  late final TextEditingController _nameController;
  late final TextEditingController _uaController;
  bool _autoUpdate = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
    _nameController = TextEditingController();
    _uaController = TextEditingController(text: 'arma');
  }

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    _uaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.addSubscription),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // URL field
              TextFormField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                autofocus: widget.initialUrl == null,
                decoration: InputDecoration(
                  labelText: l10n.subscriptionUrl,
                  errorText: _errorMessage,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.subscriptionUrl;
                  }
                  final uri = Uri.tryParse(value.trim());
                  if (uri == null ||
                      (uri.scheme != 'http' && uri.scheme != 'https') ||
                      uri.host.isEmpty) {
                    return l10n.subscriptionFetchError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.subscriptionName,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // User-Agent field
              TextFormField(
                controller: _uaController,
                decoration: InputDecoration(
                  labelText: 'User-Agent',
                  helperText: l10n.userAgentHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),

              // Auto-update toggle
              CheckboxListTile(
                value: _autoUpdate,
                onChanged: (value) {
                  setState(() => _autoUpdate = value ?? true);
                },
                title: Text(l10n.autoUpdateOnLaunch),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Dismiss
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.dismissDialog),
        ),

        // Add
        FilledButton(
          onPressed: _isLoading ? null : _onAdd,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.addSubscription),
        ),
      ],
    );
  }

  Future<void> _onAdd() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final count = await ref
          .read(subscriptionProvider.notifier)
          .addSubscription(
            url: _urlController.text.trim(),
            name: _nameController.text.trim(),
            userAgent: _uaController.text.trim(),
            autoUpdate: _autoUpdate,
          );

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.importedServersCount(count))));
    } catch (e) {
      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isLoading = false;
        _errorMessage = l10n.subscriptionFetchError;
      });
    }
  }
}
