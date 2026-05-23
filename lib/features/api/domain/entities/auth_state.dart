import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';
part 'auth_state.g.dart';

/// Canonical auth contract for device token state.
@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    String? token,
    DateTime? expiresAt,
    @Default(false) bool isAuthenticated,
    @Default(false) bool isGuest,
    int? userId,
    String? deviceId,
  }) = _AuthState;

  factory AuthState.fromJson(Map<String, dynamic> json) =>
      _$AuthStateFromJson(json);
}
