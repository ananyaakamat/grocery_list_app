import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/grocery_item.dart';

class GroceryItemTile extends StatelessWidget {
  final GroceryItem item;
  final Function(GroceryItem) onToggleNeeded;
  final Function(GroceryItem) onEdit;
  final Function(GroceryItem) onDelete;
  final Function(GroceryItem)? onToggleSelection;
  final bool isSelected;

  const GroceryItemTile({
    super.key,
    required this.item,
    required this.onToggleNeeded,
    required this.onEdit,
    required this.onDelete,
    this.onToggleSelection,
    this.isSelected = false,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item name
        Text(
          item.name,
          style: AppTextStyles.bodyLarge.copyWith(
            decoration: item.needed ? null : TextDecoration.lineThrough,
            color: item.needed
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        // Price display (show only if price > 0)
        if (item.price > 0) ...[
          const SizedBox(height: 2),
          Text(
            item.formattedPrice,
            style: AppTextStyles.labelMedium.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
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
        // Small spacer to shift icons right for timestamp alignment
        const SizedBox(width: 4),
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
        // Selection checkbox (for bulk operations)
        if (onToggleSelection != null)
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: isSelected,
              onChanged: (value) => onToggleSelection!(item),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
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
