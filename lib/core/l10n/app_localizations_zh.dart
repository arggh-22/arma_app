// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Arma VPN';

  @override
  String get dashboard => '仪表盘';

  @override
  String get servers => '服务器';

  @override
  String get routing => '路由';

  @override
  String get settings => '设置';

  @override
  String get importServer => '导入服务器';

  @override
  String get noServersYet => '暂无服务器';

  @override
  String get noServersBody => '导入您的第一个服务器配置开始使用';

  @override
  String get importFromClipboard => '从剪贴板导入';

  @override
  String get clipboard => '剪贴板';

  @override
  String get pasteConfig => '粘贴配置';

  @override
  String get scanQr => '扫描二维码';

  @override
  String get parseErrorInvalidLink => '无法解析配置 — 请检查链接格式后重试';

  @override
  String get parseErrorUnsupported =>
      '不支持的协议 — 仅支持 VLESS、VMess、Trojan、Shadowsocks 和 Hysteria2 链接';

  @override
  String get parseErrorEmptyClipboard => '剪贴板为空 — 请先复制服务器配置链接';

  @override
  String get importSuccess => '服务器导入成功';

  @override
  String get duplicateServer => '此服务器已导入';

  @override
  String get disabledConnect => '连接功能将在下一版本中提供';

  @override
  String get disabledQrScan => '二维码扫描即将推出';

  @override
  String get deleteServerTitle => '删除服务器？';

  @override
  String deleteServerBody(String serverName) {
    return '这将永久删除 $serverName。';
  }

  @override
  String get deleteConfirm => '删除';

  @override
  String get deleteCancel => '保留';

  @override
  String get pasteConfigTitle => '粘贴配置';

  @override
  String get pasteConfigHint => '粘贴分享链接（vless://、vmess:// 等）或 JSON 配置';

  @override
  String get pasteConfigAction => '导入配置';

  @override
  String get pasteConfigEmpty => '请粘贴配置以继续';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeTitle => '主题';

  @override
  String get languageTitle => '语言';

  @override
  String get routingPlaceholder => '自定义路由规则将在未来版本中推出';

  @override
  String get bypassLan => '绕过局域网';

  @override
  String get bypassLanSubtitle => '不通过代理路由本地网络流量 (192.168.x.x, 10.x.x.x)';

  @override
  String get notConnected => '未连接';

  @override
  String get noServerSelected => '未选择服务器';

  @override
  String get generalSection => '通用';

  @override
  String get aboutSection => '关于';

  @override
  String get version => '版本';

  @override
  String get openSourceLicenses => '开源许可证';

  @override
  String languageChanged(String language) {
    return '语言已更改为$language';
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
  String get viewAction => '查看';

  @override
  String get retryAction => '重试';

  @override
  String get connecting => '连接中';

  @override
  String get connected => '已连接';

  @override
  String get addSubscription => '添加订阅';

  @override
  String get noLogsYet => '暂无日志';

  @override
  String get noLogsBody => '连接服务器后查看日志';

  @override
  String get subscriptionFetchError => '获取订阅失败，请检查URL';

  @override
  String get latencyTestFailed => '无法连接服务器';

  @override
  String get qrUnrecognized => '无法识别此二维码';

  @override
  String get cameraPermissionDenied => '扫描二维码需要相机权限，请在设置中启用';

  @override
  String deleteServersTitle(int count) {
    return '删除 $count 个服务器？';
  }

  @override
  String get deleteServersBody => '选中的服务器将被永久删除。订阅服务器会在下次刷新时恢复。';

  @override
  String deleteServersConfirm(int count) {
    return '删除 $count 个';
  }

  @override
  String get keepServers => '保留';

  @override
  String subscriptionRefreshSuccess(int count) {
    return '已更新 $count 个订阅';
  }

  @override
  String get subscriptionRefreshNoChange => '全部已是最新';

  @override
  String subscriptionRefreshFail(String name) {
    return '更新 $name 失败';
  }

  @override
  String get qrSubscriptionPrompt => '这看起来是订阅链接。是否添加为订阅？';

  @override
  String get notNow => '暂不';

  @override
  String get dismissDialog => '取消';

  @override
  String get sortBy => '排序';

  @override
  String get sortByDefault => '默认';

  @override
  String get sortByName => '名称';

  @override
  String get sortByLatency => '延迟';

  @override
  String get sortByProtocol => '协议';

  @override
  String get filterAll => '全部';

  @override
  String get filterWorking => '可用';

  @override
  String get filterFailed => '不可用';

  @override
  String get testAllServers => '全部测试';

  @override
  String get bestServer => '最佳服务器';

  @override
  String selectedCount(int count) {
    return '已选 $count 个';
  }

  @override
  String get selectAll => '全选';

  @override
  String get scanQrTitle => '扫描二维码';

  @override
  String get scanQrInstruction => '将摄像头对准二维码';

  @override
  String get shareServer => '分享服务器';

  @override
  String get copyLink => '复制链接';

  @override
  String get linkCopied => '链接已复制';

  @override
  String get shareLink => '分享链接';

  @override
  String get exportLogs => '导出日志';

  @override
  String get viewLogs => '查看日志';

  @override
  String get autoScroll => '自动滚动';

  @override
  String linesCount(int count) {
    return '$count 行';
  }

  @override
  String get autoUpdateOnLaunch => '启动时自动更新';

  @override
  String get userAgentHint => '留空使用默认浏览器UA';

  @override
  String get subscriptionUrl => 'URL';

  @override
  String get subscriptionName => '名称';

  @override
  String subscriptionInfoFormat(int count) {
    return '$count 个服务器';
  }

  @override
  String importedServersCount(int count) {
    return '已导入 $count 个服务器';
  }

  @override
  String get logFilterAll => '全部';

  @override
  String get logFilterInfo => '信息';

  @override
  String get logFilterWarning => '警告';

  @override
  String get logFilterError => '错误';

  @override
  String get diagnosticsSection => '诊断';

  @override
  String get regionPresets => '地区预设';

  @override
  String get domainRules => '域名规则';

  @override
  String get perAppProxy => '分应用代理';

  @override
  String get enablePerAppProxy => '启用分应用代理';

  @override
  String get searchApps => '搜索应用…';

  @override
  String appsSelectedCount(int count) {
    return '已选择 $count 个应用';
  }

  @override
  String get blacklistMode => '黑名单';

  @override
  String get whitelistMode => '白名单';

  @override
  String get blacklistDescription => '所有应用通过VPN，选中的除外';

  @override
  String get whitelistDescription => '仅选中的应用通过VPN';

  @override
  String switchedToMode(String mode) {
    return '已切换到$mode模式';
  }

  @override
  String get loadingApps => '正在加载已安装应用…';

  @override
  String get noAppsSelected => '未选择应用 — 勾选要包含或排除的应用';

  @override
  String get addRule => '添加规则';

  @override
  String get addDomainRule => '添加域名规则';

  @override
  String get discardRule => '放弃';

  @override
  String get domainHint => 'example.com';

  @override
  String get invalidDomain => '请输入有效域名（例如 example.com）';

  @override
  String get ruleRemoved => '规则已删除';

  @override
  String get undo => '撤销';

  @override
  String get noRulesYet => '暂无自定义规则 — 点击添加规则开始';

  @override
  String get proxy => '代理';

  @override
  String get direct => '直连';

  @override
  String get block => '拦截';

  @override
  String get updateRules => '更新规则';

  @override
  String get rulesUpdated => '规则已更新';

  @override
  String get bundledRulesNote => '使用内置规则。点击 ↓ 更新。';

  @override
  String get regionIran => '伊朗 🇮🇷';

  @override
  String get regionChina => '中国 🇨🇳';

  @override
  String get regionRussia => '俄罗斯 🇷🇺';

  @override
  String get dnsSection => 'DNS';

  @override
  String get dnsProtocol => 'DNS 协议';

  @override
  String get remoteDns => '远程 DNS';

  @override
  String get directDns => '直连 DNS';

  @override
  String get selectDnsServer => '选择 DNS 服务器';

  @override
  String get customDns => '自定义...';

  @override
  String get enterDnsAddress => '输入 DNS 地址';

  @override
  String get dnsUpdated => 'DNS 已更新';

  @override
  String get engineSettingsSection => '引擎设置';

  @override
  String get sniffing => '流量嗅探';

  @override
  String get sniffingSubtitle => '从流量内容检测协议类型';

  @override
  String get mux => 'Mux（多路复用）';

  @override
  String get muxSubtitle => '将多个连接合并为一个';

  @override
  String get concurrency => '并发数';

  @override
  String get antiCensorshipSection => '反审查';

  @override
  String get profile => '配置';

  @override
  String get profileNone => '无';

  @override
  String get profileLight => '轻度';

  @override
  String get profileModerate => '中度';

  @override
  String get profileAggressive => '强力';

  @override
  String get profileLightDesc => '轻度过滤的最小分片';

  @override
  String get profileModerateDesc => '分片 + 填充适用于中度 DPI';

  @override
  String get profileAggressiveDesc => '完全分片 + 延迟 + 混合 SNI 适用于重度 DPI';

  @override
  String get fragment => '分片';

  @override
  String get fragmentSubtitle => '将 TLS ClientHello 拆分为片段';

  @override
  String get fragmentSize => '分片大小';

  @override
  String get sleepMs => '延迟（毫秒）';

  @override
  String get padding => '填充';

  @override
  String get paddingSubtitle => '向 TLS 记录添加填充';

  @override
  String get mixedSniCase => '混合 SNI 大小写';

  @override
  String get mixedSniSubtitle => '随机化 SNI 字段中的字母大小写';

  @override
  String get dataSection => '数据';

  @override
  String get clearCachedData => '清除缓存数据';

  @override
  String get clearCacheSubtitle => '地理规则、订阅缓存、日志';

  @override
  String get clearCacheTitle => '清除缓存数据？';

  @override
  String get clearCacheBody =>
      '将清除：\n• 已下载的地理规则文件\n• 订阅响应缓存\n• 日志文件\n\n服务器配置和偏好设置不会受影响。';

  @override
  String get clearCacheConfirm => '清除缓存';

  @override
  String get keepData => '保留数据';

  @override
  String get cachedDataCleared => '缓存数据已清除';

  @override
  String get couldntUpdateRules => '无法更新规则。请检查网络连接后重试。';
}
