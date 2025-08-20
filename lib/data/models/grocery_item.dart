import 'package:freezed_annotation/freezed_annotation.dart';

part 'grocery_item.freezed.dart';
part 'grocery_item.g.dart';

@freezed
class GroceryItem with _$GroceryItem {
  const factory GroceryItem({
    int? id,
    required String name,
    double? qtyValue,
    String? qtyUnit,
    @Default(0.0) double price, // Added price field with default 0.0
    @Default(false) bool needed,
    required int position,
    required int listId, // Added for CR1 multi-list feature
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _GroceryItem;

  factory GroceryItem.fromJson(Map<String, dynamic> json) =>
      _$GroceryItemFromJson(json);

  // Factory constructor for creating new items
  factory GroceryItem.create({
    required String name,
    double? qtyValue,
    String? qtyUnit,
    double price = 0.0, // Added price parameter with default
    bool needed = false,
    required int position,
    required int listId, // Added for CR1 multi-list feature
  }) {
    final now = DateTime.now();
    return GroceryItem(
      name: name.trim(),
      qtyValue: qtyValue,
      qtyUnit: qtyUnit,
      price: price,
      needed: needed,
      position: position,
      listId: listId,
      createdAt: now,
      updatedAt: now,
    );
  }
}

extension GroceryItemExtensions on GroceryItem {
  // Convert to Map for SQLite insertion
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'qty_value': qtyValue,
      'qty_unit': qtyUnit,
      'price': price, // Added price field
      'needed': needed ? 1 : 0,
      'position': position,
      'list_id': listId, // Added for CR1 multi-list feature
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create from SQLite Map
  static GroceryItem fromMap(Map<String, dynamic> map) {
    return GroceryItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      qtyValue: map['qty_value'] as double?,
      qtyUnit: map['qty_unit'] as String?,
      price: (map['price'] as double?) ?? 0.0, // Added price field with default
      needed: (map['needed'] as int) == 1,
      position: map['position'] as int,
      listId: map['list_id'] as int? ??
          1, // Default to 1 for backward compatibility
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Get formatted quantity string
  String get formattedQuantity {
    if (qtyValue == null && (qtyUnit == null || qtyUnit!.isEmpty)) {
      return '';
    }

    final valueStr = qtyValue != null
        ? qtyValue!
            .toStringAsFixed(qtyValue == qtyValue!.roundToDouble() ? 0 : 2)
        : '';

    final unitStr = qtyUnit ?? '';

    if (valueStr.isEmpty && unitStr.isEmpty) return '';
    if (valueStr.isEmpty) return unitStr;
    if (unitStr.isEmpty) return valueStr;

    return '$valueStr $unitStr';
  }

  // Get formatted price string
  String get formattedPrice {
    return '${price.toStringAsFixed(2)} Rs';
  }

  // Validate price value
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) return null; // Price is optional

    final double? price = double.tryParse(value);
    if (price == null) return 'Please enter a valid number';

    if (price < 0) return 'Price cannot be negative';
    if (price > 10000.99) return 'Price cannot exceed Rs 10,000.99';

    // Check decimal places
    final parts = value.split('.');
    if (parts.length > 1 && parts[1].length > 2) {
      return 'Price can have maximum 2 decimal places';
    }

    return null; // Valid price
  }

  // Parse and format price input
  static double parsePrice(String? value) {
    if (value == null || value.isEmpty) return 0.0;
    final price = double.tryParse(value) ?? 0.0;
    return price.clamp(0.0, 10000.99);
  }

  // Check if item is valid
  bool get isValid {
    return name.trim().isNotEmpty && name.trim().length <= 60 && position > 0;
  }

  // Create a copy with updated timestamp
  GroceryItem withUpdatedTimestamp() {
    return copyWith(updatedAt: DateTime.now());
  }
}
