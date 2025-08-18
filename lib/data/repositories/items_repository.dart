import '../database/database_helper.dart';
import '../models/grocery_item.dart';

abstract class ItemsRepository {
  Future<List<GroceryItem>> fetchAll();
  Future<void> saveAll(List<GroceryItem> items);
  Future<void> clear();
  Future<GroceryItem?> getById(int id);
  Future<int> add(GroceryItem item);
  Future<void> update(GroceryItem item);
  Future<void> delete(int id);
  Future<void> deleteMultiple(List<int> ids);
  Future<DateTime?> getLastSavedAt();
  Future<int> getNextPosition();
  Future<void> reindexPositions(List<GroceryItem> items);
}

class ItemsRepositoryImpl implements ItemsRepository {
  final DatabaseHelper _databaseHelper;

  ItemsRepositoryImpl({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  @override
  Future<List<GroceryItem>> fetchAll() async {
    return await _databaseHelper.getAllItems();
  }

  @override
  Future<void> saveAll(List<GroceryItem> items) async {
    return await _databaseHelper.saveAllItems(items);
  }

  @override
  Future<void> clear() async {
    return await _databaseHelper.clearAllItems();
  }

  @override
  Future<GroceryItem?> getById(int id) async {
    return await _databaseHelper.getItemById(id);
  }

  @override
  Future<int> add(GroceryItem item) async {
    return await _databaseHelper.insertItem(item);
  }

  @override
  Future<void> update(GroceryItem item) async {
    return await _databaseHelper.updateItem(item);
  }

  @override
  Future<void> delete(int id) async {
    return await _databaseHelper.deleteItem(id);
  }

  @override
  Future<void> deleteMultiple(List<int> ids) async {
    return await _databaseHelper.deleteItemsByIds(ids);
  }

  @override
  Future<DateTime?> getLastSavedAt() async {
    return await _databaseHelper.getLastSavedAt();
  }

  @override
  Future<int> getNextPosition() async {
    return await _databaseHelper.getNextPosition();
  }

  @override
  Future<void> reindexPositions(List<GroceryItem> items) async {
    return await _databaseHelper.reindexPositions(items);
  }
}
