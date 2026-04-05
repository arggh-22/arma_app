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
}
