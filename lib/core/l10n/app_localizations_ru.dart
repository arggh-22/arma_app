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
  String get connectionDisplaySection => 'Отображение подключения';

  @override
  String get detailedNotification => 'Подробное VPN-уведомление';

  @override
  String get detailedNotificationSubtitle =>
      'Показывать имя сервера и статистику трафика в уведомлении VPN Android';

  @override
  String get dashboardStatistics => 'Статистика на главной';

  @override
  String get dashboardStatisticsSubtitle =>
      'Показывать карточку скорости загрузки/отдачи на экране Главная';

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

  @override
  String get connecting => 'Подключение';

  @override
  String get connected => 'Подключено';

  @override
  String get addSubscription => 'Добавить подписку';

  @override
  String get noLogsYet => 'Логов пока нет';

  @override
  String get noLogsBody => 'Подключитесь к серверу для просмотра логов';

  @override
  String get subscriptionFetchError =>
      'Не удалось получить подписку. Проверьте URL.';

  @override
  String get latencyTestFailed => 'Сервер недоступен';

  @override
  String get qrUnrecognized => 'Не удалось распознать QR-код';

  @override
  String get cameraPermissionDenied =>
      'Для сканирования QR требуется доступ к камере. Включите в настройках.';

  @override
  String deleteServersTitle(int count) {
    return 'Удалить $count серверов?';
  }

  @override
  String get deleteServersBody =>
      'Выбранные серверы будут удалены. Серверы из подписок вернутся при обновлении.';

  @override
  String deleteServersConfirm(int count) {
    return 'Удалить $count';
  }

  @override
  String get keepServers => 'Оставить';

  @override
  String subscriptionRefreshSuccess(int count) {
    return 'Обновлено $count подписок';
  }

  @override
  String get subscriptionRefreshNoChange => 'Всё актуально';

  @override
  String subscriptionRefreshFail(String name) {
    return 'Не удалось обновить $name.';
  }

  @override
  String get qrSubscriptionPrompt =>
      'Похоже на URL подписки. Добавить как подписку?';

  @override
  String get notNow => 'Не сейчас';

  @override
  String get dismissDialog => 'Отмена';

  @override
  String get sortBy => 'Сортировка';

  @override
  String get sortByDefault => 'По умолчанию';

  @override
  String get sortByName => 'По имени';

  @override
  String get sortByLatency => 'По задержке';

  @override
  String get sortByProtocol => 'По протоколу';

  @override
  String get filterAll => 'Все';

  @override
  String get filterWorking => 'Рабочие';

  @override
  String get filterFailed => 'Нерабочие';

  @override
  String get testAllServers => 'Тест всех';

  @override
  String get bestServer => 'Лучший сервер';

  @override
  String selectedCount(int count) {
    return '$count выбрано';
  }

  @override
  String get selectAll => 'Выбрать все';

  @override
  String get scanQrTitle => 'Сканировать QR';

  @override
  String get scanQrInstruction => 'Наведите камеру на QR-код';

  @override
  String get shareServer => 'Поделиться сервером';

  @override
  String get copyLink => 'Копировать ссылку';

  @override
  String get linkCopied => 'Ссылка скопирована';

  @override
  String get shareLink => 'Поделиться';

  @override
  String get exportLogs => 'Экспорт логов';

  @override
  String get viewLogs => 'Просмотр логов';

  @override
  String get autoScroll => 'Автопрокрутка';

  @override
  String linesCount(int count) {
    return '$count строк';
  }

  @override
  String get autoUpdateOnLaunch => 'Обновлять при запуске';

  @override
  String get userAgentHint => 'Оставьте пустым для стандартного UA';

  @override
  String get subscriptionUrl => 'URL';

  @override
  String get subscriptionName => 'Название';

  @override
  String subscriptionInfoFormat(int count) {
    return '$count серверов';
  }

  @override
  String importedServersCount(int count) {
    return 'Импортировано $count серверов';
  }

  @override
  String get logFilterAll => 'Все';

  @override
  String get logFilterInfo => 'Инфо';

  @override
  String get logFilterWarning => 'Предупр.';

  @override
  String get logFilterError => 'Ошибки';

  @override
  String get diagnosticsSection => 'Диагностика';

  @override
  String get regionPresets => 'Региональные пресеты';

  @override
  String get domainRules => 'Правила доменов';

  @override
  String get perAppProxy => 'Прокси для приложений';

  @override
  String get enablePerAppProxy => 'Включить прокси для приложений';

  @override
  String get searchApps => 'Поиск приложений…';

  @override
  String appsSelectedCount(int count) {
    return '$count приложений выбрано';
  }

  @override
  String get blacklistMode => 'Чёрный список';

  @override
  String get whitelistMode => 'Белый список';

  @override
  String get blacklistDescription =>
      'Все приложения через VPN, кроме выбранных';

  @override
  String get whitelistDescription => 'Только выбранные приложения через VPN';

  @override
  String switchedToMode(String mode) {
    return 'Переключено на режим $mode';
  }

  @override
  String get loadingApps => 'Загрузка установленных приложений…';

  @override
  String get noAppsSelected => 'Приложения не выбраны — отметьте приложения';

  @override
  String get addRule => 'Добавить правило';

  @override
  String get addDomainRule => 'Добавить правило домена';

  @override
  String get discardRule => 'Отменить';

  @override
  String get domainHint => 'example.com';

  @override
  String get invalidDomain =>
      'Введите корректный домен (например, example.com)';

  @override
  String get ruleRemoved => 'Правило удалено';

  @override
  String get undo => 'Отменить';

  @override
  String get noRulesYet => 'Пока нет правил — нажмите Добавить правило';

  @override
  String get proxy => 'Прокси';

  @override
  String get direct => 'Напрямую';

  @override
  String get block => 'Блокировать';

  @override
  String get updateRules => 'Обновить правила';

  @override
  String get rulesUpdated => 'Правила обновлены';

  @override
  String get bundledRulesNote =>
      'Используются встроенные правила. Нажмите ↓ для обновления.';

  @override
  String get regionIran => 'Иран 🇮🇷';

  @override
  String get regionChina => 'Китай 🇨🇳';

  @override
  String get regionRussia => 'Россия 🇷🇺';

  @override
  String get dnsSection => 'DNS';

  @override
  String get dnsProtocol => 'Протокол DNS';

  @override
  String get remoteDns => 'Удалённый DNS';

  @override
  String get directDns => 'Прямой DNS';

  @override
  String get selectDnsServer => 'Выбрать DNS сервер';

  @override
  String get customDns => 'Другой...';

  @override
  String get enterDnsAddress => 'Введите адрес DNS';

  @override
  String get dnsUpdated => 'DNS обновлён';

  @override
  String get engineSettingsSection => 'Настройки движка';

  @override
  String get sniffing => 'Обнаружение';

  @override
  String get sniffingSubtitle =>
      'Определение типа протокола из содержимого трафика';

  @override
  String get mux => 'Mux (мультиплексирование)';

  @override
  String get muxSubtitle => 'Объединение нескольких соединений в одно';

  @override
  String get concurrency => 'Параллельность';

  @override
  String get antiCensorshipSection => 'Антицензура';

  @override
  String get profile => 'Профиль';

  @override
  String get profileNone => 'Нет';

  @override
  String get profileLight => 'Лёгкий';

  @override
  String get profileModerate => 'Средний';

  @override
  String get profileAggressive => 'Агрессивный';

  @override
  String get profileLightDesc =>
      'Минимальная фрагментация для лёгкой фильтрации';

  @override
  String get profileModerateDesc =>
      'Фрагментация + заполнение для среднего DPI';

  @override
  String get profileAggressiveDesc =>
      'Полная фрагментация + задержка + смешанный SNI для тяжёлого DPI';

  @override
  String get fragment => 'Фрагментация';

  @override
  String get fragmentSubtitle => 'Разделение TLS ClientHello на фрагменты';

  @override
  String get fragmentSize => 'Размер фрагмента';

  @override
  String get sleepMs => 'Задержка (мс)';

  @override
  String get padding => 'Заполнение';

  @override
  String get paddingSubtitle => 'Добавление заполнения к записям TLS';

  @override
  String get mixedSniCase => 'Смешанный регистр SNI';

  @override
  String get mixedSniSubtitle => 'Случайный регистр букв в поле SNI';

  @override
  String get dataSection => 'Данные';

  @override
  String get clearCachedData => 'Очистить кеш';

  @override
  String get clearCacheSubtitle => 'Геоправила, кеш подписок, логи';

  @override
  String get clearCacheTitle => 'Очистить кеш?';

  @override
  String get clearCacheBody =>
      'Будут удалены:\n• Загруженные файлы геоправил\n• Кеш ответов подписок\n• Файлы логов\n\nНастройки серверов и предпочтения НЕ будут затронуты.';

  @override
  String get clearCacheConfirm => 'Очистить';

  @override
  String get keepData => 'Оставить';

  @override
  String get cachedDataCleared => 'Кеш очищен';

  @override
  String get couldntUpdateRules =>
      'Не удалось обновить правила. Проверьте подключение.';
}
