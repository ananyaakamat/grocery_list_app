import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/items_repository.dart';
import '../../data/repositories/csv_repository.dart';
import '../../data/repositories/reference_item_repository.dart';
import '../../data/repositories/grocery_lists_repository.dart'; // Added for CR1
import '../../data/models/grocery_item.dart';
import '../../data/models/grocery_list.dart'; // Added for CR1
import '../../data/database/database_helper.dart'; // Added for CR1

// Item filter options
enum ItemFilter {
  all,
  needed,
  notNeeded,
}

extension ItemFilterExtension on ItemFilter {
  String get displayName {
    switch (this) {
      case ItemFilter.all:
        return 'All';
      case ItemFilter.needed:
        return 'Needed';
      case ItemFilter.notNeeded:
        return 'Not Needed';
    }
  }
}

// Repository providers
final itemsRepositoryProvider = Provider<ItemsRepository>((ref) {
  return ItemsRepositoryImpl();
});

final csvRepositoryProvider = Provider<CsvRepository>((ref) {
  return CsvRepository();
});

final referenceItemRepositoryProvider =
    Provider<ReferenceItemRepository>((ref) {
  return ReferenceItemRepository();
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

  Future<int?> copyList(int sourceListId, String newListName) async {
    try {
      final newListId = await _repository.copyList(sourceListId, newListName);
      await loadLists(); // Refresh the list
      return newListId;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  Future<void> reorderLists(List<GroceryList> reorderedLists) async {
    try {
      // Update the state immediately for UI responsiveness
      state = AsyncValue.data(reorderedLists);

      // Persist the reordering to database
      await _repository.reorderLists(reorderedLists);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      // Reload from database if reordering fails
      await loadLists();
    }
  }
}

final groceryListsProvider =
    StateNotifierProvider<GroceryListsNotifier, AsyncValue<List<GroceryList>>>(
        (ref) {
  final repository = ref.watch(groceryListsRepositoryProvider);
  return GroceryListsNotifier(repository);
});

// Filter and search providers
final itemFilterProvider = StateProvider<ItemFilter>((ref) => ItemFilter.all);
final searchQueryProvider = StateProvider<String>((ref) => '');

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
      // Sort and reindex items after loading
      await _sortAndReindexAllItems();
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
      // Sort and reindex items after loading for specific list
      await _sortAndReindexAllItems();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addItem(GroceryItem item) async {
    try {
      final newId = await _repository.add(item);
      // Create the new item with the assigned ID
      final newItem = item.copyWith(id: newId);
      // Instead of full reload, add to existing state
      final currentItems = state.value ?? [];
      final updatedItems = [...currentItems, newItem];
      state = AsyncValue.data(updatedItems);
      // Sort and reindex all items after adding
      await _sortAndReindexAllItems();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateItem(GroceryItem item) async {
    try {
      await _repository.update(item);
      // Instead of full reload, update specific item in state
      final currentItems = state.value ?? [];
      final updatedItems = currentItems.map((existingItem) {
        return existingItem.id == item.id ? item : existingItem;
      }).toList();
      state = AsyncValue.data(updatedItems);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      // First delete from database
      await _repository.delete(id);

      // Instead of full reload, remove specific item from state
      final currentItems = state.value ?? [];
      final updatedItems = currentItems.where((item) => item.id != id).toList();
      state = AsyncValue.data(updatedItems);

      // Sort and reindex remaining items
      await _sortAndReindexAllItems();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteMultipleItems(List<int> ids) async {
    try {
      // First delete from database
      await _repository.deleteMultiple(ids);

      // Instead of full reload, remove specific items from state
      final currentItems = state.value ?? [];
      final updatedItems =
          currentItems.where((item) => !ids.contains(item.id)).toList();
      state = AsyncValue.data(updatedItems);

      // Sort and reindex remaining items
      await _sortAndReindexAllItems();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteAllItems() async {
    try {
      final currentItems = state.value ?? [];
      if (currentItems.isEmpty) return;

      final allIds = currentItems.map((item) => item.id!).toList();
      await deleteMultipleItems(allIds);
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

  // Helper method to sort items alphabetically and update positions in database
  Future<void> _sortAndReindexAllItems() async {
    try {
      final currentItems = state.value ?? [];
      if (currentItems.isEmpty) return;

      // Sort alphabetically
      final sortedItems = List<GroceryItem>.from(currentItems);
      sortedItems
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      // Reindex positions
      final reindexedItems = sortedItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return item.copyWith(position: index + 1);
      }).toList();

      // Update positions in database
      await _repository.reindexPositions(reindexedItems);

      // Update state with sorted and reindexed items
      state = AsyncValue.data(reindexedItems);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
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
    // Trigger a state update to notify listeners by creating a new AsyncValue
    final currentItems = state.value ?? [];
    state = AsyncValue.data(currentItems);
  }

  void selectAll() {
    final items = state.value ?? [];
    _selectedItemIds.clear();
    _selectedItemIds.addAll(items.map((item) => item.id!));
    // Trigger a state update by creating a new AsyncValue
    state = AsyncValue.data(items);
  }

  void clearSelection() {
    _selectedItemIds.clear();
    // Trigger a state update by creating a new AsyncValue
    final currentItems = state.value ?? [];
    state = AsyncValue.data(currentItems);
  }

  Future<void> deleteSelected() async {
    if (_selectedItemIds.isNotEmpty) {
      await deleteMultipleItems(_selectedItemIds.toList());
      clearSelection();
    }
  }

  // Added missing methods for compatibility
  void toggleSelectAll() {
    if (allSelected) {
      clearSelection();
    } else {
      selectAll();
    }
  }

  Future<void> toggleAllNeeded() async {
    final items = state.value ?? [];
    if (items.isEmpty) return;

    try {
      // Check if all items are needed
      final allNeeded = items.every((item) => item.needed);

      // Update all items in state immediately
      final updatedItems =
          items.map((item) => item.copyWith(needed: !allNeeded)).toList();
      state = AsyncValue.data(updatedItems);

      // Update database in background
      await _repository.saveAll(updatedItems);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleItemNeeded(int itemId) async {
    final items = state.value ?? [];
    final itemIndex = items.indexWhere((item) => item.id == itemId);

    if (itemIndex != -1) {
      try {
        final item = items[itemIndex];
        final updatedItem = item.copyWith(needed: !item.needed);

        // Update state immediately
        final updatedItems = [...items];
        updatedItems[itemIndex] = updatedItem;
        state = AsyncValue.data(updatedItems);

        // Update database in background
        await _repository.update(updatedItem);
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<int> getNextPosition() async {
    final items = state.value ?? [];
    if (items.isEmpty) return 1;
    return items.map((item) => item.position).reduce((a, b) => a > b ? a : b) +
        1;
  }

  Future<void> saveAllItems(List<GroceryItem> items) async {
    try {
      await _repository.saveAll(items);
      if (_currentListId != null) {
        await loadItemsForList(_currentListId!);
      } else {
        await loadItems();
      }
      // Sort and reindex all items after saving
      await _sortAndReindexAllItems();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final itemsProvider =
    StateNotifierProvider<ItemsNotifier, AsyncValue<List<GroceryItem>>>((ref) {
  final repository = ref.watch(itemsRepositoryProvider);
  return ItemsNotifier(repository);
});

// Filtered items provider that applies search and filter
final filteredItemsProvider = Provider<AsyncValue<List<GroceryItem>>>((ref) {
  final itemsAsync = ref.watch(itemsProvider);
  final filter = ref.watch(itemFilterProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return itemsAsync.when(
    data: (items) {
      List<GroceryItem> filteredItems = items;

      // Apply filter
      switch (filter) {
        case ItemFilter.needed:
          filteredItems = filteredItems.where((item) => item.needed).toList();
          break;
        case ItemFilter.notNeeded:
          filteredItems = filteredItems.where((item) => !item.needed).toList();
          break;
        case ItemFilter.all:
          // No filtering
          break;
      }

      // Apply search
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        filteredItems = filteredItems.where((item) {
          return item.name.toLowerCase().contains(query);
        }).toList();
      }

      // Items are already sorted alphabetically in the database, so no need to sort here
      return AsyncValue.data(filteredItems);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Selection state providers
final selectedCountProvider = Provider<int>((ref) {
  final itemsNotifier = ref.watch(itemsProvider.notifier);
  ref.watch(itemsProvider); // Watch for state changes
  return itemsNotifier.selectedCount;
});

final neededCountProvider = Provider<int>((ref) {
  final itemsAsync = ref.watch(itemsProvider);
  return itemsAsync.when(
    data: (items) => items.where((item) => item.needed).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final allSelectedProvider = Provider<bool>((ref) {
  final itemsNotifier = ref.watch(itemsProvider.notifier);
  ref.watch(itemsProvider); // Watch for state changes
  return itemsNotifier.allSelected;
});

final allNeededProvider = Provider<bool>((ref) {
  final itemsAsync = ref.watch(itemsProvider);
  return itemsAsync.when(
    data: (items) => items.isNotEmpty && items.every((item) => item.needed),
    loading: () => false,
    error: (_, __) => false,
  );
});

final hasSelectionProvider = Provider<bool>((ref) {
  final itemsNotifier = ref.watch(itemsProvider.notifier);
  ref.watch(itemsProvider); // Watch for state changes
  return itemsNotifier.hasSelection;
});

// Item selection provider for individual items
final itemSelectionProvider = Provider.family<bool, int>((ref, itemId) {
  final itemsNotifier = ref.watch(itemsProvider.notifier);
  ref.watch(itemsProvider); // Watch for state changes
  return itemsNotifier.selectedItemIds.contains(itemId);
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
  final bool isSaving;
  final bool hasUnsavedChanges;

  const AppState({
    this.filter = AppFilter.all,
    this.sort = AppSort.position,
    this.isSearching = false,
    this.searchQuery = '',
    this.isSaving = false,
    this.hasUnsavedChanges = false,
  });

  AppState copyWith({
    AppFilter? filter,
    AppSort? sort,
    bool? isSearching,
    String? searchQuery,
    bool? isSaving,
    bool? hasUnsavedChanges,
  }) {
    return AppState(
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      isSaving: isSaving ?? this.isSaving,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
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

  // Added missing methods for compatibility
  void markUnsaved() {
    state = state.copyWith(hasUnsavedChanges: true);
  }

  void markSaved() {
    state = state.copyWith(hasUnsavedChanges: false, isSaving: false);
  }

  void markSaving() {
    state = state.copyWith(isSaving: true);
  }
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

// Theme mode provider with persistence
class ThemeNotifier extends StateNotifier<bool> {
  static const String _themeKey = 'isDarkMode';

  ThemeNotifier() : super(true) {
    // Changed default to true for dark mode
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? true; // Default to dark mode
    state = isDark;
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    state = !state;
    await prefs.setBool(_themeKey, state);
  }

  Future<void> setTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    state = isDark;
    await prefs.setBool(_themeKey, isDark);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeNotifier, bool>((ref) => ThemeNotifier());
