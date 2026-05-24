import 'package:arma_proxy_vpn_client/features/api/data/datasources/api_client.dart';
import 'package:arma_proxy_vpn_client/features/api/data/services/default_server_refresh_service.dart';
import 'package:arma_proxy_vpn_client/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/settings/domain/entities/default_server_auto_update_interval.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

const defaultServerPeriodicRefreshWorkUniqueName =
    'default-server-refresh-periodic';
const defaultServerPeriodicRefreshTaskName = 'default_server_refresh_periodic';
const defaultServerRetryRefreshWorkUniquePrefix =
    'default-server-refresh-retry';
const defaultServerRetryRefreshTaskName = 'default_server_refresh_retry';
const defaultServerRetryStepInputKey = 'retryStep';

const _retrySchedule = <Duration>[
  Duration(minutes: 1),
  Duration(minutes: 5),
  Duration(minutes: 15),
];

typedef DefaultServerSchedulerNow = DateTime Function();
typedef DefaultServerRefreshInvoker = Future<void> Function();

abstract interface class DefaultServerBackgroundSchedulerClient {
  Future<void> registerPeriodic({
    required String uniqueName,
    required String taskName,
    required Duration frequency,
  });

  Future<void> registerOneOff({
    required String uniqueName,
    required String taskName,
    required Duration initialDelay,
    required Map<String, Object?> inputData,
  });

  Future<void> cancelByUniqueName(String uniqueName);
}

class WorkmanagerDefaultServerBackgroundSchedulerClient
    implements DefaultServerBackgroundSchedulerClient {
  WorkmanagerDefaultServerBackgroundSchedulerClient(this._workmanager);

  final Workmanager _workmanager;

  @override
  Future<void> cancelByUniqueName(String uniqueName) {
    return _workmanager.cancelByUniqueName(uniqueName);
  }

  @override
  Future<void> registerOneOff({
    required String uniqueName,
    required String taskName,
    required Duration initialDelay,
    required Map<String, Object?> inputData,
  }) {
    return _workmanager.registerOneOffTask(
      uniqueName,
      taskName,
      initialDelay: initialDelay,
      inputData: inputData,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  @override
  Future<void> registerPeriodic({
    required String uniqueName,
    required String taskName,
    required Duration frequency,
  }) {
    return _workmanager.registerPeriodicTask(
      uniqueName,
      taskName,
      frequency: frequency,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}

final defaultServerBackgroundSchedulerClientProvider =
    Provider<DefaultServerBackgroundSchedulerClient>((ref) {
      return WorkmanagerDefaultServerBackgroundSchedulerClient(Workmanager());
    });

final defaultServerSchedulerNowProvider = Provider<DefaultServerSchedulerNow>(
  (ref) => DateTime.now,
);

final defaultServerRefreshInvokerProvider =
    Provider<DefaultServerRefreshInvoker>((ref) {
      return () async {
        await ref.read(defaultServerRefreshServiceProvider).refreshNow();
      };
    });

class DefaultServerRefreshSchedulerState {
  const DefaultServerRefreshSchedulerState({
    this.lastOverdueRefreshAt,
    this.hasRecentOverdueRefresh = false,
  });

  final DateTime? lastOverdueRefreshAt;
  final bool hasRecentOverdueRefresh;

  DefaultServerRefreshSchedulerState copyWith({
    DateTime? lastOverdueRefreshAt,
    bool clearLastOverdueRefreshAt = false,
    bool? hasRecentOverdueRefresh,
  }) {
    return DefaultServerRefreshSchedulerState(
      lastOverdueRefreshAt: clearLastOverdueRefreshAt
          ? null
          : lastOverdueRefreshAt ?? this.lastOverdueRefreshAt,
      hasRecentOverdueRefresh:
          hasRecentOverdueRefresh ?? this.hasRecentOverdueRefresh,
    );
  }
}

class DefaultServerRefreshSchedulerNotifier
    extends Notifier<DefaultServerRefreshSchedulerState> {
  late SettingsLocalDatasource _settingsDatasource;

  @override
  DefaultServerRefreshSchedulerState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    _settingsDatasource = SettingsLocalDatasource(prefs);
    return const DefaultServerRefreshSchedulerState();
  }

  Future<void> applyInterval(DefaultServerAutoUpdateInterval interval) async {
    if (interval == DefaultServerAutoUpdateInterval.disabled) {
      await _cancelPeriodic();
      await _cancelRetryJobs();
      return;
    }

    await ref
        .read(defaultServerBackgroundSchedulerClientProvider)
        .registerPeriodic(
          uniqueName: defaultServerPeriodicRefreshWorkUniqueName,
          taskName: defaultServerPeriodicRefreshTaskName,
          frequency: interval.duration,
        );
  }

  Future<void> applyPersistedInterval() async {
    await applyInterval(
      _settingsDatasource.getDefaultServerAutoUpdateInterval(),
    );
  }

  Future<void> checkAndRunOverdueRefresh() async {
    final interval = _settingsDatasource.getDefaultServerAutoUpdateInterval();
    if (interval == DefaultServerAutoUpdateInterval.disabled) {
      return;
    }

    final now = ref.read(defaultServerSchedulerNowProvider)().toUtc();
    final lastSuccess = _settingsDatasource
        .getDefaultServerAutoUpdateLastSuccessAt();
    final isOverdue =
        lastSuccess == null ||
        now.difference(lastSuccess.toUtc()) >= interval.duration;
    if (!isOverdue) {
      return;
    }

    final refreshed = await _refreshAndScheduleRetryIfNeeded(
      currentRetryStep: -1,
    );
    if (refreshed) {
      state = state.copyWith(
        lastOverdueRefreshAt: now,
        hasRecentOverdueRefresh: true,
      );
    }
  }

  Future<bool> runBackgroundTask({
    required String task,
    Map<String, dynamic>? inputData,
  }) async {
    final currentRetryStep = switch (task) {
      defaultServerPeriodicRefreshTaskName => -1,
      defaultServerRetryRefreshTaskName => _parseRetryStep(inputData),
      _ => -1,
    };
    if (currentRetryStep == -2) {
      return false;
    }
    return _refreshAndScheduleRetryIfNeeded(currentRetryStep: currentRetryStep);
  }

  int _parseRetryStep(Map<String, dynamic>? inputData) {
    final raw = inputData?[defaultServerRetryStepInputKey];
    if (raw is int) {
      return raw;
    }
    return -2;
  }

  Future<bool> _refreshAndScheduleRetryIfNeeded({
    required int currentRetryStep,
  }) async {
    try {
      await ref.read(defaultServerRefreshInvokerProvider)();
      await _cancelRetryJobs();
      return true;
    } on Object catch (error) {
      if (!_isRetryable(error)) {
        await _cancelRetryJobs();
        return false;
      }

      final nextRetryStep = currentRetryStep + 1;
      if (nextRetryStep >= _retrySchedule.length) {
        return false;
      }

      final delay = _retrySchedule[nextRetryStep];
      await ref
          .read(defaultServerBackgroundSchedulerClientProvider)
          .registerOneOff(
            uniqueName:
                '$defaultServerRetryRefreshWorkUniquePrefix-$nextRetryStep',
            taskName: defaultServerRetryRefreshTaskName,
            initialDelay: delay,
            inputData: {defaultServerRetryStepInputKey: nextRetryStep},
          );
      return false;
    }
  }

  bool _isRetryable(Object error) {
    if (error is ApiClientException) {
      return error.type == ApiClientErrorType.network ||
          error.type == ApiClientErrorType.timeout;
    }

    final raw = error.toString().toLowerCase();
    return raw.contains('network') ||
        raw.contains('offline') ||
        raw.contains('timeout');
  }

  Future<void> _cancelPeriodic() {
    return ref
        .read(defaultServerBackgroundSchedulerClientProvider)
        .cancelByUniqueName(defaultServerPeriodicRefreshWorkUniqueName);
  }

  Future<void> _cancelRetryJobs() async {
    final scheduler = ref.read(defaultServerBackgroundSchedulerClientProvider);
    for (var step = 0; step < _retrySchedule.length; step++) {
      await scheduler.cancelByUniqueName(
        '$defaultServerRetryRefreshWorkUniquePrefix-$step',
      );
    }
  }
}

final defaultServerRefreshSchedulerProvider =
    NotifierProvider<
      DefaultServerRefreshSchedulerNotifier,
      DefaultServerRefreshSchedulerState
    >(DefaultServerRefreshSchedulerNotifier.new);

extension on DefaultServerAutoUpdateInterval {
  Duration get duration {
    return switch (this) {
      DefaultServerAutoUpdateInterval.disabled => Duration.zero,
      DefaultServerAutoUpdateInterval.every12Hours => const Duration(hours: 12),
      DefaultServerAutoUpdateInterval.every24Hours => const Duration(hours: 24),
      DefaultServerAutoUpdateInterval.every7Days => const Duration(days: 7),
    };
  }
}
