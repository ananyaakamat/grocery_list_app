import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/grocery_item.dart';
import '../providers/app_providers.dart';

class AddItemModal extends ConsumerStatefulWidget {
  final GroceryItem? itemToEdit;

  const AddItemModal({super.key, this.itemToEdit});

  @override
  ConsumerState<AddItemModal> createState() => _AddItemModalState();
}

class _AddItemModalState extends ConsumerState<AddItemModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _qtyValueController = TextEditingController();

  String? _selectedUnit;
  bool _needed = false;
  bool _isLoading = false;

  bool get _isEditing => widget.itemToEdit != null;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (_isEditing) {
      final item = widget.itemToEdit!;
      _nameController.text = item.name;
      _qtyValueController.text = item.qtyValue?.toString() ?? '';
      _selectedUnit = item.qtyUnit;
      _needed = item.needed;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: _buildForm(),
                ),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          _isEditing ? 'Edit Item' : 'Add Item',
          style: AppTextStyles.titleLarge,
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNameField(),
          const SizedBox(height: 16),
          _buildQuantitySection(),
          const SizedBox(height: 16),
          _buildNeededCheckbox(),
          const SizedBox(height: 16),
          _buildPresetSuggestions(),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Name *',
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'e.g., Idli Rice, Coconut Oil',
            prefixIcon: const Icon(Icons.shopping_basket_outlined),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an item name';
            }
            if (value.trim().length > AppConstants.maxItemNameLength) {
              return 'Item name too long (max ${AppConstants.maxItemNameLength} characters)';
            }
            return null;
          },
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildQuantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity',
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _qtyValueController,
                decoration: const InputDecoration(
                  hintText: 'Amount',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final parsed = double.tryParse(value);
                    if (parsed == null) {
                      return 'Invalid number';
                    }
                    if (parsed <= 0) {
                      return 'Must be greater than 0';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: _buildUnitDropdown(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUnitDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedUnit,
      decoration: const InputDecoration(
        hintText: 'Unit',
        prefixIcon: Icon(Icons.straighten),
      ),
      items: _buildUnitDropdownItems(),
      onChanged: (value) => setState(() => _selectedUnit = value),
      validator: (value) {
        if (_qtyValueController.text.isNotEmpty && value == null) {
          return 'Please select a unit';
        }
        return null;
      },
    );
  }

  List<DropdownMenuItem<String>> _buildUnitDropdownItems() {
    final items = <DropdownMenuItem<String>>[];

    // Add grouped items
    for (final entry in QuantityUnits.groupedUnits.entries) {
      // Add category header (disabled)
      items.add(
        DropdownMenuItem<String>(
          value: null,
          enabled: false,
          child: Text(
            entry.key,
            style: AppTextStyles.labelMedium.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

      // Add units in this category
      for (final unit in entry.value) {
        items.add(
          DropdownMenuItem<String>(
            value: unit,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(unit),
            ),
          ),
        );
      }
    }

    return items;
  }

  Widget _buildNeededCheckbox() {
    return CheckboxListTile(
      title: Text(
        'Mark as needed',
        style: AppTextStyles.bodyLarge,
      ),
      subtitle: Text(
        'Add to shopping list',
        style: AppTextStyles.bodyMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      value: _needed,
      onChanged: (value) => setState(() => _needed = value ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildPresetSuggestions() {
    if (_nameController.text.isNotEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Add',
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: PresetGroceries.allItems
              .take(10)
              .map(
                (item) => ActionChip(
                  label: Text(item),
                  onPressed: () => _selectPresetItem(item),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveItem,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'Update' : 'Add Item'),
          ),
        ),
      ],
    );
  }

  void _selectPresetItem(String itemName) {
    setState(() {
      _nameController.text = itemName;
    });
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final qtyValue = _qtyValueController.text.isNotEmpty
          ? double.parse(_qtyValueController.text)
          : null;

      if (_isEditing) {
        final updatedItem = widget.itemToEdit!
            .copyWith(
              name: name,
              qtyValue: qtyValue,
              qtyUnit: _selectedUnit,
              needed: _needed,
            )
            .withUpdatedTimestamp();

        await ref.read(itemsProvider.notifier).updateItem(updatedItem);
      } else {
        final position =
            await ref.read(itemsProvider.notifier).getNextPosition();
        final newItem = GroceryItem.create(
          name: name,
          qtyValue: qtyValue,
          qtyUnit: _selectedUnit,
          needed: _needed,
          position: position,
        );

        await ref.read(itemsProvider.notifier).addItem(newItem);
      }

      ref.read(appStateProvider.notifier).markUnsaved();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_isEditing ? 'Item updated' : 'Item added'}. Don\'t forget to Save!'),
            action: SnackBarAction(
              label: 'Save Now',
              onPressed: () async {
                final items = ref.read(itemsProvider).value ?? [];
                await ref.read(itemsProvider.notifier).saveAllItems(items);
                ref.read(appStateProvider.notifier).markSaved();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
