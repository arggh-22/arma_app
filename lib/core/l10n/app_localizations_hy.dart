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
      'Չաջակցվող պրոտոկոլ — աջակցվում են միայն VLESS, VMess, Trojan, Shadowsocks և Hysteria2 հղումները';

  @override
  String get parseErrorEmptyClipboard => 'Clipboard-ը դատարկ է';

  @override
  String get importSuccess => 'Սերվերը հաջողությամբ ներմուծվեց';

  @override
  String get duplicateServer => 'Այս սերվերն արդեն ներմուծված է';

  @override
  String get disabledConnect =>
      'Միացման հնարավորությունը հասանելի կլինի հաջորդ թարմացման մեջ';

  @override
  String get disabledQrScan => 'QR սկանավորումը շուտով կհասնի';

  @override
  String get deleteServerTitle => 'Ջնջե՞լ սերվերը';

  @override
  String deleteServerBody(String serverName) {
    return 'Սա մշտապես կջնջի $serverName-ը։';
  }

  @override
  String get deleteConfirm => 'Ջնջել';

  @override
  String get deleteCancel => 'Պահել';

  @override
  String get pasteConfigTitle => 'Տեղադրել կոնֆիգ';

  @override
  String get pasteConfigHint =>
      'Տեղադրեք share հղում (vless://, vmess:// և այլն) կամ raw JSON կոնֆիգ';

  @override
  String get pasteConfigAction => 'Ներմուծել կոնֆիգ';

  @override
  String get pasteConfigEmpty => 'Շարունակելու համար տեղադրեք կոնֆիգ';

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
  String get connectionDisplaySection => 'Միացման ցուցադրում';

  @override
  String get detailedNotification => 'Մանրամասն VPN ծանուցում';

  @override
  String get detailedNotificationSubtitle =>
      'Ցուցադրել սերվերի անունը և իրական ժամանակի տրաֆիկի վիճակագրությունը Android VPN ծանուցման մեջ';

  @override
  String get dashboardStatistics => 'Դեշբորդի վիճակագրություն';

  @override
  String get dashboardStatisticsSubtitle =>
      'Ցուցադրել իրական ժամանակի ներբեռնման/վերբեռնման քարտը դեշբորդում';

  @override
  String get routingPlaceholder =>
      'Custom routing rules coming in a future update';

  @override
  String get bypassLan => 'Շրջանցել LAN-ը';

  @override
  String get bypassLanSubtitle =>
      'Չուղարկել տեղային ցանցի տրաֆիկը (192.168.x.x, 10.x.x.x) պրոքսիով';

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
    return 'Լեզուն փոխվեց՝ $language';
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
  String get viewAction => 'Դիտել';

  @override
  String get retryAction => 'Կրկնել';

  @override
  String get connecting => 'Միացվում է';

  @override
  String get connected => 'Միացված է';

  @override
  String get addSubscription => 'Ավելացնել բաժանորդագրություն';

  @override
  String get noLogsYet => 'Լոգեր դեռ չկան';

  @override
  String get noLogsBody => 'Լոգերը տեսնելու համար միացեք սերվերի';

  @override
  String get subscriptionFetchError => 'Չհաջողվեց ստանալ բաժանորդագրությունը';

  @override
  String get latencyTestFailed => 'Չհաջողվեց կապ հաստատել սերվերի հետ';

  @override
  String get qrUnrecognized => 'Չհաջողվեց ճանաչել QR կոդը';

  @override
  String get cameraPermissionDenied =>
      'QR սկանավորման համար անհրաժեշտ է տեսախցիկի թույլտվություն';

  @override
  String deleteServersTitle(int count) {
    return 'Ջնջե՞լ $count սերվեր';
  }

  @override
  String get deleteServersBody =>
      'Սա մշտապես կջնջի ընտրված սերվերները։ Բաժանորդագրությունից սերվերները կվերադառնան թարմացման ժամանակ։';

  @override
  String deleteServersConfirm(int count) {
    return 'Ջնջել $count';
  }

  @override
  String get keepServers => 'Պահել';

  @override
  String subscriptionRefreshSuccess(int count) {
    return 'Թարմացվել է $count բաժանորդագրություն';
  }

  @override
  String get subscriptionRefreshNoChange => 'Ամեն ինչ արդիական է';

  @override
  String subscriptionRefreshFail(String name) {
    return 'Չհաջողվեց թարմացնել $name-ը';
  }

  @override
  String get qrSubscriptionPrompt =>
      'Սա նման է բաժանորդագրության URL-ի։ Ավելացնե՞լ որպես բաժանորդագրություն';

  @override
  String get notNow => 'Հիմա ոչ';

  @override
  String get dismissDialog => 'Փակել';

  @override
  String get sortBy => 'Դասավորել';

  @override
  String get sortByDefault => 'Լռելյայն';

  @override
  String get sortByName => 'Անուն';

  @override
  String get sortByLatency => 'Հապաղում';

  @override
  String get sortByProtocol => 'Պրոտոկոլ';

  @override
  String get filterAll => 'Բոլորը';

  @override
  String get filterWorking => 'Աշխատող';

  @override
  String get filterFailed => 'Խափանված';

  @override
  String get testAllServers => 'Ստուգել բոլորը';

  @override
  String get bestServer => 'Լավագույն սերվեր';

  @override
  String selectedCount(int count) {
    return '$count ընտրված է';
  }

  @override
  String get selectAll => 'Ընտրել բոլորը';

  @override
  String get scanQrTitle => 'QR սքանավորում';

  @override
  String get scanQrInstruction => 'Տեսախցիկը ուղղեք QR կոդի վրա';

  @override
  String get shareServer => 'Կիսվել սերվերով';

  @override
  String get copyLink => 'Պատճենել հղումը';

  @override
  String get linkCopied => 'Հղումը պատճենվեց';

  @override
  String get shareLink => 'Կիսվել հղմամբ';

  @override
  String get exportLogs => 'Արտահանել լոգերը';

  @override
  String get viewLogs => 'Դիտել լոգերը';

  @override
  String get autoScroll => 'Ավտո-scroll';

  @override
  String linesCount(int count) {
    return '$count տող';
  }

  @override
  String get autoUpdateOnLaunch => 'Ավտոթարմացում գործարկման ժամանակ';

  @override
  String get userAgentHint => 'Թողեք դատարկ՝ լռելյայն browser UA-ի համար';

  @override
  String get subscriptionUrl => 'URL';

  @override
  String get subscriptionName => 'Անուն';

  @override
  String subscriptionInfoFormat(int count) {
    return '$count սերվեր';
  }

  @override
  String importedServersCount(int count) {
    return 'Ներմուծվել է $count սերվեր';
  }

  @override
  String get logFilterAll => 'Բոլորը';

  @override
  String get logFilterInfo => 'Տեղեկություն';

  @override
  String get logFilterWarning => 'Զգուշացում';

  @override
  String get logFilterError => 'Սխալ';

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
    return '$count հավելված ընտրված է';
  }

  @override
  String get blacklistMode => 'Սև ցուցակ';

  @override
  String get whitelistMode => 'Սպիտակ ցուցակ';

  @override
  String get blacklistDescription =>
      'Բոլոր հավելվածները անցնում են VPN-ով՝ բացի ընտրվածներից';

  @override
  String get whitelistDescription =>
      'Միայն ընտրված հավելվածներն են անցնում VPN-ով';

  @override
  String switchedToMode(String mode) {
    return 'Փոխվեց $mode ռեժիմի';
  }

  @override
  String get loadingApps => 'Տեղադրված հավելվածների բեռնում…';

  @override
  String get noAppsSelected => 'Հավելվածներ չեն ընտրված';

  @override
  String get addRule => 'Ավելացնել կանոն';

  @override
  String get addDomainRule => 'Ավելացնել դոմեյնի կանոն';

  @override
  String get discardRule => 'Չեղարկել';

  @override
  String get domainHint => 'example.com';

  @override
  String get invalidDomain => 'Մուտքագրեք վավեր դոմեյն (օր. example.com)';

  @override
  String get ruleRemoved => 'Կանոնը ջնջվեց';

  @override
  String get undo => 'Հետարկել';

  @override
  String get noRulesYet => 'Դեռ կանոններ չկան — սեղմեք «Ավելացնել կանոն»';

  @override
  String get proxy => 'Պրոքսի';

  @override
  String get direct => 'Ուղիղ';

  @override
  String get block => 'Արգելափակել';

  @override
  String get updateRules => 'Թարմացնել կանոնները';

  @override
  String get rulesUpdated => 'Կանոնները թարմացվեցին';

  @override
  String get bundledRulesNote =>
      'Օգտագործվում են ներկառուցված կանոնները։ Սեղմեք ↓ թարմացնելու համար։';

  @override
  String get regionIran => 'Իրան 🇮🇷';

  @override
  String get regionChina => 'Չինաստան 🇨🇳';

  @override
  String get regionRussia => 'Ռուսաստան 🇷🇺';

  @override
  String get dnsSection => 'DNS';

  @override
  String get dnsProtocol => 'DNS պրոտոկոլ';

  @override
  String get remoteDns => 'Հեռակա DNS';

  @override
  String get directDns => 'Ուղիղ DNS';

  @override
  String get selectDnsServer => 'Ընտրել DNS սերվեր';

  @override
  String get customDns => 'Սեփական...';

  @override
  String get enterDnsAddress => 'Մուտքագրեք DNS հասցեն';

  @override
  String get dnsUpdated => 'DNS-ը թարմացվեց';

  @override
  String get engineSettingsSection => 'Շարժիչի կարգավորումներ';

  @override
  String get sniffing => 'Sniffing';

  @override
  String get sniffingSubtitle =>
      'Բացահայտել պրոտոկոլի տեսակը տրաֆիկի բովանդակությունից';

  @override
  String get mux => 'Mux (մուլտիպլեքսավորում)';

  @override
  String get muxSubtitle => 'Միավորել մի քանի կապ մեկ կապի մեջ';

  @override
  String get concurrency => 'Զուգահեռություն';

  @override
  String get antiCensorshipSection => 'Հակացենզուրա';

  @override
  String get profile => 'Պրոֆիլ';

  @override
  String get profileNone => 'Չկա';

  @override
  String get profileLight => 'Թեթև';

  @override
  String get profileModerate => 'Միջին';

  @override
  String get profileAggressive => 'Ագրեսիվ';

  @override
  String get profileLightDesc => 'Նվազագույն fragment՝ թեթև ֆիլտրացիայի համար';

  @override
  String get profileModerateDesc => 'Fragment + padding՝ միջին DPI-ի համար';

  @override
  String get profileAggressiveDesc =>
      'Լրիվ fragment + sleep + mixed SNI՝ ծանր DPI-ի համար';

  @override
  String get fragment => 'Fragment';

  @override
  String get fragmentSubtitle => 'Բաժանել TLS ClientHello-ը մասերի';

  @override
  String get fragmentSize => 'Մասի չափ';

  @override
  String get sleepMs => 'Դադար (մվ)';

  @override
  String get padding => 'Padding';

  @override
  String get paddingSubtitle => 'Ավելացնել padding TLS գրառումներին';

  @override
  String get mixedSniCase => 'Mixed SNI Case';

  @override
  String get mixedSniSubtitle =>
      'Պատահականացնել տառերի մեծ/փոքր լինելը SNI-ում';

  @override
  String get dataSection => 'Տվյալներ';

  @override
  String get clearCachedData => 'Մաքրել cache-ը';

  @override
  String get clearCacheSubtitle => 'Geo կանոններ, subscription cache, logs';

  @override
  String get clearCacheTitle => 'Մաքրե՞լ cache-ը';

  @override
  String get clearCacheBody =>
      'Սա կմաքրի՝\n• Ներբեռնված geo կանոնների ֆայլերը\n• Subscription-ի cache-ը\n• Log ֆայլերը\n\nՍերվերի կոնֆիգներն ու նախընտրությունները չեն վնասվի։';

  @override
  String get clearCacheConfirm => 'Մաքրել cache-ը';

  @override
  String get keepData => 'Պահել տվյալները';

  @override
  String get cachedDataCleared => 'Cache-ը մաքրվեց';

  @override
  String get couldntUpdateRules =>
      'Չհաջողվեց թարմացնել կանոնները։ Ստուգեք ինտերնետ կապը։';

  @override
  String get armaVpnSettingsSection => 'Arma VPN կարգավորումներ';

  @override
  String get defaultServerAutoUpdateLabel =>
      'Լռելյայն սերվերների ինքնաթարմացման միջակայք';

  @override
  String get defaultServerAutoUpdateDisabled => 'Անջատված';

  @override
  String get defaultServerAutoUpdateEvery12Hours => 'Ամեն 12 ժամը մեկ';

  @override
  String get defaultServerAutoUpdateEvery24Hours => 'Ամեն 24 ժամը մեկ';

  @override
  String get defaultServerAutoUpdateEvery7Days => 'Ամեն 7 օրը մեկ';

  @override
  String get defaultServerAutoUpdateUpdatedIndicatorLabel =>
      'Թարմացվել է բաց թողնված թարմացումից հետո';

  @override
  String defaultServerAutoUpdateUpdatedIndicatorTimestamp(Object timestamp) {
    return 'Թարմացվել է $timestamp';
  }

  @override
  String get defaultServersTitle => 'Լռելյայն սերվերներ';

  @override
  String get defaultServersShowAll => 'Ցուցադրել բոլոր սերվերները';

  @override
  String get defaultServersRefreshSemantics => 'Թարմացնել լռելյայն սերվերները';

  @override
  String get defaultServersOfflineData => 'Օֆլայն տվյալներ';

  @override
  String get defaultServersEmptyTitle => 'Լռելյայն սերվերներ չկան';

  @override
  String get defaultServersEmptyBody =>
      'Սեղմեք Թարմացնել՝ նոր սերվերներ ստանալու համար։';

  @override
  String get defaultServersNoCacheOfflineBody =>
      'Կապ չկա և դեռ cache չկա։ Սեղմեք Թարմացնել, երբ առցանց լինեք։';

  @override
  String get defaultServersTimeoutError =>
      'Հարցման ժամանակը սպառվեց։ Սեղմեք Թարմացնել՝ կրկին փորձելու համար։';

  @override
  String get defaultServersOfflineError =>
      'Դուք օֆլայն եք։ Ցուցադրվում են օֆլայն տվյալները։';

  @override
  String get defaultServersUnauthorizedError =>
      'Սեսիան ավարտվել է։ Կրկին անցեք նույնականացում։';

  @override
  String get defaultServersServerError =>
      'Սերվերի սխալ։ Խնդրում ենք նորից փորձել քիչ անց։';

  @override
  String get defaultServersClientError =>
      'Հարցումը չհաջողվեց։ Խնդրում ենք կրկին փորձել։';

  @override
  String get defaultServersMalformedError =>
      'Սերվերի պատասխանը անվավեր էր։ Կրկին թարմացրեք։';

  @override
  String get defaultServersStatusActive => 'Ակտիվ';

  @override
  String get defaultServersStatusExpired => 'Ժամկետանց';

  @override
  String get defaultServersStatusLimited => 'Սահմանափակ';

  @override
  String get defaultServersStatusUnknown => 'Անհայտ';

  @override
  String get telegramLinkFabLabel => 'Link';

  @override
  String get telegramLinkScreenTitle => 'Link Telegram';

  @override
  String get telegramLinkOpenBot => 'Open Telegram Bot';

  @override
  String get telegramLinkStepStartTitle => 'Tap Start in Telegram bot';

  @override
  String get telegramLinkStepStartBody =>
      'Open @devarmabot — the bot will automatically send you a 6-digit link code.';

  @override
  String get telegramLinkStepGetIdTitle => 'Get your link code';

  @override
  String get telegramLinkStepGetIdBody =>
      'Type /link in the bot or tap Start. Copy the 6-digit code it sends you.';

  @override
  String get telegramLinkIdLabel => 'Link Code';

  @override
  String get telegramLinkIdHint => 'Enter 6-digit code';

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
      'Enter the 6-digit code from the Telegram bot.';

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

  @override
  String get telegramLinkLinkedTitle => 'Telegram Linked!';

  @override
  String get telegramLinkLinkedBody =>
      'Your account has been successfully linked to Telegram.';

  @override
  String get telegramLinkDoneAction => 'Done';

  @override
  String get dashboardTelegramFabLabel => 'Telegram';

  @override
  String get dashboardAnnouncementTitle => 'Announcement';

  @override
  String get dashboardAnnouncementReadMore => 'Read more';

  @override
  String get navHome => 'Գլխավոր';

  @override
  String get tapToConnect => 'Հպեք՝ կապը պաշտպանելու համար';

  @override
  String get tapToDisconnect => 'Հպեք՝ անջատվելու համար';

  @override
  String get disconnecting => 'Անջատվում է';

  @override
  String get searchServersHint => 'Որոնել սերվերներ...';

  @override
  String serversCountSubtitle(int serverCount, int providerCount) {
    return '$serverCount սերվեր · $providerCount մատակարար';
  }

  @override
  String get searchNoResults =>
      'Ձեր որոնմանը կամ զտիչներին համապատասխանող սերվերներ չկան';

  @override
  String get routingSettingsSubtitle => 'Դոմենի կանոններ և հավելվածների պրոքսի';

  @override
  String get updateSubscriptionAction => 'Թարմացնել բաժանորդագրությունը';

  @override
  String get pingAction => 'Փինգ';

  @override
  String get manageAction => 'Կառավարել';

  @override
  String get pinAction => 'Ամրացնել';

  @override
  String get unpinAction => 'Ապամրացնել';

  @override
  String get couldNotOpenLink => 'Չհաջողվեց բացել հղումը';

  @override
  String get renewAction => 'Երկարաձգել';

  @override
  String get supportAction => 'Աջակցություն';

  @override
  String get expiresNever => 'Ժամկետ՝ անժամկետ';

  @override
  String expiresCountdown(String countdown) {
    return 'Ժամկետը լրանում է՝ $countdown';
  }

  @override
  String get pingTypeTitle => 'Փինգի տեսակ';

  @override
  String get pingTypeSubtitle => 'Ինչպես է չափվում սերվերի ուշացումը';

  @override
  String get deleteAllAction => 'Ջնջել բոլորը';

  @override
  String get pingTypeHttpTitle => 'HTTP (խորհուրդ է տրվում)';

  @override
  String get pingTypeHttpSubtitle =>
      'Իրական ծայրից ծայր ինտերնետի ստուգում թունելի միջոցով';

  @override
  String get pingTypeTcpTitle => 'TCP Connect';

  @override
  String get pingTypeTcpSubtitle => 'Արագ TCP կապ անմիջապես սերվերի պորտին';

  @override
  String get pingTypeIcmpTitle => 'ICMP';

  @override
  String get pingTypeIcmpSubtitle =>
      'Համակարգային ping դեպի սերվեր՝ շրջանցելով թունելը';
}
