import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:arma_proxy_vpn_client/features/connection/data/datasources/vpn_platform_service.dart';
import 'package:arma_proxy_vpn_client/features/log/data/services/log_service.dart';

part 'log_provider.g.dart';

/// Singleton [LogService] instance that subscribes to VPN debug events.
///
/// Listens to the existing EventChannel `vpnEvents` stream, filtering for
/// `type == 'debug'` events (see Pitfall 7 in RESEARCH.md — debug events
/// already flow through the pipeline, we just need to capture them).
@Riverpod(keepAlive: true)
LogService logService(Ref ref) {
  final service = LogService();

  // Subscribe to debug events from VPN EventChannel.
  // The existing EventChannel already streams {"type": "debug", "message": "..."}
  final vpnService = VpnPlatformService();
  final subscription = vpnService.vpnEvents
      .where((event) => event['type'] == 'debug')
      .listen((event) {
        final message = event['message'] as String? ?? '';
        if (message.isNotEmpty) {
          service.addLine(message);
        }
      });

  ref.onDispose(() {
    subscription.cancel();
    service.dispose();
  });

  return service;
}

/// Reactive log lines list for the log viewer.
///
/// Rebuilds state when new lines arrive via stream subscription, providing
/// a reactive snapshot of the current buffer contents.
@Riverpod(keepAlive: true)
class LogLinesNotifier extends _$LogLinesNotifier {
  StreamSubscription<String>? _subscription;

  @override
  List<String> build() {
    final service = ref.watch(logServiceProvider);
    _subscription = service.logStream.listen((_) {
      // Rebuild state with current buffer contents
      state = service.lines;
    });

    ref.onDispose(() => _subscription?.cancel());

    return service.lines;
  }
}
