import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/grocery_item.dart';
import '../../data/models/grocery_list.dart'; // Added for CR1
import '../providers/app_providers.dart';
import '../widgets/grocery_item_tile.dart';
import '../widgets/add_item_modal.dart';
import '../widgets/import_csv_modal.dart';
import '../widgets/help_screen.dart';

class GroceryListScreen extends ConsumerStatefulWidget {
  final GroceryList groceryList; // Added for CR1 - list-scoped screen

  const GroceryListScreen({super.key, required this.groceryList});

  @override
  ConsumerState<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends ConsumerState<GroceryListScreen> {
  @override
  void initState() {
    super.initState();
    // Load items for the specific list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemsProvider.notifier).loadItemsForList(widget.groceryList.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsProvider);
    // Remove unused variables that were causing warnings
    // final appState = ref.watch(appStateProvider);
    // final lastSavedAsync = ref.watch(lastSavedProvider);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: itemsAsync.when(
        data: (items) => _buildItemsList(context, items),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(context, error),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemModal(context),
        tooltip: 'Add Item',
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final itemsAsync = ref.watch(itemsProvider);

    return PreferredSize(
      preferredSize:
          const Size.fromHeight(120), // Increased height for two lines
      child: AppBar(
        automaticallyImplyLeading: false, // Disable automatic back button
        toolbarHeight: 120,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First line: List name
                Container(
                  height: 56, // Standard app bar height for title
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      // Back button (custom positioning in first row only)
                      if (Navigator.of(context).canPop())
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      Expanded(
                        child: Text(
                          widget.groceryList.name,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Second line: Action icons
                SizedBox(
                  height: 48, // Height for icon row
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Add Item
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: 'Add Item',
                        onPressed: () => _showAddItemModal(context),
                      ),
                      // Import CSV
                      IconButton(
                        icon: const Icon(Icons.upload_file),
                        tooltip: 'Import CSV',
                        onPressed: () => _showImportModal(context),
                      ),
                      // Export CSV
                      IconButton(
                        icon: const Icon(Icons.download),
                        tooltip: 'Export CSV',
                        onPressed:
                            itemsAsync.hasValue && itemsAsync.value!.isNotEmpty
                                ? () => _exportToCsv(context)
                                : null,
                      ),
                      // Delete All Items
                      IconButton(
                        icon: const Icon(Icons.delete_sweep),
                        tooltip: 'Delete All Items',
                        onPressed:
                            itemsAsync.hasValue && itemsAsync.value!.isNotEmpty
                                ? () => _deleteAllItems(context)
                                : null,
                      ),
                      // Save
                      IconButton(
                        icon: const Icon(Icons.save),
                        tooltip: 'Save',
                        onPressed: () => _saveItems(context),
                      ),
                      // Help
                      IconButton(
                        icon: const Icon(Icons.help_outline),
                        tooltip: 'Help',
                        onPressed: () => _showHelpScreen(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, List<GroceryItem> items) {
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    final neededCount = ref.watch(neededCountProvider);
    final allNeeded = ref.watch(allNeededProvider);

    return Column(
      children: [
        // Status bar with last saved time and item count
        _buildStatusBar(context, items.length),
        // Select All Checkbox (appears above first item)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Checkbox(
                value: allNeeded,
                tristate: true,
                onChanged: (value) => _toggleAllNeeded(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  neededCount == 0
                      ? 'Mark items as needed'
                      : neededCount == items.length
                          ? 'All items marked as needed'
                          : '$neededCount of ${items.length} items needed',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        // Items list with pull-to-refresh
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshItems,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              itemBuilder: (context, index) => GroceryItemTile(
                item: items[index],
                onToggleNeeded: (item) => _toggleItemNeeded(item.id!),
                onEdit: (item) => _showEditItemModal(context, item),
                onDelete: (item) => _deleteItem(context, item),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar(BuildContext context, int itemCount) {
    final lastSavedAsync = ref.watch(lastSavedProvider);
    final neededCount = ref.watch(neededCountProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$itemCount items ($neededCount needed)',
            style: AppTextStyles.bodyMedium,
          ),
          lastSavedAsync.when(
            data: (lastSaved) => Text(
              lastSaved != null
                  ? 'Last saved: ${DateFormat('d MMM yy, h:mm a').format(lastSaved)}'
                  : 'Not saved yet',
              style: AppTextStyles.labelMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            loading: () => const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => Text(
              'Save status unknown',
              style: AppTextStyles.labelMedium.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Your pantry is empty',
            style: AppTextStyles.titleLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap Add to begin',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddItemModal(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Item'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: AppTextStyles.titleLarge.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.read(itemsProvider.notifier).loadItems(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // Action methods
  void _toggleAllNeeded() {
    ref.read(itemsProvider.notifier).toggleAllNeeded();
    ref.read(appStateProvider.notifier).markUnsaved();
  }

  void _toggleItemNeeded(int itemId) {
    ref.read(itemsProvider.notifier).toggleItemNeeded(itemId);
    ref.read(appStateProvider.notifier).markUnsaved();
  }

  void _showAddItemModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddItemModal(),
    );
  }

  void _showEditItemModal(BuildContext context, GroceryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemModal(itemToEdit: item),
    );
  }

  // Refresh method for pull-to-refresh
  Future<void> _refreshItems() async {
    await ref
        .read(itemsProvider.notifier)
        .loadItemsForList(widget.groceryList.id!);
  }

  void _showImportModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ImportCsvModal(listId: widget.groceryList.id!),
    );
  }

  void _showHelpScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HelpScreen(),
      ),
    );
  }

  void _deleteItem(BuildContext context, GroceryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(itemsProvider.notifier).deleteItem(item.id!);
              ref.read(appStateProvider.notifier).markUnsaved();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item.name} deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteAllItems(BuildContext context) {
    final items = ref.read(itemsProvider).value ?? [];
    if (items.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Items'),
        content: Text(
            'Are you sure you want to delete all ${items.length} items? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(itemsProvider.notifier).deleteAllItems();
              ref.read(appStateProvider.notifier).markUnsaved();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('All ${items.length} items deleted')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _exportToCsv(BuildContext context) async {
    try {
      final items = ref.read(itemsProvider).value ?? [];
      final csvRepository = ref.read(csvRepositoryProvider);

      await csvRepository.exportToCsv(items);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _saveItems(BuildContext context) async {
    try {
      ref.read(appStateProvider.notifier).markSaving();
      final items = ref.read(itemsProvider).value ?? [];
      await ref.read(itemsProvider.notifier).saveAllItems(items);
      ref.read(appStateProvider.notifier).markSaved();
      // Refresh the last saved provider
      ref.invalidate(lastSavedProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saved. Last saved: ${DateFormat('d MMM yy, h:mm a').format(DateTime.now())}',
            ),
          ),
        );
      }
    } catch (e) {
      ref.read(appStateProvider.notifier).markUnsaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }
}
