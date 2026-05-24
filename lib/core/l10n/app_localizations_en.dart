// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Arma VPN';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get servers => 'Servers';

  @override
  String get routing => 'Routing';

  @override
  String get settings => 'Settings';

  @override
  String get importServer => 'Import Server';

  @override
  String get noServersYet => 'No servers yet';

  @override
  String get noServersBody => 'Import your first server config to get started';

  @override
  String get importFromClipboard => 'Import from Clipboard';

  @override
  String get clipboard => 'Clipboard';

  @override
  String get pasteConfig => 'Paste Config';

  @override
  String get scanQr => 'Scan QR';

  @override
  String get parseErrorInvalidLink =>
      'Couldn\'t parse config — check the link format and try again';

  @override
  String get parseErrorUnsupported =>
      'Unsupported protocol — only VLESS, VMess, Trojan, Shadowsocks, and Hysteria2 links are supported';

  @override
  String get parseErrorEmptyClipboard =>
      'Nothing on clipboard — copy a server config link first';

  @override
  String get importSuccess => 'Server imported successfully';

  @override
  String get duplicateServer => 'This server is already imported';

  @override
  String get disabledConnect => 'Connection available in next update';

  @override
  String get disabledQrScan => 'QR scanning coming soon';

  @override
  String get deleteServerTitle => 'Delete server?';

  @override
  String deleteServerBody(String serverName) {
    return 'This will permanently remove $serverName.';
  }

  @override
  String get deleteConfirm => 'Delete';

  @override
  String get deleteCancel => 'Keep Server';

  @override
  String get pasteConfigTitle => 'Paste Config';

  @override
  String get pasteConfigHint =>
      'Paste a share link (vless://, vmess://, etc.) or raw JSON config';

  @override
  String get pasteConfigAction => 'Import Config';

  @override
  String get pasteConfigEmpty => 'Paste a config to continue';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeTitle => 'Theme';

  @override
  String get languageTitle => 'Language';

  @override
  String get connectionDisplaySection => 'Connection Display';

  @override
  String get detailedNotification => 'Detailed VPN Notification';

  @override
  String get detailedNotificationSubtitle =>
      'Show server name and live traffic stats in the Android VPN notification';

  @override
  String get dashboardStatistics => 'Dashboard Statistics';

  @override
  String get dashboardStatisticsSubtitle =>
      'Show live upload/download statistics card on Dashboard';

  @override
  String get routingPlaceholder =>
      'Custom routing rules coming in a future update';

  @override
  String get bypassLan => 'Bypass LAN';

  @override
  String get bypassLanSubtitle =>
      'Don\'t route local network traffic (192.168.x.x, 10.x.x.x) through proxy';

  @override
  String get notConnected => 'Not Connected';

  @override
  String get noServerSelected => 'No server selected';

  @override
  String get generalSection => 'General';

  @override
  String get aboutSection => 'About';

  @override
  String get version => 'Version';

  @override
  String get openSourceLicenses => 'Open Source Licenses';

  @override
  String languageChanged(String language) {
    return 'Language changed to $language';
  }

  @override
  String downloadSpeed(String speed) {
    return '↓ $speed';
  }

  @override
  String uploadSpeed(String speed) {
    return '↑ $speed';
  }

  @override
  String get viewAction => 'View';

  @override
  String get retryAction => 'Retry';

  @override
  String get connecting => 'Connecting';

  @override
  String get connected => 'Connected';

  @override
  String get addSubscription => 'Add Subscription';

  @override
  String get noLogsYet => 'No logs yet';

  @override
  String get noLogsBody => 'Connect to a server to see logs';

  @override
  String get subscriptionFetchError =>
      'Failed to fetch subscription. Check the URL and try again.';

  @override
  String get latencyTestFailed => 'Couldn\'t reach server';

  @override
  String get qrUnrecognized => 'Couldn\'t recognize this QR code';

  @override
  String get cameraPermissionDenied =>
      'Camera permission required to scan QR codes. Enable in Settings.';

  @override
  String deleteServersTitle(int count) {
    return 'Delete $count servers?';
  }

  @override
  String get deleteServersBody =>
      'This will permanently remove the selected servers. Servers from subscriptions will reappear on next refresh.';

  @override
  String deleteServersConfirm(int count) {
    return 'Delete $count';
  }

  @override
  String get keepServers => 'Keep Servers';

  @override
  String subscriptionRefreshSuccess(int count) {
    return 'Updated $count subscriptions';
  }

  @override
  String get subscriptionRefreshNoChange => 'All up to date';

  @override
  String subscriptionRefreshFail(String name) {
    return 'Failed to update $name. Check your connection.';
  }

  @override
  String get qrSubscriptionPrompt =>
      'This looks like a subscription URL. Add as subscription?';

  @override
  String get notNow => 'Not Now';

  @override
  String get dismissDialog => 'Dismiss';

  @override
  String get sortBy => 'Sort';

  @override
  String get sortByDefault => 'Default';

  @override
  String get sortByName => 'Name';

  @override
  String get sortByLatency => 'Latency';

  @override
  String get sortByProtocol => 'Protocol';

  @override
  String get filterAll => 'All';

  @override
  String get filterWorking => 'Working';

  @override
  String get filterFailed => 'Failed';

  @override
  String get testAllServers => 'Test All';

  @override
  String get bestServer => 'Best Server';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get selectAll => 'Select All';

  @override
  String get scanQrTitle => 'Scan QR Code';

  @override
  String get scanQrInstruction => 'Point camera at a QR code';

  @override
  String get shareServer => 'Share Server';

  @override
  String get copyLink => 'Copy Link';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get shareLink => 'Share Link';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get viewLogs => 'View Logs';

  @override
  String get autoScroll => 'Auto-scroll';

  @override
  String linesCount(int count) {
    return '$count lines';
  }

  @override
  String get autoUpdateOnLaunch => 'Auto-update on app launch';

  @override
  String get userAgentHint => 'Leave empty for default browser UA';

  @override
  String get subscriptionUrl => 'URL';

  @override
  String get subscriptionName => 'Name';

  @override
  String subscriptionInfoFormat(int count) {
    return '$count servers';
  }

  @override
  String importedServersCount(int count) {
    return 'Imported $count servers';
  }

  @override
  String get logFilterAll => 'All';

  @override
  String get logFilterInfo => 'Info';

  @override
  String get logFilterWarning => 'Warning';

  @override
  String get logFilterError => 'Error';

  @override
  String get diagnosticsSection => 'Diagnostics';

  @override
  String get regionPresets => 'Region Presets';

  @override
  String get domainRules => 'Domain Rules';

  @override
  String get perAppProxy => 'Per-App Proxy';

  @override
  String get enablePerAppProxy => 'Enable Per-App Proxy';

  @override
  String get searchApps => 'Search apps…';

  @override
  String appsSelectedCount(int count) {
    return '$count apps selected';
  }

  @override
  String get blacklistMode => 'Blacklist';

  @override
  String get whitelistMode => 'Whitelist';

  @override
  String get blacklistDescription =>
      'All apps route through VPN except selected';

  @override
  String get whitelistDescription => 'Only selected apps route through VPN';

  @override
  String switchedToMode(String mode) {
    return 'Switched to $mode mode';
  }

  @override
  String get loadingApps => 'Loading installed apps…';

  @override
  String get noAppsSelected =>
      'No apps selected — check apps to include or exclude them';

  @override
  String get addRule => 'Add Rule';

  @override
  String get addDomainRule => 'Add Domain Rule';

  @override
  String get discardRule => 'Discard';

  @override
  String get domainHint => 'example.com';

  @override
  String get invalidDomain => 'Enter a valid domain (e.g., example.com)';

  @override
  String get ruleRemoved => 'Rule removed';

  @override
  String get undo => 'Undo';

  @override
  String get noRulesYet => 'No custom rules yet — tap Add Rule to get started';

  @override
  String get proxy => 'Proxy';

  @override
  String get direct => 'Direct';

  @override
  String get block => 'Block';

  @override
  String get updateRules => 'Update Rules';

  @override
  String get rulesUpdated => 'Rules updated';

  @override
  String get bundledRulesNote => 'Uses bundled rules. Tap ↓ to update.';

  @override
  String get regionIran => 'Iran 🇮🇷';

  @override
  String get regionChina => 'China 🇨🇳';

  @override
  String get regionRussia => 'Russia 🇷🇺';

  @override
  String get dnsSection => 'DNS';

  @override
  String get dnsProtocol => 'DNS Protocol';

  @override
  String get remoteDns => 'Remote DNS';

  @override
  String get directDns => 'Direct DNS';

  @override
  String get selectDnsServer => 'Select DNS Server';

  @override
  String get customDns => 'Custom...';

  @override
  String get enterDnsAddress => 'Enter DNS address';

  @override
  String get dnsUpdated => 'DNS updated';

  @override
  String get engineSettingsSection => 'Engine Settings';

  @override
  String get sniffing => 'Sniffing';

  @override
  String get sniffingSubtitle => 'Detect protocol type from traffic content';

  @override
  String get mux => 'Mux (Multiplexing)';

  @override
  String get muxSubtitle => 'Combine multiple connections into one';

  @override
  String get concurrency => 'Concurrency';

  @override
  String get antiCensorshipSection => 'Anti-Censorship';

  @override
  String get profile => 'Profile';

  @override
  String get profileNone => 'None';

  @override
  String get profileLight => 'Light';

  @override
  String get profileModerate => 'Moderate';

  @override
  String get profileAggressive => 'Aggressive';

  @override
  String get profileLightDesc => 'Minimal fragmentation for light filtering';

  @override
  String get profileModerateDesc => 'Fragment + padding for moderate DPI';

  @override
  String get profileAggressiveDesc =>
      'Full fragmentation + sleep + mixed SNI for heavy DPI';

  @override
  String get fragment => 'Fragment';

  @override
  String get fragmentSubtitle => 'Split TLS ClientHello into fragments';

  @override
  String get fragmentSize => 'Fragment Size';

  @override
  String get sleepMs => 'Sleep (ms)';

  @override
  String get padding => 'Padding';

  @override
  String get paddingSubtitle => 'Add padding to TLS records';

  @override
  String get mixedSniCase => 'Mixed SNI Case';

  @override
  String get mixedSniSubtitle => 'Randomize letter case in SNI field';

  @override
  String get dataSection => 'Data';

  @override
  String get clearCachedData => 'Clear Cached Data';

  @override
  String get clearCacheSubtitle => 'Geo rules, subscription cache, logs';

  @override
  String get clearCacheTitle => 'Clear Cached Data?';

  @override
  String get clearCacheBody =>
      'This will clear:\n• Downloaded geo rule files\n• Subscription response cache\n• Log files\n\nServer configs and preferences will NOT be affected.';

  @override
  String get clearCacheConfirm => 'Clear Cache';

  @override
  String get keepData => 'Keep Data';

  @override
  String get cachedDataCleared => 'Cached data cleared';

  @override
  String get couldntUpdateRules =>
      'Couldn\'t update rules. Check your connection and try again.';

  @override
  String get armaVpnSettingsSection => 'Arma VPN settings';

  @override
  String get defaultServerAutoUpdateLabel =>
      'Default server auto-update interval';

  @override
  String get defaultServerAutoUpdateDisabled => 'Disabled';

  @override
  String get defaultServerAutoUpdateEvery12Hours => 'Every 12 Hours';

  @override
  String get defaultServerAutoUpdateEvery24Hours => 'Every 24 Hours';

  @override
  String get defaultServerAutoUpdateEvery7Days => 'Every 7 Days';

  @override
  String get defaultServerAutoUpdateUpdatedIndicatorLabel =>
      'Updated after a missed refresh';

  @override
  String defaultServerAutoUpdateUpdatedIndicatorTimestamp(Object timestamp) {
    return 'Updated $timestamp';
  }

  @override
  String get defaultServersTitle => 'Default servers';

  @override
  String get defaultServersShowAll => 'Show all servers';

  @override
  String get defaultServersRefreshSemantics => 'Refresh default servers';

  @override
  String get defaultServersOfflineData => 'Offline data';

  @override
  String get defaultServersEmptyTitle => 'No default servers available';

  @override
  String get defaultServersEmptyBody => 'Pull latest servers with Refresh.';

  @override
  String get defaultServersNoCacheOfflineBody =>
      'No connection and no cached servers yet. Tap Refresh when online.';

  @override
  String get defaultServersTimeoutError =>
      'Request timed out. Tap Refresh to try again.';

  @override
  String get defaultServersOfflineError =>
      'You’re offline. Showing offline data.';

  @override
  String get defaultServersUnauthorizedError =>
      'Session expired. Please retry authentication.';

  @override
  String get defaultServersServerError =>
      'Server error. Please try again shortly.';

  @override
  String get defaultServersClientError => 'Request failed. Please try again.';

  @override
  String get defaultServersMalformedError =>
      'Server response was invalid. Please refresh again.';

  @override
  String get defaultServersStatusActive => 'Active';

  @override
  String get defaultServersStatusExpired => 'Expired';

  @override
  String get defaultServersStatusLimited => 'Limited';

  @override
  String get defaultServersStatusUnknown => 'Unknown';

  @override
  String get telegramLinkFabLabel => 'Link';

  @override
  String get telegramLinkScreenTitle => 'Link Telegram';

  @override
  String get telegramLinkOpenBot => 'Open Telegram Bot';

  @override
  String get telegramLinkStepStartTitle => 'Tap Start in Telegram bot';

  @override
  String get telegramLinkStepStartBody => 'Open @devarmabot and tap Start.';

  @override
  String get telegramLinkStepGetIdTitle => 'Get your Telegram ID';

  @override
  String get telegramLinkStepGetIdBody =>
      'In bot menu commands tap Get Telegram ID, or send /my_id.';

  @override
  String get telegramLinkIdLabel => 'Telegram ID';

  @override
  String get telegramLinkIdHint => 'Paste numeric Telegram ID';

  @override
  String get telegramLinkPasteAction => 'Paste';

  @override
  String get telegramLinkSubmitAction => 'Link';

  @override
  String get telegramLinkOpenBotFailed =>
      'Couldn’t open Telegram bot. Try again.';

  @override
  String get telegramLinkPasteEmpty => 'Clipboard is empty.';

  @override
  String get telegramLinkSuccess => 'Telegram account linked successfully.';

  @override
  String get telegramLinkAlreadyLinked =>
      'This Telegram account is already linked.';

  @override
  String get telegramLinkInvalidId =>
      'Telegram ID is invalid. Use 5–20 digits.';

  @override
  String get telegramLinkUnauthorized =>
      'Session expired. Please sign in again, then retry linking.';

  @override
  String get telegramLinkNetworkError =>
      'No network connection. Reconnect and try again.';

  @override
  String get telegramLinkServerError =>
      'Server error. Please try again shortly.';

  @override
  String get telegramLinkUnknownError => 'Unexpected error. Please try again.';
}
