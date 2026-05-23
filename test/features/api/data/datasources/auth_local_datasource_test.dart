import 'dart:convert';
import 'dart:io';

import 'package:arma_proxy_vpn_client/features/api/data/datasources/auth_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  group('AuthLocalDatasource', () {
    late Directory hiveDir;
    late Map<String, String> secureStorage;
    late Box<dynamic> authBox;
    late AuthLocalDatasource datasource;

    setUp(() async {
      hiveDir = await Directory.systemTemp.createTemp('auth_local_ds_test_');
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

    test('persists auth payload and restores equivalent AuthState', () async {
      final expected = AuthState(
        token: 'token-123',
        isGuest: true,
        userId: 42,
        deviceId: 'device-abc',
        isAuthenticated: true,
        expiresAt: DateTime.utc(2026, 1, 1),
      );

      await datasource.writeAuthState(expected);
      final restored = datasource.readAuthState();

      expect(restored, expected);
    });

    test('clears auth state to unauthenticated default', () async {
      await datasource.writeAuthState(
        const AuthState(
          token: 'token-123',
          isAuthenticated: true,
        ),
      );

      await datasource.clearAuthState();
      final restored = datasource.readAuthState();

      expect(restored, const AuthState());
    });

    test('returns unauthenticated default on corrupt payload', () async {
      await authBox.put(
        AuthLocalDatasource.authStateStorageKey,
        jsonEncode(<String, dynamic>{'token': 42}),
      );

      final restored = datasource.readAuthState();

      expect(restored, const AuthState());
    });

    test('persists and loads device id', () async {
      await datasource.writeDeviceId('device-xyz');

      final restored = datasource.readDeviceId();

      expect(restored, 'device-xyz');
    });

    test('stores and reuses cipher key material from secure storage', () async {
      final firstKey = secureStorage[AuthLocalDatasource.authCipherKeyStorageKey];
      expect(firstKey, isNotNull);

      await authBox.close();
      authBox = await AuthLocalDatasource.openEncryptedBox(
        hiveDir: hiveDir,
        readSecret: (key) async => secureStorage[key],
        writeSecret: (key, value) async => secureStorage[key] = value,
      );

      expect(
        secureStorage[AuthLocalDatasource.authCipherKeyStorageKey],
        firstKey,
      );
    });
  });
}
