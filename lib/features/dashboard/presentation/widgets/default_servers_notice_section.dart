import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/core/utils/link_launcher.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';

/// Renders subscription-wide notices from the JSON subscription headers
/// (spec §2): the `announce` banner plus `support-url` / `profile-web-page-url`
/// action buttons. Renders nothing when none are present.
class DefaultServersNoticeSection extends ConsumerStatefulWidget {
  const DefaultServersNoticeSection({super.key});

  @override
  ConsumerState<DefaultServersNoticeSection> createState() =>
      _DefaultServersNoticeSectionState();
}

class _DefaultServersNoticeSectionState
    extends ConsumerState<DefaultServersNoticeSection> {
  /// Announcement text the user has dismissed this session.
  String? _dismissedAnnouncement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final announcement = ref.watch(
      defaultServersProvider.select((s) => s.announcement),
    );
    final supportUrl = ref.watch(
      defaultServersProvider.select((s) => s.supportUrl),
    );
    final webPageUrl = ref.watch(
      defaultServersProvider.select((s) => s.webPageUrl),
    );

    final showAnnouncement =
        announcement != null &&
        announcement.isNotEmpty &&
        announcement != _dismissedAnnouncement;
    final hasLinks =
        (supportUrl != null && supportUrl.isNotEmpty) ||
        (webPageUrl != null && webPageUrl.isNotEmpty);

    if (!showAnnouncement && !hasLinks) {
      return const SizedBox.shrink();
    }

    return Column(
      key: const Key('default-servers-notice-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showAnnouncement) ...[
          _AnnouncementBanner(
            title: l10n.dashboardAnnouncementTitle,
            text: announcement,
            dismissLabel: l10n.dismissDialog,
            onDismiss: () =>
                setState(() => _dismissedAnnouncement = announcement),
          ),
          if (hasLinks) const Gap(12),
        ],
        if (hasLinks)
          _LinkActions(
            supportUrl: supportUrl,
            webPageUrl: webPageUrl,
            onOpen: _open,
          ),
        const Gap(16),
      ],
    );
  }

  Future<void> _open(String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final launch = ref.read(linkLauncherProvider);
    final opened = await launch(uri);
    if (!mounted || opened) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not open link')),
    );
  }
}

class _AnnouncementBanner extends StatelessWidget {
  const _AnnouncementBanner({
    required this.title,
    required this.text,
    required this.dismissLabel,
    required this.onDismiss,
  });

  final String title;
  final String text;
  final String dismissLabel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      key: const Key('default-servers-announcement'),
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 18,
                  color: colorScheme.onSecondaryContainer,
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(4),
            Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('default-servers-announcement-dismiss'),
                onPressed: onDismiss,
                child: Text(dismissLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkActions extends StatelessWidget {
  const _LinkActions({
    required this.supportUrl,
    required this.webPageUrl,
    required this.onOpen,
  });

  final String? supportUrl;
  final String? webPageUrl;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final hasSupport = supportUrl != null && supportUrl!.isNotEmpty;
    final hasWeb = webPageUrl != null && webPageUrl!.isNotEmpty;

    return Row(
      children: [
        if (hasWeb)
          Expanded(
            child: FilledButton.tonalIcon(
              key: const Key('default-servers-renew'),
              onPressed: () => onOpen(webPageUrl!),
              icon: const Icon(Icons.card_membership_outlined, size: 18),
              label: const Text('Renew subscription'),
            ),
          ),
        if (hasWeb && hasSupport) const Gap(12),
        if (hasSupport)
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('default-servers-support'),
              onPressed: () => onOpen(supportUrl!),
              icon: const Icon(Icons.support_agent_outlined, size: 18),
              label: const Text('Support'),
            ),
          ),
      ],
    );
  }
}
