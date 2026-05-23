// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthState _$AuthStateFromJson(Map<String, dynamic> json) => _AuthState(
  token: json['token'] as String?,
  expiresAt: json['expiresAt'] == null
      ? null
      : DateTime.parse(json['expiresAt'] as String),
  isAuthenticated: json['isAuthenticated'] as bool? ?? false,
  isGuest: json['isGuest'] as bool? ?? false,
  userId: (json['userId'] as num?)?.toInt(),
  deviceId: json['deviceId'] as String?,
);

Map<String, dynamic> _$AuthStateToJson(_AuthState instance) =>
    <String, dynamic>{
      'token': instance.token,
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'isAuthenticated': instance.isAuthenticated,
      'isGuest': instance.isGuest,
      'userId': instance.userId,
      'deviceId': instance.deviceId,
    };
