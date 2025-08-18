import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/grocery_item.dart';
import '../models/grocery_list.dart'; // Added for CR1 multi-list feature
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
    // Create grocery_lists table first (for foreign key relationship)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.groceryListsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create items table with list_id foreign key
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.itemsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        qty_value REAL,
        qty_unit TEXT,
        needed INTEGER NOT NULL DEFAULT 0,
        position INTEGER NOT NULL,
        list_id INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(list_id) REFERENCES ${AppConstants.groceryListsTable}(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for items table
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_items_position_per_list 
      ON ${AppConstants.itemsTable}(list_id, position)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_items_needed 
      ON ${AppConstants.itemsTable}(needed)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_items_list_id 
      ON ${AppConstants.itemsTable}(list_id)
    ''');

    // Create app_meta table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.appMetaTable} (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Insert default grocery list for new installations
    await db.insert(AppConstants.groceryListsTable, {
      'name': 'My List',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration from version 1 to 2: Add multi-list support
      await _migrateToV2(db);
    }
  }

  Future<void> _migrateToV2(Database db) async {
    try {
      // Create grocery_lists table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${AppConstants.groceryListsTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Insert default list "My List" for existing users
      await db.insert(AppConstants.groceryListsTable, {
        'name': 'My List',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Add list_id column to items table
      await db.execute('''
        ALTER TABLE ${AppConstants.itemsTable} 
        ADD COLUMN list_id INTEGER NOT NULL DEFAULT 1
      ''');

      // Create new indexes
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_items_list_id 
        ON ${AppConstants.itemsTable}(list_id)
      ''');

      // Drop old position index and create new compound index
      await db.execute('''
        DROP INDEX IF EXISTS idx_items_position
      ''');

      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_items_position_per_list 
        ON ${AppConstants.itemsTable}(list_id, position)
      ''');

      print('Successfully migrated database to version 2');
    } catch (e) {
      print('Error during migration to V2: $e');
      rethrow;
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
        listId: 1, // Default list ID for web
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
        listId: 1, // Default list ID for web
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
        listId: 1, // Default list ID for web
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
      // For web, replace items for the specific list only
      if (items.isNotEmpty) {
        final listId = items.first.listId;
        // Remove existing items for this list
        _webItems.removeWhere((item) => item.listId == listId);
        // Add new items
        _webItems.addAll(items);
      }
      _webLastSaved = DateTime.now();
      return;
    }

    final db = await database;

    await db.transaction((txn) async {
      // Clear existing items for the specific list only
      if (items.isNotEmpty) {
        final listId = items.first.listId;
        await txn.delete(
          AppConstants.itemsTable,
          where: 'list_id = ?',
          whereArgs: [listId],
        );
      }

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
      await txn.delete(AppConstants.groceryListsTable);
      await txn.delete(AppConstants.appMetaTable);
    });
  }

  // ==================== GROCERY LISTS CRUD OPERATIONS ====================

  // Get all grocery lists
  Future<List<GroceryList>> getAllGroceryLists() async {
    if (kIsWeb) {
      // For web, return a default list
      return [
        GroceryList(
          id: 1,
          name: 'My List',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.groceryListsTable,
      orderBy: 'created_at ASC',
    );

    return List.generate(maps.length, (i) {
      return GroceryList.fromMap(maps[i]);
    });
  }

  // Get grocery list by ID
  Future<GroceryList?> getGroceryListById(int id) async {
    if (kIsWeb) {
      // For web, return default list if ID is 1
      if (id == 1) {
        return GroceryList(
          id: 1,
          name: 'My List',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      return null;
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.groceryListsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return GroceryList.fromMap(maps.first);
    }
    return null;
  }

  // Insert grocery list
  Future<int> insertGroceryList(GroceryList groceryList) async {
    if (kIsWeb) {
      // For web, return a fake ID
      return DateTime.now().millisecondsSinceEpoch;
    }

    final db = await database;
    return await db.insert(
      AppConstants.groceryListsTable,
      groceryList.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort, // Enforce unique names
    );
  }

  // Update grocery list
  Future<void> updateGroceryList(GroceryList groceryList) async {
    if (kIsWeb) {
      // For web, no-op
      return;
    }

    final db = await database;
    await db.update(
      AppConstants.groceryListsTable,
      groceryList.toMap(),
      where: 'id = ?',
      whereArgs: [groceryList.id],
    );
  }

  // Delete grocery list and all its items
  Future<void> deleteGroceryList(int id) async {
    if (kIsWeb) {
      // For web, no-op (can't delete the only list)
      return;
    }

    final db = await database;
    await db.transaction((txn) async {
      // Delete all items in this list first
      await txn.delete(
        AppConstants.itemsTable,
        where: 'list_id = ?',
        whereArgs: [id],
      );

      // Then delete the list
      await txn.delete(
        AppConstants.groceryListsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // Check if grocery list name exists (for validation)
  Future<bool> groceryListNameExists(String name, {int? excludeId}) async {
    if (kIsWeb) {
      // For web, only "My List" exists
      return name.toLowerCase() == 'my list' && excludeId != 1;
    }

    final db = await database;
    final whereClause =
        excludeId != null ? 'LOWER(name) = ? AND id != ?' : 'LOWER(name) = ?';
    final whereArgs = excludeId != null
        ? [name.toLowerCase(), excludeId]
        : [name.toLowerCase()];

    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.groceryListsTable,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  // Check if item name exists in a specific list (for validation)
  Future<bool> itemNameExistsInList(String name, int listId,
      {int? excludeId}) async {
    if (kIsWeb) {
      // For web, check in-memory items
      return _webItems.any((item) =>
          item.listId == listId &&
          item.name.toLowerCase() == name.toLowerCase() &&
          (excludeId == null || item.id != excludeId));
    }

    final db = await database;
    final whereClause = excludeId != null
        ? 'LOWER(name) = ? AND list_id = ? AND id != ?'
        : 'LOWER(name) = ? AND list_id = ?';
    final whereArgs = excludeId != null
        ? [name.toLowerCase(), listId, excludeId]
        : [name.toLowerCase(), listId];

    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.itemsTable,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  // Get items count for a specific list
  Future<int> getItemCountForList(int listId) async {
    if (kIsWeb) {
      return _webItems.where((item) => item.listId == listId).length;
    }

    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.itemsTable} WHERE list_id = ?',
      [listId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Update items methods to be list-aware
  Future<List<GroceryItem>> getItemsByListId(int listId) async {
    if (kIsWeb) {
      // For web, filter in-memory items by list ID
      if (_webItems.isEmpty) {
        _initializeWebSampleData();
      }
      return _webItems.where((item) => item.listId == listId).toList()
        ..sort((a, b) => a.position.compareTo(b.position));
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.itemsTable,
      where: 'list_id = ?',
      whereArgs: [listId],
      orderBy: 'position ASC',
    );

    return List.generate(maps.length, (i) {
      return GroceryItemExtensions.fromMap(maps[i]);
    });
  }

  // Get next position for new items in a specific list
  Future<int> getNextPositionForList(int listId) async {
    if (kIsWeb) {
      final listItems =
          _webItems.where((item) => item.listId == listId).toList();
      if (listItems.isEmpty) return 1;
      return listItems
              .map((item) => item.position)
              .reduce((a, b) => a > b ? a : b) +
          1;
    }

    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(position) as max_pos FROM ${AppConstants.itemsTable} WHERE list_id = ?',
      [listId],
    );
    final maxPosition = Sqflite.firstIntValue(result) ?? 0;
    return maxPosition + 1;
  }
}
