import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/grocery_item.dart';
import '../../core/constants/app_constants.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  // Web fallback storage
  static List<GroceryItem> _webItems = [];
  static DateTime? _webLastSaved;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<Database> get database async {
    if (kIsWeb) {
      // For web, we'll handle storage differently
      throw UnsupportedError('SQLite not supported on web');
    }
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create items table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.itemsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        qty_value REAL,
        qty_unit TEXT,
        needed INTEGER NOT NULL DEFAULT 0,
        position INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for items table
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_items_position 
      ON ${AppConstants.itemsTable}(position)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_items_needed 
      ON ${AppConstants.itemsTable}(needed)
    ''');

    // Create app_meta table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.appMetaTable} (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 1) {
      // Future migrations will be handled here
    }
  }

  // Items CRUD operations
  Future<List<GroceryItem>> getAllItems() async {
    if (kIsWeb) {
      // For web, return in-memory items sorted by position
      // Initialize with sample data if empty
      if (_webItems.isEmpty) {
        _initializeWebSampleData();
      }
      return List.from(_webItems)
        ..sort((a, b) => a.position.compareTo(b.position));
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.itemsTable,
      orderBy: 'position ASC',
    );

    return List.generate(maps.length, (i) {
      return GroceryItemExtensions.fromMap(maps[i]);
    });
  }

  void _initializeWebSampleData() {
    final sampleItems = [
      GroceryItem(
        id: 1,
        name: 'Rice',
        qtyValue: 5.0,
        qtyUnit: 'kg',
        needed: true,
        position: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      GroceryItem(
        id: 2,
        name: 'Dal (Toor)',
        qtyValue: 1.0,
        qtyUnit: 'kg',
        needed: true,
        position: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      GroceryItem(
        id: 3,
        name: 'Onions',
        qtyValue: 2.0,
        qtyUnit: 'kg',
        needed: false,
        position: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
    _webItems.addAll(sampleItems);
  }

  Future<GroceryItem?> getItemById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.itemsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return GroceryItemExtensions.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertItem(GroceryItem item) async {
    if (kIsWeb) {
      // For web, add to in-memory list and return a fake ID
      final newItem = item.copyWith(id: DateTime.now().millisecondsSinceEpoch);
      _webItems.add(newItem);
      return newItem.id!;
    }

    final db = await database;
    return await db.insert(
      AppConstants.itemsTable,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateItem(GroceryItem item) async {
    if (kIsWeb) {
      // For web, update in-memory list
      final index = _webItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _webItems[index] = item;
      }
      return;
    }

    final db = await database;
    await db.update(
      AppConstants.itemsTable,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteItem(int id) async {
    if (kIsWeb) {
      // For web, remove from in-memory list
      _webItems.removeWhere((item) => item.id == id);
      return;
    }

    final db = await database;
    await db.delete(
      AppConstants.itemsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteItemsByIds(List<int> ids) async {
    if (ids.isEmpty) return;

    if (kIsWeb) {
      // For web, remove items from in-memory list
      _webItems.removeWhere((item) => ids.contains(item.id));
      return;
    }

    final db = await database;
    final placeholders = ids.map((_) => '?').join(',');
    await db.delete(
      AppConstants.itemsTable,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  // Bulk operations for import/export and save functionality
  Future<void> saveAllItems(List<GroceryItem> items) async {
    if (kIsWeb) {
      // For web, replace in-memory items
      _webItems = List.from(items);
      _webLastSaved = DateTime.now();
      return;
    }

    final db = await database;

    await db.transaction((txn) async {
      // Clear existing items
      await txn.delete(AppConstants.itemsTable);

      // Insert all items
      for (final item in items) {
        await txn.insert(
          AppConstants.itemsTable,
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Update last saved timestamp
      await txn.insert(
        AppConstants.appMetaTable,
        {
          'key': AppConstants.lastSavedAtKey,
          'value': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> clearAllItems() async {
    final db = await database;
    await db.delete(AppConstants.itemsTable);
  }

  // Position management for reordering
  Future<void> reindexPositions(List<GroceryItem> items) async {
    final db = await database;

    await db.transaction((txn) async {
      for (int i = 0; i < items.length; i++) {
        final updatedItem = items[i].copyWith(position: i + 1);
        await txn.update(
          AppConstants.itemsTable,
          updatedItem.toMap(),
          where: 'id = ?',
          whereArgs: [updatedItem.id],
        );
      }
    });
  }

  // App Meta operations
  Future<String?> getMetaValue(String key) async {
    if (kIsWeb) {
      // For web, return hardcoded values or null
      if (key == AppConstants.lastSavedAtKey && _webLastSaved != null) {
        return _webLastSaved!.toIso8601String();
      }
      return null;
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.appMetaTable,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> setMetaValue(String key, String value) async {
    final db = await database;
    await db.insert(
      AppConstants.appMetaTable,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DateTime?> getLastSavedAt() async {
    if (kIsWeb) {
      // For web, return in-memory timestamp
      return _webLastSaved;
    }

    final timestamp = await getMetaValue(AppConstants.lastSavedAtKey);
    if (timestamp != null) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Statistics and utility methods
  Future<int> getItemCount() async {
    final db = await database;
    final result = await db
        .rawQuery('SELECT COUNT(*) as count FROM ${AppConstants.itemsTable}');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getNeededItemCount() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${AppConstants.itemsTable} WHERE needed = 1');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get next position for new items
  Future<int> getNextPosition() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT MAX(position) as max_pos FROM ${AppConstants.itemsTable}');
    final maxPosition = Sqflite.firstIntValue(result) ?? 0;
    return maxPosition + 1;
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // For testing - clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(AppConstants.itemsTable);
      await txn.delete(AppConstants.appMetaTable);
    });
  }
}
