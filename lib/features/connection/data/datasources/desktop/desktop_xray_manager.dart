import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'package:arma_proxy_vpn_client/features/connection/data/datasources/desktop/system_proxy.dart';

/// Desktop (Linux/Windows) VPN core — **proxy mode**.
///
/// Runs the bundled `xray` binary with a SOCKS/HTTP-inbound config (see
/// [XrayConfigBuilder.buildForProxy]) and points the OS system proxy at those
/// local inbounds. This is the desktop counterpart to the Android AAR/TUN path;
/// [VpnPlatformService] delegates here on desktop so the rest of the app is
/// unchanged.
///
/// Emits status maps compatible with the Android EventChannel contract:
/// `{'type': 'status', 'state': 'connecting'|'connected'|'disconnected'|'error',
///   'message': String?}`.
///
/// NOTE: traffic stats are not yet emitted on desktop (would require wiring
/// xray's stats API); the dashboard shows zeros while connected.
class DesktopXrayManager {
  DesktopXrayManager._();
  static final DesktopXrayManager instance = DesktopXrayManager._();

  /// Loopback ports for the local inbounds. Kept in sync with the ports passed
  /// to [XrayConfigBuilder.buildForProxy] by [VpnPlatformService].
  static const int socksPort = 10808;
  static const int httpPort = 10809;

  static const _assetDir = 'assets/xray';
  static const _binaryName = 'xray'; // + .exe on Windows (see _binaryFileName)
  static const _assetFiles = <String>['geoip.dat', 'geosite.dat'];

  final SystemProxy _systemProxy = const SystemProxy();
  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();

  Process? _process;
  bool _stopping = false;
  Directory? _runtimeDir;

  /// True when this platform is a supported desktop proxy target.
  static bool get isSupported => Platform.isLinux || Platform.isWindows;

  Stream<Map<String, dynamic>> get events => _events.stream;

  bool get isRunning => _process != null;

  String get _binaryFileName => Platform.isWindows ? '$_binaryName.exe' : _binaryName;

  void _emitStatus(String state, {String? message}) {
    _events.add({
      'type': 'status',
      'state': state,
      'message': ?message,
    });
  }

  /// Extracts the bundled xray binary + geo assets into the app-support dir
  /// (once), returning the directory. Throws if the binary asset is missing
  /// (e.g. a local build where CI didn't download it).
  Future<Directory> _ensureRuntime() async {
    final existing = _runtimeDir;
    if (existing != null) return existing;

    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/xray-core');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final binaryFile = File('${dir.path}/$_binaryFileName');
    if (!binaryFile.existsSync()) {
      final bytes = await _loadAssetOrThrow('$_assetDir/$_binaryFileName');
      await binaryFile.writeAsBytes(bytes, flush: true);
      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', binaryFile.path]);
      }
    }

    // Geo data is best-effort: routing rules that reference geoip/geosite need
    // it, but a config without those rules still runs if it's absent.
    for (final name in _assetFiles) {
      final f = File('${dir.path}/$name');
      if (f.existsSync()) continue;
      try {
        final data = await rootBundle.load('$_assetDir/$name');
        await f.writeAsBytes(data.buffer.asUint8List(), flush: true);
      } on Object {
        debugPrint('[DesktopXray] optional asset missing: $name');
      }
    }

    _runtimeDir = dir;
    return dir;
  }

  Future<Uint8List> _loadAssetOrThrow(String key) async {
    try {
      final data = await rootBundle.load(key);
      return data.buffer.asUint8List();
    } on Object {
      throw StateError(
        'xray binary not bundled ($key). It is downloaded during CI '
        '(see .github/workflows/release.yml); local desktop runs need it '
        'placed under $_assetDir/ manually.',
      );
    }
  }

  /// Starts xray with [configJson] and enables the system proxy.
  Future<bool> start(String configJson, String serverName) async {
    if (_process != null) {
      await stop();
    }
    _stopping = false;
    _emitStatus('connecting');

    try {
      final dir = await _ensureRuntime();
      final configFile = File('${dir.path}/config.json');
      await configFile.writeAsString(configJson, flush: true);

      final process = await Process.start(
        '${dir.path}/$_binaryFileName',
        ['run', '-c', configFile.path],
        workingDirectory: dir.path,
        // XRAY_LOCATION_ASSET tells xray where geoip/geosite.dat live.
        environment: {'XRAY_LOCATION_ASSET': dir.path},
      );
      _process = process;

      // Surface xray's own logs for debugging.
      process.stdout
          .transform(const SystemEncoding().decoder)
          .listen((l) => debugPrint('[xray] $l'));
      process.stderr
          .transform(const SystemEncoding().decoder)
          .listen((l) => debugPrint('[xray:err] $l'));

      // Detect an immediate crash (bad config / missing binary perms).
      unawaited(
        process.exitCode.then((code) => _onProcessExit(code)),
      );

      // Give xray a moment to bind the inbounds before declaring success.
      await Future.delayed(const Duration(milliseconds: 600));
      if (_process == null) {
        // Exited during the grace period → _onProcessExit already reported.
        return false;
      }

      await _systemProxy.enable(socksPort: socksPort, httpPort: httpPort);
      _emitStatus('connected');
      return true;
    } on Object catch (e) {
      debugPrint('[DesktopXray] start failed: $e');
      await _teardownProcess();
      _emitStatus('error', message: e.toString());
      return false;
    }
  }

  void _onProcessExit(int code) {
    final wasStopping = _stopping;
    _process = null;
    // Restore the system proxy no matter why xray exited.
    unawaited(_systemProxy.disable());
    if (wasStopping) {
      _emitStatus('disconnected');
    } else {
      _emitStatus('error', message: 'xray exited (code $code)');
    }
  }

  /// Stops xray and disables the system proxy.
  Future<bool> stop() async {
    final process = _process;
    if (process == null) {
      await _systemProxy.disable();
      _emitStatus('disconnected');
      return true;
    }
    _stopping = true;
    await _systemProxy.disable();
    process.kill(ProcessSignal.sigterm);
    try {
      await process.exitCode.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
    }
    _process = null;
    _emitStatus('disconnected');
    return true;
  }

  Future<void> _teardownProcess() async {
    final process = _process;
    _process = null;
    process?.kill(ProcessSignal.sigkill);
    await _systemProxy.disable();
  }

  /// Runs `xray version` from the bundled binary.
  Future<String> version() async {
    try {
      final dir = await _ensureRuntime();
      final result = await Process.run('${dir.path}/$_binaryFileName', ['version']);
      final out = (result.stdout as String).trim();
      return out.isEmpty ? 'Unknown' : out.split('\n').first;
    } on Object catch (e) {
      debugPrint('[DesktopXray] version failed: $e');
      return 'Unknown';
    }
  }
}
