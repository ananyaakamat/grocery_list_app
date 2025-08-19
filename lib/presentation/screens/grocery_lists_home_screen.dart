import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/grocery_list.dart';
import '../providers/app_providers.dart';
import '../widgets/add_edit_list_modal.dart';
import 'grocery_list_screen.dart';

class GroceryListsHomeScreen extends ConsumerStatefulWidget {
  const GroceryListsHomeScreen({super.key});

  @override
  ConsumerState<GroceryListsHomeScreen> createState() =>
      _GroceryListsHomeScreenState();
}

class _GroceryListsHomeScreenState extends ConsumerState<GroceryListsHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(groceryListsProvider);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: listsAsync.when(
        data: (lists) => _buildListsView(context, lists),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(context, error),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddListModal(context),
          icon: const Icon(Icons.add),
          label: const Text('Add List'),
          tooltip: 'Create New Grocery List',
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        AppConstants.appName,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.dark_mode_outlined),
          tooltip: 'Toggle Theme',
          onPressed: () {
            ref.read(themeModeProvider.notifier).toggleTheme();
          },
        ),
        IconButton(
          icon: const Icon(Icons.help_outline),
          tooltip: 'Help',
          onPressed: () => _showHelpDialog(context),
        ),
      ],
    );
  }

  Widget _buildListsView(BuildContext context, List<GroceryList> lists) {
    if (lists.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(groceryListsProvider);
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Grocery Lists',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${lists.length} list${lists.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: lists.length,
                onReorder: (oldIndex, newIndex) =>
                    _reorderLists(oldIndex, newIndex),
                itemBuilder: (context, index) {
                  final list = lists[index];
                  return AnimatedContainer(
                    key: ValueKey(list.id),
                    duration: Duration(milliseconds: 200 + (index * 50)),
                    curve: Curves.easeOutCubic,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: _buildListCard(context, list, index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, GroceryList list, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final itemCountFuture =
        ref.watch(groceryListsProvider.notifier).getItemCount(list.id!);

    return Card(
      elevation: 4,
      shadowColor: colorScheme.shadow.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
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
              colorScheme.surface,
              colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: InkWell(
          onTap: () => _navigateToListItems(context, list),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Drag Handle Icon
                Tooltip(
                  message: 'Hold and drag to reorder lists',
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.drag_handle,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // List Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getListColor(index, colorScheme).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: _getListColor(index, colorScheme),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // List Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<int>(
                        future: itemCountFuture,
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return Text(
                            count == 0
                                ? 'No items yet'
                                : '$count item${count == 1 ? '' : 's'}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Updated ${_formatDate(list.updatedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  colorScheme.onSurfaceVariant.withOpacity(0.7),
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      tooltip: 'Edit List',
                      onPressed: () => _showEditListModal(context, list),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      tooltip: 'Delete List',
                      onPressed: () => _showDeleteConfirmation(context, list),
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

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No grocery lists yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first grocery list to get started with organizing your shopping',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showAddListModal(context),
              icon: const Icon(Icons.add),
              label: const Text('Create First List'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                ref.invalidate(groceryListsProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getListColor(int index, ColorScheme colorScheme) {
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];
    return colors[index % colors.length];
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yy, h:mm a').format(date);
  }

  void _navigateToListItems(BuildContext context, GroceryList list) async {
    // Set the selected list
    ref.read(selectedGroceryListProvider.notifier).state = list;

    // Navigate to items screen and wait for return
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroceryListScreen(groceryList: list),
      ),
    );

    // Refresh the home screen data when returning
    if (mounted) {
      ref.read(groceryListsProvider.notifier).loadLists();
    }
  }

  void _reorderLists(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final currentLists = ref.read(groceryListsProvider).value ?? [];
    if (oldIndex >= 0 &&
        oldIndex < currentLists.length &&
        newIndex >= 0 &&
        newIndex < currentLists.length) {
      // Create a mutable copy of the lists
      final reorderedLists = List<GroceryList>.from(currentLists);

      // Reorder the lists
      final movedList = reorderedLists.removeAt(oldIndex);
      reorderedLists.insert(newIndex, movedList);

      // Update the provider with the reordered lists
      ref.read(groceryListsProvider.notifier).reorderLists(reorderedLists);

      // Show feedback to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${movedList.name} moved successfully'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAddListModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddEditListModal(),
    );
  }

  void _showEditListModal(BuildContext context, GroceryList list) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditListModal(listToEdit: list),
    );
  }

  void _showDeleteConfirmation(BuildContext context, GroceryList list) async {
    final itemCount =
        await ref.read(groceryListsProvider.notifier).getItemCount(list.id!);

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Grocery List?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${list.name}"?'),
            if (itemCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'This will also delete all $itemCount item${itemCount == 1 ? '' : 's'} in this list.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(groceryListsProvider.notifier).deleteList(list.id!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${list.name}"'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to use Grocery List'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('• Tap "Add List" to create a new grocery list'),
              SizedBox(height: 8),
              Text('• Tap on any list to view and manage its items'),
              SizedBox(height: 8),
              Text('• Use the edit button to rename a list'),
              SizedBox(height: 8),
              Text(
                  '• Use the delete button to remove a list and all its items'),
              SizedBox(height: 8),
              Text('• Pull down to refresh your lists'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
