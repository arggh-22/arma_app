// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthState {

 String? get token; DateTime? get expiresAt; bool get isAuthenticated; bool get isGuest; int? get userId; String? get deviceId; String? get announcementTitle; String? get announcementText;
/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthStateCopyWith<AuthState> get copyWith => _$AuthStateCopyWithImpl<AuthState>(this as AuthState, _$identity);

  /// Serializes this AuthState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthState&&(identical(other.token, token) || other.token == token)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.isAuthenticated, isAuthenticated) || other.isAuthenticated == isAuthenticated)&&(identical(other.isGuest, isGuest) || other.isGuest == isGuest)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.announcementTitle, announcementTitle) || other.announcementTitle == announcementTitle)&&(identical(other.announcementText, announcementText) || other.announcementText == announcementText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token,expiresAt,isAuthenticated,isGuest,userId,deviceId,announcementTitle,announcementText);

@override
String toString() {
  return 'AuthState(token: $token, expiresAt: $expiresAt, isAuthenticated: $isAuthenticated, isGuest: $isGuest, userId: $userId, deviceId: $deviceId, announcementTitle: $announcementTitle, announcementText: $announcementText)';
}


}

/// @nodoc
abstract mixin class $AuthStateCopyWith<$Res>  {
  factory $AuthStateCopyWith(AuthState value, $Res Function(AuthState) _then) = _$AuthStateCopyWithImpl;
@useResult
$Res call({
 String? token, DateTime? expiresAt, bool isAuthenticated, bool isGuest, int? userId, String? deviceId, String? announcementTitle, String? announcementText
});




}
/// @nodoc
class _$AuthStateCopyWithImpl<$Res>
    implements $AuthStateCopyWith<$Res> {
  _$AuthStateCopyWithImpl(this._self, this._then);

  final AuthState _self;
  final $Res Function(AuthState) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = freezed,Object? expiresAt = freezed,Object? isAuthenticated = null,Object? isGuest = null,Object? userId = freezed,Object? deviceId = freezed,Object? announcementTitle = freezed,Object? announcementText = freezed,}) {
  return _then(_self.copyWith(
token: freezed == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isAuthenticated: null == isAuthenticated ? _self.isAuthenticated : isAuthenticated // ignore: cast_nullable_to_non_nullable
as bool,isGuest: null == isGuest ? _self.isGuest : isGuest // ignore: cast_nullable_to_non_nullable
as bool,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int?,deviceId: freezed == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String?,announcementTitle: freezed == announcementTitle ? _self.announcementTitle : announcementTitle // ignore: cast_nullable_to_non_nullable
as String?,announcementText: freezed == announcementText ? _self.announcementText : announcementText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthState].
extension AuthStatePatterns on AuthState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthState value)  $default,){
final _that = this;
switch (_that) {
case _AuthState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthState value)?  $default,){
final _that = this;
switch (_that) {
case _AuthState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? token,  DateTime? expiresAt,  bool isAuthenticated,  bool isGuest,  int? userId,  String? deviceId,  String? announcementTitle,  String? announcementText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthState() when $default != null:
return $default(_that.token,_that.expiresAt,_that.isAuthenticated,_that.isGuest,_that.userId,_that.deviceId,_that.announcementTitle,_that.announcementText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? token,  DateTime? expiresAt,  bool isAuthenticated,  bool isGuest,  int? userId,  String? deviceId,  String? announcementTitle,  String? announcementText)  $default,) {final _that = this;
switch (_that) {
case _AuthState():
return $default(_that.token,_that.expiresAt,_that.isAuthenticated,_that.isGuest,_that.userId,_that.deviceId,_that.announcementTitle,_that.announcementText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? token,  DateTime? expiresAt,  bool isAuthenticated,  bool isGuest,  int? userId,  String? deviceId,  String? announcementTitle,  String? announcementText)?  $default,) {final _that = this;
switch (_that) {
case _AuthState() when $default != null:
return $default(_that.token,_that.expiresAt,_that.isAuthenticated,_that.isGuest,_that.userId,_that.deviceId,_that.announcementTitle,_that.announcementText);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthState implements AuthState {
  const _AuthState({this.token, this.expiresAt, this.isAuthenticated = false, this.isGuest = false, this.userId, this.deviceId, this.announcementTitle, this.announcementText});
  factory _AuthState.fromJson(Map<String, dynamic> json) => _$AuthStateFromJson(json);

@override final  String? token;
@override final  DateTime? expiresAt;
@override@JsonKey() final  bool isAuthenticated;
@override@JsonKey() final  bool isGuest;
@override final  int? userId;
@override final  String? deviceId;
@override final  String? announcementTitle;
@override final  String? announcementText;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthStateCopyWith<_AuthState> get copyWith => __$AuthStateCopyWithImpl<_AuthState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthState&&(identical(other.token, token) || other.token == token)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.isAuthenticated, isAuthenticated) || other.isAuthenticated == isAuthenticated)&&(identical(other.isGuest, isGuest) || other.isGuest == isGuest)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.announcementTitle, announcementTitle) || other.announcementTitle == announcementTitle)&&(identical(other.announcementText, announcementText) || other.announcementText == announcementText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token,expiresAt,isAuthenticated,isGuest,userId,deviceId,announcementTitle,announcementText);

@override
String toString() {
  return 'AuthState(token: $token, expiresAt: $expiresAt, isAuthenticated: $isAuthenticated, isGuest: $isGuest, userId: $userId, deviceId: $deviceId, announcementTitle: $announcementTitle, announcementText: $announcementText)';
}


}

/// @nodoc
abstract mixin class _$AuthStateCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory _$AuthStateCopyWith(_AuthState value, $Res Function(_AuthState) _then) = __$AuthStateCopyWithImpl;
@override @useResult
$Res call({
 String? token, DateTime? expiresAt, bool isAuthenticated, bool isGuest, int? userId, String? deviceId, String? announcementTitle, String? announcementText
});




}
/// @nodoc
class __$AuthStateCopyWithImpl<$Res>
    implements _$AuthStateCopyWith<$Res> {
  __$AuthStateCopyWithImpl(this._self, this._then);

  final _AuthState _self;
  final $Res Function(_AuthState) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = freezed,Object? expiresAt = freezed,Object? isAuthenticated = null,Object? isGuest = null,Object? userId = freezed,Object? deviceId = freezed,Object? announcementTitle = freezed,Object? announcementText = freezed,}) {
  return _then(_AuthState(
token: freezed == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isAuthenticated: null == isAuthenticated ? _self.isAuthenticated : isAuthenticated // ignore: cast_nullable_to_non_nullable
as bool,isGuest: null == isGuest ? _self.isGuest : isGuest // ignore: cast_nullable_to_non_nullable
as bool,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int?,deviceId: freezed == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String?,announcementTitle: freezed == announcementTitle ? _self.announcementTitle : announcementTitle // ignore: cast_nullable_to_non_nullable
as String?,announcementText: freezed == announcementText ? _self.announcementText : announcementText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
