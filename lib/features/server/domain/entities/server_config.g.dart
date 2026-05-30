// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServerConfig _$ServerConfigFromJson(Map<String, dynamic> json) =>
    _ServerConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      protocol: $enumDecode(_$ProtocolTypeEnumMap, json['protocol']),
      address: json['address'] as String,
      port: (json['port'] as num).toInt(),
      uuid: json['uuid'] as String?,
      password: json['password'] as String?,
      encryption: json['encryption'] as String? ?? 'none',
      network: json['network'] as String? ?? 'tcp',
      xhttpMode: json['xhttpMode'] as String? ?? 'auto',
      security: json['security'] as String? ?? 'none',
      sni: json['sni'] as String?,
      host: json['host'] as String?,
      path: json['path'] as String?,
      alpn: json['alpn'] as String?,
      fingerprint: json['fingerprint'] as String?,
      flow: json['flow'] as String?,
      alterId: (json['alterId'] as num?)?.toInt() ?? 0,
      serviceName: json['serviceName'] as String?,
      authority: json['authority'] as String?,
      publicKey: json['publicKey'] as String?,
      shortId: json['shortId'] as String?,
      spiderX: json['spiderX'] as String?,
      method: json['method'] as String?,
      obfs: json['obfs'] as String?,
      obfsPassword: json['obfsPassword'] as String?,
      upMbps: (json['upMbps'] as num?)?.toInt(),
      downMbps: (json['downMbps'] as num?)?.toInt(),
      insecure: json['insecure'] as bool? ?? false,
      subscriptionId: json['subscriptionId'] as String?,
      groupName: json['groupName'] as String? ?? 'Manual',
      addedAt: DateTime.parse(json['addedAt'] as String),
    );

Map<String, dynamic> _$ServerConfigToJson(_ServerConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'protocol': _$ProtocolTypeEnumMap[instance.protocol]!,
      'address': instance.address,
      'port': instance.port,
      'uuid': instance.uuid,
      'password': instance.password,
      'encryption': instance.encryption,
      'network': instance.network,
      'xhttpMode': instance.xhttpMode,
      'security': instance.security,
      'sni': instance.sni,
      'host': instance.host,
      'path': instance.path,
      'alpn': instance.alpn,
      'fingerprint': instance.fingerprint,
      'flow': instance.flow,
      'alterId': instance.alterId,
      'serviceName': instance.serviceName,
      'authority': instance.authority,
      'publicKey': instance.publicKey,
      'shortId': instance.shortId,
      'spiderX': instance.spiderX,
      'method': instance.method,
      'obfs': instance.obfs,
      'obfsPassword': instance.obfsPassword,
      'upMbps': instance.upMbps,
      'downMbps': instance.downMbps,
      'insecure': instance.insecure,
      'subscriptionId': instance.subscriptionId,
      'groupName': instance.groupName,
      'addedAt': instance.addedAt.toIso8601String(),
    };

const _$ProtocolTypeEnumMap = {
  ProtocolType.vless: 'vless',
  ProtocolType.vmess: 'vmess',
  ProtocolType.trojan: 'trojan',
  ProtocolType.shadowsocks: 'shadowsocks',
  ProtocolType.hysteria2: 'hysteria2',
};
