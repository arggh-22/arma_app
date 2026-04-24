// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Armenian (`hy`).
class AppLocalizationsHy extends AppLocalizations {
  AppLocalizationsHy([String locale = 'hy']) : super(locale);

  @override
  String get appName => 'Arma VPN';

  @override
  String get dashboard => 'Գլխավոր';

  @override
  String get servers => 'Սերվերներ';

  @override
  String get routing => 'Ուղղորդում';

  @override
  String get settings => 'Կարգավորումներ';

  @override
  String get importServer => 'Ներմուծել սերվեր';

  @override
  String get noServersYet => 'Սերվերներ դեռ չկան';

  @override
  String get noServersBody =>
      'Սկսելու համար ներմուծեք առաջին սերվերի կարգավորումը';

  @override
  String get importFromClipboard => 'Ներմուծել clipboard-ից';

  @override
  String get clipboard => 'Clipboard';

  @override
  String get pasteConfig => 'Տեղադրել կոնֆիգ';

  @override
  String get scanQr => 'Սքանավորել QR';

  @override
  String get parseErrorInvalidLink =>
      'Չհաջողվեց մշակել կոնֆիգը, ստուգեք հղման ձևաչափը';

  @override
  String get parseErrorUnsupported =>
      'Unsupported protocol — only VLESS, VMess, Trojan, Shadowsocks, and Hysteria2 links are supported';

  @override
  String get parseErrorEmptyClipboard => 'Clipboard-ը դատարկ է';

  @override
  String get importSuccess => 'Սերվերը հաջողությամբ ներմուծվեց';

  @override
  String get duplicateServer => 'Այս սերվերն արդեն ներմուծված է';

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
  String get deleteConfirm => 'Ջնջել';

  @override
  String get deleteCancel => 'Պահել';

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
  String get themeSystem => 'Համակարգ';

  @override
  String get themeLight => 'Բաց';

  @override
  String get themeDark => 'Մուգ';

  @override
  String get themeTitle => 'Թեմա';

  @override
  String get languageTitle => 'Լեզու';

  @override
  String get routingPlaceholder =>
      'Custom routing rules coming in a future update';

  @override
  String get bypassLan => 'Շրջանցել LAN-ը';

  @override
  String get bypassLanSubtitle =>
      'Don\'t route local network traffic (192.168.x.x, 10.x.x.x) through proxy';

  @override
  String get notConnected => 'Միացված չէ';

  @override
  String get noServerSelected => 'Սերվեր ընտրված չէ';

  @override
  String get generalSection => 'Ընդհանուր';

  @override
  String get aboutSection => 'Մասին';

  @override
  String get version => 'Տարբերակ';

  @override
  String get openSourceLicenses => 'Բաց կոդի լիցենզիաներ';

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
  String get retryAction => 'Կրկնել';

  @override
  String get connecting => 'Միացվում է';

  @override
  String get connected => 'Միացված է';

  @override
  String get addSubscription => 'Ավելացնել բաժանորդագրություն';

  @override
  String get noLogsYet => 'No logs yet';

  @override
  String get noLogsBody => 'Connect to a server to see logs';

  @override
  String get subscriptionFetchError => 'Չհաջողվեց ստանալ բաժանորդագրությունը';

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
  String get sortByDefault => 'Լռելյայն (բաժանորդագրության հերթականություն)';

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
  String get testAllServers => 'Ստուգել բոլորը';

  @override
  String get bestServer => 'Լավագույն սերվեր';

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
  String get shareLink => 'Կիսվել հղմամբ';

  @override
  String get exportLogs => 'Արտահանել լոգերը';

  @override
  String get viewLogs => 'Դիտել լոգերը';

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
  String get diagnosticsSection => 'Ախտորոշում';

  @override
  String get regionPresets => 'Տարածաշրջանային պրեսեթներ';

  @override
  String get domainRules => 'Դոմեյն կանոններ';

  @override
  String get perAppProxy => 'Per-app proxy';

  @override
  String get enablePerAppProxy => 'Միացնել per-app proxy';

  @override
  String get searchApps => 'Որոնել հավելվածներ…';

  @override
  String appsSelectedCount(int count) {
    return '$count apps selected';
  }

  @override
  String get blacklistMode => 'Սև ցուցակ';

  @override
  String get whitelistMode => 'Սպիտակ ցուցակ';

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
  String get addRule => 'Ավելացնել կանոն';

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
  String get updateRules => 'Թարմացնել կանոնները';

  @override
  String get rulesUpdated => 'Կանոնները թարմացվեցին';

  @override
  String get bundledRulesNote => 'Uses bundled rules. Tap ↓ to update.';

  @override
  String get regionIran => 'Իրան 🇮🇷';

  @override
  String get regionChina => 'Չինաստան 🇨🇳';

  @override
  String get regionRussia => 'Ռուսաստան 🇷🇺';

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
  String get engineSettingsSection => 'Շարժիչի կարգավորումներ';

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
  String get antiCensorshipSection => 'Հակացենզուրա';

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
  String get dataSection => 'Տվյալներ';

  @override
  String get clearCachedData => 'Մաքրել cache-ը';

  @override
  String get clearCacheSubtitle => 'Geo rules, subscription cache, logs';

  @override
  String get clearCacheTitle => 'Clear Cached Data?';

  @override
  String get clearCacheBody =>
      'This will clear:\n• Downloaded geo rule files\n• Subscription response cache\n• Log files\n\nServer configs and preferences will NOT be affected.';

  @override
  String get clearCacheConfirm => 'Մաքրել cache-ը';

  @override
  String get keepData => 'Պահել տվյալները';

  @override
  String get cachedDataCleared => 'Cache-ը մաքրվեց';

  @override
  String get couldntUpdateRules =>
      'Couldn\'t update rules. Check your connection and try again.';
}
