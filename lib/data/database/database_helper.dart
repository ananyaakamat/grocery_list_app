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
  static final List<GroceryItem> _webItems = [];
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
      onOpen: _onOpen,
    );
  }

  Future<void> _onOpen(Database db) async {
    // Fix any existing constraint violations after opening database
    await _repairPositionConstraints(db);
  }

  Future<void> _repairPositionConstraints(Database db) async {
    try {
      debugPrint('Starting position constraint repair...');

      // Get all lists
      final lists = await db.query(AppConstants.groceryListsTable);
      debugPrint('Found ${lists.length} lists to repair');

      for (final list in lists) {
        final listId = list['id'] as int;
        debugPrint('Repairing list $listId...');

        // Get all items for this list ordered by ID (as fallback order)
        final items = await db.query(
          AppConstants.itemsTable,
          where: 'list_id = ?',
          whereArgs: [listId],
          orderBy: 'id ASC',
        );

        if (items.isEmpty) {
          debugPrint('List $listId has no items, skipping...');
          continue;
        }

        debugPrint('List $listId has ${items.length} items');

        // Always reindex positions to ensure uniqueness
        await db.transaction((txn) async {
          // First set all to negative values to avoid conflicts
          for (int i = 0; i < items.length; i++) {
            final item = items[i];
            await txn.update(
              AppConstants.itemsTable,
              {'position': -(i + 1)},
              where: 'id = ?',
              whereArgs: [item['id']],
            );
          }

          // Then set to final positive values
          for (int i = 0; i < items.length; i++) {
            final item = items[i];
            final newPosition = i + 1;
            await txn.update(
              AppConstants.itemsTable,
              {'position': newPosition},
              where: 'id = ?',
              whereArgs: [item['id']],
            );
          }
        });

        debugPrint(
            'Successfully repaired position constraints for list $listId');
      }

      debugPrint('Position constraint repair completed successfully');
    } catch (e) {
      debugPrint('Error repairing position constraints: $e');
      // Don't rethrow - we don't want app startup to fail
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create grocery_lists table first (for foreign key relationship)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.groceryListsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        position INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        description TEXT DEFAULT '',
        url TEXT DEFAULT ''
      )
    ''');

    // Create items table with list_id foreign key
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.itemsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        qty_value REAL,
        qty_unit TEXT,
        price REAL NOT NULL DEFAULT 0.0,
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

    // Create index for grocery_lists position
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_grocery_lists_position 
      ON ${AppConstants.groceryListsTable}(position)
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
      'position': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration from version 1 to 2: Add multi-list support
      await _migrateToV2(db);
    }
    if (oldVersion < 3) {
      // Migration from version 2 to 3: Add list reordering support
      await _migrateToV3(db);
    }
    if (oldVersion < 4) {
      // Migration from version 3 to 4: Fix position constraint issues
      await _migrateToV4(db);
    }
    if (oldVersion < 5) {
      // Migration from version 4 to 5: Add price field support
      await _migrateToV5(db);
    }
    if (oldVersion < 6) {
      // Migration from version 5 to 6: Add description and URL fields
      await _migrateToV6(db);
    }
  }

  Future<void> _migrateToV2(Database db) async {
    try {
      // Create grocery_lists table
      await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.groceryListsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        position INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    '''); // Insert default list "My List" for existing users
      await db.insert(AppConstants.groceryListsTable, {
        'name': 'My List',
        'position': 0,
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

      debugPrint('Successfully migrated database to version 2');
    } catch (e) {
      debugPrint('Error during migration to V2: $e');
      rethrow;
    }
  }

  Future<void> _migrateToV3(Database db) async {
    try {
      // Add position column to grocery_lists table
      await db.execute('''
        ALTER TABLE ${AppConstants.groceryListsTable} 
        ADD COLUMN position INTEGER NOT NULL DEFAULT 0
      ''');

      // Set initial positions based on creation order (id)
      final lists = await db.query(
        AppConstants.groceryListsTable,
        orderBy: 'id ASC',
      );

      for (int i = 0; i < lists.length; i++) {
        await db.update(
          AppConstants.groceryListsTable,
          {'position': i},
          where: 'id = ?',
          whereArgs: [lists[i]['id']],
        );
      }

      // Create index for position
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_grocery_lists_position 
        ON ${AppConstants.groceryListsTable}(position)
      ''');

      debugPrint('Successfully migrated database to version 3');
    } catch (e) {
      debugPrint('Error during migration to V3: $e');
      rethrow;
    }
  }

  Future<void> _migrateToV4(Database db) async {
    try {
      debugPrint(
          'Starting migration to V4: Fixing position constraint issues...');

      // Check if grocery_lists table already has position column
      final tables = await db
          .rawQuery("PRAGMA table_info(${AppConstants.groceryListsTable})");
      final hasPosition = tables.any((column) => column['name'] == 'position');

      if (!hasPosition) {
        // Add position column to grocery_lists table if it doesn't exist
        await db.execute('''
          ALTER TABLE ${AppConstants.groceryListsTable} 
          ADD COLUMN position INTEGER NOT NULL DEFAULT 0
        ''');

        // Set initial positions based on creation order (id)
        final lists = await db.query(
          AppConstants.groceryListsTable,
          orderBy: 'id ASC',
        );

        for (int i = 0; i < lists.length; i++) {
          await db.update(
            AppConstants.groceryListsTable,
            {'position': i},
            where: 'id = ?',
            whereArgs: [lists[i]['id']],
          );
        }

        // Create index for position
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_grocery_lists_position 
          ON ${AppConstants.groceryListsTable}(position)
        ''');
      }

      // Fix any existing position constraint violations in items table
      await _repairPositionConstraints(db);

      debugPrint('Successfully migrated database to version 4');
    } catch (e) {
      debugPrint('Error during migration to V4: $e');
      rethrow;
    }
  }

  Future<void> _migrateToV5(Database db) async {
    try {
      debugPrint('Starting migration to V5: Adding price field support...');

      // Check if items table already has price column
      final tables =
          await db.rawQuery("PRAGMA table_info(${AppConstants.itemsTable})");
      final hasPrice = tables.any((column) => column['name'] == 'price');

      if (!hasPrice) {
        // Add price column to items table
        await db.execute('''
          ALTER TABLE ${AppConstants.itemsTable} 
          ADD COLUMN price REAL NOT NULL DEFAULT 0.0
        ''');

        debugPrint('Added price column to items table with default value 0.0');
      }

      debugPrint('Successfully migrated database to version 5');
    } catch (e) {
      debugPrint('Error during migration to V5: $e');
      rethrow;
    }
  }

  Future<void> _migrateToV6(Database db) async {
    try {
      debugPrint(
          'Starting migration to V6: Adding description and URL fields...');

      // Check if grocery_lists table already has description column
      final tables = await db
          .rawQuery("PRAGMA table_info(${AppConstants.groceryListsTable})");
      final hasDescription =
          tables.any((column) => column['name'] == 'description');
      final hasUrl = tables.any((column) => column['name'] == 'url');

      if (!hasDescription) {
        // Add description column to grocery_lists table
        await db.execute('''
          ALTER TABLE ${AppConstants.groceryListsTable} 
          ADD COLUMN description TEXT DEFAULT ''
        ''');
        debugPrint('Added description column to grocery_lists table');
      }

      if (!hasUrl) {
        // Add url column to grocery_lists table
        await db.execute('''
          ALTER TABLE ${AppConstants.groceryListsTable} 
          ADD COLUMN url TEXT DEFAULT ''
        ''');
        debugPrint('Added url column to grocery_lists table');
      }

      debugPrint('Successfully migrated database to version 6');
    } catch (e) {
      debugPrint('Error during migration to V6: $e');
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

  // Helper method to update list's updated_at timestamp
  Future<void> _updateListTimestamp(int listId) async {
    if (kIsWeb) return; // Not applicable for web

    final db = await database;
    await db.update(
      AppConstants.groceryListsTable,
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [listId],
    );
  }

  Future<int> insertItem(GroceryItem item) async {
    if (kIsWeb) {
      // For web, add to in-memory list and return a fake ID
      final newItem = item.copyWith(id: DateTime.now().millisecondsSinceEpoch);
      _webItems.add(newItem);
      _webLastSaved = DateTime.now();
      return newItem.id!;
    }

    final db = await database;
    final result = await db.insert(
      AppConstants.itemsTable,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Update the list's updated_at timestamp
    await _updateListTimestamp(item.listId);

    // Update global last saved timestamp
    await _updateLastSavedTimestamp();

    return result;
  }

  Future<void> updateItem(GroceryItem item) async {
    if (kIsWeb) {
      // For web, update in-memory list
      final index = _webItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _webItems[index] = item;
      }
      _webLastSaved = DateTime.now();
      return;
    }

    final db = await database;
    await db.update(
      AppConstants.itemsTable,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );

    // Update the list's updated_at timestamp
    await _updateListTimestamp(item.listId);

    // Update global last saved timestamp
    await _updateLastSavedTimestamp();
  }

  Future<void> deleteItem(int id) async {
    if (kIsWeb) {
      // For web, remove from in-memory list
      _webItems.removeWhere((item) => item.id == id);
      _webLastSaved = DateTime.now();
      return;
    }

    final db = await database;

    // Get the listId before deleting
    final result = await db.query(
      AppConstants.itemsTable,
      columns: ['list_id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    final listId = result.isNotEmpty ? result.first['list_id'] as int : null;

    await db.delete(
      AppConstants.itemsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    // Update the list timestamp if we found the listId
    if (listId != null) {
      await _updateListTimestamp(listId);
    }

    // Update global last saved timestamp
    await _updateLastSavedTimestamp();
  }

  Future<void> deleteItemsByIds(List<int> ids) async {
    if (ids.isEmpty) return;

    if (kIsWeb) {
      // For web, remove items from in-memory list
      _webItems.removeWhere((item) => ids.contains(item.id));
      _webLastSaved = DateTime.now();
      return;
    }

    final db = await database;

    // Get all affected listIds before deleting
    final placeholders = ids.map((_) => '?').join(',');
    final result = await db.query(
      AppConstants.itemsTable,
      columns: ['DISTINCT list_id'],
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    final affectedListIds = result.map((row) => row['list_id'] as int).toList();

    await db.delete(
      AppConstants.itemsTable,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    // Update timestamps for all affected lists
    for (final listId in affectedListIds) {
      await _updateListTimestamp(listId);
    }

    // Update global last saved timestamp
    await _updateLastSavedTimestamp();
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
    if (kIsWeb) {
      // For web, update positions in memory
      for (int i = 0; i < items.length; i++) {
        final updatedItem = items[i].copyWith(position: i + 1);
        final index = _webItems.indexWhere((item) => item.id == updatedItem.id);
        if (index != -1) {
          _webItems[index] = updatedItem;
        }
      }
      _webLastSaved = DateTime.now();
      return;
    }

    final db = await database;

    await db.transaction((txn) async {
      // Step 1: Set all items to temporary negative positions to avoid constraint conflicts
      for (int i = 0; i < items.length; i++) {
        await txn.update(
          AppConstants.itemsTable,
          {'position': -(i + 1)}, // Use negative positions temporarily
          where: 'id = ?',
          whereArgs: [items[i].id],
        );
      }

      // Step 2: Update to final positive positions
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

    // Update global last saved timestamp after reindexing
    await _updateLastSavedTimestamp();
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

  // Helper method to update the global last saved timestamp
  Future<void> _updateLastSavedTimestamp() async {
    if (kIsWeb) {
      _webLastSaved = DateTime.now();
      return;
    }

    await setMetaValue(
        AppConstants.lastSavedAtKey, DateTime.now().toIso8601String());
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
          position: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.groceryListsTable,
      orderBy: 'position ASC, created_at ASC',
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
          position: 0,
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

    // Get the maximum position and add 1 for new list
    final maxPositionResult = await db.rawQuery(
        'SELECT MAX(position) as max_pos FROM ${AppConstants.groceryListsTable}');
    final maxPosition = maxPositionResult.first['max_pos'] as int? ?? -1;

    // Create the list with the new position
    final listWithPosition = groceryList.copyWith(position: maxPosition + 1);

    return await db.insert(
      AppConstants.groceryListsTable,
      listWithPosition.toMap(),
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

  // Reorder grocery lists
  Future<void> reorderGroceryLists(List<GroceryList> reorderedLists) async {
    if (kIsWeb) {
      // For web, no-op (only one list)
      return;
    }

    final db = await database;
    await db.transaction((txn) async {
      for (int i = 0; i < reorderedLists.length; i++) {
        final list = reorderedLists[i];
        await txn.update(
          AppConstants.groceryListsTable,
          {'position': i, 'updated_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [list.id],
        );
      }
    });
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

  // Copy a grocery list and all its items
  Future<int> copyGroceryList(int sourceListId, String newListName) async {
    if (kIsWeb) {
      // For web, return a fake ID
      return DateTime.now().millisecondsSinceEpoch;
    }

    final db = await database;

    return await db.transaction<int>((txn) async {
      // Get the source list to copy basic properties
      final sourceListMaps = await txn.query(
        AppConstants.groceryListsTable,
        where: 'id = ?',
        whereArgs: [sourceListId],
        limit: 1,
      );

      if (sourceListMaps.isEmpty) {
        throw Exception('Source list not found');
      }

      final sourceList = GroceryList.fromMap(sourceListMaps.first);

      // Get the maximum position and add 1 for new list
      final maxPositionResult = await txn.rawQuery(
          'SELECT MAX(position) as max_pos FROM ${AppConstants.groceryListsTable}');
      final maxPosition = maxPositionResult.first['max_pos'] as int? ?? -1;

      // Create the new list
      final newList = GroceryList.create(name: newListName).copyWith(
        position: maxPosition + 1,
        description: sourceList.description,
        url: sourceList.url,
      );

      final newListId = await txn.insert(
        AppConstants.groceryListsTable,
        newList.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      // Get all items from the source list
      final sourceItemMaps = await txn.query(
        AppConstants.itemsTable,
        where: 'list_id = ?',
        whereArgs: [sourceListId],
        orderBy: 'position ASC',
      );

      // Copy all items to the new list
      for (final itemMap in sourceItemMaps) {
        final sourceItem = GroceryItemExtensions.fromMap(itemMap);
        final newItem = sourceItem.copyWith(
          id: null, // Let database assign new ID
          listId: newListId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await txn.insert(
          AppConstants.itemsTable,
          newItem.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return newListId;
    });
  }
}
