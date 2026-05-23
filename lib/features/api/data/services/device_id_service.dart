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
      final info = await DeviceInfoPlugin().androidInfo;
      final id = info.id.trim();
      return id.isEmpty ? null : id;
    } catch (_) {
      return null;
    }
  }

  /// Returns a persisted device id, resolving and persisting one when missing.
  Future<String> resolveDeviceId() async {
    final stored = _authLocalDatasource.readDeviceId();
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }

    final platformId = await _platformDeviceIdReader();
    final resolved =
        (platformId != null && platformId.trim().isNotEmpty)
            ? platformId.trim()
            : _uuidGenerator();

    await _authLocalDatasource.writeDeviceId(resolved);
    return resolved;
  }
}
