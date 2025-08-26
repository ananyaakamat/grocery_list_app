import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/grocery_item.dart';
import '../../data/models/grocery_list.dart'; // Added for CR1
import '../../data/repositories/csv_repository.dart'; // Added for CsvImportError
import '../providers/app_providers.dart';
import '../widgets/grocery_item_tile.dart';
import '../widgets/add_item_modal.dart';
import '../widgets/import_csv_modal.dart';
import '../widgets/help_screen.dart';
import '../widgets/list_details_modal.dart';

class GroceryListScreen extends ConsumerStatefulWidget {
  final GroceryList groceryList; // Added for CR1 - list-scoped screen

  const GroceryListScreen({super.key, required this.groceryList});

  @override
  ConsumerState<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends ConsumerState<GroceryListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load items for the specific list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemsProvider.notifier).loadItemsForList(widget.groceryList.id!);
    });

    // Sync the text controller with the provider state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentSearch = ref.read(searchQueryProvider);
      _searchController.text = currentSearch;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Immediate scroll position preservation with jumpTo for reliability
  Future<void> _preserveScrollPosition(
      Future<void> Function() operation) async {
    if (!_scrollController.hasClients) {
      await operation();
      return;
    }

    final currentOffset = _scrollController.offset;

    // Execute the operation
    await operation();

    // Use WidgetsBinding.instance.addPostFrameCallback for more reliable timing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScrollPosition(currentOffset);
    });
  }

  // Immediate sync scroll preservation with jumpTo
  void _preserveScrollPositionSync(VoidCallback operation) {
    if (!_scrollController.hasClients) {
      operation();
      return;
    }

    final currentOffset = _scrollController.offset;

    // Execute the operation
    operation();

    // Use WidgetsBinding.instance.addPostFrameCallback for immediate restoration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScrollPosition(currentOffset);
    });
  }

  // Helper method to restore scroll position with immediate jumpTo
  void _restoreScrollPosition(double targetOffset) {
    if (!mounted || !_scrollController.hasClients) return;

    try {
      final position = _scrollController.position;
      final maxExtent = position.maxScrollExtent;
      final minExtent = position.minScrollExtent;

      // Validate and clamp the target offset
      final clampedOffset = targetOffset.clamp(minExtent, maxExtent);

      // Use jumpTo for immediate, reliable positioning
      _scrollController.jumpTo(clampedOffset);
    } catch (e) {
      // Silently handle any scroll controller exceptions
      debugPrint('Scroll restore failed: $e');
    }
  }

  // Specialized scroll preservation for delete operations
  Future<void> _preserveScrollPositionForDelete(
      Future<void> Function() deleteOperation) async {
    if (!_scrollController.hasClients) {
      await deleteOperation();
      return;
    }

    final currentOffset = _scrollController.offset;
    final currentItems = ref.read(itemsProvider).value ?? [];
    final currentItemCount = currentItems.length;

    // Execute the delete operation
    await deleteOperation();

    // Give a small delay for state to settle, then use WidgetsBinding for reliable timing
    await Future.delayed(const Duration(milliseconds: 50));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScrollPositionAfterDelete(currentOffset, currentItemCount);
    });
  }

  // Helper method to restore scroll position after delete with smart adjustment
  void _restoreScrollPositionAfterDelete(
      double originalOffset, int originalItemCount) {
    if (!mounted || !_scrollController.hasClients) return;

    try {
      final position = _scrollController.position;
      final maxExtent = position.maxScrollExtent;
      final minExtent = position.minScrollExtent;

      final newItems = ref.read(itemsProvider).value ?? [];
      final newItemCount = newItems.length;

      // Calculate adjusted scroll position
      double adjustedOffset = originalOffset;

      if (newItemCount == 0) {
        // If all items deleted, scroll to top
        adjustedOffset = 0;
      } else if (newItemCount < originalItemCount && originalOffset > 0) {
        // Conservative approach: Only adjust if we're clearly past the new list extent
        if (originalOffset > maxExtent) {
          // Use proportional adjustment only when necessary
          final ratio = newItemCount / originalItemCount.toDouble();
          adjustedOffset = originalOffset * ratio;
        } else {
          // If original position is still valid, keep it as is
          adjustedOffset = originalOffset;
        }

        // Ensure we don't go below 0
        adjustedOffset = adjustedOffset.clamp(0.0, double.infinity);
      }

      // Final clamp to valid range
      final clampedOffset = adjustedOffset.clamp(minExtent, maxExtent);

      // Use jumpTo for immediate, reliable positioning
      _scrollController.jumpTo(clampedOffset);
    } catch (e) {
      debugPrint('Delete scroll restore failed: $e');
      // Fallback: use simpler approach
      try {
        final maxExtent = _scrollController.position.maxScrollExtent;
        final safeOffset = originalOffset.clamp(0.0, maxExtent);
        _scrollController.jumpTo(safeOffset);
      } catch (e2) {
        debugPrint('Fallback scroll restore also failed: $e2');
      }
    }
  }

  // Method to clear search and filter state
  void _clearSearchAndFilter() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(itemFilterProvider.notifier).state = ItemFilter.all;
  }

  // Auto-renumber items
  void _updateSerialNumbers() {
    // Auto-renumbering will be handled by the backend when items are saved
    // For now, we'll refresh the items to get updated positions
    final listId = widget.groceryList.id!;
    ref.read(itemsProvider.notifier).loadItemsForList(listId);
  }

  // Update last saved timestamp
  void _updateLastSaved() {
    ref.invalidate(lastSavedProvider);
  }

  // Helper method to check if any items are selected for bulk delete
  bool _hasSelectedItems() {
    final itemsNotifier = ref.read(itemsProvider.notifier);
    return itemsNotifier.hasSelection;
  }

  // Bulk delete selected items with confirmation
  void _bulkDeleteItems(BuildContext context) {
    final itemsNotifier = ref.read(itemsProvider.notifier);
    final selectedCount = itemsNotifier.selectedCount;

    if (selectedCount == 0) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Items'),
        content: Text(
            'Are you sure you want to delete $selectedCount selected item${selectedCount > 1 ? 's' : ''}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop();
              await _preserveScrollPositionForDelete(() async {
                await itemsNotifier.deleteSelected();
                ref.read(appStateProvider.notifier).markUnsaved();
                _updateLastSaved();
              });

              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                      content: Text(
                          '$selectedCount item${selectedCount > 1 ? 's' : ''} deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(filteredItemsProvider);
    // Remove unused variables that were causing warnings
    // final appState = ref.watch(appStateProvider);
    // final lastSavedAsync = ref.watch(lastSavedProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Clear search and filter state when navigating back
        if (didPop) {
          // Post-frame callback to ensure it happens after navigation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _clearSearchAndFilter();
          });
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            // Search and Filter UI
            _buildSearchAndFilterSection(context),
            // Items content
            Expanded(
              child: itemsAsync.when(
                data: (items) => _buildItemsList(context, items),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorWidget(context, error),
              ),
            ),
          ],
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
      ), // Close Scaffold
    ); // Close PopScope
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final itemsAsync =
        ref.watch(itemsProvider); // Keep using itemsProvider for button states

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
                          onPressed: () {
                            _clearSearchAndFilter();
                            Navigator.of(context).pop();
                          },
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
                      // Recipe Details (formerly List Details)
                      IconButton(
                        icon: const Icon(Icons.restaurant_menu),
                        tooltip: 'Recipe Details',
                        onPressed: () => _showListDetailsModal(context),
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

    final allNeeded = ref.watch(allNeededProvider);

    return Column(
      children: [
        // Status bar with last saved time and item count
        _buildStatusBar(context, items.length),
        // Select All Checkbox (matching exact ListView structure for perfect width alignment)
        Container(
          padding: const EdgeInsets.only(left: 8, right: 8, top: 0, bottom: 0),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 3,
            shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Total of needed items on the left
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      'Total: ${_calculateNeededTotal(items)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: (Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.fontSize ??
                                    14) *
                                1.5,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const Spacer(), // Push icons to right side

                  // Match individual item layout exactly: 4px spacer
                  const SizedBox(width: 4),

                  // Edit button placeholder (invisible) - exact same as individual items
                  const SizedBox(
                    width:
                        32, // Same width as edit IconButton in grocery_item_tile.dart
                    height: 32,
                  ),

                  // Additional 12px spacing to move both icons 10px more to the right
                  const SizedBox(width: 12),

                  // Bulk Delete Icon - moved 10px right
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: _hasSelectedItems()
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.5),
                    ),
                    tooltip: _hasSelectedItems()
                        ? 'Delete Selected Items'
                        : 'Select All Items',
                    onPressed: _hasSelectedItems()
                        ? () => _bulkDeleteItems(context)
                        : () => _toggleSelectAll(),
                    iconSize: 20, // Match individual item icon size
                    padding: EdgeInsets.zero, // Match individual item padding
                    constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32), // Match individual item constraints
                  ),

                  // Toggle All Needed checkbox - also moved 2px right (no additional spacing)
                  Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: allNeeded,
                      tristate: true,
                      onChanged: (value) => _toggleAllNeeded(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8), // Final right padding
                ],
              ),
            ),
          ),
        ),
        // Items list with pull-to-refresh, visual boundaries, and reordering
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshItems,
            child: ListView.builder(
              key: const ValueKey('grocery_items_list'),
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                left: 8,
                right: 8,
                top: 8,
                bottom:
                    100, // Add bottom padding to prevent FAB from blocking last item
              ),
              itemCount: items.length,
              cacheExtent: 1000, // Pre-render more items for smoother scrolling
              addAutomaticKeepAlives: true, // Keep widget states alive
              addRepaintBoundaries: true, // Optimize repaints
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  key: ValueKey(item.id),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 3,
                  shadowColor:
                      Theme.of(context).colorScheme.shadow.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: GroceryItemTile(
                      key: ValueKey('tile_${item.id}'),
                      item: item,
                      isSelected: ref.watch(itemSelectionProvider(item.id!)),
                      onToggleNeeded: (item) => _toggleItemNeeded(item.id!),
                      onToggleSelection: (item) =>
                          _toggleItemSelection(item.id!),
                      onEdit: (item) => _showEditItemModal(context, item),
                      onDelete: (item) => _deleteItem(context, item),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar(BuildContext context, int itemCount) {
    final lastSavedAsync = ref.watch(lastSavedProvider);
    final neededCount = ref.watch(neededCountProvider);
    final currentFilter = ref.watch(itemFilterProvider);

    // Only show "(x needed)" when showing all items
    String itemCountText;
    if (currentFilter == ItemFilter.all) {
      itemCountText = '$itemCount items ($neededCount needed)';
    } else {
      itemCountText = '$itemCount items';
    }

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
          Expanded(
            child: Text(
              itemCountText,
              style: AppTextStyles.bodyMedium,
            ),
          ),
          const SizedBox(width: 8), // Add spacing between count and timestamp
          lastSavedAsync.when(
            data: (lastSaved) => Text(
              lastSaved != null
                  ? DateFormat('d MMM yy, h:mm a').format(lastSaved)
                  : 'Not saved yet',
              style: AppTextStyles.labelMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.end,
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

  Widget _buildSearchAndFilterSection(BuildContext context) {
    final currentFilter = ref.watch(itemFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Container(
      margin: const EdgeInsets.all(12),
      child: Card(
        elevation: 4,
        shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.3),
                Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.1),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search box
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearchAndFilter,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor:
                        Theme.of(context).colorScheme.surface.withOpacity(0.8),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                  },
                ),
                const SizedBox(height: 16),
                // Filter buttons
                Row(
                  children: [
                    Text(
                      'Filter: ',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ItemFilter.values.map((filter) {
                            final isSelected = currentFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(
                                  _getFilterLabel(filter),
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (_) {
                                  ref.read(itemFilterProvider.notifier).state =
                                      filter;
                                },
                                selectedColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                checkmarkColor: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                elevation: isSelected ? 2 : 1,
                                shadowColor: Theme.of(context)
                                    .colorScheme
                                    .shadow
                                    .withOpacity(0.1),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getFilterLabel(ItemFilter filter) {
    switch (filter) {
      case ItemFilter.all:
        return 'All';
      case ItemFilter.needed:
        return 'Needed';
      case ItemFilter.notNeeded:
        return 'Not Needed';
    }
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
  void _toggleSelectAll() {
    _preserveScrollPositionSync(() {
      final itemsNotifier = ref.read(itemsProvider.notifier);
      if (itemsNotifier.allSelected) {
        itemsNotifier.clearSelection();
      } else {
        itemsNotifier.selectAll();
      }
    });
  }

  void _toggleAllNeeded() {
    _preserveScrollPositionSync(() {
      ref.read(itemsProvider.notifier).toggleAllNeeded();
      ref.read(appStateProvider.notifier).markUnsaved();
    });
  }

  void _toggleItemNeeded(int itemId) {
    _preserveScrollPositionSync(() {
      ref.read(itemsProvider.notifier).toggleItemNeeded(itemId);
      ref.read(appStateProvider.notifier).markUnsaved();
    });
  }

  void _toggleItemSelection(int itemId) {
    _preserveScrollPositionSync(() {
      ref.read(itemsProvider.notifier).toggleItemSelection(itemId);
    });
  }

  void _showAddItemModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddItemModal(),
    ).then((value) async {
      // Only preserve scroll if an item was actually added
      if (value != null) {
        await _preserveScrollPosition(() async {
          _updateSerialNumbers();
          _updateLastSaved();
        });
      }
    });
  }

  void _showEditItemModal(BuildContext context, GroceryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemModal(itemToEdit: item),
    ).then((value) async {
      // Only preserve scroll if the item was actually edited
      if (value != null) {
        await _preserveScrollPosition(() async {
          _updateSerialNumbers();
          _updateLastSaved();
        });
      }
    });
  }

  // Refresh method for pull-to-refresh
  // Refresh method for pull-to-refresh with scroll preservation
  Future<void> _refreshItems() async {
    await _preserveScrollPosition(() async {
      await ref
          .read(itemsProvider.notifier)
          .loadItemsForList(widget.groceryList.id!);
    });
  }

  void _showImportModal(BuildContext context) {
    showDialog<dynamic>(
      context: context,
      builder: (context) => ImportCsvModal(listId: widget.groceryList.id!),
    ).then((value) {
      // Check if validation errors were returned
      if (value is List<CsvImportError>) {
        // Show validation error dialog
        _showValidationErrorsDialog(value);
      } else {
        // Auto-renumber and update timestamp after successful importing
        _updateSerialNumbers();
        _updateLastSaved();
      }
    });
  }

  Future<void> _showValidationErrorsDialog(List<CsvImportError> errors) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Cannot dismiss by tapping outside
      useSafeArea: true,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Prevent back button from closing
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('CSV Import Errors'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Found ${errors.length} validation error${errors.length == 1 ? '' : 's'}. '
                    'Please fix these errors in your CSV file and try again.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: errors.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final error = errors[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Row ${error.lineNumber}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (error.field != 'General') ...[
                                          Text(
                                            error.field,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          if (error.value.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                error.value,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontFamily: 'monospace',
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          error.message,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (error.rawData.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    'Raw data: ${error.rawData}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHelpScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HelpScreen(),
      ),
    );
  }

  void _showListDetailsModal(BuildContext context) {
    // Get the current list from provider to ensure we have the latest data
    final currentLists = ref.read(groceryListsProvider).value ?? [];
    final currentList = currentLists.firstWhere(
      (list) => list.id == widget.groceryList.id,
      orElse: () => widget.groceryList,
    );

    showDialog(
      context: context,
      builder: (context) => ListDetailsModal(
        initialDescription: currentList.description,
        initialUrl: currentList.url,
        onSave: (description, url) {
          final updatedList = currentList.copyWith(
            description: description.trim(), // Trim spaces before saving
            url: url.trim(), // Trim spaces before saving
            updatedAt: DateTime.now(),
          );
          ref.read(groceryListsProvider.notifier).updateList(updatedList);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recipe details updated successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        },
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
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop();
              await _preserveScrollPositionForDelete(() async {
                await ref.read(itemsProvider.notifier).deleteItem(item.id!);
                ref.read(appStateProvider.notifier).markUnsaved();
                _updateLastSaved();
              });

              messenger.showSnackBar(
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
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop();
              await _preserveScrollPositionForDelete(() async {
                await ref.read(itemsProvider.notifier).deleteAllItems();
                ref.read(appStateProvider.notifier).markUnsaved();
                _updateLastSaved();
              });

              messenger.showSnackBar(
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
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Use filtered items instead of all items
      final items = ref.read(filteredItemsProvider).value ?? [];
      final csvRepository = ref.read(csvRepositoryProvider);

      // Pass the list name for custom filename format
      await csvRepository.exportToCsv(items, listName: widget.groceryList.name);

      if (mounted) {
        final filterName = ref.read(itemFilterProvider) != ItemFilter.all
            ? ' (${_getFilterLabel(ref.read(itemFilterProvider))} filter applied)'
            : '';
        messenger.showSnackBar(
          SnackBar(content: Text('CSV exported successfully$filterName')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _saveItems(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      ref.read(appStateProvider.notifier).markSaving();
      // Use the original items provider for saving all items, not filtered
      final items = ref.read(itemsProvider).value ?? [];
      await ref.read(itemsProvider.notifier).saveAllItems(items);
      ref.read(appStateProvider.notifier).markSaved();
      // Auto-renumber items after saving
      _updateSerialNumbers();
      // Refresh the last saved provider and update timestamp
      ref.invalidate(lastSavedProvider);
      _updateLastSaved();

      if (mounted) {
        messenger.showSnackBar(
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
        messenger.showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  // Calculate total price of needed items
  String _calculateNeededTotal(List<GroceryItem> items) {
    final total = items
        .where((item) => item.needed)
        .fold<double>(0.0, (sum, item) => sum + item.price);
    return '₹${total.toStringAsFixed(2)}';
  }
}
