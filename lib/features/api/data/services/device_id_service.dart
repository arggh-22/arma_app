import 'package:android_id/android_id.dart';
import 'package:arma_proxy_vpn_client/features/api/data/datasources/auth_local_datasource.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

typedef PlatformDeviceIdReader = Future<String?> Function();
typedef UuidGenerator = String Function();

/// Resolves and persists a stable device identifier for API device auth.
class DeviceIdService {
  DeviceIdService(
    this._authLocalDatasource, {
    PlatformDeviceIdReader? platformDeviceIdReader,
    UuidGenerator? uuidGenerator,
  }) : _platformDeviceIdReader =
           platformDeviceIdReader ?? _defaultAndroidDeviceIdReader,
       _uuidGenerator = uuidGenerator ?? _defaultUuidGenerator;

  final AuthLocalDatasource _authLocalDatasource;
  final PlatformDeviceIdReader _platformDeviceIdReader;
  final UuidGenerator _uuidGenerator;

  static String _defaultUuidGenerator() => const Uuid().v4();

  static Future<String?> _defaultAndroidDeviceIdReader() async {
    try {
      await DeviceInfoPlugin().androidInfo;
      final id = await const AndroidId().getId();
      if (id == null) {
        return null;
      }
      final normalized = id.trim();
      return normalized.isEmpty ? null : normalized;
    } catch (_) {
      return null;
    }
  }

  /// Returns a persisted device id, resolving and persisting one when missing.
  ///
  /// If a stable Android id is available and differs from a legacy persisted
  /// value, the legacy value is migrated once.
  Future<String> resolveDeviceId() async {
    final stored = _authLocalDatasource.readDeviceId();
    final platformId = await _platformDeviceIdReader();
    final stableId =
        (platformId != null && platformId.trim().isNotEmpty)
            ? platformId.trim()
            : null;

    if (stableId != null) {
      if (stored != stableId) {
        await _authLocalDatasource.writeDeviceId(stableId);
      }
      return stableId;
    }

    if (stored != null && stored.isNotEmpty) {
      return stored;
    }

    final resolved = _uuidGenerator();
    await _authLocalDatasource.writeDeviceId(resolved);
    return resolved;
  }
}
