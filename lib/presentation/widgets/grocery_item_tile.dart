import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/grocery_item.dart';

class GroceryItemTile extends StatelessWidget {
  final GroceryItem item;
  final Function(GroceryItem) onToggleNeeded;
  final Function(GroceryItem) onEdit;
  final Function(GroceryItem) onDelete;

  const GroceryItemTile({
    super.key,
    required this.item,
    required this.onToggleNeeded,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildSlNumber(context),
        title: _buildItemName(context),
        subtitle: _buildQuantity(context),
        trailing: _buildActions(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildSlNumber(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          '${item.position}',
          style: AppTextStyles.labelMedium.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildItemName(BuildContext context) {
    return Text(
      item.name,
      style: AppTextStyles.bodyLarge.copyWith(
        decoration: item.needed ? null : TextDecoration.lineThrough,
        color: item.needed
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget? _buildQuantity(BuildContext context) {
    final quantity = item.formattedQuantity;

    if (quantity.isEmpty) {
      return null;
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Text(
      quantity,
      style: AppTextStyles.labelMedium.copyWith(
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Edit button
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () => onEdit(item),
          tooltip: 'Edit',
        ),
        // Delete button
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () => onDelete(item),
          tooltip: 'Delete',
        ),
        // Needed checkbox
        Transform.scale(
          scale: 1.2,
          child: Checkbox(
            value: item.needed,
            onChanged: (value) => onToggleNeeded(item),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}
