import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/core/utils/clipboard_helper.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/auth_state.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/repositories/auth_repository.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/telegram_link_outcome.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/auth_provider.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/telegram_link_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/telegram_link_step_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

typedef TelegramUrlLauncher = Future<bool> Function(Uri uri);
typedef ClipboardTextReader = Future<String?> Function();

const _telegramBotUri = 'https://t.me/devarmabot';
const _checkLinkStatusLabel = 'Check Link Status';
const _checkLinkStatusNotLinkedMessage = 'Telegram account is not linked yet.';

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
  final TextEditingController _telegramIdController = TextEditingController();
  bool _isCheckingStatus = false;

  @override
  void dispose() {
    _telegramIdController.dispose();
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

  Future<void> _pasteTelegramId() async {
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
    _telegramIdController.text = text;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(telegramLinkProvider.notifier);
    final outcome = await notifier.submit(_telegramIdController.text);
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text(_messageForOutcome(l10n, outcome))),
    );
    if (outcome.type == TelegramLinkOutcomeType.linked) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _checkLinkStatus() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isCheckingStatus = true);
    try {
      final refresh = ref.read(authStatusRefreshProvider);
      final AuthState refreshed = await refresh();
      if (!mounted) {
        return;
      }

      if (refreshed.isGuest) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_checkLinkStatusNotLinkedMessage)),
        );
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.telegramLinkSuccess)));
      Navigator.of(context).maybePop();
    } on AuthRepositoryException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.telegramLinkUnknownError)));
    } finally {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
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
    final isCheckDisabled = state.isSubmitting || _isCheckingStatus;

    return Scaffold(
      key: const Key('telegram-guide-screen'),
      appBar: AppBar(title: Text(l10n.telegramLinkScreenTitle)),
      body: SingleChildScrollView(
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
            const SizedBox(height: 12),
            TelegramLinkStepCard(
              stepNumber: 3,
              title: _checkLinkStatusLabel,
              body: _checkLinkStatusNotLinkedMessage,
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('telegram-check-status-button'),
              onPressed: isCheckDisabled ? null : _checkLinkStatus,
              child: _isCheckingStatus
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(_checkLinkStatusLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('telegram-id-input'),
              controller: _telegramIdController,
              keyboardType: TextInputType.number,
              enabled: !state.isSubmitting,
              decoration: InputDecoration(
                labelText: l10n.telegramLinkIdLabel,
                hintText: l10n.telegramLinkIdHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton(
                  key: const Key('telegram-paste-button'),
                  onPressed: state.isSubmitting ? null : _pasteTelegramId,
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
      ),
    );
  }
}
