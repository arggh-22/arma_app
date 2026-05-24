import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_hy.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
    Locale('hy'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Arma VPN'**
  String get appName;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @servers.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get servers;

  /// No description provided for @routing.
  ///
  /// In en, this message translates to:
  /// **'Routing'**
  String get routing;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @importServer.
  ///
  /// In en, this message translates to:
  /// **'Import Server'**
  String get importServer;

  /// No description provided for @noServersYet.
  ///
  /// In en, this message translates to:
  /// **'No servers yet'**
  String get noServersYet;

  /// No description provided for @noServersBody.
  ///
  /// In en, this message translates to:
  /// **'Import your first server config to get started'**
  String get noServersBody;

  /// No description provided for @importFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Import from Clipboard'**
  String get importFromClipboard;

  /// No description provided for @clipboard.
  ///
  /// In en, this message translates to:
  /// **'Clipboard'**
  String get clipboard;

  /// No description provided for @pasteConfig.
  ///
  /// In en, this message translates to:
  /// **'Paste Config'**
  String get pasteConfig;

  /// No description provided for @scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQr;

  /// No description provided for @parseErrorInvalidLink.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t parse config — check the link format and try again'**
  String get parseErrorInvalidLink;

  /// No description provided for @parseErrorUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Unsupported protocol — only VLESS, VMess, Trojan, Shadowsocks, and Hysteria2 links are supported'**
  String get parseErrorUnsupported;

  /// No description provided for @parseErrorEmptyClipboard.
  ///
  /// In en, this message translates to:
  /// **'Nothing on clipboard — copy a server config link first'**
  String get parseErrorEmptyClipboard;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Server imported successfully'**
  String get importSuccess;

  /// No description provided for @duplicateServer.
  ///
  /// In en, this message translates to:
  /// **'This server is already imported'**
  String get duplicateServer;

  /// No description provided for @disabledConnect.
  ///
  /// In en, this message translates to:
  /// **'Connection available in next update'**
  String get disabledConnect;

  /// No description provided for @disabledQrScan.
  ///
  /// In en, this message translates to:
  /// **'QR scanning coming soon'**
  String get disabledQrScan;

  /// No description provided for @deleteServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete server?'**
  String get deleteServerTitle;

  /// No description provided for @deleteServerBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove {serverName}.'**
  String deleteServerBody(String serverName);

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteConfirm;

  /// No description provided for @deleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Keep Server'**
  String get deleteCancel;

  /// No description provided for @pasteConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Paste Config'**
  String get pasteConfigTitle;

  /// No description provided for @pasteConfigHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a share link (vless://, vmess://, etc.) or raw JSON config'**
  String get pasteConfigHint;

  /// No description provided for @pasteConfigAction.
  ///
  /// In en, this message translates to:
  /// **'Import Config'**
  String get pasteConfigAction;

  /// No description provided for @pasteConfigEmpty.
  ///
  /// In en, this message translates to:
  /// **'Paste a config to continue'**
  String get pasteConfigEmpty;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @connectionDisplaySection.
  ///
  /// In en, this message translates to:
  /// **'Connection Display'**
  String get connectionDisplaySection;

  /// No description provided for @detailedNotification.
  ///
  /// In en, this message translates to:
  /// **'Detailed VPN Notification'**
  String get detailedNotification;

  /// No description provided for @detailedNotificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show server name and live traffic stats in the Android VPN notification'**
  String get detailedNotificationSubtitle;

  /// No description provided for @dashboardStatistics.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Statistics'**
  String get dashboardStatistics;

  /// No description provided for @dashboardStatisticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show live upload/download statistics card on Dashboard'**
  String get dashboardStatisticsSubtitle;

  /// No description provided for @routingPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Custom routing rules coming in a future update'**
  String get routingPlaceholder;

  /// No description provided for @bypassLan.
  ///
  /// In en, this message translates to:
  /// **'Bypass LAN'**
  String get bypassLan;

  /// No description provided for @bypassLanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t route local network traffic (192.168.x.x, 10.x.x.x) through proxy'**
  String get bypassLanSubtitle;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not Connected'**
  String get notConnected;

  /// No description provided for @noServerSelected.
  ///
  /// In en, this message translates to:
  /// **'No server selected'**
  String get noServerSelected;

  /// No description provided for @generalSection.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalSection;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get openSourceLicenses;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {language}'**
  String languageChanged(String language);

  /// No description provided for @downloadSpeed.
  ///
  /// In en, this message translates to:
  /// **'↓ {speed}'**
  String downloadSpeed(String speed);

  /// No description provided for @uploadSpeed.
  ///
  /// In en, this message translates to:
  /// **'↑ {speed}'**
  String uploadSpeed(String speed);

  /// No description provided for @viewAction.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewAction;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connecting;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @addSubscription.
  ///
  /// In en, this message translates to:
  /// **'Add Subscription'**
  String get addSubscription;

  /// No description provided for @noLogsYet.
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get noLogsYet;

  /// No description provided for @noLogsBody.
  ///
  /// In en, this message translates to:
  /// **'Connect to a server to see logs'**
  String get noLogsBody;

  /// No description provided for @subscriptionFetchError.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch subscription. Check the URL and try again.'**
  String get subscriptionFetchError;

  /// No description provided for @latencyTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach server'**
  String get latencyTestFailed;

  /// No description provided for @qrUnrecognized.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t recognize this QR code'**
  String get qrUnrecognized;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission required to scan QR codes. Enable in Settings.'**
  String get cameraPermissionDenied;

  /// No description provided for @deleteServersTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} servers?'**
  String deleteServersTitle(int count);

  /// No description provided for @deleteServersBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove the selected servers. Servers from subscriptions will reappear on next refresh.'**
  String get deleteServersBody;

  /// No description provided for @deleteServersConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {count}'**
  String deleteServersConfirm(int count);

  /// No description provided for @keepServers.
  ///
  /// In en, this message translates to:
  /// **'Keep Servers'**
  String get keepServers;

  /// No description provided for @subscriptionRefreshSuccess.
  ///
  /// In en, this message translates to:
  /// **'Updated {count} subscriptions'**
  String subscriptionRefreshSuccess(int count);

  /// No description provided for @subscriptionRefreshNoChange.
  ///
  /// In en, this message translates to:
  /// **'All up to date'**
  String get subscriptionRefreshNoChange;

  /// No description provided for @subscriptionRefreshFail.
  ///
  /// In en, this message translates to:
  /// **'Failed to update {name}. Check your connection.'**
  String subscriptionRefreshFail(String name);

  /// No description provided for @qrSubscriptionPrompt.
  ///
  /// In en, this message translates to:
  /// **'This looks like a subscription URL. Add as subscription?'**
  String get qrSubscriptionPrompt;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notNow;

  /// No description provided for @dismissDialog.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismissDialog;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortBy;

  /// No description provided for @sortByDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get sortByDefault;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortByName;

  /// No description provided for @sortByLatency.
  ///
  /// In en, this message translates to:
  /// **'Latency'**
  String get sortByLatency;

  /// No description provided for @sortByProtocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get sortByProtocol;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterWorking.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get filterWorking;

  /// No description provided for @filterFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get filterFailed;

  /// No description provided for @testAllServers.
  ///
  /// In en, this message translates to:
  /// **'Test All'**
  String get testAllServers;

  /// No description provided for @bestServer.
  ///
  /// In en, this message translates to:
  /// **'Best Server'**
  String get bestServer;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @scanQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrTitle;

  /// No description provided for @scanQrInstruction.
  ///
  /// In en, this message translates to:
  /// **'Point camera at a QR code'**
  String get scanQrInstruction;

  /// No description provided for @shareServer.
  ///
  /// In en, this message translates to:
  /// **'Share Server'**
  String get shareServer;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @shareLink.
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get shareLink;

  /// No description provided for @exportLogs.
  ///
  /// In en, this message translates to:
  /// **'Export Logs'**
  String get exportLogs;

  /// No description provided for @viewLogs.
  ///
  /// In en, this message translates to:
  /// **'View Logs'**
  String get viewLogs;

  /// No description provided for @autoScroll.
  ///
  /// In en, this message translates to:
  /// **'Auto-scroll'**
  String get autoScroll;

  /// No description provided for @linesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} lines'**
  String linesCount(int count);

  /// No description provided for @autoUpdateOnLaunch.
  ///
  /// In en, this message translates to:
  /// **'Auto-update on app launch'**
  String get autoUpdateOnLaunch;

  /// No description provided for @userAgentHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for default browser UA'**
  String get userAgentHint;

  /// No description provided for @subscriptionUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get subscriptionUrl;

  /// No description provided for @subscriptionName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get subscriptionName;

  /// No description provided for @subscriptionInfoFormat.
  ///
  /// In en, this message translates to:
  /// **'{count} servers'**
  String subscriptionInfoFormat(int count);

  /// No description provided for @importedServersCount.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} servers'**
  String importedServersCount(int count);

  /// No description provided for @logFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get logFilterAll;

  /// No description provided for @logFilterInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get logFilterInfo;

  /// No description provided for @logFilterWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get logFilterWarning;

  /// No description provided for @logFilterError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get logFilterError;

  /// No description provided for @diagnosticsSection.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnosticsSection;

  /// No description provided for @regionPresets.
  ///
  /// In en, this message translates to:
  /// **'Region Presets'**
  String get regionPresets;

  /// No description provided for @domainRules.
  ///
  /// In en, this message translates to:
  /// **'Domain Rules'**
  String get domainRules;

  /// No description provided for @perAppProxy.
  ///
  /// In en, this message translates to:
  /// **'Per-App Proxy'**
  String get perAppProxy;

  /// No description provided for @enablePerAppProxy.
  ///
  /// In en, this message translates to:
  /// **'Enable Per-App Proxy'**
  String get enablePerAppProxy;

  /// No description provided for @searchApps.
  ///
  /// In en, this message translates to:
  /// **'Search apps…'**
  String get searchApps;

  /// No description provided for @appsSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} apps selected'**
  String appsSelectedCount(int count);

  /// No description provided for @blacklistMode.
  ///
  /// In en, this message translates to:
  /// **'Blacklist'**
  String get blacklistMode;

  /// No description provided for @whitelistMode.
  ///
  /// In en, this message translates to:
  /// **'Whitelist'**
  String get whitelistMode;

  /// No description provided for @blacklistDescription.
  ///
  /// In en, this message translates to:
  /// **'All apps route through VPN except selected'**
  String get blacklistDescription;

  /// No description provided for @whitelistDescription.
  ///
  /// In en, this message translates to:
  /// **'Only selected apps route through VPN'**
  String get whitelistDescription;

  /// No description provided for @switchedToMode.
  ///
  /// In en, this message translates to:
  /// **'Switched to {mode} mode'**
  String switchedToMode(String mode);

  /// No description provided for @loadingApps.
  ///
  /// In en, this message translates to:
  /// **'Loading installed apps…'**
  String get loadingApps;

  /// No description provided for @noAppsSelected.
  ///
  /// In en, this message translates to:
  /// **'No apps selected — check apps to include or exclude them'**
  String get noAppsSelected;

  /// No description provided for @addRule.
  ///
  /// In en, this message translates to:
  /// **'Add Rule'**
  String get addRule;

  /// No description provided for @addDomainRule.
  ///
  /// In en, this message translates to:
  /// **'Add Domain Rule'**
  String get addDomainRule;

  /// No description provided for @discardRule.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardRule;

  /// No description provided for @domainHint.
  ///
  /// In en, this message translates to:
  /// **'example.com'**
  String get domainHint;

  /// No description provided for @invalidDomain.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid domain (e.g., example.com)'**
  String get invalidDomain;

  /// No description provided for @ruleRemoved.
  ///
  /// In en, this message translates to:
  /// **'Rule removed'**
  String get ruleRemoved;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @noRulesYet.
  ///
  /// In en, this message translates to:
  /// **'No custom rules yet — tap Add Rule to get started'**
  String get noRulesYet;

  /// No description provided for @proxy.
  ///
  /// In en, this message translates to:
  /// **'Proxy'**
  String get proxy;

  /// No description provided for @direct.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get direct;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @updateRules.
  ///
  /// In en, this message translates to:
  /// **'Update Rules'**
  String get updateRules;

  /// No description provided for @rulesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Rules updated'**
  String get rulesUpdated;

  /// No description provided for @bundledRulesNote.
  ///
  /// In en, this message translates to:
  /// **'Uses bundled rules. Tap ↓ to update.'**
  String get bundledRulesNote;

  /// No description provided for @regionIran.
  ///
  /// In en, this message translates to:
  /// **'Iran 🇮🇷'**
  String get regionIran;

  /// No description provided for @regionChina.
  ///
  /// In en, this message translates to:
  /// **'China 🇨🇳'**
  String get regionChina;

  /// No description provided for @regionRussia.
  ///
  /// In en, this message translates to:
  /// **'Russia 🇷🇺'**
  String get regionRussia;

  /// No description provided for @dnsSection.
  ///
  /// In en, this message translates to:
  /// **'DNS'**
  String get dnsSection;

  /// No description provided for @dnsProtocol.
  ///
  /// In en, this message translates to:
  /// **'DNS Protocol'**
  String get dnsProtocol;

  /// No description provided for @remoteDns.
  ///
  /// In en, this message translates to:
  /// **'Remote DNS'**
  String get remoteDns;

  /// No description provided for @directDns.
  ///
  /// In en, this message translates to:
  /// **'Direct DNS'**
  String get directDns;

  /// No description provided for @selectDnsServer.
  ///
  /// In en, this message translates to:
  /// **'Select DNS Server'**
  String get selectDnsServer;

  /// No description provided for @customDns.
  ///
  /// In en, this message translates to:
  /// **'Custom...'**
  String get customDns;

  /// No description provided for @enterDnsAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter DNS address'**
  String get enterDnsAddress;

  /// No description provided for @dnsUpdated.
  ///
  /// In en, this message translates to:
  /// **'DNS updated'**
  String get dnsUpdated;

  /// No description provided for @engineSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Engine Settings'**
  String get engineSettingsSection;

  /// No description provided for @sniffing.
  ///
  /// In en, this message translates to:
  /// **'Sniffing'**
  String get sniffing;

  /// No description provided for @sniffingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Detect protocol type from traffic content'**
  String get sniffingSubtitle;

  /// No description provided for @mux.
  ///
  /// In en, this message translates to:
  /// **'Mux (Multiplexing)'**
  String get mux;

  /// No description provided for @muxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Combine multiple connections into one'**
  String get muxSubtitle;

  /// No description provided for @concurrency.
  ///
  /// In en, this message translates to:
  /// **'Concurrency'**
  String get concurrency;

  /// No description provided for @antiCensorshipSection.
  ///
  /// In en, this message translates to:
  /// **'Anti-Censorship'**
  String get antiCensorshipSection;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @profileNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get profileNone;

  /// No description provided for @profileLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get profileLight;

  /// No description provided for @profileModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get profileModerate;

  /// No description provided for @profileAggressive.
  ///
  /// In en, this message translates to:
  /// **'Aggressive'**
  String get profileAggressive;

  /// No description provided for @profileLightDesc.
  ///
  /// In en, this message translates to:
  /// **'Minimal fragmentation for light filtering'**
  String get profileLightDesc;

  /// No description provided for @profileModerateDesc.
  ///
  /// In en, this message translates to:
  /// **'Fragment + padding for moderate DPI'**
  String get profileModerateDesc;

  /// No description provided for @profileAggressiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Full fragmentation + sleep + mixed SNI for heavy DPI'**
  String get profileAggressiveDesc;

  /// No description provided for @fragment.
  ///
  /// In en, this message translates to:
  /// **'Fragment'**
  String get fragment;

  /// No description provided for @fragmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Split TLS ClientHello into fragments'**
  String get fragmentSubtitle;

  /// No description provided for @fragmentSize.
  ///
  /// In en, this message translates to:
  /// **'Fragment Size'**
  String get fragmentSize;

  /// No description provided for @sleepMs.
  ///
  /// In en, this message translates to:
  /// **'Sleep (ms)'**
  String get sleepMs;

  /// No description provided for @padding.
  ///
  /// In en, this message translates to:
  /// **'Padding'**
  String get padding;

  /// No description provided for @paddingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add padding to TLS records'**
  String get paddingSubtitle;

  /// No description provided for @mixedSniCase.
  ///
  /// In en, this message translates to:
  /// **'Mixed SNI Case'**
  String get mixedSniCase;

  /// No description provided for @mixedSniSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Randomize letter case in SNI field'**
  String get mixedSniSubtitle;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataSection;

  /// No description provided for @clearCachedData.
  ///
  /// In en, this message translates to:
  /// **'Clear Cached Data'**
  String get clearCachedData;

  /// No description provided for @clearCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Geo rules, subscription cache, logs'**
  String get clearCacheSubtitle;

  /// No description provided for @clearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Cached Data?'**
  String get clearCacheTitle;

  /// No description provided for @clearCacheBody.
  ///
  /// In en, this message translates to:
  /// **'This will clear:\n• Downloaded geo rule files\n• Subscription response cache\n• Log files\n\nServer configs and preferences will NOT be affected.'**
  String get clearCacheBody;

  /// No description provided for @clearCacheConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCacheConfirm;

  /// No description provided for @keepData.
  ///
  /// In en, this message translates to:
  /// **'Keep Data'**
  String get keepData;

  /// No description provided for @cachedDataCleared.
  ///
  /// In en, this message translates to:
  /// **'Cached data cleared'**
  String get cachedDataCleared;

  /// No description provided for @couldntUpdateRules.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update rules. Check your connection and try again.'**
  String get couldntUpdateRules;

  /// No description provided for @armaVpnSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Arma VPN settings'**
  String get armaVpnSettingsSection;

  /// No description provided for @defaultServerAutoUpdateLabel.
  ///
  /// In en, this message translates to:
  /// **'Default server auto-update interval'**
  String get defaultServerAutoUpdateLabel;

  /// No description provided for @defaultServerAutoUpdateDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get defaultServerAutoUpdateDisabled;

  /// No description provided for @defaultServerAutoUpdateEvery12Hours.
  ///
  /// In en, this message translates to:
  /// **'Every 12 Hours'**
  String get defaultServerAutoUpdateEvery12Hours;

  /// No description provided for @defaultServerAutoUpdateEvery24Hours.
  ///
  /// In en, this message translates to:
  /// **'Every 24 Hours'**
  String get defaultServerAutoUpdateEvery24Hours;

  /// No description provided for @defaultServerAutoUpdateEvery7Days.
  ///
  /// In en, this message translates to:
  /// **'Every 7 Days'**
  String get defaultServerAutoUpdateEvery7Days;

  /// No description provided for @defaultServerAutoUpdateUpdatedIndicatorLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated after a missed refresh'**
  String get defaultServerAutoUpdateUpdatedIndicatorLabel;

  /// No description provided for @defaultServerAutoUpdateUpdatedIndicatorTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Updated {timestamp}'**
  String defaultServerAutoUpdateUpdatedIndicatorTimestamp(Object timestamp);

  /// No description provided for @defaultServersTitle.
  ///
  /// In en, this message translates to:
  /// **'Default servers'**
  String get defaultServersTitle;

  /// No description provided for @defaultServersShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all servers'**
  String get defaultServersShowAll;

  /// No description provided for @defaultServersRefreshSemantics.
  ///
  /// In en, this message translates to:
  /// **'Refresh default servers'**
  String get defaultServersRefreshSemantics;

  /// No description provided for @defaultServersOfflineData.
  ///
  /// In en, this message translates to:
  /// **'Offline data'**
  String get defaultServersOfflineData;

  /// No description provided for @defaultServersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No default servers available'**
  String get defaultServersEmptyTitle;

  /// No description provided for @defaultServersEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Pull latest servers with Refresh.'**
  String get defaultServersEmptyBody;

  /// No description provided for @defaultServersNoCacheOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'No connection and no cached servers yet. Tap Refresh when online.'**
  String get defaultServersNoCacheOfflineBody;

  /// No description provided for @defaultServersTimeoutError.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Tap Refresh to try again.'**
  String get defaultServersTimeoutError;

  /// No description provided for @defaultServersOfflineError.
  ///
  /// In en, this message translates to:
  /// **'You’re offline. Showing offline data.'**
  String get defaultServersOfflineError;

  /// No description provided for @defaultServersUnauthorizedError.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please retry authentication.'**
  String get defaultServersUnauthorizedError;

  /// No description provided for @defaultServersServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again shortly.'**
  String get defaultServersServerError;

  /// No description provided for @defaultServersClientError.
  ///
  /// In en, this message translates to:
  /// **'Request failed. Please try again.'**
  String get defaultServersClientError;

  /// No description provided for @defaultServersMalformedError.
  ///
  /// In en, this message translates to:
  /// **'Server response was invalid. Please refresh again.'**
  String get defaultServersMalformedError;

  /// No description provided for @defaultServersStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get defaultServersStatusActive;

  /// No description provided for @defaultServersStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get defaultServersStatusExpired;

  /// No description provided for @defaultServersStatusLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited'**
  String get defaultServersStatusLimited;

  /// No description provided for @defaultServersStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get defaultServersStatusUnknown;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa', 'hy', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
    case 'hy':
      return AppLocalizationsHy();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
