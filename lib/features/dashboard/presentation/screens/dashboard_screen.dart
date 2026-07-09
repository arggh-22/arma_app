import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/auth_provider.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/widgets/connection_timer.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/widgets/traffic_stats_card.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/active_server_card.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/connect_button.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/widgets/default_servers_section.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/ui_preferences_provider.dart';

typedef DashboardTelegramLauncher = Future<bool> Function(Uri uri);

const _dashboardTelegramBotUri = 'https://t.me/devarmabot';

final dashboardTelegramLauncherProvider = Provider<DashboardTelegramLauncher>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// Dashboard screen — home screen of the app.
///
/// Shows the animated connect button, connection status text,
/// elapsed timer, active server card, and real-time traffic stats.
/// All widgets are wired to live Riverpod providers from Plan 02-04.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showLinkFab = true;

  bool _onScroll(UserScrollNotification notification) {
    switch (notification.direction) {
      case ScrollDirection.reverse:
        if (_showLinkFab) {
          setState(() => _showLinkFab = false);
        }
      case ScrollDirection.forward:
        if (!_showLinkFab) {
          setState(() => _showLinkFab = true);
        }
      case ScrollDirection.idle:
        break;
    }
    return false;
  }

  Future<void> _openTelegramBot() async {
    final l10n = AppLocalizations.of(context)!;
    final launch = ref.read(dashboardTelegramLauncherProvider);
    final opened = await launch(Uri.parse(_dashboardTelegramBotUri));
    if (!mounted || opened) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.telegramLinkOpenBotFailed)));
  }

  void _openAnnouncementSheet(String text) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            key: const Key('dashboard-announcement-sheet'),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dashboardAnnouncementTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Gap(12),
                Text(text),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uiPreferences = ref.watch(uiPreferencesProvider);
    final authState = ref.watch(authStateProvider).asData?.value;
    final isGuest = authState?.isGuest ?? true;
    final announcementTitle = authState?.announcementTitle?.trim();
    final announcementText = authState?.announcementText?.trim();
    final hasAnnouncementTitle =
        announcementTitle != null && announcementTitle.isNotEmpty;
    final hasAnnouncementText =
        announcementText != null && announcementText.isNotEmpty;
    final hasAnnouncement = hasAnnouncementTitle || hasAnnouncementText;

    final colorScheme = Theme.of(context).colorScheme;
    // Failed connects (permission denied, unreachable server, native error)
    // must stay visible — the connect button alone just flips back to
    // DISCONNECTED with no explanation.
    final connectionError = switch (ref.watch(connectionProvider)) {
      Disconnected(:final lastError) => lastError,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shield, color: colorScheme.primary, size: 24),
            const Gap(8),
            Text(l10n.appName),
          ],
        ),
      ),
      body: _isDesktopUi
          ? _buildDesktopBody(context)
          : NotificationListener<UserScrollNotification>(
              onNotification: _onScroll,
              child: RefreshIndicator(
                // Pull-to-refresh re-fetches the API subscriptions/servers.
                onRefresh: () =>
                    ref.read(defaultServersProvider.notifier).refresh(),
                child: SingleChildScrollView(
                  // AlwaysScrollable so the pull gesture works even when the
                  // content doesn't fill the viewport.
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  child: Column(
                    children: [
                      Container(
                        key: const Key('dashboard-top-visual-group'),
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 180),
                        child: Column(
                          children: [
                            const Gap(4),
                            const ConnectButton(),
                            if (connectionError != null) ...[
                              const Gap(12),
                              Text(
                                connectionError,
                                key: const Key('dashboard-connection-error'),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: colorScheme.error),
                              ),
                            ],
                            const Gap(20),
                            // Statistics flank the running time: ↑ upload · timer ·
                            // download ↓. When stats are disabled, show the timer alone.
                            if (uiPreferences.showDashboardStatistics)
                              const TrafficStatsCard(middle: ConnectionTimer())
                            else
                              const ConnectionTimer(),
                            const Gap(24),
                            const ActiveServerCard(),
                          ],
                        ),
                      ),
                      const Gap(24),
                      SizedBox(
                        key: const Key('dashboard-bottom-visual-group'),
                        width: double.infinity,
                        child: Column(
                          children: [
                            if (hasAnnouncement) ...[
                              Card(
                                key: const Key('dashboard-announcement-card'),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    8,
                                    8,
                                    4,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (hasAnnouncementTitle)
                                        Text(
                                          announcementTitle,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      if (hasAnnouncementTitle &&
                                          hasAnnouncementText)
                                        const Gap(2),
                                      if (hasAnnouncementText)
                                        Text(
                                          announcementText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      if (hasAnnouncementText)
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            key: const Key(
                                              'dashboard-announcement-read-more',
                                            ),
                                            onPressed: () =>
                                                _openAnnouncementSheet(
                                                  announcementText,
                                                ),
                                            style: TextButton.styleFrom(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              minimumSize: const Size(0, 28),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Text(
                                              l10n.dashboardAnnouncementReadMore,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const Gap(12),
                            ],
                            const DefaultServersSection(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      // Lift the FAB clear of the floating pill nav.
      floatingActionButton: _showLinkFab
          ? Padding(
              padding: const EdgeInsets.only(bottom: 84),
              child: isGuest
                  ? FloatingActionButton.extended(
                      key: const Key('dashboard-telegram-link-fab'),
                      heroTag: 'dashboard-telegram-link-fab',
                      onPressed: () => context.push('/telegram-link'),
                      icon: const FaIcon(FontAwesomeIcons.telegram, size: 18),
                      label: Text(l10n.telegramLinkFabLabel),
                    )
                  : FloatingActionButton(
                      key: const Key('dashboard-telegram-bot-fab'),
                      heroTag: 'dashboard-telegram-bot-fab',
                      tooltip: l10n.dashboardTelegramFabLabel,
                      onPressed: _openTelegramBot,
                      child: const FaIcon(FontAwesomeIcons.telegram, size: 20),
                    ),
            )
          : null,
    );
  }

  /// Desktop uses a two-pane home; mobile keeps the single scroll column.
  bool get _isDesktopUi {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  // ── Desktop home: connect "hero" on the left, servers on the right ────────
  Widget _buildDesktopBody(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final uiPreferences = ref.watch(uiPreferencesProvider);
    final authState = ref.watch(authStateProvider).asData?.value;
    final announcementTitle = authState?.announcementTitle?.trim();
    final announcementText = authState?.announcementText?.trim();
    final hasTitle = announcementTitle != null && announcementTitle.isNotEmpty;
    final hasText = announcementText != null && announcementText.isNotEmpty;
    final connectionError = switch (ref.watch(connectionProvider)) {
      Disconnected(:final lastError) => lastError,
      _ => null,
    };

    final hero = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ConnectButton(),
        if (connectionError != null) ...[
          const Gap(12),
          Text(
            connectionError,
            key: const Key('dashboard-connection-error'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ],
        const Gap(24),
        if (uiPreferences.showDashboardStatistics)
          const TrafficStatsCard(middle: ConnectionTimer())
        else
          const ConnectionTimer(),
        const Gap(28),
        const ActiveServerCard(),
      ],
    );

    return Padding(
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: a full-height connection panel (subtle surface). Centering
          // the hero on the panel lets the connect button's soft glow blend
          // into the surface instead of spilling past a card border.
          Container(
            width: 400,
            color: colorScheme.surfaceContainerLow,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: hero,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          // Right: announcement + the servers list, scrollable.
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(defaultServersProvider.notifier).refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasTitle || hasText) ...[
                      _DesktopAnnouncementCard(
                        title: hasTitle ? announcementTitle : null,
                        text: hasText ? announcementText : null,
                        onReadMore: hasText
                            ? () => _openAnnouncementSheet(announcementText)
                            : null,
                        readMoreLabel: l10n.dashboardAnnouncementReadMore,
                      ),
                      const Gap(12),
                    ],
                    const DefaultServersSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Announcement banner for the desktop home's right pane.
class _DesktopAnnouncementCard extends StatelessWidget {
  const _DesktopAnnouncementCard({
    required this.title,
    required this.text,
    required this.onReadMore,
    required this.readMoreLabel,
  });

  final String? title;
  final String? text;
  final VoidCallback? onReadMore;
  final String readMoreLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const Key('dashboard-announcement-card'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Text(
                title!,
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (title != null && text != null) const Gap(4),
            if (text != null)
              Text(
                text!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            if (onReadMore != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onReadMore,
                  child: Text(readMoreLabel),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
