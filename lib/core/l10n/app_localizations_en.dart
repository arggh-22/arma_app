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
}
