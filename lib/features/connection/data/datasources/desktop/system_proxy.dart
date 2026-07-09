import 'dart:io';

import 'package:flutter/foundation.dart';

/// Configures the OS system proxy to point at the locally-running xray
/// SOCKS/HTTP inbounds (desktop proxy mode). Best-effort and desktop-only.
///
/// - **Windows:** WinINet per-user settings (registry + `InternetSetOption`
///   refresh), the same store Edge/Chrome/most apps read.
/// - **Linux:** GNOME `gsettings` (`org.gnome.system.proxy`). Non-GNOME
///   desktops (KDE, etc.) are a no-op for now — apps there won't be proxied
///   automatically; this is a known limitation of proxy mode on Linux.
class SystemProxy {
  const SystemProxy();

  Future<void> enable({
    String host = '127.0.0.1',
    required int socksPort,
    required int httpPort,
  }) async {
    try {
      if (Platform.isWindows) {
        await _enableWindows(host, httpPort);
      } else if (Platform.isLinux) {
        await _enableLinuxGnome(host, socksPort, httpPort);
      }
    } on Object catch (e) {
      debugPrint('[SystemProxy] enable failed: $e');
    }
  }

  Future<void> disable() async {
    try {
      if (Platform.isWindows) {
        await _disableWindows();
      } else if (Platform.isLinux) {
        await _disableLinuxGnome();
      }
    } on Object catch (e) {
      debugPrint('[SystemProxy] disable failed: $e');
    }
  }

  // ── Windows ──────────────────────────────────────────────────────────────

  static const _winInternetSettings =
      r'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings';

  Future<void> _enableWindows(String host, int httpPort) async {
    // A single HTTP(S) proxy endpoint is what WinINet understands; xray's HTTP
    // inbound handles both. SOCKS-only apps still use 127.0.0.1:socksPort.
    await _powerShell('''
Set-ItemProperty -Path '$_winInternetSettings' -Name ProxyServer -Value '$host:$httpPort'
Set-ItemProperty -Path '$_winInternetSettings' -Name ProxyEnable -Value 1
${_winRefreshSnippet()}
''');
  }

  Future<void> _disableWindows() async {
    await _powerShell('''
Set-ItemProperty -Path '$_winInternetSettings' -Name ProxyEnable -Value 0
${_winRefreshSnippet()}
''');
  }

  /// Registry writes don't take effect until WinINet is told to reload via
  /// InternetSetOption(INTERNET_OPTION_SETTINGS_CHANGED / REFRESH).
  String _winRefreshSnippet() => r'''
$sig = @"
[System.Runtime.InteropServices.DllImport("wininet.dll", SetLastError=true)]
public static extern bool InternetSetOption(IntPtr hInternet, int dwOption, IntPtr lpBuffer, int dwBufferLength);
"@
$type = Add-Type -MemberDefinition $sig -Name WinInet -Namespace Native -PassThru
$type::InternetSetOption([IntPtr]::Zero, 39, [IntPtr]::Zero, 0) | Out-Null
$type::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0) | Out-Null
''';

  Future<void> _powerShell(String script) async {
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      script,
    ]);
    if (result.exitCode != 0) {
      debugPrint(
        '[SystemProxy] powershell exit ${result.exitCode}: ${result.stderr}',
      );
    }
  }

  // ── Linux (GNOME) ──────────────────────────────────────────────────────────

  Future<void> _enableLinuxGnome(
    String host,
    int socksPort,
    int httpPort,
  ) async {
    await _gsettings(['set', 'org.gnome.system.proxy', 'mode', 'manual']);
    for (final entry in <MapEntry<String, int>>[
      MapEntry('socks', socksPort),
      MapEntry('http', httpPort),
      MapEntry('https', httpPort),
    ]) {
      await _gsettings([
        'set',
        'org.gnome.system.proxy.${entry.key}',
        'host',
        host,
      ]);
      await _gsettings([
        'set',
        'org.gnome.system.proxy.${entry.key}',
        'port',
        '${entry.value}',
      ]);
    }
  }

  Future<void> _disableLinuxGnome() async {
    await _gsettings(['set', 'org.gnome.system.proxy', 'mode', 'none']);
  }

  Future<void> _gsettings(List<String> args) async {
    final result = await Process.run('gsettings', args);
    if (result.exitCode != 0) {
      debugPrint(
        '[SystemProxy] gsettings ${args.join(' ')} -> ${result.stderr}',
      );
    }
  }
}
