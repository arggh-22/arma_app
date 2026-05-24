import 'package:arma_proxy_vpn_client/features/api/data/datasources/api_client.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/default_server_refresh_scheduler_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/settings/domain/entities/default_server_auto_update_interval.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('defaultServerRefreshSchedulerProvider', () {
    test('applyInterval registers periodic task and cancels when disabled', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final fakeClient = _FakeSchedulerClient();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          defaultServerBackgroundSchedulerClientProvider.overrideWithValue(
            fakeClient,
          ),
          defaultServerRefreshInvokerProvider.overrideWithValue(() async {}),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(defaultServerRefreshSchedulerProvider.notifier)
          .applyInterval(DefaultServerAutoUpdateInterval.every24Hours);

      expect(fakeClient.periodicRegistrations, hasLength(1));
      expect(
        fakeClient.periodicRegistrations.single.frequency,
        const Duration(hours: 24),
      );

      await container
          .read(defaultServerRefreshSchedulerProvider.notifier)
          .applyInterval(DefaultServerAutoUpdateInterval.disabled);

      expect(
        fakeClient.cancelledUniqueNames,
        contains(defaultServerPeriodicRefreshWorkUniqueName),
      );
      expect(
        fakeClient.cancelledUniqueNames,
        contains('$defaultServerRetryRefreshWorkUniquePrefix-0'),
      );
      expect(
        fakeClient.cancelledUniqueNames,
        contains('$defaultServerRetryRefreshWorkUniquePrefix-1'),
      );
      expect(
        fakeClient.cancelledUniqueNames,
        contains('$defaultServerRetryRefreshWorkUniquePrefix-2'),
      );
    });

    test('uses retry ladder 1m, 5m, 15m then stops', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final fakeClient = _FakeSchedulerClient();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          defaultServerBackgroundSchedulerClientProvider.overrideWithValue(
            fakeClient,
          ),
          defaultServerRefreshInvokerProvider.overrideWithValue(() async {
            throw const ApiClientException(
              type: ApiClientErrorType.network,
              message: 'offline',
            );
          }),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(defaultServerRefreshSchedulerProvider.notifier);

      await notifier.runBackgroundTask(task: defaultServerPeriodicRefreshTaskName);
      await notifier.runBackgroundTask(
        task: defaultServerRetryRefreshTaskName,
        inputData: const {defaultServerRetryStepInputKey: 0},
      );
      await notifier.runBackgroundTask(
        task: defaultServerRetryRefreshTaskName,
        inputData: const {defaultServerRetryStepInputKey: 1},
      );
      await notifier.runBackgroundTask(
        task: defaultServerRetryRefreshTaskName,
        inputData: const {defaultServerRetryStepInputKey: 2},
      );

      expect(
        fakeClient.oneOffRegistrations.map((job) => job.initialDelay),
        const <Duration>[
          Duration(minutes: 1),
          Duration(minutes: 5),
          Duration(minutes: 15),
        ],
      );
    });

    test('checkAndRunOverdueRefresh marks recovered timestamp on success', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsLocalDatasource(prefs);
      await settings.setDefaultServerAutoUpdateInterval(
        DefaultServerAutoUpdateInterval.every12Hours,
      );
      await settings.setDefaultServerAutoUpdateLastSuccessAt(
        DateTime.utc(2026, 1, 1),
      );

      final now = DateTime.utc(2026, 1, 2, 13);
      var refreshCalls = 0;
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          defaultServerBackgroundSchedulerClientProvider.overrideWithValue(
            _FakeSchedulerClient(),
          ),
          defaultServerSchedulerNowProvider.overrideWithValue(() => now),
          defaultServerRefreshInvokerProvider.overrideWithValue(() async {
            refreshCalls++;
          }),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(defaultServerRefreshSchedulerProvider.notifier);

      await notifier.checkAndRunOverdueRefresh();

      expect(refreshCalls, 1);
      final state = container.read(defaultServerRefreshSchedulerProvider);
      expect(state.lastOverdueRefreshAt, now);
      expect(state.hasRecentOverdueRefresh, isTrue);
    });
  });
}

class _FakeSchedulerClient implements DefaultServerBackgroundSchedulerClient {
  final List<_PeriodicRegistration> periodicRegistrations = [];
  final List<_OneOffRegistration> oneOffRegistrations = [];
  final List<String> cancelledUniqueNames = [];

  @override
  Future<void> cancelByUniqueName(String uniqueName) async {
    cancelledUniqueNames.add(uniqueName);
  }

  @override
  Future<void> registerOneOff({
    required String uniqueName,
    required String taskName,
    required Duration initialDelay,
    required Map<String, Object?> inputData,
  }) async {
    oneOffRegistrations.add(
      _OneOffRegistration(
        uniqueName: uniqueName,
        taskName: taskName,
        initialDelay: initialDelay,
        inputData: inputData,
      ),
    );
  }

  @override
  Future<void> registerPeriodic({
    required String uniqueName,
    required String taskName,
    required Duration frequency,
  }) async {
    periodicRegistrations.add(
      _PeriodicRegistration(
        uniqueName: uniqueName,
        taskName: taskName,
        frequency: frequency,
      ),
    );
  }
}

class _PeriodicRegistration {
  const _PeriodicRegistration({
    required this.uniqueName,
    required this.taskName,
    required this.frequency,
  });

  final String uniqueName;
  final String taskName;
  final Duration frequency;
}

class _OneOffRegistration {
  const _OneOffRegistration({
    required this.uniqueName,
    required this.taskName,
    required this.initialDelay,
    required this.inputData,
  });

  final String uniqueName;
  final String taskName;
  final Duration initialDelay;
  final Map<String, Object?> inputData;
}
