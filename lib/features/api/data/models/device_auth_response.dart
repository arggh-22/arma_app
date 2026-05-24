import 'package:arma_proxy_vpn_client/features/api/domain/entities/auth_state.dart';

/// API constants for `/auth/device/` requests and auth headers.
class DeviceAuthApiFields {
  DeviceAuthApiFields._();

  static const deviceId = 'device_id';
  static const osType = 'os_type';
  static const appVersion = 'app_version';
  static const authorization = 'Authorization';
  static const authorizationTokenPrefix = 'Token';
}

/// DTO for `/auth/device/` response payload.
class DeviceAuthResponse {
  const DeviceAuthResponse({
    required this.token,
    required this.isGuest,
    required this.userId,
    this.announcementTitle,
    this.announcementText,
  });

  final String token;
  final bool isGuest;
  final int userId;
  final String? announcementTitle;
  final String? announcementText;

  static const _tokenKey = 'token';
  static const _isGuestKey = 'is_guest';
  static const _userIdKey = 'user_id';
  static const _announcementTitleKey = 'announcement_title';
  static const _announcementTextKey = 'announcement_text';

  factory DeviceAuthResponse.fromJson(Map<String, dynamic> json) {
    final token = json[_tokenKey];
    final isGuest = json[_isGuestKey];
    final userId = json[_userIdKey];
    final announcementTitle = json[_announcementTitleKey];
    final announcementText = json[_announcementTextKey];

    if (token is! String || token.isEmpty) {
      throw const FormatException('Invalid auth response: token');
    }
    if (isGuest is! bool) {
      throw const FormatException('Invalid auth response: is_guest');
    }
    if (userId is! int) {
      throw const FormatException('Invalid auth response: user_id');
    }
    if (announcementTitle != null && announcementTitle is! String) {
      throw const FormatException('Invalid auth response: announcement_title');
    }
    if (announcementText != null && announcementText is! String) {
      throw const FormatException('Invalid auth response: announcement_text');
    }

    return DeviceAuthResponse(
      token: token,
      isGuest: isGuest,
      userId: userId,
      announcementTitle: announcementTitle as String?,
      announcementText: announcementText as String?,
    );
  }

  AuthState toDomain({String? deviceId, DateTime? expiresAt}) {
    return AuthState(
      token: token,
      expiresAt: expiresAt,
      isAuthenticated: token.isNotEmpty,
      isGuest: isGuest,
      userId: userId,
      deviceId: deviceId,
      announcementTitle: announcementTitle,
      announcementText: announcementText,
    );
  }
}
