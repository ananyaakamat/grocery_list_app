import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/reference_item.dart';
import '../models/grocery_item.dart';

class ReferenceItemRepository {
  static const String _referenceListCsvPath =
      'assets/Grocery_Reference_List.csv';

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Load reference items from database or CSV file if not exists
  Future<List<ReferenceItem>> getReferenceItems() async {
    // First check if reference items already exist in database
    if (await _databaseHelper.hasReferenceItems()) {
      return await _databaseHelper.getAllReferenceItems();
    }

    // If not in database, load from CSV and save to database
    return await _loadReferenceItemsFromCsv();
  }

  // Load reference items from CSV file and save to database
  Future<List<ReferenceItem>> _loadReferenceItemsFromCsv() async {
    try {
      // Try to read from assets first (for production builds)
      String csvContent;

      try {
        csvContent = await rootBundle.loadString(_referenceListCsvPath);
      } catch (e) {
        // If asset doesn't exist, try to read from project root
        final file = File('Grocery_Reference_List.csv');
        if (!await file.exists()) {
          throw Exception(
              'Reference list CSV file not found in assets or project root');
        }
        csvContent = await file.readAsString();
      }

      final csvData = const CsvToListConverter().convert(csvContent);

      if (csvData.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Skip header row and parse items
      final referenceItems = <ReferenceItem>[];

      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        if (row.length >= 6) {
          try {
            final item = ReferenceItem.create(
              name: row[1]?.toString().trim() ?? '',
              qtyValue: _parseDouble(row[2]?.toString().trim()),
              qtyUnit: _parseString(row[3]?.toString().trim()),
              needed: _parseBoolean(row[4]?.toString().trim()),
              price: _parseDouble(row[5]?.toString().trim()) ?? 0.0,
              position: i,
            );

            if (item.name.isNotEmpty) {
              referenceItems.add(item);
            }
          } catch (e) {
            // Skip invalid rows but continue processing
            // Debug info: Skipping invalid reference item row $i: $e
          }
        }
      }

      // Save to database for future use
      if (referenceItems.isNotEmpty) {
        await _databaseHelper.insertReferenceItems(referenceItems);
      }

      return referenceItems;
    } catch (e) {
      throw Exception('Failed to load reference items: $e');
    }
  }

  // Convert reference items to grocery items for a specific list
  List<GroceryItem> convertToGroceryItems(
      List<ReferenceItem> referenceItems, int listId) {
    return referenceItems
        .map((referenceItem) => referenceItem.toGroceryItem(listId: listId))
        .toList();
  }

  // Clear reference items from database (for testing or refresh)
  Future<void> clearReferenceItems() async {
    await _databaseHelper.clearReferenceItems();
  }

  // Helper methods
  double? _parseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value);
  }

  String? _parseString(String? value) {
    if (value == null || value.isEmpty) return null;
    return value;
  }

  bool _parseBoolean(String? value) {
    if (value == null || value.isEmpty) return false;
    final normalized = value.toUpperCase().trim();
    return normalized == 'Y' ||
        normalized == 'YES' ||
        normalized == '1' ||
        normalized == 'TRUE';
  }
}
