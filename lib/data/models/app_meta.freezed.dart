// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_meta.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AppMeta _$AppMetaFromJson(Map<String, dynamic> json) {
  return _AppMeta.fromJson(json);
}

/// @nodoc
mixin _$AppMeta {
  String get key => throw _privateConstructorUsedError;
  String get value => throw _privateConstructorUsedError;

  /// Serializes this AppMeta to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppMeta
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppMetaCopyWith<AppMeta> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppMetaCopyWith<$Res> {
  factory $AppMetaCopyWith(AppMeta value, $Res Function(AppMeta) then) =
      _$AppMetaCopyWithImpl<$Res, AppMeta>;
  @useResult
  $Res call({String key, String value});
}

/// @nodoc
class _$AppMetaCopyWithImpl<$Res, $Val extends AppMeta>
    implements $AppMetaCopyWith<$Res> {
  _$AppMetaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppMeta
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? value = null,
  }) {
    return _then(_value.copyWith(
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppMetaImplCopyWith<$Res> implements $AppMetaCopyWith<$Res> {
  factory _$$AppMetaImplCopyWith(
          _$AppMetaImpl value, $Res Function(_$AppMetaImpl) then) =
      __$$AppMetaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String key, String value});
}

/// @nodoc
class __$$AppMetaImplCopyWithImpl<$Res>
    extends _$AppMetaCopyWithImpl<$Res, _$AppMetaImpl>
    implements _$$AppMetaImplCopyWith<$Res> {
  __$$AppMetaImplCopyWithImpl(
      _$AppMetaImpl _value, $Res Function(_$AppMetaImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppMeta
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? value = null,
  }) {
    return _then(_$AppMetaImpl(
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AppMetaImpl implements _AppMeta {
  const _$AppMetaImpl({required this.key, required this.value});

  factory _$AppMetaImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppMetaImplFromJson(json);

  @override
  final String key;
  @override
  final String value;

  @override
  String toString() {
    return 'AppMeta(key: $key, value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppMetaImpl &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, key, value);

  /// Create a copy of AppMeta
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppMetaImplCopyWith<_$AppMetaImpl> get copyWith =>
      __$$AppMetaImplCopyWithImpl<_$AppMetaImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppMetaImplToJson(
      this,
    );
  }
}

abstract class _AppMeta implements AppMeta {
  const factory _AppMeta(
      {required final String key, required final String value}) = _$AppMetaImpl;

  factory _AppMeta.fromJson(Map<String, dynamic> json) = _$AppMetaImpl.fromJson;

  @override
  String get key;
  @override
  String get value;

  /// Create a copy of AppMeta
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppMetaImplCopyWith<_$AppMetaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
