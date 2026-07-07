// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Subscription {

/// Unique identifier (UUID v4).
 String get id;/// User-facing display name.
 String get name;/// Subscription URL to fetch server configs from.
 String get url;/// Custom User-Agent header for this subscription (CONF-08).
 String get userAgent;/// Upload bytes consumed (from subscription-userinfo header).
 int? get uploadBytes;/// Download bytes consumed (from subscription-userinfo header).
 int? get downloadBytes;/// Total bandwidth quota in bytes (from subscription-userinfo header).
 int? get totalBytes;/// Subscription expiration date (from subscription-userinfo header).
 DateTime? get expireDate;/// When the subscription was last fetched/updated.
 DateTime get lastUpdated;/// When the subscription was added to the app.
 DateTime get addedAt;/// Whether to auto-refresh this subscription on app launch (CONF-07).
 bool get autoUpdate;/// `support-url` header — opened from the "Support" action.
 String? get supportUrl;/// `profile-web-page-url` header — opened from the "Renew"/"Cabinet" action.
 String? get webPageUrl;
/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionCopyWith<Subscription> get copyWith => _$SubscriptionCopyWithImpl<Subscription>(this as Subscription, _$identity);

  /// Serializes this Subscription to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Subscription&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.userAgent, userAgent) || other.userAgent == userAgent)&&(identical(other.uploadBytes, uploadBytes) || other.uploadBytes == uploadBytes)&&(identical(other.downloadBytes, downloadBytes) || other.downloadBytes == downloadBytes)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&(identical(other.expireDate, expireDate) || other.expireDate == expireDate)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.autoUpdate, autoUpdate) || other.autoUpdate == autoUpdate)&&(identical(other.supportUrl, supportUrl) || other.supportUrl == supportUrl)&&(identical(other.webPageUrl, webPageUrl) || other.webPageUrl == webPageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,url,userAgent,uploadBytes,downloadBytes,totalBytes,expireDate,lastUpdated,addedAt,autoUpdate,supportUrl,webPageUrl);

@override
String toString() {
  return 'Subscription(id: $id, name: $name, url: $url, userAgent: $userAgent, uploadBytes: $uploadBytes, downloadBytes: $downloadBytes, totalBytes: $totalBytes, expireDate: $expireDate, lastUpdated: $lastUpdated, addedAt: $addedAt, autoUpdate: $autoUpdate, supportUrl: $supportUrl, webPageUrl: $webPageUrl)';
}


}

/// @nodoc
abstract mixin class $SubscriptionCopyWith<$Res>  {
  factory $SubscriptionCopyWith(Subscription value, $Res Function(Subscription) _then) = _$SubscriptionCopyWithImpl;
@useResult
$Res call({
 String id, String name, String url, String userAgent, int? uploadBytes, int? downloadBytes, int? totalBytes, DateTime? expireDate, DateTime lastUpdated, DateTime addedAt, bool autoUpdate, String? supportUrl, String? webPageUrl
});




}
/// @nodoc
class _$SubscriptionCopyWithImpl<$Res>
    implements $SubscriptionCopyWith<$Res> {
  _$SubscriptionCopyWithImpl(this._self, this._then);

  final Subscription _self;
  final $Res Function(Subscription) _then;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? url = null,Object? userAgent = null,Object? uploadBytes = freezed,Object? downloadBytes = freezed,Object? totalBytes = freezed,Object? expireDate = freezed,Object? lastUpdated = null,Object? addedAt = null,Object? autoUpdate = null,Object? supportUrl = freezed,Object? webPageUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,userAgent: null == userAgent ? _self.userAgent : userAgent // ignore: cast_nullable_to_non_nullable
as String,uploadBytes: freezed == uploadBytes ? _self.uploadBytes : uploadBytes // ignore: cast_nullable_to_non_nullable
as int?,downloadBytes: freezed == downloadBytes ? _self.downloadBytes : downloadBytes // ignore: cast_nullable_to_non_nullable
as int?,totalBytes: freezed == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int?,expireDate: freezed == expireDate ? _self.expireDate : expireDate // ignore: cast_nullable_to_non_nullable
as DateTime?,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime,autoUpdate: null == autoUpdate ? _self.autoUpdate : autoUpdate // ignore: cast_nullable_to_non_nullable
as bool,supportUrl: freezed == supportUrl ? _self.supportUrl : supportUrl // ignore: cast_nullable_to_non_nullable
as String?,webPageUrl: freezed == webPageUrl ? _self.webPageUrl : webPageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Subscription].
extension SubscriptionPatterns on Subscription {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Subscription value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Subscription() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Subscription value)  $default,){
final _that = this;
switch (_that) {
case _Subscription():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Subscription value)?  $default,){
final _that = this;
switch (_that) {
case _Subscription() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String url,  String userAgent,  int? uploadBytes,  int? downloadBytes,  int? totalBytes,  DateTime? expireDate,  DateTime lastUpdated,  DateTime addedAt,  bool autoUpdate,  String? supportUrl,  String? webPageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that.id,_that.name,_that.url,_that.userAgent,_that.uploadBytes,_that.downloadBytes,_that.totalBytes,_that.expireDate,_that.lastUpdated,_that.addedAt,_that.autoUpdate,_that.supportUrl,_that.webPageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String url,  String userAgent,  int? uploadBytes,  int? downloadBytes,  int? totalBytes,  DateTime? expireDate,  DateTime lastUpdated,  DateTime addedAt,  bool autoUpdate,  String? supportUrl,  String? webPageUrl)  $default,) {final _that = this;
switch (_that) {
case _Subscription():
return $default(_that.id,_that.name,_that.url,_that.userAgent,_that.uploadBytes,_that.downloadBytes,_that.totalBytes,_that.expireDate,_that.lastUpdated,_that.addedAt,_that.autoUpdate,_that.supportUrl,_that.webPageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String url,  String userAgent,  int? uploadBytes,  int? downloadBytes,  int? totalBytes,  DateTime? expireDate,  DateTime lastUpdated,  DateTime addedAt,  bool autoUpdate,  String? supportUrl,  String? webPageUrl)?  $default,) {final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that.id,_that.name,_that.url,_that.userAgent,_that.uploadBytes,_that.downloadBytes,_that.totalBytes,_that.expireDate,_that.lastUpdated,_that.addedAt,_that.autoUpdate,_that.supportUrl,_that.webPageUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Subscription implements Subscription {
  const _Subscription({required this.id, required this.name, required this.url, this.userAgent = '', this.uploadBytes, this.downloadBytes, this.totalBytes, this.expireDate, required this.lastUpdated, required this.addedAt, this.autoUpdate = true, this.supportUrl, this.webPageUrl});
  factory _Subscription.fromJson(Map<String, dynamic> json) => _$SubscriptionFromJson(json);

/// Unique identifier (UUID v4).
@override final  String id;
/// User-facing display name.
@override final  String name;
/// Subscription URL to fetch server configs from.
@override final  String url;
/// Custom User-Agent header for this subscription (CONF-08).
@override@JsonKey() final  String userAgent;
/// Upload bytes consumed (from subscription-userinfo header).
@override final  int? uploadBytes;
/// Download bytes consumed (from subscription-userinfo header).
@override final  int? downloadBytes;
/// Total bandwidth quota in bytes (from subscription-userinfo header).
@override final  int? totalBytes;
/// Subscription expiration date (from subscription-userinfo header).
@override final  DateTime? expireDate;
/// When the subscription was last fetched/updated.
@override final  DateTime lastUpdated;
/// When the subscription was added to the app.
@override final  DateTime addedAt;
/// Whether to auto-refresh this subscription on app launch (CONF-07).
@override@JsonKey() final  bool autoUpdate;
/// `support-url` header — opened from the "Support" action.
@override final  String? supportUrl;
/// `profile-web-page-url` header — opened from the "Renew"/"Cabinet" action.
@override final  String? webPageUrl;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionCopyWith<_Subscription> get copyWith => __$SubscriptionCopyWithImpl<_Subscription>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Subscription&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.userAgent, userAgent) || other.userAgent == userAgent)&&(identical(other.uploadBytes, uploadBytes) || other.uploadBytes == uploadBytes)&&(identical(other.downloadBytes, downloadBytes) || other.downloadBytes == downloadBytes)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&(identical(other.expireDate, expireDate) || other.expireDate == expireDate)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.autoUpdate, autoUpdate) || other.autoUpdate == autoUpdate)&&(identical(other.supportUrl, supportUrl) || other.supportUrl == supportUrl)&&(identical(other.webPageUrl, webPageUrl) || other.webPageUrl == webPageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,url,userAgent,uploadBytes,downloadBytes,totalBytes,expireDate,lastUpdated,addedAt,autoUpdate,supportUrl,webPageUrl);

@override
String toString() {
  return 'Subscription(id: $id, name: $name, url: $url, userAgent: $userAgent, uploadBytes: $uploadBytes, downloadBytes: $downloadBytes, totalBytes: $totalBytes, expireDate: $expireDate, lastUpdated: $lastUpdated, addedAt: $addedAt, autoUpdate: $autoUpdate, supportUrl: $supportUrl, webPageUrl: $webPageUrl)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionCopyWith<$Res> implements $SubscriptionCopyWith<$Res> {
  factory _$SubscriptionCopyWith(_Subscription value, $Res Function(_Subscription) _then) = __$SubscriptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String url, String userAgent, int? uploadBytes, int? downloadBytes, int? totalBytes, DateTime? expireDate, DateTime lastUpdated, DateTime addedAt, bool autoUpdate, String? supportUrl, String? webPageUrl
});




}
/// @nodoc
class __$SubscriptionCopyWithImpl<$Res>
    implements _$SubscriptionCopyWith<$Res> {
  __$SubscriptionCopyWithImpl(this._self, this._then);

  final _Subscription _self;
  final $Res Function(_Subscription) _then;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? url = null,Object? userAgent = null,Object? uploadBytes = freezed,Object? downloadBytes = freezed,Object? totalBytes = freezed,Object? expireDate = freezed,Object? lastUpdated = null,Object? addedAt = null,Object? autoUpdate = null,Object? supportUrl = freezed,Object? webPageUrl = freezed,}) {
  return _then(_Subscription(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,userAgent: null == userAgent ? _self.userAgent : userAgent // ignore: cast_nullable_to_non_nullable
as String,uploadBytes: freezed == uploadBytes ? _self.uploadBytes : uploadBytes // ignore: cast_nullable_to_non_nullable
as int?,downloadBytes: freezed == downloadBytes ? _self.downloadBytes : downloadBytes // ignore: cast_nullable_to_non_nullable
as int?,totalBytes: freezed == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int?,expireDate: freezed == expireDate ? _self.expireDate : expireDate // ignore: cast_nullable_to_non_nullable
as DateTime?,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime,autoUpdate: null == autoUpdate ? _self.autoUpdate : autoUpdate // ignore: cast_nullable_to_non_nullable
as bool,supportUrl: freezed == supportUrl ? _self.supportUrl : supportUrl // ignore: cast_nullable_to_non_nullable
as String?,webPageUrl: freezed == webPageUrl ? _self.webPageUrl : webPageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
