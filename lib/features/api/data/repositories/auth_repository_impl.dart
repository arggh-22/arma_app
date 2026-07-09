import 'package:arma_proxy_vpn_client/features/api/data/datasources/api_client.dart';
import 'package:arma_proxy_vpn_client/features/api/data/datasources/auth_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/api/data/services/device_id_service.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/auth_state.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/repositories/auth_repository.dart';

/// Token lifecycle orchestration for device-auth API flows.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required ApiClient apiClient,
    required AuthLocalDatasource authLocalDatasource,
    required DeviceIdService deviceIdService,
    required this.appVersion,
    required this.osType,
    DateTime Function()? now,
    this.tokenLifetime = const Duration(hours: 24),
    this.refreshThreshold = const Duration(minutes: 5),
  }) : _apiClient = apiClient,
       _authLocalDatasource = authLocalDatasource,
       _deviceIdService = deviceIdService,
       _now = now ?? DateTime.now;

  final ApiClient _apiClient;
  final AuthLocalDatasource _authLocalDatasource;
  final DeviceIdService _deviceIdService;
  final String appVersion;
  final String osType;
  final DateTime Function() _now;
  final Duration tokenLifetime;
  final Duration refreshThreshold;

  @override
  Future<AuthState> authenticateDevice() async {
    try {
      final deviceId = await _deviceIdService.resolveDeviceId();
      final response = await _apiClient.authenticateDevice(
        deviceId: deviceId,
        osType: osType,
        appVersion: appVersion,
      );
      final state = response.toDomain(
        deviceId: deviceId,
        expiresAt: _now().add(tokenLifetime),
      );
      final token = state.token?.trim();
      final normalized = state.copyWith(
        token: token,
        isAuthenticated: token != null && token.isNotEmpty,
      );
      await _authLocalDatasource.writeAuthState(normalized);
      return normalized;
    } catch (error) {
      throw AuthRepositoryException(
        type: AuthRepositoryFailureType.authenticationFailed,
        message: 'Device authentication failed',
        cause: error,
      );
    }
  }

  @override
  Future<String> getValidToken() async {
    final state = _authLocalDatasource.readAuthState();
    if (_isUsableToken(state)) {
      return state.token!;
    }

    final refreshed = await authenticateDevice();
    if (!_isUsableToken(refreshed)) {
      throw const AuthRepositoryException(
        type: AuthRepositoryFailureType.missingToken,
        message: 'Authentication did not return a usable token',
      );
    }
    return refreshed.token!;
  }

  @override
  Future<T> executeWithAuthRetry<T>(
    Future<T> Function(String token) action,
  ) async {
    final initialToken = await getValidToken();

    try {
      return await action(initialToken);
    } on ApiClientException catch (error) {
      if (error.type != ApiClientErrorType.unauthorized) {
        rethrow;
      }
      await _authLocalDatasource.clearAuthState();

      AuthState refreshed;
      try {
        refreshed = await authenticateDevice();
      } on AuthRepositoryException {
        rethrow;
      } catch (reauthError) {
        throw AuthRepositoryException(
          type: AuthRepositoryFailureType.authenticationFailed,
          message: 'Device re-authentication failed',
          cause: reauthError,
        );
      }

      if (!_isUsableToken(refreshed)) {
        throw const AuthRepositoryException(
          type: AuthRepositoryFailureType.missingToken,
          message: 'Re-authentication produced an empty token',
        );
      }

      try {
        return await action(refreshed.token!);
      } on ApiClientException catch (retryError) {
        if (retryError.type == ApiClientErrorType.unauthorized) {
          throw AuthRepositoryException(
            type: AuthRepositoryFailureType.unauthorizedAfterRetry,
            message: 'Unauthorized after one re-auth retry',
            cause: retryError,
          );
        }
        rethrow;
      }
    }
  }

  bool _isUsableToken(AuthState state) {
    final token = state.token?.trim();
    if (token == null || token.isEmpty || !state.isAuthenticated) {
      return false;
    }
    final expiresAt = state.expiresAt;
    if (expiresAt == null) {
      return false;
    }
    return expiresAt.isAfter(_now().add(refreshThreshold));
  }
}
