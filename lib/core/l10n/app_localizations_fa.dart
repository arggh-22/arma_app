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
}
