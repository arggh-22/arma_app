import 'package:hive_ce/hive_ce.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';

part 'server_config_model.g.dart';

/// Hive-persisted model for server configurations.
///
/// Uses explicit `@HiveField` indices with intentional gaps to allow
/// adding new fields in future schema versions without breaking existing data.
///
/// Index gaps: 3-4, 7-9, 16-19, 26(xhttpMode), 27-29, 36-39
@HiveType(typeId: 0)
class ServerConfigModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int protocolIndex;

  // GAP: 3-4 reserved for future protocol fields

  @HiveField(5)
  final String address;

  @HiveField(6)
  final int port;

  // GAP: 7-9 reserved for future connection fields

  @HiveField(10)
  final String? uuid;

  @HiveField(11)
  final String? password;

  @HiveField(12)
  final String encryption;

  @HiveField(13)
  final String network;

  @HiveField(14)
  final String security;

  @HiveField(15)
  final String? sni;

  // GAP: 16-19 reserved for future TLS fields

  @HiveField(20)
  final String? host;

  @HiveField(21)
  final String? path;

  @HiveField(22)
  final String? alpn;

  @HiveField(23)
  final String? fingerprint;

  @HiveField(24)
  final String? flow;

  @HiveField(25)
  final int alterId;

  // GAP: 26-29 reserved for future transport fields
  @HiveField(26)
  final String xhttpMode;

  @HiveField(30)
  final String? serviceName;

  @HiveField(31)
  final String? authority;

  @HiveField(32)
  final String? publicKey;

  @HiveField(33)
  final String? shortId;

  @HiveField(34)
  final String? spiderX;

  @HiveField(35)
  final String? method;

  // GAP: 36-39 reserved for future encryption fields

  @HiveField(40)
  final String? obfs;

  @HiveField(41)
  final String? obfsPassword;

  @HiveField(42)
  final String? subscriptionId;

  @HiveField(43)
  final String groupName;

  @HiveField(44)
  final int addedAtMillis;

  @HiveField(45)
  final int? upMbps;

  @HiveField(46)
  final int? downMbps;

  @HiveField(47)
  final bool insecure;

  ServerConfigModel({
    required this.id,
    required this.name,
    required this.protocolIndex,
    required this.address,
    required this.port,
    this.uuid,
    this.password,
    this.encryption = 'none',
    this.network = 'tcp',
    this.security = 'none',
    this.sni,
    this.host,
    this.path,
    this.alpn,
    this.fingerprint,
    this.flow,
    this.alterId = 0,
    this.xhttpMode = 'auto',
    this.serviceName,
    this.authority,
    this.publicKey,
    this.shortId,
    this.spiderX,
    this.method,
    this.obfs,
    this.obfsPassword,
    this.subscriptionId,
    this.groupName = 'Manual',
    required this.addedAtMillis,
    this.upMbps,
    this.downMbps,
    this.insecure = false,
  });

  /// Maps this Hive model to the domain [ServerConfig] entity.
  ServerConfig toDomain() {
    return ServerConfig(
      id: id,
      name: name,
      protocol: ProtocolType.values[protocolIndex],
      address: address,
      port: port,
      uuid: uuid,
      password: password,
      encryption: encryption,
      network: network,
      security: security,
      sni: sni,
      host: host,
      path: path,
      alpn: alpn,
      fingerprint: fingerprint,
      flow: flow,
      alterId: alterId,
      xhttpMode: xhttpMode,
      serviceName: serviceName,
      authority: authority,
      publicKey: publicKey,
      shortId: shortId,
      spiderX: spiderX,
      method: method,
      obfs: obfs,
      obfsPassword: obfsPassword,
      upMbps: upMbps,
      downMbps: downMbps,
      insecure: insecure,
      subscriptionId: subscriptionId,
      groupName: groupName,
      addedAt: DateTime.fromMillisecondsSinceEpoch(addedAtMillis),
    );
  }
}

/// Extension providing static factory to map domain entity to Hive model.
extension ServerConfigModelMapper on ServerConfigModel {
  /// Creates a [ServerConfigModel] from a domain [ServerConfig] entity.
  static ServerConfigModel fromDomain(ServerConfig config) {
    return ServerConfigModel(
      id: config.id,
      name: config.name,
      protocolIndex: config.protocol.index,
      address: config.address,
      port: config.port,
      uuid: config.uuid,
      password: config.password,
      encryption: config.encryption,
      network: config.network,
      security: config.security,
      sni: config.sni,
      host: config.host,
      path: config.path,
      alpn: config.alpn,
      fingerprint: config.fingerprint,
      flow: config.flow,
      alterId: config.alterId,
      xhttpMode: config.xhttpMode,
      serviceName: config.serviceName,
      authority: config.authority,
      publicKey: config.publicKey,
      shortId: config.shortId,
      spiderX: config.spiderX,
      method: config.method,
      obfs: config.obfs,
      obfsPassword: config.obfsPassword,
      upMbps: config.upMbps,
      downMbps: config.downMbps,
      insecure: config.insecure,
      subscriptionId: config.subscriptionId,
      groupName: config.groupName,
      addedAtMillis: config.addedAt.millisecondsSinceEpoch,
    );
  }
}
