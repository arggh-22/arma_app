import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';

/// Displays elapsed connection time in HH:MM:SS format (D-04).
///
/// Uses a [ConsumerStatefulWidget] with a periodic [Timer] that ticks
/// every second while the VPN is in [Connected] state.
/// Resets to 00:00:00 on disconnect.
class ConnectionTimer extends ConsumerStatefulWidget {
  const ConnectionTimer({super.key});

  @override
  ConsumerState<ConnectionTimer> createState() => _ConnectionTimerState();
}

class _ConnectionTimerState extends ConsumerState<ConnectionTimer> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleStateChange(ConnectionStatus? prev, ConnectionStatus next) {
    switch (next) {
      case Connected(:final connectedAt):
        _elapsed = DateTime.now().difference(connectedAt);
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {
            _elapsed = DateTime.now().difference(connectedAt);
          });
        });
      case Disconnected():
      case Disconnecting():
        _timer?.cancel();
        setState(() {
          _elapsed = Duration.zero;
        });
      case Connecting():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(connectionProvider, _handleStateChange);

    final hours = _elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final timeStr = '$hours:$minutes:$seconds';

    return Text(
      timeStr,
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }
}
