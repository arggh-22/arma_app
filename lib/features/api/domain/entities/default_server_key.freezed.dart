// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'default_server_key.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DefaultServerKey {

 int get id; String get name; String get keyBody; String get subscriptionUrl; DateTime get expireDate; bool get isActive; String get status; int get usedTraffic; int get dataLimit;
/// Create a copy of DefaultServerKey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DefaultServerKeyCopyWith<DefaultServerKey> get copyWith => _$DefaultServerKeyCopyWithImpl<DefaultServerKey>(this as DefaultServerKey, _$identity);

  /// Serializes this DefaultServerKey to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DefaultServerKey&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.keyBody, keyBody) || other.keyBody == keyBody)&&(identical(other.subscriptionUrl, subscriptionUrl) || other.subscriptionUrl == subscriptionUrl)&&(identical(other.expireDate, expireDate) || other.expireDate == expireDate)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.status, status) || other.status == status)&&(identical(other.usedTraffic, usedTraffic) || other.usedTraffic == usedTraffic)&&(identical(other.dataLimit, dataLimit) || other.dataLimit == dataLimit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,keyBody,subscriptionUrl,expireDate,isActive,status,usedTraffic,dataLimit);

@override
String toString() {
  return 'DefaultServerKey(id: $id, name: $name, keyBody: $keyBody, subscriptionUrl: $subscriptionUrl, expireDate: $expireDate, isActive: $isActive, status: $status, usedTraffic: $usedTraffic, dataLimit: $dataLimit)';
}


}

/// @nodoc
abstract mixin class $DefaultServerKeyCopyWith<$Res>  {
  factory $DefaultServerKeyCopyWith(DefaultServerKey value, $Res Function(DefaultServerKey) _then) = _$DefaultServerKeyCopyWithImpl;
@useResult
$Res call({
 int id, String name, String keyBody, String subscriptionUrl, DateTime expireDate, bool isActive, String status, int usedTraffic, int dataLimit
});




}
/// @nodoc
class _$DefaultServerKeyCopyWithImpl<$Res>
    implements $DefaultServerKeyCopyWith<$Res> {
  _$DefaultServerKeyCopyWithImpl(this._self, this._then);

  final DefaultServerKey _self;
  final $Res Function(DefaultServerKey) _then;

/// Create a copy of DefaultServerKey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? keyBody = null,Object? subscriptionUrl = null,Object? expireDate = null,Object? isActive = null,Object? status = null,Object? usedTraffic = null,Object? dataLimit = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,keyBody: null == keyBody ? _self.keyBody : keyBody // ignore: cast_nullable_to_non_nullable
as String,subscriptionUrl: null == subscriptionUrl ? _self.subscriptionUrl : subscriptionUrl // ignore: cast_nullable_to_non_nullable
as String,expireDate: null == expireDate ? _self.expireDate : expireDate // ignore: cast_nullable_to_non_nullable
as DateTime,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,usedTraffic: null == usedTraffic ? _self.usedTraffic : usedTraffic // ignore: cast_nullable_to_non_nullable
as int,dataLimit: null == dataLimit ? _self.dataLimit : dataLimit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DefaultServerKey].
extension DefaultServerKeyPatterns on DefaultServerKey {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DefaultServerKey value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DefaultServerKey() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DefaultServerKey value)  $default,){
final _that = this;
switch (_that) {
case _DefaultServerKey():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DefaultServerKey value)?  $default,){
final _that = this;
switch (_that) {
case _DefaultServerKey() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String keyBody,  String subscriptionUrl,  DateTime expireDate,  bool isActive,  String status,  int usedTraffic,  int dataLimit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DefaultServerKey() when $default != null:
return $default(_that.id,_that.name,_that.keyBody,_that.subscriptionUrl,_that.expireDate,_that.isActive,_that.status,_that.usedTraffic,_that.dataLimit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String keyBody,  String subscriptionUrl,  DateTime expireDate,  bool isActive,  String status,  int usedTraffic,  int dataLimit)  $default,) {final _that = this;
switch (_that) {
case _DefaultServerKey():
return $default(_that.id,_that.name,_that.keyBody,_that.subscriptionUrl,_that.expireDate,_that.isActive,_that.status,_that.usedTraffic,_that.dataLimit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String keyBody,  String subscriptionUrl,  DateTime expireDate,  bool isActive,  String status,  int usedTraffic,  int dataLimit)?  $default,) {final _that = this;
switch (_that) {
case _DefaultServerKey() when $default != null:
return $default(_that.id,_that.name,_that.keyBody,_that.subscriptionUrl,_that.expireDate,_that.isActive,_that.status,_that.usedTraffic,_that.dataLimit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DefaultServerKey implements DefaultServerKey {
  const _DefaultServerKey({required this.id, required this.name, required this.keyBody, required this.subscriptionUrl, required this.expireDate, required this.isActive, required this.status, required this.usedTraffic, required this.dataLimit});
  factory _DefaultServerKey.fromJson(Map<String, dynamic> json) => _$DefaultServerKeyFromJson(json);

@override final  int id;
@override final  String name;
@override final  String keyBody;
@override final  String subscriptionUrl;
@override final  DateTime expireDate;
@override final  bool isActive;
@override final  String status;
@override final  int usedTraffic;
@override final  int dataLimit;

/// Create a copy of DefaultServerKey
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DefaultServerKeyCopyWith<_DefaultServerKey> get copyWith => __$DefaultServerKeyCopyWithImpl<_DefaultServerKey>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DefaultServerKeyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DefaultServerKey&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.keyBody, keyBody) || other.keyBody == keyBody)&&(identical(other.subscriptionUrl, subscriptionUrl) || other.subscriptionUrl == subscriptionUrl)&&(identical(other.expireDate, expireDate) || other.expireDate == expireDate)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.status, status) || other.status == status)&&(identical(other.usedTraffic, usedTraffic) || other.usedTraffic == usedTraffic)&&(identical(other.dataLimit, dataLimit) || other.dataLimit == dataLimit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,keyBody,subscriptionUrl,expireDate,isActive,status,usedTraffic,dataLimit);

@override
String toString() {
  return 'DefaultServerKey(id: $id, name: $name, keyBody: $keyBody, subscriptionUrl: $subscriptionUrl, expireDate: $expireDate, isActive: $isActive, status: $status, usedTraffic: $usedTraffic, dataLimit: $dataLimit)';
}


}

/// @nodoc
abstract mixin class _$DefaultServerKeyCopyWith<$Res> implements $DefaultServerKeyCopyWith<$Res> {
  factory _$DefaultServerKeyCopyWith(_DefaultServerKey value, $Res Function(_DefaultServerKey) _then) = __$DefaultServerKeyCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String keyBody, String subscriptionUrl, DateTime expireDate, bool isActive, String status, int usedTraffic, int dataLimit
});




}
/// @nodoc
class __$DefaultServerKeyCopyWithImpl<$Res>
    implements _$DefaultServerKeyCopyWith<$Res> {
  __$DefaultServerKeyCopyWithImpl(this._self, this._then);

  final _DefaultServerKey _self;
  final $Res Function(_DefaultServerKey) _then;

/// Create a copy of DefaultServerKey
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? keyBody = null,Object? subscriptionUrl = null,Object? expireDate = null,Object? isActive = null,Object? status = null,Object? usedTraffic = null,Object? dataLimit = null,}) {
  return _then(_DefaultServerKey(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,keyBody: null == keyBody ? _self.keyBody : keyBody // ignore: cast_nullable_to_non_nullable
as String,subscriptionUrl: null == subscriptionUrl ? _self.subscriptionUrl : subscriptionUrl // ignore: cast_nullable_to_non_nullable
as String,expireDate: null == expireDate ? _self.expireDate : expireDate // ignore: cast_nullable_to_non_nullable
as DateTime,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,usedTraffic: null == usedTraffic ? _self.usedTraffic : usedTraffic // ignore: cast_nullable_to_non_nullable
as int,dataLimit: null == dataLimit ? _self.dataLimit : dataLimit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
