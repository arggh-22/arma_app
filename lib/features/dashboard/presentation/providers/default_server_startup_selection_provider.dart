import 'dart:math' as math;

import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef DefaultServerRandomIndexPicker = int Function(int max);

final defaultServerRandomIndexPickerProvider =
    Provider<DefaultServerRandomIndexPicker>(
      (ref) =>
          (max) => math.Random().nextInt(max),
    );

class DefaultServerStartupSelectionController {
  const DefaultServerStartupSelectionController(this._ref);

  final Ref _ref;

  Future<void> autoSelectRandomServer() async {
    await _ref.read(defaultServersProvider.notifier).refresh();

    final candidates = _ref
        .read(defaultServersProvider)
        .items
        .where((item) => item.isConnectable)
        .map((item) => item.serverConfig!)
        .toList(growable: false);

    if (candidates.isEmpty) {
      return;
    }

    final index = _ref.read(defaultServerRandomIndexPickerProvider)(
      candidates.length,
    );
    final selected = candidates[index];
    await _ref.read(activeServerProvider.notifier).selectServer(selected);
  }
}

final defaultServerStartupSelectionProvider =
    Provider<DefaultServerStartupSelectionController>(
      (ref) => DefaultServerStartupSelectionController(ref),
    );
