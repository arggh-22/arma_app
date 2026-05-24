import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/default_server_refresh_scheduler_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/domain/entities/default_server_auto_update_interval.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/xray_version_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows Arma VPN interval controls at top with disabled default', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final fakeScheduler = _FakeSchedulerClient();

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      fakeScheduler: fakeScheduler,
    );

    expect(find.text('Arma VPN settings'), findsOneWidget);
    expect(find.text('Disabled'), findsOneWidget);
    expect(find.text('Every 12 Hours'), findsOneWidget);
    expect(find.text('Every 24 Hours'), findsOneWidget);
    expect(find.text('Every 7 Days'), findsOneWidget);

    final armaHeaderTop = tester.getTopLeft(find.text('Arma VPN settings')).dy;
    final generalHeaderTop = tester.getTopLeft(find.text('General')).dy;
    expect(armaHeaderTop, lessThan(generalHeaderTop));

    final disabledRadio = tester.widget<RadioListTile<DefaultServerAutoUpdateInterval>>(
      find.byKey(const Key('default-server-auto-update-disabled')),
    );
    expect(disabledRadio.groupValue, DefaultServerAutoUpdateInterval.disabled);
  });

  testWidgets('selecting interval persists value and triggers scheduler update', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final fakeScheduler = _FakeSchedulerClient();

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      fakeScheduler: fakeScheduler,
    );

    await tester.tap(find.byKey(const Key('default-server-auto-update-12h')));
    await tester.pumpAndSettle();

    expect(prefs.getString('default_server_auto_update_interval'), '12h');
    expect(fakeScheduler.periodicRegistrations, hasLength(1));
    expect(
      fakeScheduler.periodicRegistrations.single.frequency,
      const Duration(hours: 12),
    );
  });
}

Future<void> _pumpSettingsScreen(
  WidgetTester tester, {
  required SharedPreferences prefs,
  required _FakeSchedulerClient fakeScheduler,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        defaultServerBackgroundSchedulerClientProvider.overrideWithValue(
          fakeScheduler,
        ),
        xrayVersionProvider.overrideWith((ref) async => '1.0.0'),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeSchedulerClient implements DefaultServerBackgroundSchedulerClient {
  final List<_PeriodicRegistration> periodicRegistrations = [];
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
  }) async {}

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
