import 'dart:io';

import 'package:arma_proxy_vpn_client/features/api/data/datasources/api_client.dart';
import 'package:arma_proxy_vpn_client/features/api/data/datasources/auth_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/api/data/repositories/auth_repository_impl.dart';
import 'package:arma_proxy_vpn_client/features/api/data/services/device_id_service.dart';
import 'package:arma_proxy_vpn_client/features/api/data/models/device_auth_response.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/auth_state.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AuthRepositoryImpl', () {
    late Directory hiveDir;
    late Box<dynamic> authBox;
    late AuthLocalDatasource authLocalDatasource;
    late Map<String, String> secureStorage;
    late _StubApiClient apiClient;
    late DeviceIdService deviceIdService;
    late DateTime fixedNow;

    setUp(() async {
      fixedNow = DateTime.utc(2026, 1, 1, 10, 0, 0);
      hiveDir = await Directory.systemTemp.createTemp('auth_repo_test_');
      Hive.init(hiveDir.path);
      secureStorage = <String, String>{};
      authBox = await AuthLocalDatasource.openEncryptedBox(
        hiveDir: hiveDir,
        readSecret: (key) async => secureStorage[key],
        writeSecret: (key, value) async => secureStorage[key] = value,
      );
      authLocalDatasource = AuthLocalDatasource(authBox);
      apiClient = _StubApiClient();
      deviceIdService = DeviceIdService(
        authLocalDatasource,
        platformDeviceIdReader: () async => 'android-device-id',
      );
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

    test('getValidToken returns persisted token when not near expiry', () async {
      final repository = AuthRepositoryImpl(
        apiClient: apiClient,
        authLocalDatasource: authLocalDatasource,
        deviceIdService: deviceIdService,
        appVersion: '1.2.3',
        osType: 'android',
        now: () => fixedNow,
      );
      await authLocalDatasource.writeAuthState(
        AuthState(
          token: 'persisted-token',
          isAuthenticated: true,
          expiresAt: fixedNow.add(const Duration(minutes: 30)),
          deviceId: 'android-device-id',
          userId: 1,
        ),
      );

      final token = await repository.getValidToken();

      expect(token, 'persisted-token');
      expect(apiClient.authCalls, 0);
    });

    test('getValidToken re-authenticates when token is near expiry', () async {
      apiClient.deviceAuthHandler = ({required deviceId, required osType, required appVersion}) async {
        return const DeviceAuthResponse(token: 'new-token', isGuest: false, userId: 42);
      };
      final repository = AuthRepositoryImpl(
        apiClient: apiClient,
        authLocalDatasource: authLocalDatasource,
        deviceIdService: deviceIdService,
        appVersion: '1.2.3',
        osType: 'android',
        now: () => fixedNow,
      );
      await authLocalDatasource.writeAuthState(
        AuthState(
          token: 'old-token',
          isAuthenticated: true,
          expiresAt: fixedNow.add(const Duration(minutes: 4)),
          deviceId: 'android-device-id',
          userId: 1,
        ),
      );

      final token = await repository.getValidToken();

      expect(token, 'new-token');
      expect(apiClient.authCalls, 1);
      expect(authLocalDatasource.readAuthState().token, 'new-token');
    });

    test('executeWithAuthRetry clears stale token, re-auths, and replays once on 401', () async {
      apiClient.deviceAuthHandler = ({required deviceId, required osType, required appVersion}) async {
        return const DeviceAuthResponse(token: 'fresh-token', isGuest: false, userId: 7);
      };
      final repository = AuthRepositoryImpl(
        apiClient: apiClient,
        authLocalDatasource: authLocalDatasource,
        deviceIdService: deviceIdService,
        appVersion: '1.2.3',
        osType: 'android',
        now: () => fixedNow,
      );
      await authLocalDatasource.writeAuthState(
        AuthState(
          token: 'stale-token',
          isAuthenticated: true,
          expiresAt: fixedNow.add(const Duration(hours: 1)),
          deviceId: 'android-device-id',
          userId: 1,
        ),
      );
      var requestCalls = 0;

      final result = await repository.executeWithAuthRetry<String>((token) async {
        requestCalls++;
        if (requestCalls == 1) {
          throw const ApiClientException(
            type: ApiClientErrorType.unauthorized,
            message: 'Unauthorized request',
            statusCode: 401,
          );
        }
        return 'ok:$token';
      });

      expect(result, 'ok:fresh-token');
      expect(requestCalls, 2);
      expect(apiClient.authCalls, 1);
    });

    test('executeWithAuthRetry throws typed auth failure when re-auth fails', () async {
      apiClient.deviceAuthHandler = ({required deviceId, required osType, required appVersion}) {
        throw const ApiClientException(
          type: ApiClientErrorType.network,
          message: 'network',
        );
      };
      final repository = AuthRepositoryImpl(
        apiClient: apiClient,
        authLocalDatasource: authLocalDatasource,
        deviceIdService: deviceIdService,
        appVersion: '1.2.3',
        osType: 'android',
        now: () => fixedNow,
      );
      await authLocalDatasource.writeAuthState(
        AuthState(
          token: 'stale-token',
          isAuthenticated: true,
          expiresAt: fixedNow.add(const Duration(hours: 1)),
          deviceId: 'android-device-id',
          userId: 1,
        ),
      );

      final call = repository.executeWithAuthRetry<void>((_) async {
        throw const ApiClientException(
          type: ApiClientErrorType.unauthorized,
          message: 'Unauthorized request',
          statusCode: 401,
        );
      });

      await expectLater(
        call,
        throwsA(
          isA<AuthRepositoryException>().having(
            (e) => e.type,
            'type',
            AuthRepositoryFailureType.authenticationFailed,
          ),
        ),
      );
    });
  });
}

class _StubApiClient extends ApiClient {
  _StubApiClient()
    : super(
        client: MockClient((_) async => throw UnimplementedError()),
        baseUrl: 'https://example.com/api/v1',
      );

  int authCalls = 0;

  Future<DeviceAuthResponse> Function({
    required String deviceId,
    required String osType,
    required String appVersion,
  })? deviceAuthHandler;

  @override
  Future<DeviceAuthResponse> authenticateDevice({
    required String deviceId,
    required String osType,
    required String appVersion,
  }) async {
    authCalls++;
    final handler = deviceAuthHandler;
    if (handler == null) {
      return const DeviceAuthResponse(
        token: 'default-token',
        isGuest: false,
        userId: 1,
      );
    }
    return handler(
      deviceId: deviceId,
      osType: osType,
      appVersion: appVersion,
    );
  }

  @override
  Future<List<dynamic>> getKeys(String token) {
    throw UnimplementedError();
  }
}
