import 'package:intl/intl.dart';

class AppUtils {
  // Date formatting utilities
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('d MMM yy, h:mm a').format(dateTime);
  }

  static String formatDateTimeForFilename(DateTime dateTime) {
    return DateFormat('yyyyMMdd_HHmm').format(dateTime);
  }

  // Validation utilities
  static bool isValidItemName(String name) {
    final trimmed = name.trim();
    return trimmed.isNotEmpty && trimmed.length <= 60;
  }

  static bool isValidQuantityValue(String value) {
    if (value.isEmpty) return true; // Optional field
    final parsed = double.tryParse(value);
    return parsed != null && parsed > 0;
  }

  // String utilities
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String formatQuantity(double? value, String? unit) {
    if (value == null && (unit == null || unit.isEmpty)) {
      return '';
    }

    final valueStr = value != null
        ? value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2)
        : '';

    final unitStr = unit ?? '';

    if (valueStr.isEmpty && unitStr.isEmpty) return '';
    if (valueStr.isEmpty) return unitStr;
    if (unitStr.isEmpty) return valueStr;

    return '$valueStr $unitStr';
  }

  // CSV utilities
  static String generateCsvFilename() {
    final timestamp = formatDateTimeForFilename(DateTime.now());
    return 'annadaata_grocery_$timestamp.csv';
  }

  // Error message utilities
  static String getErrorMessage(Object error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error.toString();
  }
}
