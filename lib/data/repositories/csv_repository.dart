import 'dart:io';
import 'package:csv/csv.dart';
// import 'package:file_picker/file_picker.dart'; // Disabled for APK build
// import 'package:share_plus/share_plus.dart';   // Disabled for APK build
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

import '../models/grocery_item.dart';
import '../../core/constants/app_constants.dart';

class CsvImportResult {
  final List<GroceryItem> validItems;
  final List<CsvImportError> errors;
  final int totalRows;

  CsvImportResult({
    required this.validItems,
    required this.errors,
    required this.totalRows,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasValidItems => validItems.isNotEmpty;
}

class CsvImportError {
  final int lineNumber;
  final String reason;
  final String rawData;

  CsvImportError({
    required this.lineNumber,
    required this.reason,
    required this.rawData,
  });
}

enum ImportMode { merge, replace }

class CsvRepository {
  static const List<String> _expectedHeaders = AppConstants.csvHeaders;

  // Export functionality
  Future<void> exportToCsv(List<GroceryItem> items) async {
    try {
      final csvData = _generateCsvData(items);
      final csvString = const ListToCsvConverter().convert(csvData);

      // Generate filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final filename =
          '${AppConstants.csvPrefix}$timestamp${AppConstants.csvExtension}';

      // Get temporary directory and create file
      final tempDir = await getTemporaryDirectory();
      final file = File(path.join(tempDir.path, filename));
      await file.writeAsString(csvString);

      // Share functionality disabled for APK build
      if (kIsWeb) {
        // For web, could implement download functionality
        throw UnimplementedError('File sharing not available in APK version');
      } else {
        // For APK, save to Downloads or show save location
        throw UnimplementedError('File sharing not available in APK version');
      }
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }

  // Import functionality
  Future<String?> pickCsvFile() async {
    try {
      // File picker disabled for APK build
      throw UnimplementedError('File picking not available in APK version');
    } catch (e) {
      throw Exception('Failed to pick CSV file: $e');
    }
  }

  Future<CsvImportResult> parseCsvFile(String filePath) async {
    try {
      final file = File(filePath);
      final contents = await file.readAsString();

      return _parseCsvContent(contents);
    } catch (e) {
      throw Exception('Failed to read CSV file: $e');
    }
  }

  Future<List<GroceryItem>> applyImport(
    List<GroceryItem> currentItems,
    List<GroceryItem> newItems,
    ImportMode mode,
  ) async {
    switch (mode) {
      case ImportMode.replace:
        return _reindexItems(newItems);

      case ImportMode.merge:
        return _mergeItems(currentItems, newItems);
    }
  }

  // Private helper methods
  List<List<dynamic>> _generateCsvData(List<GroceryItem> items) {
    final csvData = <List<dynamic>>[];

    // Add header row
    csvData.add(_expectedHeaders);

    // Add data rows
    for (final item in items) {
      csvData.add([
        item.position,
        item.name,
        item.qtyValue?.toStringAsFixed(
                item.qtyValue == item.qtyValue?.roundToDouble() ? 0 : 2) ??
            '',
        item.qtyUnit ?? '',
        item.needed ? 'Y' : 'N',
      ]);
    }

    return csvData;
  }

  CsvImportResult _parseCsvContent(String csvContent) {
    final validItems = <GroceryItem>[];
    final errors = <CsvImportError>[];

    try {
      final csvData = const CsvToListConverter().convert(csvContent);

      if (csvData.isEmpty) {
        return CsvImportResult(
          validItems: validItems,
          errors: [
            CsvImportError(
              lineNumber: 0,
              reason: 'CSV file is empty',
              rawData: '',
            )
          ],
          totalRows: 0,
        );
      }

      // Validate header
      final headers = csvData.first.map((h) => h.toString().trim()).toList();
      if (!_validateHeaders(headers)) {
        return CsvImportResult(
          validItems: validItems,
          errors: [
            CsvImportError(
              lineNumber: 1,
              reason:
                  'Invalid header format. Expected: ${_expectedHeaders.join(', ')}',
              rawData: headers.join(', '),
            )
          ],
          totalRows: csvData.length,
        );
      }

      // Parse data rows
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        final lineNumber = i + 1;

        try {
          final item = _parseRowToItem(row, i + 1);
          if (item != null) {
            validItems.add(item);
          }
        } catch (e) {
          errors.add(CsvImportError(
            lineNumber: lineNumber,
            reason: e.toString(),
            rawData: row.join(', '),
          ));
        }
      }

      return CsvImportResult(
        validItems: validItems,
        errors: errors,
        totalRows: csvData.length,
      );
    } catch (e) {
      return CsvImportResult(
        validItems: validItems,
        errors: [
          CsvImportError(
            lineNumber: 0,
            reason: 'Failed to parse CSV: $e',
            rawData: '',
          )
        ],
        totalRows: 0,
      );
    }
  }

  bool _validateHeaders(List<String> headers) {
    if (headers.length != _expectedHeaders.length) return false;

    for (int i = 0; i < _expectedHeaders.length; i++) {
      if (headers[i].toLowerCase() != _expectedHeaders[i].toLowerCase()) {
        return false;
      }
    }

    return true;
  }

  GroceryItem? _parseRowToItem(List<dynamic> row, int position) {
    if (row.length < 5) {
      throw Exception('Insufficient columns. Expected 5, got ${row.length}');
    }

    // Parse item name (required)
    final name = row[1]?.toString().trim() ?? '';
    if (name.isEmpty) {
      throw Exception('Item name cannot be empty');
    }

    if (name.length > AppConstants.maxItemNameLength) {
      throw Exception(
          'Item name too long (max ${AppConstants.maxItemNameLength} characters)');
    }

    // Parse quantity value (optional)
    double? qtyValue;
    final qtyValueStr = row[2]?.toString().trim() ?? '';
    if (qtyValueStr.isNotEmpty) {
      qtyValue = double.tryParse(qtyValueStr);
      if (qtyValue == null) {
        throw Exception('Invalid quantity value: $qtyValueStr');
      }
    }

    // Parse quantity unit (optional)
    String? qtyUnit = row[3]?.toString().trim();
    if (qtyUnit?.isEmpty == true) qtyUnit = null;

    // Validate unit if provided
    if (qtyUnit != null && !QuantityUnits.allUnits.contains(qtyUnit)) {
      // Try to find closest match or allow free text
      // For now, we'll allow any unit but could add fuzzy matching later
    }

    // Parse needed status (required)
    final neededStr = row[4]?.toString().trim().toUpperCase() ?? '';
    bool needed;
    if (neededStr == 'Y' || neededStr == 'YES' || neededStr == '1') {
      needed = true;
    } else if (neededStr == 'N' ||
        neededStr == 'NO' ||
        neededStr == '0' ||
        neededStr.isEmpty) {
      needed = false;
    } else {
      throw Exception('Invalid needed value: $neededStr. Expected Y/N');
    }

    return GroceryItem.create(
      name: name,
      qtyValue: qtyValue,
      qtyUnit: qtyUnit,
      needed: needed,
      position: position,
    );
  }

  List<GroceryItem> _reindexItems(List<GroceryItem> items) {
    final reindexedItems = <GroceryItem>[];

    for (int i = 0; i < items.length; i++) {
      reindexedItems.add(items[i].copyWith(position: i + 1));
    }

    return reindexedItems;
  }

  List<GroceryItem> _mergeItems(
    List<GroceryItem> currentItems,
    List<GroceryItem> newItems,
  ) {
    final mergedItems = List<GroceryItem>.from(currentItems);

    // Add new items to the end
    for (final newItem in newItems) {
      // Check for duplicates by name (optional - could make configurable)
      final existingIndex = mergedItems.indexWhere(
          (item) => item.name.toLowerCase() == newItem.name.toLowerCase());

      if (existingIndex != -1) {
        // Update existing item
        mergedItems[existingIndex] = mergedItems[existingIndex].copyWith(
          qtyValue: newItem.qtyValue,
          qtyUnit: newItem.qtyUnit,
          needed: newItem.needed,
          updatedAt: DateTime.now(),
        );
      } else {
        // Add new item
        mergedItems.add(newItem);
      }
    }

    return _reindexItems(mergedItems);
  }
}
