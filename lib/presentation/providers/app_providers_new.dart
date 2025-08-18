import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/items_repository.dart';
import '../../data/repositories/csv_repository.dart';
import '../../data/repositories/grocery_lists_repository.dart'; // Added for CR1
import '../../data/models/grocery_item.dart';
import '../../data/models/grocery_list.dart'; // Added for CR1
import '../../data/database/database_helper.dart'; // Added for CR1

// Repository providers
final itemsRepositoryProvider = Provider<ItemsRepository>((ref) {
  return ItemsRepositoryImpl();
});

final csvRepositoryProvider = Provider<CsvRepository>((ref) {
  return CsvRepository();
});

// Added for CR1: Grocery Lists Repository Provider
final groceryListsRepositoryProvider = Provider<GroceryListsRepository>((ref) {
  return GroceryListsRepositoryImpl(DatabaseHelper());
});

// Added for CR1: Current Selected List Provider
final selectedGroceryListProvider = StateProvider<GroceryList?>((ref) => null);

// Added for CR1: Grocery Lists Notifier
class GroceryListsNotifier
    extends StateNotifier<AsyncValue<List<GroceryList>>> {
  final GroceryListsRepository _repository;

  GroceryListsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadLists();
  }

  Future<void> loadLists() async {
    try {
      state = const AsyncValue.loading();
      final lists = await _repository.getAll();
      state = AsyncValue.data(lists);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<int?> addList(GroceryList list) async {
    try {
      final id = await _repository.add(list);
      await loadLists(); // Refresh the list
      return id;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  Future<void> updateList(GroceryList list) async {
    try {
      await _repository.update(list);
      await loadLists(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteList(int id) async {
    try {
      await _repository.delete(id);
      await loadLists(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<bool> nameExists(String name, {int? excludeId}) async {
    try {
      return await _repository.nameExists(name, excludeId: excludeId);
    } catch (error) {
      return false;
    }
  }

  Future<int> getItemCount(int listId) async {
    try {
      return await _repository.getItemCount(listId);
    } catch (error) {
      return 0;
    }
  }
}

final groceryListsProvider =
    StateNotifierProvider<GroceryListsNotifier, AsyncValue<List<GroceryList>>>(
        (ref) {
  final repository = ref.watch(groceryListsRepositoryProvider);
  return GroceryListsNotifier(repository);
});

// Items state provider (updated to be list-aware)
class ItemsNotifier extends StateNotifier<AsyncValue<List<GroceryItem>>> {
  final ItemsRepository _repository;
  int? _currentListId;

  ItemsNotifier(this._repository) : super(const AsyncValue.loading());

  int? get currentListId => _currentListId;

  Future<void> loadItems() async {
    try {
      state = const AsyncValue.loading();
      final items = await _repository.fetchAll();
      state = AsyncValue.data(items);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Added for CR1: Load items for specific list
  Future<void> loadItemsForList(int listId) async {
    try {
      _currentListId = listId;
      state = const AsyncValue.loading();
      final items = await _repository.fetchByListId(listId);
      state = AsyncValue.data(items);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addItem(GroceryItem item) async {
    try {
      await _repository.add(item);
      if (_currentListId != null) {
        await loadItemsForList(_currentListId!);
      } else {
        await loadItems();
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateItem(GroceryItem item) async {
    try {
      await _repository.update(item);
      if (_currentListId != null) {
        await loadItemsForList(_currentListId!);
      } else {
        await loadItems();
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await _repository.delete(id);

      final currentItems = state.value ?? [];
      final updatedItems = currentItems.where((item) => item.id != id).toList();
      final reindexedItems = _reindexItems(updatedItems);
      await _repository.reindexPositions(reindexedItems);

      if (_currentListId != null) {
        await loadItemsForList(_currentListId!);
      } else {
        await loadItems();
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteMultipleItems(List<int> ids) async {
    try {
      await _repository.deleteMultiple(ids);

      final currentItems = state.value ?? [];
      final updatedItems =
          currentItems.where((item) => !ids.contains(item.id)).toList();
      final reindexedItems = _reindexItems(updatedItems);

      await _repository.reindexPositions(reindexedItems);

      if (_currentListId != null) {
        await loadItemsForList(_currentListId!);
      } else {
        await loadItems();
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> reorderItems(List<GroceryItem> items) async {
    try {
      final reindexedItems = _reindexItems(items);
      await _repository.saveAll(reindexedItems);
      state = AsyncValue.data(reindexedItems);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<GroceryItem> _reindexItems(List<GroceryItem> items) {
    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return item.copyWith(position: index + 1);
    }).toList();
  }

  // Get items statistics
  List<GroceryItem> get neededItems {
    final items = state.value ?? [];
    return items.where((item) => item.needed).toList();
  }

  List<GroceryItem> get notNeededItems {
    final items = state.value ?? [];
    return items.where((item) => !item.needed).toList();
  }

  int get totalCount => state.value?.length ?? 0;
  int get neededCount => neededItems.length;
  int get notNeededCount => notNeededItems.length;

  // Selection management
  final Set<int> _selectedItemIds = {};

  Set<int> get selectedItemIds => _selectedItemIds;
  int get selectedCount => _selectedItemIds.length;
  bool get hasSelection => _selectedItemIds.isNotEmpty;
  bool get allSelected => _selectedItemIds.length == totalCount;

  void toggleItemSelection(int itemId) {
    if (_selectedItemIds.contains(itemId)) {
      _selectedItemIds.remove(itemId);
    } else {
      _selectedItemIds.add(itemId);
    }
    // Trigger a state update to notify listeners
    state = state;
  }

  void selectAll() {
    final items = state.value ?? [];
    _selectedItemIds.clear();
    _selectedItemIds.addAll(items.map((item) => item.id!));
    // Trigger a state update
    state = state;
  }

  void clearSelection() {
    _selectedItemIds.clear();
    // Trigger a state update
    state = state;
  }

  Future<void> deleteSelected() async {
    if (_selectedItemIds.isNotEmpty) {
      await deleteMultipleItems(_selectedItemIds.toList());
      clearSelection();
    }
  }
}

final itemsProvider =
    StateNotifierProvider<ItemsNotifier, AsyncValue<List<GroceryItem>>>((ref) {
  final repository = ref.watch(itemsRepositoryProvider);
  return ItemsNotifier(repository);
});

// Last saved provider
final lastSavedProvider = FutureProvider<DateTime?>((ref) async {
  final repository = ref.watch(itemsRepositoryProvider);
  return await repository.getLastSavedAt();
});

// App state provider for UI states
enum AppFilter { all, needed, notNeeded }

enum AppSort { position, name, dateAdded }

class AppState {
  final AppFilter filter;
  final AppSort sort;
  final bool isSearching;
  final String searchQuery;

  const AppState({
    this.filter = AppFilter.all,
    this.sort = AppSort.position,
    this.isSearching = false,
    this.searchQuery = '',
  });

  AppState copyWith({
    AppFilter? filter,
    AppSort? sort,
    bool? isSearching,
    String? searchQuery,
  }) {
    return AppState(
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState());

  void setFilter(AppFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setSort(AppSort sort) {
    state = state.copyWith(sort: sort);
  }

  void setSearching(bool isSearching) {
    state = state.copyWith(isSearching: isSearching);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearSearch() {
    state = state.copyWith(isSearching: false, searchQuery: '');
  }
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

// Theme mode provider
final themeModeProvider =
    StateProvider<bool>((ref) => false); // false = light, true = dark
