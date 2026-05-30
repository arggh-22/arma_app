// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appName => 'آرما VPN';

  @override
  String get dashboard => 'داشبورد';

  @override
  String get servers => 'سرورها';

  @override
  String get routing => 'مسیریابی';

  @override
  String get settings => 'تنظیمات';

  @override
  String get importServer => 'وارد کردن سرور';

  @override
  String get noServersYet => 'هنوز سروری نیست';

  @override
  String get noServersBody => 'اولین پیکربندی سرور خود را وارد کنید';

  @override
  String get importFromClipboard => 'وارد کردن از کلیپ‌بورد';

  @override
  String get clipboard => 'کلیپ‌بورد';

  @override
  String get pasteConfig => 'پیکربندی را بچسبانید';

  @override
  String get scanQr => 'اسکن QR';

  @override
  String get parseErrorInvalidLink =>
      'پیکربندی قابل تجزیه نیست — فرمت لینک را بررسی و دوباره امتحان کنید';

  @override
  String get parseErrorUnsupported =>
      'پروتکل پشتیبانی نمی‌شود — فقط لینک‌های VLESS، VMess، Trojan، Shadowsocks و Hysteria2 پشتیبانی می‌شوند';

  @override
  String get parseErrorEmptyClipboard =>
      'کلیپ‌بورد خالی است — ابتدا یک لینک پیکربندی سرور کپی کنید';

  @override
  String get importSuccess => 'سرور با موفقیت وارد شد';

  @override
  String get duplicateServer => 'این سرور قبلاً وارد شده است';

  @override
  String get disabledConnect => 'اتصال در به‌روزرسانی بعدی فعال می‌شود';

  @override
  String get disabledQrScan => 'اسکن QR به زودی اضافه می‌شود';

  @override
  String get deleteServerTitle => 'حذف سرور؟';

  @override
  String deleteServerBody(String serverName) {
    return 'این عمل $serverName را برای همیشه حذف می‌کند.';
  }

  @override
  String get deleteConfirm => 'حذف';

  @override
  String get deleteCancel => 'نگه داشتن';

  @override
  String get pasteConfigTitle => 'پیکربندی را بچسبانید';

  @override
  String get pasteConfigHint =>
      'یک لینک اشتراکی (vless://، vmess:// و غیره) یا پیکربندی JSON بچسبانید';

  @override
  String get pasteConfigAction => 'وارد کردن پیکربندی';

  @override
  String get pasteConfigEmpty => 'برای ادامه یک پیکربندی بچسبانید';

  @override
  String get themeSystem => 'سیستم';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeDark => 'تاریک';

  @override
  String get themeTitle => 'تم';

  @override
  String get languageTitle => 'زبان';

  @override
  String get connectionDisplaySection => 'نمایش اتصال';

  @override
  String get detailedNotification => 'اعلان جزئیات VPN';

  @override
  String get detailedNotificationSubtitle =>
      'نمایش نام سرور و آمار زنده ترافیک در اعلان VPN اندروید';

  @override
  String get dashboardStatistics => 'آمار داشبورد';

  @override
  String get dashboardStatisticsSubtitle =>
      'نمایش کارت آمار زنده آپلود/دانلود در داشبورد';

  @override
  String get routingPlaceholder =>
      'قوانین مسیریابی سفارشی در به‌روزرسانی آینده اضافه می‌شود';

  @override
  String get bypassLan => 'عبور از LAN';

  @override
  String get bypassLanSubtitle =>
      'ترافیک شبکه محلی (192.168.x.x, 10.x.x.x) از طریق پروکسی ارسال نشود';

  @override
  String get notConnected => 'متصل نیست';

  @override
  String get noServerSelected => 'سروری انتخاب نشده';

  @override
  String get generalSection => 'عمومی';

  @override
  String get aboutSection => 'درباره';

  @override
  String get version => 'نسخه';

  @override
  String get openSourceLicenses => 'مجوزهای متن‌باز';

  @override
  String languageChanged(String language) {
    return 'زبان به $language تغییر کرد';
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
  String get viewAction => 'مشاهده';

  @override
  String get retryAction => 'تلاش مجدد';

  @override
  String get connecting => 'در حال اتصال';

  @override
  String get connected => 'متصل';

  @override
  String get addSubscription => 'افزودن اشتراک';

  @override
  String get noLogsYet => 'هنوز لاگی نیست';

  @override
  String get noLogsBody => 'برای مشاهده لاگ‌ها به سرور متصل شوید';

  @override
  String get subscriptionFetchError =>
      'دریافت اشتراک ناموفق بود. آدرس را بررسی کنید.';

  @override
  String get latencyTestFailed => 'سرور در دسترس نیست';

  @override
  String get qrUnrecognized => 'محتوای QR قابل شناسایی نیست';

  @override
  String get cameraPermissionDenied =>
      'برای اسکن QR به دسترسی دوربین نیاز است. در تنظیمات فعال کنید.';

  @override
  String deleteServersTitle(int count) {
    return 'حذف $count سرور؟';
  }

  @override
  String get deleteServersBody =>
      'سرورهای انتخاب شده حذف خواهند شد. سرورهای اشتراکی در بروزرسانی بعدی بازمی‌گردند.';

  @override
  String deleteServersConfirm(int count) {
    return 'حذف $count';
  }

  @override
  String get keepServers => 'نگه داشتن';

  @override
  String subscriptionRefreshSuccess(int count) {
    return '$count اشتراک بروزرسانی شد';
  }

  @override
  String get subscriptionRefreshNoChange => 'همه بروز هستند';

  @override
  String subscriptionRefreshFail(String name) {
    return 'بروزرسانی $name ناموفق بود.';
  }

  @override
  String get qrSubscriptionPrompt =>
      'این یک آدرس اشتراک به نظر می‌رسد. افزودن به عنوان اشتراک؟';

  @override
  String get notNow => 'الان نه';

  @override
  String get dismissDialog => 'بستن';

  @override
  String get sortBy => 'مرتب‌سازی';

  @override
  String get sortByDefault => 'پیش‌فرض';

  @override
  String get sortByName => 'نام';

  @override
  String get sortByLatency => 'تأخیر';

  @override
  String get sortByProtocol => 'پروتکل';

  @override
  String get filterAll => 'همه';

  @override
  String get filterWorking => 'فعال';

  @override
  String get filterFailed => 'ناموفق';

  @override
  String get testAllServers => 'تست همه';

  @override
  String get bestServer => 'بهترین سرور';

  @override
  String selectedCount(int count) {
    return '$count انتخاب شده';
  }

  @override
  String get selectAll => 'انتخاب همه';

  @override
  String get scanQrTitle => 'اسکن QR';

  @override
  String get scanQrInstruction => 'دوربین را به سمت QR بگیرید';

  @override
  String get shareServer => 'اشتراک‌گذاری سرور';

  @override
  String get copyLink => 'کپی لینک';

  @override
  String get linkCopied => 'لینک کپی شد';

  @override
  String get shareLink => 'اشتراک‌گذاری لینک';

  @override
  String get exportLogs => 'خروجی لاگ‌ها';

  @override
  String get viewLogs => 'مشاهده لاگ‌ها';

  @override
  String get autoScroll => 'اسکرول خودکار';

  @override
  String linesCount(int count) {
    return '$count خط';
  }

  @override
  String get autoUpdateOnLaunch => 'بروزرسانی خودکار هنگام اجرا';

  @override
  String get userAgentHint => 'خالی بگذارید برای UA پیش‌فرض';

  @override
  String get subscriptionUrl => 'آدرس';

  @override
  String get subscriptionName => 'نام';

  @override
  String subscriptionInfoFormat(int count) {
    return '$count سرور';
  }

  @override
  String importedServersCount(int count) {
    return '$count سرور وارد شد';
  }

  @override
  String get logFilterAll => 'همه';

  @override
  String get logFilterInfo => 'اطلاعات';

  @override
  String get logFilterWarning => 'هشدار';

  @override
  String get logFilterError => 'خطا';

  @override
  String get diagnosticsSection => 'عیب‌یابی';

  @override
  String get regionPresets => 'پیش‌فرض‌های منطقه‌ای';

  @override
  String get domainRules => 'قوانین دامنه';

  @override
  String get perAppProxy => 'پروکسی هر برنامه';

  @override
  String get enablePerAppProxy => 'فعال‌سازی پروکسی هر برنامه';

  @override
  String get searchApps => 'جستجوی برنامه‌ها…';

  @override
  String appsSelectedCount(int count) {
    return '$count برنامه انتخاب شده';
  }

  @override
  String get blacklistMode => 'لیست سیاه';

  @override
  String get whitelistMode => 'لیست سفید';

  @override
  String get blacklistDescription =>
      'همه برنامه‌ها از VPN عبور می‌کنند به جز انتخاب‌شده‌ها';

  @override
  String get whitelistDescription =>
      'فقط برنامه‌های انتخاب‌شده از VPN عبور می‌کنند';

  @override
  String switchedToMode(String mode) {
    return 'تغییر به حالت $mode';
  }

  @override
  String get loadingApps => 'بارگذاری برنامه‌های نصب‌شده…';

  @override
  String get noAppsSelected =>
      'هیچ برنامه‌ای انتخاب نشده — برنامه‌ها را علامت بزنید';

  @override
  String get addRule => 'افزودن قانون';

  @override
  String get addDomainRule => 'افزودن قانون دامنه';

  @override
  String get discardRule => 'انصراف';

  @override
  String get domainHint => 'example.com';

  @override
  String get invalidDomain => 'یک دامنه معتبر وارد کنید (مثلاً example.com)';

  @override
  String get ruleRemoved => 'قانون حذف شد';

  @override
  String get undo => 'بازگردانی';

  @override
  String get noRulesYet => 'هنوز قانونی اضافه نشده — روی افزودن قانون بزنید';

  @override
  String get proxy => 'پروکسی';

  @override
  String get direct => 'مستقیم';

  @override
  String get block => 'مسدود';

  @override
  String get updateRules => 'به‌روزرسانی قوانین';

  @override
  String get rulesUpdated => 'قوانین به‌روز شد';

  @override
  String get bundledRulesNote =>
      'از قوانین داخلی استفاده می‌شود. برای به‌روزرسانی ↓ بزنید.';

  @override
  String get regionIran => 'ایران 🇮🇷';

  @override
  String get regionChina => 'چین 🇨🇳';

  @override
  String get regionRussia => 'روسیه 🇷🇺';

  @override
  String get dnsSection => 'DNS';

  @override
  String get dnsProtocol => 'پروتکل DNS';

  @override
  String get remoteDns => 'DNS راه دور';

  @override
  String get directDns => 'DNS مستقیم';

  @override
  String get selectDnsServer => 'انتخاب سرور DNS';

  @override
  String get customDns => 'سفارشی...';

  @override
  String get enterDnsAddress => 'آدرس DNS را وارد کنید';

  @override
  String get dnsUpdated => 'DNS به‌روز شد';

  @override
  String get engineSettingsSection => 'تنظیمات موتور';

  @override
  String get sniffing => 'شناسایی';

  @override
  String get sniffingSubtitle => 'تشخیص نوع پروتکل از محتوای ترافیک';

  @override
  String get mux => 'Mux (چندگانه‌سازی)';

  @override
  String get muxSubtitle => 'ترکیب چند اتصال در یک اتصال';

  @override
  String get concurrency => 'همزمانی';

  @override
  String get antiCensorshipSection => 'ضد سانسور';

  @override
  String get profile => 'پروفایل';

  @override
  String get profileNone => 'هیچ';

  @override
  String get profileLight => 'سبک';

  @override
  String get profileModerate => 'متوسط';

  @override
  String get profileAggressive => 'تهاجمی';

  @override
  String get profileLightDesc => 'تکه‌تکه‌سازی حداقلی برای فیلترینگ سبک';

  @override
  String get profileModerateDesc => 'تکه‌تکه‌سازی + لایه‌گذاری برای DPI متوسط';

  @override
  String get profileAggressiveDesc =>
      'تکه‌تکه‌سازی کامل + تأخیر + SNI مختلط برای DPI سنگین';

  @override
  String get fragment => 'تکه‌تکه‌سازی';

  @override
  String get fragmentSubtitle => 'تقسیم ClientHello TLS به قطعات';

  @override
  String get fragmentSize => 'اندازه قطعه';

  @override
  String get sleepMs => 'تأخیر (میلی‌ثانیه)';

  @override
  String get padding => 'لایه‌گذاری';

  @override
  String get paddingSubtitle => 'افزودن لایه به رکوردهای TLS';

  @override
  String get mixedSniCase => 'حروف مختلط SNI';

  @override
  String get mixedSniSubtitle => 'تصادفی‌سازی حروف بزرگ و کوچک در فیلد SNI';

  @override
  String get dataSection => 'داده';

  @override
  String get clearCachedData => 'پاک‌سازی داده‌های کش';

  @override
  String get clearCacheSubtitle => 'قوانین جغرافیایی، کش اشتراک، لاگ‌ها';

  @override
  String get clearCacheTitle => 'پاک‌سازی داده‌های کش؟';

  @override
  String get clearCacheBody =>
      'این عمل پاک می‌کند:\n• فایل‌های قوانین جغرافیایی دانلودشده\n• کش پاسخ اشتراک\n• فایل‌های لاگ\n\nتنظیمات سرور و ترجیحات تأثیر نمی‌گیرد.';

  @override
  String get clearCacheConfirm => 'پاک‌سازی کش';

  @override
  String get keepData => 'نگه‌داشتن داده';

  @override
  String get cachedDataCleared => 'داده‌های کش پاک شد';

  @override
  String get couldntUpdateRules =>
      'به‌روزرسانی قوانین ناموفق بود. اتصال خود را بررسی کنید.';

  @override
  String get armaVpnSettingsSection => 'تنظیمات Arma VPN';

  @override
  String get defaultServerAutoUpdateLabel =>
      'بازه بروزرسانی خودکار سرورهای پیش‌فرض';

  @override
  String get defaultServerAutoUpdateDisabled => 'غیرفعال';

  @override
  String get defaultServerAutoUpdateEvery12Hours => 'هر ۱۲ ساعت';

  @override
  String get defaultServerAutoUpdateEvery24Hours => 'هر ۲۴ ساعت';

  @override
  String get defaultServerAutoUpdateEvery7Days => 'هر ۷ روز';

  @override
  String get defaultServerAutoUpdateUpdatedIndicatorLabel =>
      'پس از تازه‌سازی جبرانی به‌روزرسانی شد';

  @override
  String defaultServerAutoUpdateUpdatedIndicatorTimestamp(Object timestamp) {
    return 'به‌روزرسانی در $timestamp';
  }

  @override
  String get defaultServersTitle => 'سرورهای پیش‌فرض';

  @override
  String get defaultServersShowAll => 'نمایش همه سرورها';

  @override
  String get defaultServersRefreshSemantics => 'تازه‌سازی سرورهای پیش‌فرض';

  @override
  String get defaultServersOfflineData => 'داده آفلاین';

  @override
  String get defaultServersEmptyTitle => 'سرور پیش‌فرضی موجود نیست';

  @override
  String get defaultServersEmptyBody =>
      'برای دریافت سرورها، تازه‌سازی را بزنید.';

  @override
  String get defaultServersNoCacheOfflineBody =>
      'اتصال ندارید و هنوز کشی موجود نیست. وقتی آنلاین شدید تازه‌سازی کنید.';

  @override
  String get defaultServersTimeoutError =>
      'درخواست زمان‌بر شد. برای تلاش دوباره تازه‌سازی کنید.';

  @override
  String get defaultServersOfflineError =>
      'شما آفلاین هستید. داده آفلاین نمایش داده می‌شود.';

  @override
  String get defaultServersUnauthorizedError =>
      'نشست منقضی شد. دوباره احراز هویت را انجام دهید.';

  @override
  String get defaultServersServerError =>
      'خطای سرور. کمی بعد دوباره تلاش کنید.';

  @override
  String get defaultServersClientError =>
      'درخواست ناموفق بود. دوباره تلاش کنید.';

  @override
  String get defaultServersMalformedError =>
      'پاسخ سرور نامعتبر بود. دوباره تازه‌سازی کنید.';

  @override
  String get defaultServersStatusActive => 'فعال';

  @override
  String get defaultServersStatusExpired => 'منقضی';

  @override
  String get defaultServersStatusLimited => 'محدود';

  @override
  String get defaultServersStatusUnknown => 'نامشخص';

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
      'بات @devarmabot را باز کنید — بات به طور خودکار یک کد ۶ رقمی برای شما ارسال می‌کند.';

  @override
  String get telegramLinkStepGetIdTitle => 'کد پیوند دریافت کنید';

  @override
  String get telegramLinkStepGetIdBody =>
      'دستور /link را در بات تایپ کنید یا روی Start فشار دهید. کد ۶ رقمی ارسال شده را کپی کنید.';

  @override
  String get telegramLinkIdLabel => 'کد پیوند';

  @override
  String get telegramLinkIdHint => 'کد ۶ رقمی را وارد کنید';

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
      'کد ۶ رقمی ارسال شده از بات تلگرام را وارد کنید.';

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
  String get telegramLinkLinkedTitle => 'تلگرام متصل شد!';

  @override
  String get telegramLinkLinkedBody => 'حساب شما با موفقیت به تلگرام متصل شد.';

  @override
  String get telegramLinkDoneAction => 'انجام شد';

  @override
  String get dashboardTelegramFabLabel => 'Telegram';

  @override
  String get dashboardAnnouncementTitle => 'Announcement';

  @override
  String get dashboardAnnouncementReadMore => 'Read more';
}
