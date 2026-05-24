import 'package:arma_proxy_vpn_client/core/storage/app_hive_bootstrap.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/default_server_refresh_scheduler_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

typedef DefaultServerBackgroundTaskRunner =
    Future<bool> Function({
      required String task,
      Map<String, dynamic>? inputData,
    });

DefaultServerBackgroundTaskRunner defaultServerBackgroundTaskRunner =
    _defaultBackgroundTaskRunner;

@pragma('vm:entry-point')
void defaultServerBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) {
    return runDefaultServerBackgroundTask(task: task, inputData: inputData);
  });
}

Future<bool> runDefaultServerBackgroundTask({
  required String task,
  Map<String, dynamic>? inputData,
}) async {
  try {
    return await defaultServerBackgroundTaskRunner(
      task: task,
      inputData: inputData,
    );
  } catch (_) {
    return false;
  }
}

Future<bool> _defaultBackgroundTaskRunner({
  required String task,
  Map<String, dynamic>? inputData,
}) async {
  await initializeAppHiveStorage();
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  try {
    return await container
        .read(defaultServerRefreshSchedulerProvider.notifier)
        .runBackgroundTask(task: task, inputData: inputData);
  } finally {
    container.dispose();
  }
}
