import '../database/database_helper.dart';
import '../models/grocery_list.dart';

abstract class GroceryListsRepository {
  Future<List<GroceryList>> getAll();
  Future<GroceryList?> getById(int id);
  Future<int> add(GroceryList groceryList);
  Future<void> update(GroceryList groceryList);
  Future<void> delete(int id);
  Future<bool> nameExists(String name, {int? excludeId});
  Future<int> getItemCount(int listId);
  Future<void> reorderLists(List<GroceryList> reorderedLists);
  Future<int> copyList(int sourceListId, String newListName);
}

class GroceryListsRepositoryImpl implements GroceryListsRepository {
  final DatabaseHelper _databaseHelper;

  GroceryListsRepositoryImpl(this._databaseHelper);

  @override
  Future<List<GroceryList>> getAll() async {
    return await _databaseHelper.getAllGroceryLists();
  }

  @override
  Future<GroceryList?> getById(int id) async {
    return await _databaseHelper.getGroceryListById(id);
  }

  @override
  Future<int> add(GroceryList groceryList) async {
    return await _databaseHelper.insertGroceryList(groceryList);
  }

  @override
  Future<void> update(GroceryList groceryList) async {
    return await _databaseHelper.updateGroceryList(groceryList);
  }

  @override
  Future<void> delete(int id) async {
    return await _databaseHelper.deleteGroceryList(id);
  }

  @override
  Future<bool> nameExists(String name, {int? excludeId}) async {
    return await _databaseHelper.groceryListNameExists(name,
        excludeId: excludeId);
  }

  @override
  Future<int> getItemCount(int listId) async {
    return await _databaseHelper.getItemCountForList(listId);
  }

  @override
  Future<void> reorderLists(List<GroceryList> reorderedLists) async {
    return await _databaseHelper.reorderGroceryLists(reorderedLists);
  }

  @override
  Future<int> copyList(int sourceListId, String newListName) async {
    return await _databaseHelper.copyGroceryList(sourceListId, newListName);
  }
}
