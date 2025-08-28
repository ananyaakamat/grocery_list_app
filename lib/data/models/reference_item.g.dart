// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reference_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReferenceItemImpl _$$ReferenceItemImplFromJson(Map<String, dynamic> json) =>
    _$ReferenceItemImpl(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String,
      qtyValue: (json['qtyValue'] as num?)?.toDouble(),
      qtyUnit: json['qtyUnit'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      needed: json['needed'] as bool? ?? false,
      position: (json['position'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ReferenceItemImplToJson(_$ReferenceItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'qtyValue': instance.qtyValue,
      'qtyUnit': instance.qtyUnit,
      'price': instance.price,
      'needed': instance.needed,
      'position': instance.position,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
