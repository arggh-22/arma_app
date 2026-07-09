import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:arma_proxy_vpn_client/features/api/domain/entities/auth_state.dart';
import 'package:hive_ce/hive_ce.dart';

typedef ReadSecret = Future<String?> Function(String key);
typedef WriteSecret = Future<void> Function(String key, String value);

/// Encrypted local persistence for API auth state and resolved device id.
class AuthLocalDatasource {
  AuthLocalDatasource(this._box);

  static const authStateBoxName = 'auth_state';
  static const authStateStorageKey = 'current';
  static const deviceIdStorageKey = 'device_id';
  static const authCipherKeyStorageKey = 'auth_box_cipher_key_v1';

  final Box<dynamic> _box;

  /// Opens the `auth_state` box using AES encryption key material loaded from
  /// secure storage.
  static Future<Box<dynamic>> openEncryptedBox({
    required Directory hiveDir,
    required ReadSecret readSecret,
    required WriteSecret writeSecret,
  }) async {
    final keyBytes = await _resolveCipherKey(
      readSecret: readSecret,
      writeSecret: writeSecret,
    );
    final cipher = HiveAesCipher(keyBytes);

    try {
      return await Hive.openBox<dynamic>(
        authStateBoxName,
        encryptionCipher: cipher,
      );
    } catch (_) {
      if (Hive.isBoxOpen(authStateBoxName)) {
        await Hive.box<dynamic>(authStateBoxName).close();
      }

      for (final ext in ['.hive', '.lock']) {
        final f = File('${hiveDir.path}/$authStateBoxName$ext');
        if (await f.exists()) {
          await f.delete();
        }
      }

      return Hive.openBox<dynamic>(authStateBoxName, encryptionCipher: cipher);
    }
  }

  static Future<Uint8List> _resolveCipherKey({
    required ReadSecret readSecret,
    required WriteSecret writeSecret,
  }) async {
    final encoded = await readSecret(authCipherKeyStorageKey);
    if (encoded != null && encoded.isNotEmpty) {
      try {
        final decoded = base64Decode(encoded);
        if (decoded.length == 32) {
          return decoded;
        }
      } catch (_) {
        // Generate and rewrite a valid key below.
      }
    }

    final key = Hive.generateSecureKey();
    await writeSecret(authCipherKeyStorageKey, base64Encode(key));
    return Uint8List.fromList(key);
  }

  AuthState readAuthState() {
    final raw = _box.get(authStateStorageKey);
    if (raw == null) {
      return const AuthState();
    }

    try {
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return AuthState.fromJson(decoded);
        }
      }

      if (raw is Map) {
        return AuthState.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (_) {
      // Corrupt payloads degrade to signed-out state.
    }

    return const AuthState();
  }

  Future<void> writeAuthState(AuthState state) =>
      _box.put(authStateStorageKey, jsonEncode(state.toJson()));

  Future<void> clearAuthState() => _box.delete(authStateStorageKey);

  String? readDeviceId() {
    final value = _box.get(deviceIdStorageKey);
    if (value is! String) {
      return null;
    }
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  Future<void> writeDeviceId(String deviceId) =>
      _box.put(deviceIdStorageKey, deviceId.trim());
}
