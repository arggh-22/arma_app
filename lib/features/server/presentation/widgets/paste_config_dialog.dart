import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arma_proxy_vpn_client/core/constants/app_constants.dart';
import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/share_link_parser.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/server_list_provider.dart';

/// Full-screen dialog for manually pasting a share link or raw JSON config.
///
/// Provides a multiline [TextField] for input, validates via
/// [ShareLinkParser.parse], checks for duplicates, and adds
/// the server to the list on success.
class PasteConfigDialog extends ConsumerStatefulWidget {
  const PasteConfigDialog({super.key});

  @override
  ConsumerState<PasteConfigDialog> createState() => _PasteConfigDialogState();
}

class _PasteConfigDialogState extends ConsumerState<PasteConfigDialog> {
  final _controller = TextEditingController();
  String? _errorText;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
        // Clear error when user starts typing again
        if (hasText && _errorText != null) {
          _errorText = null;
        }
      });
    }
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _controller.text.trim();

    if (text.isEmpty) {
      setState(() => _errorText = l10n.pasteConfigEmpty);
      return;
    }

    final config = ShareLinkParser.parse(text);
    if (config == null) {
      setState(() => _errorText = l10n.parseErrorInvalidLink);
      return;
    }

    // Check for duplicates by address + port + protocol
    final servers = await ref.read(serverListProvider.future);
    final isDuplicate = servers.any(
      (s) =>
          s.address == config.address &&
          s.port == config.port &&
          s.protocol == config.protocol,
    );

    if (isDuplicate) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.duplicateServer),
          duration: AppConstants.snackBarDurationDefault,
        ),
      );
      return;
    }

    await ref.read(serverListProvider.notifier).addServer(config);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${l10n.importSuccess} — ${config.name}'),
        duration: AppConstants.snackBarDurationDefault,
        backgroundColor: Colors.green.shade700,
        action: SnackBarAction(
          label: l10n.viewAction,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.pasteConfigTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          TextButton(
            onPressed: _hasText ? _import : null,
            child: Text(l10n.pasteConfigAction),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          maxLines: null,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.pasteConfigHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            errorText: _errorText,
          ),
        ),
      ),
    );
  }
}
