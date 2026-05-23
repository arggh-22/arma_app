import 'package:arma_proxy_vpn_client/features/api/domain/entities/auth_state.dart';

enum AuthRepositoryFailureType {
  authenticationFailed,
  unauthorizedAfterRetry,
  missingToken,
}

class AuthRepositoryException implements Exception {
  const AuthRepositoryException({
    required this.type,
    required this.message,
    this.cause,
  });

  final AuthRepositoryFailureType type;
  final String message;
  final Object? cause;

  @override
  String toString() => 'AuthRepositoryException($type)';
}

abstract class AuthRepository {
  Future<AuthState> authenticateDevice();

  Future<String> getValidToken();

  Future<T> executeWithAuthRetry<T>(Future<T> Function(String token) action);
}
