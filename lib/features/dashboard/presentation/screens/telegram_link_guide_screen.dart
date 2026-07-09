import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/core/utils/clipboard_helper.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/telegram_link_outcome.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/telegram_link_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/telegram_link_step_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

typedef TelegramUrlLauncher = Future<bool> Function(Uri uri);
typedef ClipboardTextReader = Future<String?> Function();

/// Bot URL with ?start=link so the bot auto-generates and sends the 6-digit code.
const _telegramBotUri = 'https://t.me/devarmabot?start=link';

final telegramUrlLauncherProvider = Provider<TelegramUrlLauncher>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

final telegramClipboardReaderProvider = Provider<ClipboardTextReader>(
  (ref) => ClipboardHelper.getText,
);

class TelegramLinkGuideScreen extends ConsumerStatefulWidget {
  const TelegramLinkGuideScreen({super.key});

  @override
  ConsumerState<TelegramLinkGuideScreen> createState() =>
      _TelegramLinkGuideScreenState();
}

class _TelegramLinkGuideScreenState
    extends ConsumerState<TelegramLinkGuideScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _openTelegramBot() async {
    final l10n = AppLocalizations.of(context)!;
    final launch = ref.read(telegramUrlLauncherProvider);
    final opened = await launch(Uri.parse(_telegramBotUri));
    if (!mounted || opened) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.telegramLinkOpenBotFailed)));
  }

  Future<void> _pasteCode() async {
    final l10n = AppLocalizations.of(context)!;
    final readClipboard = ref.read(telegramClipboardReaderProvider);
    final text = await readClipboard();
    if (!mounted) {
      return;
    }
    if (text == null || text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.telegramLinkPasteEmpty)));
      return;
    }
    _codeController.text = text.trim();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(telegramLinkProvider.notifier);
    final outcome = await notifier.submit(_codeController.text);
    if (!mounted) {
      return;
    }

    // Success is shown inline — only show snackbar for errors
    if (outcome.type != TelegramLinkOutcomeType.linked &&
        outcome.type != TelegramLinkOutcomeType.alreadyLinked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageForOutcome(l10n, outcome))),
      );
    }
  }

  String _messageForOutcome(
    AppLocalizations l10n,
    TelegramLinkOutcome outcome,
  ) {
    return switch (outcome.type) {
      TelegramLinkOutcomeType.linked => l10n.telegramLinkSuccess,
      TelegramLinkOutcomeType.alreadyLinked => l10n.telegramLinkAlreadyLinked,
      TelegramLinkOutcomeType.invalidId => l10n.telegramLinkInvalidId,
      TelegramLinkOutcomeType.unauthorized => l10n.telegramLinkUnauthorized,
      TelegramLinkOutcomeType.network => l10n.telegramLinkNetworkError,
      TelegramLinkOutcomeType.server => l10n.telegramLinkServerError,
      TelegramLinkOutcomeType.unknown => l10n.telegramLinkUnknownError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(telegramLinkProvider);

    return Scaffold(
      key: const Key('telegram-guide-screen'),
      appBar: AppBar(title: Text(l10n.telegramLinkScreenTitle)),
      body: state.isLinked
          ? _buildSuccessView(context, l10n)
          : _buildLinkForm(context, l10n, state),
    );
  }

  Widget _buildSuccessView(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      key: const Key('telegram-linked-success-view'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.telegramLinkLinkedTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.telegramLinkLinkedBody,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('telegram-linked-done-button'),
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(l10n.telegramLinkDoneAction),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkForm(
    BuildContext context,
    AppLocalizations l10n,
    TelegramLinkState state,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            key: const Key('telegram-open-bot-button'),
            onPressed: _openTelegramBot,
            icon: const FaIcon(FontAwesomeIcons.telegram, size: 18),
            label: Text(l10n.telegramLinkOpenBot),
          ),
          const SizedBox(height: 16),
          TelegramLinkStepCard(
            stepNumber: 1,
            title: l10n.telegramLinkStepStartTitle,
            body: l10n.telegramLinkStepStartBody,
          ),
          const SizedBox(height: 12),
          TelegramLinkStepCard(
            stepNumber: 2,
            title: l10n.telegramLinkStepGetIdTitle,
            body: l10n.telegramLinkStepGetIdBody,
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('telegram-code-input'),
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            enabled: !state.isSubmitting,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
            decoration: InputDecoration(
              labelText: l10n.telegramLinkIdLabel,
              hintText: l10n.telegramLinkIdHint,
              border: const OutlineInputBorder(),
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                key: const Key('telegram-paste-button'),
                onPressed: state.isSubmitting ? null : _pasteCode,
                child: Text(l10n.telegramLinkPasteAction),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const Key('telegram-link-submit-button'),
                  onPressed: state.isSubmitting ? null : _submit,
                  child: state.isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.telegramLinkSubmitAction),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
