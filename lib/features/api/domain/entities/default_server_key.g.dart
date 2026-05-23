// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'default_server_key.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DefaultServerKey _$DefaultServerKeyFromJson(Map<String, dynamic> json) =>
    _DefaultServerKey(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      keyBody: json['keyBody'] as String,
      subscriptionUrl: json['subscriptionUrl'] as String,
      expireDate: DateTime.parse(json['expireDate'] as String),
      isActive: json['isActive'] as bool,
      status: json['status'] as String,
      usedTraffic: (json['usedTraffic'] as num).toInt(),
      dataLimit: (json['dataLimit'] as num).toInt(),
    );

Map<String, dynamic> _$DefaultServerKeyToJson(_DefaultServerKey instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'keyBody': instance.keyBody,
      'subscriptionUrl': instance.subscriptionUrl,
      'expireDate': instance.expireDate.toIso8601String(),
      'isActive': instance.isActive,
      'status': instance.status,
      'usedTraffic': instance.usedTraffic,
      'dataLimit': instance.dataLimit,
    };
