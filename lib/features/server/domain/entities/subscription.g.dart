// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Subscription _$SubscriptionFromJson(Map<String, dynamic> json) =>
    _Subscription(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      userAgent: json['userAgent'] as String? ?? '',
      uploadBytes: (json['uploadBytes'] as num?)?.toInt(),
      downloadBytes: (json['downloadBytes'] as num?)?.toInt(),
      totalBytes: (json['totalBytes'] as num?)?.toInt(),
      expireDate: json['expireDate'] == null
          ? null
          : DateTime.parse(json['expireDate'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      addedAt: DateTime.parse(json['addedAt'] as String),
      autoUpdate: json['autoUpdate'] as bool? ?? true,
      supportUrl: json['supportUrl'] as String?,
      webPageUrl: json['webPageUrl'] as String?,
    );

Map<String, dynamic> _$SubscriptionToJson(_Subscription instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'url': instance.url,
      'userAgent': instance.userAgent,
      'uploadBytes': instance.uploadBytes,
      'downloadBytes': instance.downloadBytes,
      'totalBytes': instance.totalBytes,
      'expireDate': instance.expireDate?.toIso8601String(),
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'addedAt': instance.addedAt.toIso8601String(),
      'autoUpdate': instance.autoUpdate,
      'supportUrl': instance.supportUrl,
      'webPageUrl': instance.webPageUrl,
    };
