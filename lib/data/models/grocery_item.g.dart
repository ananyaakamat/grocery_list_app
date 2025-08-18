// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grocery_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GroceryItemImpl _$$GroceryItemImplFromJson(Map<String, dynamic> json) =>
    _$GroceryItemImpl(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String,
      qtyValue: (json['qtyValue'] as num?)?.toDouble(),
      qtyUnit: json['qtyUnit'] as String?,
      needed: json['needed'] as bool? ?? false,
      position: (json['position'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$GroceryItemImplToJson(_$GroceryItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'qtyValue': instance.qtyValue,
      'qtyUnit': instance.qtyUnit,
      'needed': instance.needed,
      'position': instance.position,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
