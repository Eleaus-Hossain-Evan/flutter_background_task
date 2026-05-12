// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'socket_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SocketEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SocketEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SocketEvent()';
}


}

/// @nodoc
class $SocketEventCopyWith<$Res>  {
$SocketEventCopyWith(SocketEvent _, $Res Function(SocketEvent) __);
}


/// Adds pattern-matching-related methods to [SocketEvent].
extension SocketEventPatterns on SocketEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ConnectedEvent value)?  connected,TResult Function( DisconnectedEvent value)?  disconnected,TResult Function( ErrorEvent value)?  error,TResult Function( NotificationEvent value)?  notification,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ConnectedEvent() when connected != null:
return connected(_that);case DisconnectedEvent() when disconnected != null:
return disconnected(_that);case ErrorEvent() when error != null:
return error(_that);case NotificationEvent() when notification != null:
return notification(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ConnectedEvent value)  connected,required TResult Function( DisconnectedEvent value)  disconnected,required TResult Function( ErrorEvent value)  error,required TResult Function( NotificationEvent value)  notification,}){
final _that = this;
switch (_that) {
case ConnectedEvent():
return connected(_that);case DisconnectedEvent():
return disconnected(_that);case ErrorEvent():
return error(_that);case NotificationEvent():
return notification(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ConnectedEvent value)?  connected,TResult? Function( DisconnectedEvent value)?  disconnected,TResult? Function( ErrorEvent value)?  error,TResult? Function( NotificationEvent value)?  notification,}){
final _that = this;
switch (_that) {
case ConnectedEvent() when connected != null:
return connected(_that);case DisconnectedEvent() when disconnected != null:
return disconnected(_that);case ErrorEvent() when error != null:
return error(_that);case NotificationEvent() when notification != null:
return notification(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  connected,TResult Function()?  disconnected,TResult Function( dynamic message)?  error,TResult Function( NotificationModel data)?  notification,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ConnectedEvent() when connected != null:
return connected();case DisconnectedEvent() when disconnected != null:
return disconnected();case ErrorEvent() when error != null:
return error(_that.message);case NotificationEvent() when notification != null:
return notification(_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  connected,required TResult Function()  disconnected,required TResult Function( dynamic message)  error,required TResult Function( NotificationModel data)  notification,}) {final _that = this;
switch (_that) {
case ConnectedEvent():
return connected();case DisconnectedEvent():
return disconnected();case ErrorEvent():
return error(_that.message);case NotificationEvent():
return notification(_that.data);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  connected,TResult? Function()?  disconnected,TResult? Function( dynamic message)?  error,TResult? Function( NotificationModel data)?  notification,}) {final _that = this;
switch (_that) {
case ConnectedEvent() when connected != null:
return connected();case DisconnectedEvent() when disconnected != null:
return disconnected();case ErrorEvent() when error != null:
return error(_that.message);case NotificationEvent() when notification != null:
return notification(_that.data);case _:
  return null;

}
}

}

/// @nodoc


class ConnectedEvent implements SocketEvent {
  const ConnectedEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConnectedEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SocketEvent.connected()';
}


}




/// @nodoc


class DisconnectedEvent implements SocketEvent {
  const DisconnectedEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DisconnectedEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SocketEvent.disconnected()';
}


}




/// @nodoc


class ErrorEvent implements SocketEvent {
  const ErrorEvent(this.message);
  

 final  dynamic message;

/// Create a copy of SocketEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ErrorEventCopyWith<ErrorEvent> get copyWith => _$ErrorEventCopyWithImpl<ErrorEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ErrorEvent&&const DeepCollectionEquality().equals(other.message, message));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(message));

@override
String toString() {
  return 'SocketEvent.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ErrorEventCopyWith<$Res> implements $SocketEventCopyWith<$Res> {
  factory $ErrorEventCopyWith(ErrorEvent value, $Res Function(ErrorEvent) _then) = _$ErrorEventCopyWithImpl;
@useResult
$Res call({
 dynamic message
});




}
/// @nodoc
class _$ErrorEventCopyWithImpl<$Res>
    implements $ErrorEventCopyWith<$Res> {
  _$ErrorEventCopyWithImpl(this._self, this._then);

  final ErrorEvent _self;
  final $Res Function(ErrorEvent) _then;

/// Create a copy of SocketEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(ErrorEvent(
freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}


}

/// @nodoc


class NotificationEvent implements SocketEvent {
  const NotificationEvent(this.data);
  

 final  NotificationModel data;

/// Create a copy of SocketEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationEventCopyWith<NotificationEvent> get copyWith => _$NotificationEventCopyWithImpl<NotificationEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationEvent&&(identical(other.data, data) || other.data == data));
}


@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'SocketEvent.notification(data: $data)';
}


}

/// @nodoc
abstract mixin class $NotificationEventCopyWith<$Res> implements $SocketEventCopyWith<$Res> {
  factory $NotificationEventCopyWith(NotificationEvent value, $Res Function(NotificationEvent) _then) = _$NotificationEventCopyWithImpl;
@useResult
$Res call({
 NotificationModel data
});




}
/// @nodoc
class _$NotificationEventCopyWithImpl<$Res>
    implements $NotificationEventCopyWith<$Res> {
  _$NotificationEventCopyWithImpl(this._self, this._then);

  final NotificationEvent _self;
  final $Res Function(NotificationEvent) _then;

/// Create a copy of SocketEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(NotificationEvent(
null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as NotificationModel,
  ));
}


}

// dart format on
