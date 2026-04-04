// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Arma VPN';

  @override
  String get dashboard => 'Главная';

  @override
  String get servers => 'Серверы';

  @override
  String get routing => 'Маршрутизация';

  @override
  String get settings => 'Настройки';

  @override
  String get importServer => 'Импорт сервера';

  @override
  String get noServersYet => 'Серверов пока нет';

  @override
  String get noServersBody => 'Импортируйте первую конфигурацию сервера';

  @override
  String get importFromClipboard => 'Импорт из буфера обмена';

  @override
  String get clipboard => 'Буфер обмена';

  @override
  String get pasteConfig => 'Вставить конфигурацию';

  @override
  String get scanQr => 'Сканировать QR';

  @override
  String get parseErrorInvalidLink =>
      'Не удалось разобрать конфигурацию — проверьте формат ссылки и попробуйте снова';

  @override
  String get parseErrorUnsupported =>
      'Протокол не поддерживается — поддерживаются только ссылки VLESS, VMess, Trojan, Shadowsocks и Hysteria2';

  @override
  String get parseErrorEmptyClipboard =>
      'Буфер обмена пуст — сначала скопируйте ссылку конфигурации сервера';

  @override
  String get importSuccess => 'Сервер успешно импортирован';

  @override
  String get duplicateServer => 'Этот сервер уже импортирован';

  @override
  String get disabledConnect =>
      'Подключение будет доступно в следующем обновлении';

  @override
  String get disabledQrScan => 'Сканирование QR скоро появится';

  @override
  String get deleteServerTitle => 'Удалить сервер?';

  @override
  String deleteServerBody(String serverName) {
    return 'Это навсегда удалит $serverName.';
  }

  @override
  String get deleteConfirm => 'Удалить';

  @override
  String get deleteCancel => 'Оставить';

  @override
  String get pasteConfigTitle => 'Вставить конфигурацию';

  @override
  String get pasteConfigHint =>
      'Вставьте ссылку (vless://, vmess:// и т.д.) или JSON конфигурацию';

  @override
  String get pasteConfigAction => 'Импортировать';

  @override
  String get pasteConfigEmpty => 'Вставьте конфигурацию для продолжения';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeTitle => 'Тема';

  @override
  String get languageTitle => 'Язык';

  @override
  String get routingPlaceholder =>
      'Пользовательские правила маршрутизации появятся в будущем обновлении';

  @override
  String get bypassLan => 'Обход LAN';

  @override
  String get bypassLanSubtitle =>
      'Не направлять трафик локальной сети (192.168.x.x, 10.x.x.x) через прокси';

  @override
  String get notConnected => 'Не подключено';

  @override
  String get noServerSelected => 'Сервер не выбран';

  @override
  String get generalSection => 'Общие';

  @override
  String get aboutSection => 'О приложении';

  @override
  String get version => 'Версия';

  @override
  String get openSourceLicenses => 'Лицензии открытого кода';

  @override
  String languageChanged(String language) {
    return 'Язык изменён на $language';
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
  String get viewAction => 'Просмотр';

  @override
  String get retryAction => 'Повторить';
}
