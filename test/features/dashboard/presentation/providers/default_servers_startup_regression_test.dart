import 'dart:io';

import 'package:arma_proxy_vpn_client/features/api/data/datasources/api_client.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/default_server_keys_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  group('defaultServersProvider startup regression', () {
    late Directory hiveDir;

    setUp(() async {
      hiveDir = await Directory.systemTemp.createTemp(
        'default_servers_startup_regression_',
      );
      Hive.init(hiveDir.path);
    });

    tearDown(() async {
      Hive.close();
      if (await hiveDir.exists()) {
        await hiveDir.delete(recursive: true);
      }
    });

    test('returns failure state instead of throwing on startup fallback read', () async {
      final container = ProviderContainer(
        overrides: [
          defaultServerKeysProvider.overrideWith((ref) async {
            throw const ApiClientException(
              type: ApiClientErrorType.network,
              message: 'offline',
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      container.read(defaultServersProvider);
      await _settle();

      final state = container.read(defaultServersProvider);
      expect(state.items, isEmpty);
      expect(state.lastFailureType, DefaultServersFailureType.offline);
    });
  });
}

Future<void> _settle() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
