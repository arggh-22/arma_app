// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'server_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServerConfig {

/// Unique identifier (UUID v4).
 String get id;/// User-facing display name (e.g., "Tokyo #3").
 String get name;/// Proxy protocol type.
 ProtocolType get protocol;/// Server hostname or IP address.
 String get address;/// Server port number.
 int get port;/// UUID for VLESS/VMess authentication.
 String? get uuid;/// Password for Trojan/Shadowsocks/Hysteria2.
 String? get password;/// Encryption method (VMess: auto/aes-128-gcm/chacha20-poly1305/none).
 String get encryption;/// Transport network type: tcp, ws, grpc, h2, kcp.
 String get network;/// TLS security: none, tls, reality.
 String get security;/// TLS Server Name Indication.
 String? get sni;/// WebSocket/HTTP/2 host header.
 String? get host;/// WebSocket/HTTP/2 path.
 String? get path;/// ALPN negotiation protocols (comma-separated).
 String? get alpn;/// TLS fingerprint (e.g., chrome, firefox, safari).
 String? get fingerprint;/// VLESS XTLS flow control (e.g., xtls-rprx-vision).
 String? get flow;/// VMess alterId (legacy, usually 0 for AEAD).
 int get alterId;/// gRPC service name.
 String? get serviceName;/// gRPC authority.
 String? get authority;/// Reality public key.
 String? get publicKey;/// Reality short ID.
 String? get shortId;/// Reality spiderX path.
 String? get spiderX;/// Shadowsocks encryption method (e.g., aes-256-gcm, chacha20-ietf-poly1305).
 String? get method;/// Hysteria2 obfuscation type.
 String? get obfs;/// Hysteria2 obfuscation password.
 String? get obfsPassword;/// Hysteria2 upload bandwidth hint in Mbps (optional — auto-detect if null).
 int? get upMbps;/// Hysteria2 download bandwidth hint in Mbps (optional — auto-detect if null).
 int? get downMbps;/// Hysteria2: skip TLS certificate verification.
 bool get insecure;/// ID of the subscription this config belongs to (null = manual import).
 String? get subscriptionId;/// Group name for UI grouping.
 String get groupName;/// Timestamp when the config was added.
 DateTime get addedAt;
/// Create a copy of ServerConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerConfigCopyWith<ServerConfig> get copyWith => _$ServerConfigCopyWithImpl<ServerConfig>(this as ServerConfig, _$identity);

  /// Serializes this ServerConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerConfig&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.protocol, protocol) || other.protocol == protocol)&&(identical(other.address, address) || other.address == address)&&(identical(other.port, port) || other.port == port)&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.password, password) || other.password == password)&&(identical(other.encryption, encryption) || other.encryption == encryption)&&(identical(other.network, network) || other.network == network)&&(identical(other.security, security) || other.security == security)&&(identical(other.sni, sni) || other.sni == sni)&&(identical(other.host, host) || other.host == host)&&(identical(other.path, path) || other.path == path)&&(identical(other.alpn, alpn) || other.alpn == alpn)&&(identical(other.fingerprint, fingerprint) || other.fingerprint == fingerprint)&&(identical(other.flow, flow) || other.flow == flow)&&(identical(other.alterId, alterId) || other.alterId == alterId)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.authority, authority) || other.authority == authority)&&(identical(other.publicKey, publicKey) || other.publicKey == publicKey)&&(identical(other.shortId, shortId) || other.shortId == shortId)&&(identical(other.spiderX, spiderX) || other.spiderX == spiderX)&&(identical(other.method, method) || other.method == method)&&(identical(other.obfs, obfs) || other.obfs == obfs)&&(identical(other.obfsPassword, obfsPassword) || other.obfsPassword == obfsPassword)&&(identical(other.upMbps, upMbps) || other.upMbps == upMbps)&&(identical(other.downMbps, downMbps) || other.downMbps == downMbps)&&(identical(other.insecure, insecure) || other.insecure == insecure)&&(identical(other.subscriptionId, subscriptionId) || other.subscriptionId == subscriptionId)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,protocol,address,port,uuid,password,encryption,network,security,sni,host,path,alpn,fingerprint,flow,alterId,serviceName,authority,publicKey,shortId,spiderX,method,obfs,obfsPassword,upMbps,downMbps,insecure,subscriptionId,groupName,addedAt]);

@override
String toString() {
  return 'ServerConfig(id: $id, name: $name, protocol: $protocol, address: $address, port: $port, uuid: $uuid, password: $password, encryption: $encryption, network: $network, security: $security, sni: $sni, host: $host, path: $path, alpn: $alpn, fingerprint: $fingerprint, flow: $flow, alterId: $alterId, serviceName: $serviceName, authority: $authority, publicKey: $publicKey, shortId: $shortId, spiderX: $spiderX, method: $method, obfs: $obfs, obfsPassword: $obfsPassword, upMbps: $upMbps, downMbps: $downMbps, insecure: $insecure, subscriptionId: $subscriptionId, groupName: $groupName, addedAt: $addedAt)';
}


}

/// @nodoc
abstract mixin class $ServerConfigCopyWith<$Res>  {
  factory $ServerConfigCopyWith(ServerConfig value, $Res Function(ServerConfig) _then) = _$ServerConfigCopyWithImpl;
@useResult
$Res call({
 String id, String name, ProtocolType protocol, String address, int port, String? uuid, String? password, String encryption, String network, String security, String? sni, String? host, String? path, String? alpn, String? fingerprint, String? flow, int alterId, String? serviceName, String? authority, String? publicKey, String? shortId, String? spiderX, String? method, String? obfs, String? obfsPassword, int? upMbps, int? downMbps, bool insecure, String? subscriptionId, String groupName, DateTime addedAt
});




}
/// @nodoc
class _$ServerConfigCopyWithImpl<$Res>
    implements $ServerConfigCopyWith<$Res> {
  _$ServerConfigCopyWithImpl(this._self, this._then);

  final ServerConfig _self;
  final $Res Function(ServerConfig) _then;

/// Create a copy of ServerConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? protocol = null,Object? address = null,Object? port = null,Object? uuid = freezed,Object? password = freezed,Object? encryption = null,Object? network = null,Object? security = null,Object? sni = freezed,Object? host = freezed,Object? path = freezed,Object? alpn = freezed,Object? fingerprint = freezed,Object? flow = freezed,Object? alterId = null,Object? serviceName = freezed,Object? authority = freezed,Object? publicKey = freezed,Object? shortId = freezed,Object? spiderX = freezed,Object? method = freezed,Object? obfs = freezed,Object? obfsPassword = freezed,Object? upMbps = freezed,Object? downMbps = freezed,Object? insecure = null,Object? subscriptionId = freezed,Object? groupName = null,Object? addedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,protocol: null == protocol ? _self.protocol : protocol // ignore: cast_nullable_to_non_nullable
as ProtocolType,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,uuid: freezed == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String?,password: freezed == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String?,encryption: null == encryption ? _self.encryption : encryption // ignore: cast_nullable_to_non_nullable
as String,network: null == network ? _self.network : network // ignore: cast_nullable_to_non_nullable
as String,security: null == security ? _self.security : security // ignore: cast_nullable_to_non_nullable
as String,sni: freezed == sni ? _self.sni : sni // ignore: cast_nullable_to_non_nullable
as String?,host: freezed == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String?,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,alpn: freezed == alpn ? _self.alpn : alpn // ignore: cast_nullable_to_non_nullable
as String?,fingerprint: freezed == fingerprint ? _self.fingerprint : fingerprint // ignore: cast_nullable_to_non_nullable
as String?,flow: freezed == flow ? _self.flow : flow // ignore: cast_nullable_to_non_nullable
as String?,alterId: null == alterId ? _self.alterId : alterId // ignore: cast_nullable_to_non_nullable
as int,serviceName: freezed == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String?,authority: freezed == authority ? _self.authority : authority // ignore: cast_nullable_to_non_nullable
as String?,publicKey: freezed == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String?,shortId: freezed == shortId ? _self.shortId : shortId // ignore: cast_nullable_to_non_nullable
as String?,spiderX: freezed == spiderX ? _self.spiderX : spiderX // ignore: cast_nullable_to_non_nullable
as String?,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String?,obfs: freezed == obfs ? _self.obfs : obfs // ignore: cast_nullable_to_non_nullable
as String?,obfsPassword: freezed == obfsPassword ? _self.obfsPassword : obfsPassword // ignore: cast_nullable_to_non_nullable
as String?,upMbps: freezed == upMbps ? _self.upMbps : upMbps // ignore: cast_nullable_to_non_nullable
as int?,downMbps: freezed == downMbps ? _self.downMbps : downMbps // ignore: cast_nullable_to_non_nullable
as int?,insecure: null == insecure ? _self.insecure : insecure // ignore: cast_nullable_to_non_nullable
as bool,subscriptionId: freezed == subscriptionId ? _self.subscriptionId : subscriptionId // ignore: cast_nullable_to_non_nullable
as String?,groupName: null == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ServerConfig].
extension ServerConfigPatterns on ServerConfig {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServerConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServerConfig() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServerConfig value)  $default,){
final _that = this;
switch (_that) {
case _ServerConfig():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServerConfig value)?  $default,){
final _that = this;
switch (_that) {
case _ServerConfig() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  ProtocolType protocol,  String address,  int port,  String? uuid,  String? password,  String encryption,  String network,  String security,  String? sni,  String? host,  String? path,  String? alpn,  String? fingerprint,  String? flow,  int alterId,  String? serviceName,  String? authority,  String? publicKey,  String? shortId,  String? spiderX,  String? method,  String? obfs,  String? obfsPassword,  int? upMbps,  int? downMbps,  bool insecure,  String? subscriptionId,  String groupName,  DateTime addedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServerConfig() when $default != null:
return $default(_that.id,_that.name,_that.protocol,_that.address,_that.port,_that.uuid,_that.password,_that.encryption,_that.network,_that.security,_that.sni,_that.host,_that.path,_that.alpn,_that.fingerprint,_that.flow,_that.alterId,_that.serviceName,_that.authority,_that.publicKey,_that.shortId,_that.spiderX,_that.method,_that.obfs,_that.obfsPassword,_that.upMbps,_that.downMbps,_that.insecure,_that.subscriptionId,_that.groupName,_that.addedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  ProtocolType protocol,  String address,  int port,  String? uuid,  String? password,  String encryption,  String network,  String security,  String? sni,  String? host,  String? path,  String? alpn,  String? fingerprint,  String? flow,  int alterId,  String? serviceName,  String? authority,  String? publicKey,  String? shortId,  String? spiderX,  String? method,  String? obfs,  String? obfsPassword,  int? upMbps,  int? downMbps,  bool insecure,  String? subscriptionId,  String groupName,  DateTime addedAt)  $default,) {final _that = this;
switch (_that) {
case _ServerConfig():
return $default(_that.id,_that.name,_that.protocol,_that.address,_that.port,_that.uuid,_that.password,_that.encryption,_that.network,_that.security,_that.sni,_that.host,_that.path,_that.alpn,_that.fingerprint,_that.flow,_that.alterId,_that.serviceName,_that.authority,_that.publicKey,_that.shortId,_that.spiderX,_that.method,_that.obfs,_that.obfsPassword,_that.upMbps,_that.downMbps,_that.insecure,_that.subscriptionId,_that.groupName,_that.addedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  ProtocolType protocol,  String address,  int port,  String? uuid,  String? password,  String encryption,  String network,  String security,  String? sni,  String? host,  String? path,  String? alpn,  String? fingerprint,  String? flow,  int alterId,  String? serviceName,  String? authority,  String? publicKey,  String? shortId,  String? spiderX,  String? method,  String? obfs,  String? obfsPassword,  int? upMbps,  int? downMbps,  bool insecure,  String? subscriptionId,  String groupName,  DateTime addedAt)?  $default,) {final _that = this;
switch (_that) {
case _ServerConfig() when $default != null:
return $default(_that.id,_that.name,_that.protocol,_that.address,_that.port,_that.uuid,_that.password,_that.encryption,_that.network,_that.security,_that.sni,_that.host,_that.path,_that.alpn,_that.fingerprint,_that.flow,_that.alterId,_that.serviceName,_that.authority,_that.publicKey,_that.shortId,_that.spiderX,_that.method,_that.obfs,_that.obfsPassword,_that.upMbps,_that.downMbps,_that.insecure,_that.subscriptionId,_that.groupName,_that.addedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServerConfig implements ServerConfig {
  const _ServerConfig({required this.id, required this.name, required this.protocol, required this.address, required this.port, this.uuid, this.password, this.encryption = 'none', this.network = 'tcp', this.security = 'none', this.sni, this.host, this.path, this.alpn, this.fingerprint, this.flow, this.alterId = 0, this.serviceName, this.authority, this.publicKey, this.shortId, this.spiderX, this.method, this.obfs, this.obfsPassword, this.upMbps, this.downMbps, this.insecure = false, this.subscriptionId, this.groupName = 'Manual', required this.addedAt});
  factory _ServerConfig.fromJson(Map<String, dynamic> json) => _$ServerConfigFromJson(json);

/// Unique identifier (UUID v4).
@override final  String id;
/// User-facing display name (e.g., "Tokyo #3").
@override final  String name;
/// Proxy protocol type.
@override final  ProtocolType protocol;
/// Server hostname or IP address.
@override final  String address;
/// Server port number.
@override final  int port;
/// UUID for VLESS/VMess authentication.
@override final  String? uuid;
/// Password for Trojan/Shadowsocks/Hysteria2.
@override final  String? password;
/// Encryption method (VMess: auto/aes-128-gcm/chacha20-poly1305/none).
@override@JsonKey() final  String encryption;
/// Transport network type: tcp, ws, grpc, h2, kcp.
@override@JsonKey() final  String network;
/// TLS security: none, tls, reality.
@override@JsonKey() final  String security;
/// TLS Server Name Indication.
@override final  String? sni;
/// WebSocket/HTTP/2 host header.
@override final  String? host;
/// WebSocket/HTTP/2 path.
@override final  String? path;
/// ALPN negotiation protocols (comma-separated).
@override final  String? alpn;
/// TLS fingerprint (e.g., chrome, firefox, safari).
@override final  String? fingerprint;
/// VLESS XTLS flow control (e.g., xtls-rprx-vision).
@override final  String? flow;
/// VMess alterId (legacy, usually 0 for AEAD).
@override@JsonKey() final  int alterId;
/// gRPC service name.
@override final  String? serviceName;
/// gRPC authority.
@override final  String? authority;
/// Reality public key.
@override final  String? publicKey;
/// Reality short ID.
@override final  String? shortId;
/// Reality spiderX path.
@override final  String? spiderX;
/// Shadowsocks encryption method (e.g., aes-256-gcm, chacha20-ietf-poly1305).
@override final  String? method;
/// Hysteria2 obfuscation type.
@override final  String? obfs;
/// Hysteria2 obfuscation password.
@override final  String? obfsPassword;
/// Hysteria2 upload bandwidth hint in Mbps (optional — auto-detect if null).
@override final  int? upMbps;
/// Hysteria2 download bandwidth hint in Mbps (optional — auto-detect if null).
@override final  int? downMbps;
/// Hysteria2: skip TLS certificate verification.
@override@JsonKey() final  bool insecure;
/// ID of the subscription this config belongs to (null = manual import).
@override final  String? subscriptionId;
/// Group name for UI grouping.
@override@JsonKey() final  String groupName;
/// Timestamp when the config was added.
@override final  DateTime addedAt;

/// Create a copy of ServerConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServerConfigCopyWith<_ServerConfig> get copyWith => __$ServerConfigCopyWithImpl<_ServerConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServerConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServerConfig&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.protocol, protocol) || other.protocol == protocol)&&(identical(other.address, address) || other.address == address)&&(identical(other.port, port) || other.port == port)&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.password, password) || other.password == password)&&(identical(other.encryption, encryption) || other.encryption == encryption)&&(identical(other.network, network) || other.network == network)&&(identical(other.security, security) || other.security == security)&&(identical(other.sni, sni) || other.sni == sni)&&(identical(other.host, host) || other.host == host)&&(identical(other.path, path) || other.path == path)&&(identical(other.alpn, alpn) || other.alpn == alpn)&&(identical(other.fingerprint, fingerprint) || other.fingerprint == fingerprint)&&(identical(other.flow, flow) || other.flow == flow)&&(identical(other.alterId, alterId) || other.alterId == alterId)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.authority, authority) || other.authority == authority)&&(identical(other.publicKey, publicKey) || other.publicKey == publicKey)&&(identical(other.shortId, shortId) || other.shortId == shortId)&&(identical(other.spiderX, spiderX) || other.spiderX == spiderX)&&(identical(other.method, method) || other.method == method)&&(identical(other.obfs, obfs) || other.obfs == obfs)&&(identical(other.obfsPassword, obfsPassword) || other.obfsPassword == obfsPassword)&&(identical(other.upMbps, upMbps) || other.upMbps == upMbps)&&(identical(other.downMbps, downMbps) || other.downMbps == downMbps)&&(identical(other.insecure, insecure) || other.insecure == insecure)&&(identical(other.subscriptionId, subscriptionId) || other.subscriptionId == subscriptionId)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,protocol,address,port,uuid,password,encryption,network,security,sni,host,path,alpn,fingerprint,flow,alterId,serviceName,authority,publicKey,shortId,spiderX,method,obfs,obfsPassword,upMbps,downMbps,insecure,subscriptionId,groupName,addedAt]);

@override
String toString() {
  return 'ServerConfig(id: $id, name: $name, protocol: $protocol, address: $address, port: $port, uuid: $uuid, password: $password, encryption: $encryption, network: $network, security: $security, sni: $sni, host: $host, path: $path, alpn: $alpn, fingerprint: $fingerprint, flow: $flow, alterId: $alterId, serviceName: $serviceName, authority: $authority, publicKey: $publicKey, shortId: $shortId, spiderX: $spiderX, method: $method, obfs: $obfs, obfsPassword: $obfsPassword, upMbps: $upMbps, downMbps: $downMbps, insecure: $insecure, subscriptionId: $subscriptionId, groupName: $groupName, addedAt: $addedAt)';
}


}

/// @nodoc
abstract mixin class _$ServerConfigCopyWith<$Res> implements $ServerConfigCopyWith<$Res> {
  factory _$ServerConfigCopyWith(_ServerConfig value, $Res Function(_ServerConfig) _then) = __$ServerConfigCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, ProtocolType protocol, String address, int port, String? uuid, String? password, String encryption, String network, String security, String? sni, String? host, String? path, String? alpn, String? fingerprint, String? flow, int alterId, String? serviceName, String? authority, String? publicKey, String? shortId, String? spiderX, String? method, String? obfs, String? obfsPassword, int? upMbps, int? downMbps, bool insecure, String? subscriptionId, String groupName, DateTime addedAt
});




}
/// @nodoc
class __$ServerConfigCopyWithImpl<$Res>
    implements _$ServerConfigCopyWith<$Res> {
  __$ServerConfigCopyWithImpl(this._self, this._then);

  final _ServerConfig _self;
  final $Res Function(_ServerConfig) _then;

/// Create a copy of ServerConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? protocol = null,Object? address = null,Object? port = null,Object? uuid = freezed,Object? password = freezed,Object? encryption = null,Object? network = null,Object? security = null,Object? sni = freezed,Object? host = freezed,Object? path = freezed,Object? alpn = freezed,Object? fingerprint = freezed,Object? flow = freezed,Object? alterId = null,Object? serviceName = freezed,Object? authority = freezed,Object? publicKey = freezed,Object? shortId = freezed,Object? spiderX = freezed,Object? method = freezed,Object? obfs = freezed,Object? obfsPassword = freezed,Object? upMbps = freezed,Object? downMbps = freezed,Object? insecure = null,Object? subscriptionId = freezed,Object? groupName = null,Object? addedAt = null,}) {
  return _then(_ServerConfig(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,protocol: null == protocol ? _self.protocol : protocol // ignore: cast_nullable_to_non_nullable
as ProtocolType,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,uuid: freezed == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as String?,password: freezed == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String?,encryption: null == encryption ? _self.encryption : encryption // ignore: cast_nullable_to_non_nullable
as String,network: null == network ? _self.network : network // ignore: cast_nullable_to_non_nullable
as String,security: null == security ? _self.security : security // ignore: cast_nullable_to_non_nullable
as String,sni: freezed == sni ? _self.sni : sni // ignore: cast_nullable_to_non_nullable
as String?,host: freezed == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String?,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,alpn: freezed == alpn ? _self.alpn : alpn // ignore: cast_nullable_to_non_nullable
as String?,fingerprint: freezed == fingerprint ? _self.fingerprint : fingerprint // ignore: cast_nullable_to_non_nullable
as String?,flow: freezed == flow ? _self.flow : flow // ignore: cast_nullable_to_non_nullable
as String?,alterId: null == alterId ? _self.alterId : alterId // ignore: cast_nullable_to_non_nullable
as int,serviceName: freezed == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String?,authority: freezed == authority ? _self.authority : authority // ignore: cast_nullable_to_non_nullable
as String?,publicKey: freezed == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String?,shortId: freezed == shortId ? _self.shortId : shortId // ignore: cast_nullable_to_non_nullable
as String?,spiderX: freezed == spiderX ? _self.spiderX : spiderX // ignore: cast_nullable_to_non_nullable
as String?,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String?,obfs: freezed == obfs ? _self.obfs : obfs // ignore: cast_nullable_to_non_nullable
as String?,obfsPassword: freezed == obfsPassword ? _self.obfsPassword : obfsPassword // ignore: cast_nullable_to_non_nullable
as String?,upMbps: freezed == upMbps ? _self.upMbps : upMbps // ignore: cast_nullable_to_non_nullable
as int?,downMbps: freezed == downMbps ? _self.downMbps : downMbps // ignore: cast_nullable_to_non_nullable
as int?,insecure: null == insecure ? _self.insecure : insecure // ignore: cast_nullable_to_non_nullable
as bool,subscriptionId: freezed == subscriptionId ? _self.subscriptionId : subscriptionId // ignore: cast_nullable_to_non_nullable
as String?,groupName: null == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
