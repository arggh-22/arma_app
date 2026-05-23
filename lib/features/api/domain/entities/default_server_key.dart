import 'package:freezed_annotation/freezed_annotation.dart';

part 'default_server_key.freezed.dart';
part 'default_server_key.g.dart';

/// Canonical VPN key contract consumed by default-server features.
@freezed
abstract class DefaultServerKey with _$DefaultServerKey {
  const factory DefaultServerKey({
    required int id,
    required String name,
    required String keyBody,
    required String subscriptionUrl,
    required DateTime expireDate,
    required bool isActive,
    required String status,
    required int usedTraffic,
    required int dataLimit,
  }) = _DefaultServerKey;

  factory DefaultServerKey.fromJson(Map<String, dynamic> json) =>
      _$DefaultServerKeyFromJson(json);
}
