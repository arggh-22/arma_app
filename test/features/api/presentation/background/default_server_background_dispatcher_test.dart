import 'package:arma_proxy_vpn_client/features/api/presentation/background/default_server_background_dispatcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('default_server_background_dispatcher', () {
    test('delegates task execution to configured runner', () async {
      final calls = <String>[];
      defaultServerBackgroundTaskRunner = ({required task, inputData}) async {
        calls.add(task);
        return true;
      };

      final result = await runDefaultServerBackgroundTask(
        task: 'default_server_refresh_periodic',
        inputData: const {'retryStep': 0},
      );

      expect(result, isTrue);
      expect(calls, ['default_server_refresh_periodic']);
    });

    test('returns false when runner throws', () async {
      defaultServerBackgroundTaskRunner = ({required task, inputData}) async {
        throw StateError('boom');
      };

      final result = await runDefaultServerBackgroundTask(
        task: 'default_server_refresh_periodic',
        inputData: null,
      );

      expect(result, isFalse);
    });
  });
}
