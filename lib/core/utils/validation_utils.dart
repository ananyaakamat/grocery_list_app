/// Validation utilities for form inputs across the app
class ValidationUtils {
  // Regular expression to match only numbers, spaces, and special characters
  static final RegExp _onlyNumbersSpacesSpecialChars =
      RegExp(r'^[\d\s!@#$%^&*()_+\-=\[\]{};:"\\|,.<>/?`~]*$');

  /// Validates that a name is not only numbers, special characters, or spaces
  /// Returns null if valid, error message if invalid
  static String? validateName(String? value, {required String fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a $fieldName';
    }

    final trimmed = value.trim();

    // Check if it's only numbers, special characters, or spaces
    if (_onlyNumbersSpacesSpecialChars.hasMatch(trimmed)) {
      return '$fieldName must contain at least one letter';
    }

    return null;
  }

  /// Validates list name with specific requirements
  static String? validateListName(String? value) {
    final basicValidation = validateName(value, fieldName: 'list name');
    if (basicValidation != null) return basicValidation;

    final trimmed = value!.trim();

    if (trimmed.length > 50) {
      return 'List name must be 50 characters or less';
    }

    return null;
  }

  /// Validates item name with specific requirements
  static String? validateItemName(String? value) {
    final basicValidation = validateName(value, fieldName: 'item name');
    if (basicValidation != null) return basicValidation;

    final trimmed = value!.trim();

    if (trimmed.length > 100) {
      return 'Item name must be 100 characters or less';
    }

    return null;
  }

  /// Validates quantity and unit of measure relationship
  /// Returns null if valid, error message if invalid
  static String? validateQuantityUomRelationship({
    required String? qtyValue,
    required String? uom,
  }) {
    final hasQty = qtyValue != null && qtyValue.trim().isNotEmpty;
    final hasUom = uom != null && uom.trim().isNotEmpty;

    // If UOM is provided, quantity must also be provided
    if (hasUom && !hasQty) {
      return 'Quantity is required when unit is specified';
    }

    // If quantity is provided, UOM must also be provided
    if (hasQty && !hasUom) {
      return 'Unit of measure is required when quantity is specified';
    }

    return null;
  }

  /// Validates price field
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Price is optional
    }

    final trimmed = value.trim();
    final price = double.tryParse(trimmed);

    if (price == null) {
      return 'Please enter a valid price';
    }

    if (price <= 0) {
      return 'Price must be greater than 0';
    }

    if (price > 10000.99) {
      return 'Price cannot exceed Rs 10,000.99';
    }

    // Check decimal places
    final parts = trimmed.split('.');
    if (parts.length > 1 && parts[1].length > 2) {
      return 'Price can have maximum 2 decimal places';
    }

    return null;
  }

  /// Validates quantity value
  static String? validateQuantityValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Quantity is optional when no UOM is specified
    }

    final trimmed = value.trim();
    final qty = double.tryParse(trimmed);

    if (qty == null) {
      return 'Please enter a valid quantity';
    }

    if (qty <= 0) {
      return 'Quantity must be greater than 0';
    }

    if (qty > 999999) {
      return 'Quantity too large';
    }

    return null;
  }
}
