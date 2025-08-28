import 'package:freezed_annotation/freezed_annotation.dart';
import 'grocery_item.dart';

part 'reference_item.freezed.dart';
part 'reference_item.g.dart';

@freezed
class ReferenceItem with _$ReferenceItem {
  const factory ReferenceItem({
    int? id,
    required String name,
    double? qtyValue,
    String? qtyUnit,
    @Default(0.0) double price,
    @Default(false) bool needed,
    required int position,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ReferenceItem;

  factory ReferenceItem.fromJson(Map<String, dynamic> json) =>
      _$ReferenceItemFromJson(json);

  // Factory constructor for creating new reference items
  factory ReferenceItem.create({
    required String name,
    double? qtyValue,
    String? qtyUnit,
    double price = 0.0,
    bool needed = false,
    required int position,
  }) {
    final now = DateTime.now();
    return ReferenceItem(
      name: name.trim(),
      qtyValue: qtyValue,
      qtyUnit: qtyUnit,
      price: price,
      needed: needed,
      position: position,
      createdAt: now,
      updatedAt: now,
    );
  }
}

extension ReferenceItemExtensions on ReferenceItem {
  // Convert to Map for SQLite insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'qty_value': qtyValue,
      'qty_unit': qtyUnit,
      'price': price,
      'needed': needed ? 1 : 0,
      'position': position,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create from SQLite Map
  static ReferenceItem fromMap(Map<String, dynamic> map) {
    return ReferenceItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      qtyValue: map['qty_value'] as double?,
      qtyUnit: map['qty_unit'] as String?,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      needed: (map['needed'] as int) == 1,
      position: map['position'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Convert to GroceryItem for import
  GroceryItem toGroceryItem({required int listId}) {
    return GroceryItem(
      name: name,
      qtyValue: qtyValue,
      qtyUnit: qtyUnit,
      price: price,
      needed: needed,
      position: position,
      listId: listId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
