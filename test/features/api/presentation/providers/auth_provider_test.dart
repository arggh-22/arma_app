import 'dart:io';

import 'package:arma_proxy_vpn_client/core/constants/app_constants.dart';
import 'package:arma_proxy_vpn_client/features/api/data/datasources/auth_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/api/data/repositories/auth_repository_impl.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/auth_state.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/repositories/auth_repository.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  group('auth providers', () {
    late Directory hiveDir;
    late Box<dynamic> authBox;
    late AuthLocalDatasource datasource;
    late Map<String, String> secureStorage;

    setUp(() async {
      hiveDir = await Directory.systemTemp.createTemp('auth_provider_test_');
      Hive.init(hiveDir.path);
      secureStorage = <String, String>{};
      authBox = await AuthLocalDatasource.openEncryptedBox(
        hiveDir: hiveDir,
        readSecret: (key) async => secureStorage[key],
        writeSecret: (key, value) async => secureStorage[key] = value,
      );
      datasource = AuthLocalDatasource(authBox);
    });

    tearDown(() async {
      if (authBox.isOpen) {
        await authBox.close();
      }
      Hive.close();
      if (await hiveDir.exists()) {
        await hiveDir.delete(recursive: true);
      }
    });

    test('authStateNotifier restores persisted auth state on init', () async {
      await datasource.writeAuthState(
        AuthState(
          token: 'persisted-token',
          isAuthenticated: true,
          isGuest: true,
          userId: 42,
          deviceId: 'device-abc',
          expiresAt: DateTime.utc(2026, 1, 1, 12, 0, 0),
        ),
      );

      final container = ProviderContainer(
        overrides: [authLocalDatasourceProvider.overrideWithValue(datasource)],
      );
      addTearDown(container.dispose);

      final restored = await container.read(authStateProvider.future);

      expect(restored.token, 'persisted-token');
      expect(restored.isAuthenticated, isTrue);
      expect(restored.userId, 42);
    });

    test('authTokenProvider returns valid token from repository', () async {
      final fakeRepo = _FakeAuthRepository(token: 'repo-token');
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
          authLocalDatasourceProvider.overrideWithValue(datasource),
        ],
      );
      addTearDown(container.dispose);

      final token = await container.read(authTokenProvider.future);

      expect(token, 'repo-token');
      expect(fakeRepo.getValidTokenCalls, 1);
    });

    test(
      'authRepositoryProvider uses shared AppConstants app version',
      () async {
        final container = ProviderContainer(
          overrides: [
            authLocalDatasourceProvider.overrideWithValue(datasource),
          ],
        );
        addTearDown(container.dispose);

        final repository = container.read(authRepositoryProvider);

        expect(repository, isA<AuthRepositoryImpl>());
        expect(
          (repository as AuthRepositoryImpl).appVersion,
          AppConstants.appVersion,
        );
      },
    );

    test(
      'authStatusRefreshProvider triggers authenticateDevice and updates state',
      () async {
        final refreshedState = AuthState(
          token: 'fresh-token',
          isAuthenticated: true,
          isGuest: false,
          userId: 7,
          deviceId: 'device-id',
          expiresAt: DateTime.utc(2026, 1, 2),
        );
        final fakeRepo = _FakeAuthRepository(
          token: 'repo-token',
          refreshedState: refreshedState,
        );
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
            authLocalDatasourceProvider.overrideWithValue(datasource),
          ],
        );
        addTearDown(container.dispose);

        final refresh = container.read(authStatusRefreshProvider);
        final result = await refresh();

        expect(fakeRepo.authenticateDeviceCalls, 1);
        expect(result, refreshedState);
        expect(container.read(authStateProvider).value, refreshedState);
      },
    );
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({required this.token, AuthState? refreshedState})
    : _refreshedState =
          refreshedState ??
          const AuthState(
            token: 'token',
            isAuthenticated: true,
            isGuest: true,
            userId: 1,
          );

  final String token;
  final AuthState _refreshedState;
  int authenticateDeviceCalls = 0;
  int getValidTokenCalls = 0;

  @override
  Future<AuthState> authenticateDevice() async {
    authenticateDeviceCalls++;
    return _refreshedState;
  }

  @override
  Future<T> executeWithAuthRetry<T>(
    Future<T> Function(String token) action,
  ) async {
    return action(token);
  }

  @override
  Future<String> getValidToken() async {
    getValidTokenCalls++;
    return token;
  }
}
