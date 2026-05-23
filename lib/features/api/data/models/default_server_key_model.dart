import 'package:arma_proxy_vpn_client/features/api/domain/entities/default_server_key.dart';

/// DTO for `/keys/` payload entry.
class DefaultServerKeyModel {
  const DefaultServerKeyModel({
    required this.id,
    required this.name,
    required this.keyBody,
    required this.subscriptionUrl,
    required this.expireDate,
    required this.isActive,
    required this.status,
    required this.usedTraffic,
    required this.dataLimit,
  });

  final int id;
  final String name;
  final String keyBody;
  final String subscriptionUrl;
  final DateTime expireDate;
  final bool isActive;
  final String status;
  final int usedTraffic;
  final int dataLimit;

  factory DefaultServerKeyModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final keyBody = json['key_body'];
    final subscriptionUrl = json['subscription_url'];
    final expireDateRaw = json['expire_date'];
    final isActive = json['is_active'];
    final status = json['status'];
    final usedTraffic = json['used_traffic'];
    final dataLimit = json['data_limit'];

    if (id is! int) {
      throw const FormatException('Invalid key payload: id');
    }
    if (name is! String || name.isEmpty) {
      throw const FormatException('Invalid key payload: name');
    }
    if (keyBody is! String || keyBody.isEmpty) {
      throw const FormatException('Invalid key payload: key_body');
    }
    if (subscriptionUrl is! String || subscriptionUrl.isEmpty) {
      throw const FormatException('Invalid key payload: subscription_url');
    }
    if (expireDateRaw is! String) {
      throw const FormatException('Invalid key payload: expire_date');
    }
    final expireDate = DateTime.tryParse(expireDateRaw);
    if (expireDate == null) {
      throw const FormatException('Invalid key payload: expire_date');
    }
    if (isActive is! bool) {
      throw const FormatException('Invalid key payload: is_active');
    }
    if (status is! String || status.isEmpty) {
      throw const FormatException('Invalid key payload: status');
    }
    if (usedTraffic is! int) {
      throw const FormatException('Invalid key payload: used_traffic');
    }
    if (dataLimit is! int) {
      throw const FormatException('Invalid key payload: data_limit');
    }

    return DefaultServerKeyModel(
      id: id,
      name: name,
      keyBody: keyBody,
      subscriptionUrl: subscriptionUrl,
      expireDate: expireDate,
      isActive: isActive,
      status: status,
      usedTraffic: usedTraffic,
      dataLimit: dataLimit,
    );
  }

  DefaultServerKey toDomain() {
    return DefaultServerKey(
      id: id,
      name: name,
      keyBody: keyBody,
      subscriptionUrl: subscriptionUrl,
      expireDate: expireDate,
      isActive: isActive,
      status: status,
      usedTraffic: usedTraffic,
      dataLimit: dataLimit,
    );
  }
}
