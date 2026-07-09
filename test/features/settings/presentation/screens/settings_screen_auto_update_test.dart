import 'package:arma_proxy_vpn_client/core/l10n/app_localizations.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/default_server_refresh_scheduler_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/domain/entities/default_server_auto_update_interval.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/xray_version_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/foundation.dart';
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

    final context = tester.element(find.byType(SettingsScreen));
    final l10n = AppLocalizations.of(context)!;
    expect(find.text(l10n.armaVpnSettingsSection), findsOneWidget);
    expect(find.text(l10n.defaultServerAutoUpdateDisabled), findsOneWidget);
    expect(find.text(l10n.defaultServerAutoUpdateEvery12Hours), findsOneWidget);
    expect(find.text(l10n.defaultServerAutoUpdateEvery24Hours), findsOneWidget);
    expect(find.text(l10n.defaultServerAutoUpdateEvery7Days), findsOneWidget);

    final armaHeaderTop = tester
        .getTopLeft(find.text(l10n.armaVpnSettingsSection))
        .dy;
    final generalHeaderTop = tester
        .getTopLeft(find.text(l10n.generalSection))
        .dy;
    expect(armaHeaderTop, lessThan(generalHeaderTop));

    // The tiles are wrapped in a RadioGroup ancestor that owns the selected
    // value, so assert on the group rather than a per-tile groupValue.
    final radioGroup = tester
        .widget<RadioGroup<DefaultServerAutoUpdateInterval>>(
          find.ancestor(
            of: find.byKey(const Key('default-server-auto-update-disabled')),
            matching: find.byType(RadioGroup<DefaultServerAutoUpdateInterval>),
          ),
        );
    expect(radioGroup.groupValue, DefaultServerAutoUpdateInterval.disabled);
  });

  testWidgets(
    'selecting interval persists value and triggers scheduler update',
    (tester) async {
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
    },
  );

  testWidgets('renders localized labels when locale is Russian', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{'locale': 'ru'});
    final prefs = await SharedPreferences.getInstance();
    final fakeScheduler = _FakeSchedulerClient();

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      fakeScheduler: fakeScheduler,
      locale: const Locale('ru'),
    );

    expect(find.text('Настройки Arma VPN'), findsOneWidget);
    expect(find.text('Отключено'), findsOneWidget);
    expect(find.text('Каждые 12 часов'), findsOneWidget);
  });

  testWidgets(
    'shows overdue refresh updated indicator when scheduler reports recent refresh',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final fakeScheduler = _FakeSchedulerClient();

      await _pumpSettingsScreen(
        tester,
        prefs: prefs,
        fakeScheduler: fakeScheduler,
        schedulerState: DefaultServerRefreshSchedulerState(
          hasRecentOverdueRefresh: true,
          lastOverdueRefreshAt: DateTime.utc(2026, 1, 2, 3, 4),
        ),
      );

      final context = tester.element(find.byType(SettingsScreen));
      final l10n = AppLocalizations.of(context)!;
      expect(
        find.byKey(const Key('default-server-overdue-refresh-indicator')),
        findsOneWidget,
      );
      expect(
        find.text(l10n.defaultServerAutoUpdateUpdatedIndicatorLabel),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'hides overdue refresh updated indicator with default scheduler state',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final fakeScheduler = _FakeSchedulerClient();

      await _pumpSettingsScreen(
        tester,
        prefs: prefs,
        fakeScheduler: fakeScheduler,
      );

      expect(
        find.byKey(const Key('default-server-overdue-refresh-indicator')),
        findsNothing,
      );
    },
  );

  testWidgets('desktop centers settings in a constrained (<=720) column', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      await _pumpSettingsScreen(
        tester,
        prefs: prefs,
        fakeScheduler: _FakeSchedulerClient(),
      );

      final context = tester.element(find.byType(SettingsScreen));
      final l10n = AppLocalizations.of(context)!;
      // Content is not stretched to the full 1400px window width.
      expect(
        tester.getSize(find.text(l10n.armaVpnSettingsSection).first).width,
        lessThan(720),
      );
      // Settings still render.
      expect(find.text(l10n.generalSection), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

Future<void> _pumpSettingsScreen(
  WidgetTester tester, {
  required SharedPreferences prefs,
  required _FakeSchedulerClient fakeScheduler,
  DefaultServerRefreshSchedulerState? schedulerState,
  Locale? locale,
}) async {
  final overrides = [
    sharedPreferencesProvider.overrideWithValue(prefs),
    defaultServerBackgroundSchedulerClientProvider.overrideWithValue(
      fakeScheduler,
    ),
    xrayVersionProvider.overrideWith((ref) async => '1.0.0'),
  ];
  if (schedulerState != null) {
    overrides.add(
      defaultServerRefreshSchedulerProvider.overrideWith(
        () => _TestDefaultServerRefreshSchedulerNotifier(schedulerState),
      ),
    );
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _TestDefaultServerRefreshSchedulerNotifier
    extends DefaultServerRefreshSchedulerNotifier {
  _TestDefaultServerRefreshSchedulerNotifier(this._state);

  final DefaultServerRefreshSchedulerState _state;

  @override
  DefaultServerRefreshSchedulerState build() => _state;
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
