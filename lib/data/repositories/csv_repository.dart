import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/grocery_item.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validation_utils.dart';

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
  final String field;
  final String value;
  final String message;
  final String rawData;

  CsvImportError({
    required this.lineNumber,
    required this.field,
    required this.value,
    required this.message,
    required this.rawData,
  });

  // Legacy constructor for backward compatibility
  CsvImportError.legacy({
    required this.lineNumber,
    required String reason,
    required this.rawData,
  })  : field = 'General',
        value = '',
        message = reason;

  // Property for backward compatibility
  String get reason => message;
}

enum ImportMode { referenceList, merge, replace }

class CsvRepository {
  static const List<String> _expectedHeaders = AppConstants.csvHeaders;

  // Export functionality
  Future<void> exportToCsv(List<GroceryItem> items,
      {String? listName, String? filterType}) async {
    try {
      final csvData = _generateCsvData(items);
      final csvString = const ListToCsvConverter().convert(csvData);

      // Generate filename with custom format: ListName_FilterType_Date_Time.csv
      final now = DateTime.now();
      final dateStr = DateFormat('dMMMy').format(now); // 29Aug2025
      final timeStr = DateFormat('h_mmaa')
          .format(now)
          .toUpperCase(); // 10_00AM (uppercase AM/PM)

      // Clean list name for filename (remove special characters)
      final cleanListName = (listName ?? 'GroceryList')
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '')
          .trim();

      // Clean filter type for filename (remove spaces and special characters)
      final cleanFilterType = (filterType ?? 'All')
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '')
          .trim();

      final filename =
          '${cleanListName}_${cleanFilterType}_${dateStr}_$timeStr${AppConstants.csvExtension}';

      if (kIsWeb) {
        // For web, we need to implement download functionality differently
        // For now, throw an error indicating web is not supported
        throw UnimplementedError('CSV export not yet implemented for web');
      } else {
        // For mobile/desktop, save file and share it
        final tempDir = await getTemporaryDirectory();
        final file = File(path.join(tempDir.path, filename));
        await file.writeAsString(csvString);

        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Grocery List Export - $filename',
          subject: 'Grocery List CSV Export',
        );
      }
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }

  // Export sample template
  Future<void> exportSampleTemplate() async {
    try {
      final csvData = await _loadSampleTemplateData();
      final csvString = const ListToCsvConverter().convert(csvData);

      // Generate filename with new format: Grocery_List_CSV_Sample_Template_DateTime.csv
      final now = DateTime.now();
      final dateStr = DateFormat('dMMMy').format(now); // 29Aug2025
      final timeStr = DateFormat('h_mmaa')
          .format(now)
          .toUpperCase(); // 10_00AM (uppercase AM/PM)

      final filename =
          'Grocery_List_CSV_Sample_Template_${dateStr}_$timeStr${AppConstants.csvExtension}';

      if (kIsWeb) {
        // For web, we need to implement download functionality differently
        // For now, throw an error indicating web is not supported
        throw UnimplementedError(
            'CSV sample template export not yet implemented for web');
      } else {
        // For mobile/desktop, save file and share it
        final tempDir = await getTemporaryDirectory();
        final file = File(path.join(tempDir.path, filename));
        await file.writeAsString(csvString);

        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Grocery List Sample Template - $filename',
          subject: 'Grocery List CSV Sample Template',
        );
      }
    } catch (e) {
      throw Exception('Failed to export sample template: $e');
    }
  }

  // Import functionality
  Future<String?> pickCsvFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single.path!;
      }

      return null; // User cancelled the picker
    } catch (e) {
      throw Exception('Failed to pick CSV file: $e');
    }
  }

  Future<CsvImportResult> parseCsvFile(String filePath, int listId) async {
    try {
      final file = File(filePath);
      final contents = await file.readAsString();

      return _parseCsvContent(contents, listId);
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
      case ImportMode.referenceList:
        // For reference list, replace all items (should only be used on blank lists)
        return _reindexItems(newItems);

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
        item.price.toStringAsFixed(2),
      ]);
    }

    return csvData;
  }

  // Load sample template data from assets
  Future<List<List<dynamic>>> _loadSampleTemplateData() async {
    try {
      // Load the sample template from assets
      final String csvContent = await rootBundle
          .loadString('assets/Grocery_List_CSV_Sample_Template.csv');

      // Parse the CSV content
      final List<List<dynamic>> csvData =
          const CsvToListConverter().convert(csvContent);

      return csvData;
    } catch (e) {
      // Fallback to basic sample data if asset loading fails
      final csvData = <List<dynamic>>[];

      // Add header row
      csvData.add(_expectedHeaders);

      // Add basic sample data
      csvData.add(['1', 'Apples', '2', 'kg', 'Y', '150.00']);
      csvData.add(['2', 'Milk', '1', 'liter', 'Y', '60.00']);
      csvData.add(['3', 'Bread', '', 'loaf', 'N']);
      csvData.add(['4', 'Eggs', '12', 'pieces', 'Y']);

      return csvData;
    }
  }

  CsvImportResult _parseCsvContent(String csvContent, int listId) {
    final validItems = <GroceryItem>[];
    final errors = <CsvImportError>[];

    try {
      final csvData = const CsvToListConverter().convert(csvContent);

      if (csvData.isEmpty) {
        return CsvImportResult(
          validItems: validItems,
          errors: [
            CsvImportError.legacy(
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
            CsvImportError.legacy(
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
          final item = _parseRowToItem(row, lineNumber, listId, errors);
          if (item != null) {
            validItems.add(item);
          }
        } catch (e) {
          errors.add(CsvImportError.legacy(
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
          CsvImportError.legacy(
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

  GroceryItem? _parseRowToItem(List<dynamic> row, int position, int listId,
      List<CsvImportError> errors) {
    if (row.length < 6) {
      errors.add(CsvImportError(
        lineNumber: position,
        field: 'Row Structure',
        value: '${row.length} columns',
        message: 'Insufficient columns. Expected 6, got ${row.length}',
        rawData: row.join(', '),
      ));
      return null;
    }

    final List<CsvImportError> rowErrors = [];
    final rawData = row.join(', ');

    // Parse item name (required)
    final name = row[1]?.toString().trim() ?? '';
    final nameValidation = ValidationUtils.validateItemName(name);
    if (nameValidation != null) {
      rowErrors.add(CsvImportError(
        lineNumber: position,
        field: 'Item Name',
        value: name,
        message: nameValidation,
        rawData: rawData,
      ));
    }

    // Parse quantity value (optional)
    double? qtyValue;
    final qtyValueStr = row[2]?.toString().trim() ?? '';
    if (qtyValueStr.isNotEmpty) {
      final qtyValidation = ValidationUtils.validateQuantityValue(qtyValueStr);
      if (qtyValidation != null) {
        rowErrors.add(CsvImportError(
          lineNumber: position,
          field: 'Quantity',
          value: qtyValueStr,
          message: qtyValidation,
          rawData: rawData,
        ));
      } else {
        qtyValue = double.tryParse(qtyValueStr);
      }
    }

    // Parse quantity unit (optional)
    String? qtyUnit = row[3]?.toString().trim();
    if (qtyUnit?.isEmpty == true) qtyUnit = null;

    // Validate quantity/UOM relationship
    final qtyUomValidation = ValidationUtils.validateQuantityUomRelationship(
      qtyValue: qtyValueStr,
      uom: qtyUnit,
    );
    if (qtyUomValidation != null) {
      rowErrors.add(CsvImportError(
        lineNumber: position,
        field: 'Quantity/UOM',
        value: 'Qty: $qtyValueStr, UOM: ${qtyUnit ?? '(empty)'}',
        message: qtyUomValidation,
        rawData: rawData,
      ));
    }

    // Validate unit if provided
    if (qtyUnit != null && !QuantityUnits.allUnits.contains(qtyUnit)) {
      rowErrors.add(CsvImportError(
        lineNumber: position,
        field: 'Unit of Measure',
        value: qtyUnit,
        message:
            'Invalid unit of measure. Please use one of the supported units.',
        rawData: rawData,
      ));
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
      rowErrors.add(CsvImportError(
        lineNumber: position,
        field: 'Needed',
        value: neededStr,
        message: 'Invalid needed value. Expected Y/N, YES/NO, 1/0',
        rawData: rawData,
      ));
      needed = false; // Default fallback
    }

    // Parse price (optional, defaults to 0.0)
    double price = 0.0;
    final priceStr = row[5]?.toString().trim() ?? '';
    if (priceStr.isNotEmpty) {
      final priceValidation = ValidationUtils.validatePrice(priceStr);
      if (priceValidation != null) {
        rowErrors.add(CsvImportError(
          lineNumber: position,
          field: 'Price',
          value: priceStr,
          message: priceValidation,
          rawData: rawData,
        ));
      } else {
        price = double.tryParse(priceStr) ?? 0.0;
      }
    }

    // Add all row errors to the main errors list
    errors.addAll(rowErrors);

    // Only create item if there are no validation errors
    if (rowErrors.isEmpty) {
      return GroceryItem.create(
        name: name,
        qtyValue: qtyValue,
        qtyUnit: qtyUnit,
        needed: needed,
        listId: listId,
        position: position,
        price: price,
      );
    }

    return null;
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
