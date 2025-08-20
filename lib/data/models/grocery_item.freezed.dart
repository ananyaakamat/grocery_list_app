// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grocery_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GroceryItem _$GroceryItemFromJson(Map<String, dynamic> json) {
  return _GroceryItem.fromJson(json);
}

/// @nodoc
mixin _$GroceryItem {
  int? get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double? get qtyValue => throw _privateConstructorUsedError;
  String? get qtyUnit => throw _privateConstructorUsedError;
  double get price =>
      throw _privateConstructorUsedError; // Added price field with default 0.0
  bool get needed => throw _privateConstructorUsedError;
  int get position => throw _privateConstructorUsedError;
  int get listId =>
      throw _privateConstructorUsedError; // Added for CR1 multi-list feature
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this GroceryItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GroceryItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GroceryItemCopyWith<GroceryItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroceryItemCopyWith<$Res> {
  factory $GroceryItemCopyWith(
          GroceryItem value, $Res Function(GroceryItem) then) =
      _$GroceryItemCopyWithImpl<$Res, GroceryItem>;
  @useResult
  $Res call(
      {int? id,
      String name,
      double? qtyValue,
      String? qtyUnit,
      double price,
      bool needed,
      int position,
      int listId,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$GroceryItemCopyWithImpl<$Res, $Val extends GroceryItem>
    implements $GroceryItemCopyWith<$Res> {
  _$GroceryItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GroceryItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = null,
    Object? qtyValue = freezed,
    Object? qtyUnit = freezed,
    Object? price = null,
    Object? needed = null,
    Object? position = null,
    Object? listId = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      qtyValue: freezed == qtyValue
          ? _value.qtyValue
          : qtyValue // ignore: cast_nullable_to_non_nullable
              as double?,
      qtyUnit: freezed == qtyUnit
          ? _value.qtyUnit
          : qtyUnit // ignore: cast_nullable_to_non_nullable
              as String?,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      needed: null == needed
          ? _value.needed
          : needed // ignore: cast_nullable_to_non_nullable
              as bool,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      listId: null == listId
          ? _value.listId
          : listId // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GroceryItemImplCopyWith<$Res>
    implements $GroceryItemCopyWith<$Res> {
  factory _$$GroceryItemImplCopyWith(
          _$GroceryItemImpl value, $Res Function(_$GroceryItemImpl) then) =
      __$$GroceryItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? id,
      String name,
      double? qtyValue,
      String? qtyUnit,
      double price,
      bool needed,
      int position,
      int listId,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$GroceryItemImplCopyWithImpl<$Res>
    extends _$GroceryItemCopyWithImpl<$Res, _$GroceryItemImpl>
    implements _$$GroceryItemImplCopyWith<$Res> {
  __$$GroceryItemImplCopyWithImpl(
      _$GroceryItemImpl _value, $Res Function(_$GroceryItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of GroceryItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = null,
    Object? qtyValue = freezed,
    Object? qtyUnit = freezed,
    Object? price = null,
    Object? needed = null,
    Object? position = null,
    Object? listId = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$GroceryItemImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      qtyValue: freezed == qtyValue
          ? _value.qtyValue
          : qtyValue // ignore: cast_nullable_to_non_nullable
              as double?,
      qtyUnit: freezed == qtyUnit
          ? _value.qtyUnit
          : qtyUnit // ignore: cast_nullable_to_non_nullable
              as String?,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      needed: null == needed
          ? _value.needed
          : needed // ignore: cast_nullable_to_non_nullable
              as bool,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      listId: null == listId
          ? _value.listId
          : listId // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GroceryItemImpl implements _GroceryItem {
  const _$GroceryItemImpl(
      {this.id,
      required this.name,
      this.qtyValue,
      this.qtyUnit,
      this.price = 0.0,
      this.needed = false,
      required this.position,
      required this.listId,
      required this.createdAt,
      required this.updatedAt});

  factory _$GroceryItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroceryItemImplFromJson(json);

  @override
  final int? id;
  @override
  final String name;
  @override
  final double? qtyValue;
  @override
  final String? qtyUnit;
  @override
  @JsonKey()
  final double price;
// Added price field with default 0.0
  @override
  @JsonKey()
  final bool needed;
  @override
  final int position;
  @override
  final int listId;
// Added for CR1 multi-list feature
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'GroceryItem(id: $id, name: $name, qtyValue: $qtyValue, qtyUnit: $qtyUnit, price: $price, needed: $needed, position: $position, listId: $listId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroceryItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.qtyValue, qtyValue) ||
                other.qtyValue == qtyValue) &&
            (identical(other.qtyUnit, qtyUnit) || other.qtyUnit == qtyUnit) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.needed, needed) || other.needed == needed) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.listId, listId) || other.listId == listId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, qtyValue, qtyUnit,
      price, needed, position, listId, createdAt, updatedAt);

  /// Create a copy of GroceryItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GroceryItemImplCopyWith<_$GroceryItemImpl> get copyWith =>
      __$$GroceryItemImplCopyWithImpl<_$GroceryItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroceryItemImplToJson(
      this,
    );
  }
}

abstract class _GroceryItem implements GroceryItem {
  const factory _GroceryItem(
      {final int? id,
      required final String name,
      final double? qtyValue,
      final String? qtyUnit,
      final double price,
      final bool needed,
      required final int position,
      required final int listId,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$GroceryItemImpl;

  factory _GroceryItem.fromJson(Map<String, dynamic> json) =
      _$GroceryItemImpl.fromJson;

  @override
  int? get id;
  @override
  String get name;
  @override
  double? get qtyValue;
  @override
  String? get qtyUnit;
  @override
  double get price; // Added price field with default 0.0
  @override
  bool get needed;
  @override
  int get position;
  @override
  int get listId; // Added for CR1 multi-list feature
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of GroceryItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GroceryItemImplCopyWith<_$GroceryItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
