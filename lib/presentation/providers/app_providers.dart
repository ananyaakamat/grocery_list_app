import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/items_repository.dart';
import '../../data/repositories/csv_repository.dart';
import '../../data/models/grocery_item.dart';

// Repository providers
final itemsRepositoryProvider = Provider<ItemsRepository>((ref) {
  return ItemsRepositoryImpl();
});

final csvRepositoryProvider = Provider<CsvRepository>((ref) {
  return CsvRepository();
});

// Items state provider
class ItemsNotifier extends StateNotifier<AsyncValue<List<GroceryItem>>> {
  final ItemsRepository _repository;

  ItemsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadItems();
  }

  Future<void> loadItems() async {
    try {
      state = const AsyncValue.loading();
      final items = await _repository.fetchAll();
      state = AsyncValue.data(items);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addItem(GroceryItem item) async {
    try {
      await _repository.add(item);
      await loadItems(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateItem(GroceryItem item) async {
    try {
      await _repository.update(item);
      await loadItems(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await _repository.delete(id);
      // Reindex positions after delete
      final currentItems = state.value ?? [];
      final updatedItems = currentItems.where((item) => item.id != id).toList();
      final reindexedItems = _reindexItems(updatedItems);
      await _repository.reindexPositions(reindexedItems);
      await loadItems(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteMultipleItems(List<int> ids) async {
    try {
      await _repository.deleteMultiple(ids);
      // Reindex positions after delete
      final currentItems = state.value ?? [];
      final updatedItems =
          currentItems.where((item) => !ids.contains(item.id)).toList();
      final reindexedItems = _reindexItems(updatedItems);
      await _repository.reindexPositions(reindexedItems);
      await loadItems(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> saveAllItems(List<GroceryItem> items) async {
    try {
      final reindexedItems = _reindexItems(items);
      await _repository.saveAll(reindexedItems);
      state = AsyncValue.data(reindexedItems);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleSelectAll() async {
    final currentItems = state.value;
    if (currentItems == null) return;

    try {
      // Check if all items are selected (needed = true)
      final allSelected = currentItems.every((item) => item.needed);

      // Toggle all items
      final updatedItems = currentItems
          .map((item) =>
              item.copyWith(needed: !allSelected).withUpdatedTimestamp())
          .toList();

      // Update state temporarily for immediate UI feedback
      state = AsyncValue.data(updatedItems);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleItemNeeded(int itemId) async {
    final currentItems = state.value;
    if (currentItems == null) return;

    try {
      final updatedItems = currentItems.map((item) {
        if (item.id == itemId) {
          return item.copyWith(needed: !item.needed).withUpdatedTimestamp();
        }
        return item;
      }).toList();

      // Update state temporarily for immediate UI feedback
      state = AsyncValue.data(updatedItems);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<int> getNextPosition() async {
    return await _repository.getNextPosition();
  }

  List<GroceryItem> _reindexItems(List<GroceryItem> items) {
    final reindexedItems = <GroceryItem>[];
    for (int i = 0; i < items.length; i++) {
      reindexedItems.add(items[i].copyWith(position: i + 1));
    }
    return reindexedItems;
  }

  // Get items that are marked as needed
  List<GroceryItem> get neededItems {
    final currentItems = state.value;
    if (currentItems == null) return [];
    return currentItems.where((item) => item.needed).toList();
  }

  // Get selected items count
  int get selectedCount {
    return neededItems.length;
  }

  // Check if all items are selected
  bool get allSelected {
    final currentItems = state.value;
    if (currentItems == null || currentItems.isEmpty) return false;
    return currentItems.every((item) => item.needed);
  }
}

final itemsProvider =
    StateNotifierProvider<ItemsNotifier, AsyncValue<List<GroceryItem>>>((ref) {
  final repository = ref.read(itemsRepositoryProvider);
  return ItemsNotifier(repository);
});

// Last saved timestamp provider
final lastSavedProvider = FutureProvider<DateTime?>((ref) async {
  final repository = ref.read(itemsRepositoryProvider);
  return await repository.getLastSavedAt();
});

// App state for tracking unsaved changes
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState.saved);

  void markUnsaved() {
    state = AppState.unsaved;
  }

  void markSaved() {
    state = AppState.saved;
  }

  void markSaving() {
    state = AppState.saving;
  }
}

enum AppState { saved, unsaved, saving }

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

// Theme mode provider
class ThemeModeNotifier extends StateNotifier<bool> {
  ThemeModeNotifier() : super(false); // false = light mode, true = dark mode

  void toggleTheme() {
    state = !state;
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  return ThemeModeNotifier();
});
