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
}
