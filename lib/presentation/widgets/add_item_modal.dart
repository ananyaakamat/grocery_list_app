import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validation_utils.dart';
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
  final _priceController = TextEditingController(); // Added price controller

  String? _selectedUnit;
  bool _needed = false;
  bool _isLoading = false;
  String? _duplicateError; // Add error state for duplicate validation

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
      _priceController.text = item.price > 0
          ? item.price.toStringAsFixed(2)
          : ''; // Initialize price
      _selectedUnit = item.qtyUnit;
      _needed = item.needed;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyValueController.dispose();
    _priceController.dispose(); // Dispose price controller
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
          _buildPriceField(), // Added price field
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
        const Text(
          'Item Name *',
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'e.g., Idli Rice, Coconut Oil',
            prefixIcon: const Icon(Icons.shopping_basket_outlined),
            // Add red border when duplicate error exists
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _duplicateError != null
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.outline,
                width: _duplicateError != null ? 2 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _duplicateError != null
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.outline,
                width: _duplicateError != null ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _duplicateError != null
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
            // Show error text in decoration
            errorText: _duplicateError,
            errorStyle: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            // Return null if there's a duplicate error (it's shown via errorText)
            if (_duplicateError != null) {
              return null; // The duplicate error is shown via errorText
            }
            return ValidationUtils.validateItemName(value);
          },
          onChanged: (value) => setState(() {
            _duplicateError = null; // Clear error when user types
          }),
        ),
      ],
    );
  }

  Widget _buildQuantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantity',
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: 8),
        // Use Column layout instead of Row for better error display
        Column(
          children: [
            // Quantity Value Field
            TextFormField(
              controller: _qtyValueController,
              decoration: const InputDecoration(
                hintText: 'Enter quantity (e.g., 2.5)',
                prefixIcon: Icon(Icons.numbers),
                labelText: 'Quantity Value',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) {
                // First validate the quantity value itself
                final qtyValidation =
                    ValidationUtils.validateQuantityValue(value);
                if (qtyValidation != null) return qtyValidation;

                // Then validate the qty/UOM relationship
                final relationshipValidation =
                    ValidationUtils.validateQuantityUomRelationship(
                  qtyValue: value,
                  uom: _selectedUnit,
                );
                return relationshipValidation;
              },
              onChanged: (value) {
                setState(() {
                  // Trigger validation update for unit field when quantity changes
                  if (_formKey.currentState != null) {
                    _formKey.currentState!.validate();
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            // Unit Dropdown Field
            _buildUnitDropdown(),
            const SizedBox(height: 8),
            // Helpful text
            Text(
              'Both quantity and unit are required when adding measurements',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
        hintText: 'Select unit (e.g., kg, pieces)',
        prefixIcon: Icon(Icons.straighten),
        labelText: 'Unit of Measure',
      ),
      items: _buildUnitDropdownItems(),
      onChanged: (value) => setState(() {
        _selectedUnit = value;
        // Trigger validation update for quantity field
        _formKey.currentState?.validate();
      }),
      validator: (value) {
        // Validate the qty/UOM relationship from the UOM side
        final relationshipValidation =
            ValidationUtils.validateQuantityUomRelationship(
          qtyValue: _qtyValueController.text,
          uom: value,
        );
        return relationshipValidation;
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

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price (Rs)',
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _priceController,
          decoration: const InputDecoration(
            hintText: '0.00',
            prefixIcon: Icon(Icons.currency_rupee),
            suffixText: 'Rs',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,5}(\.\d{0,2})?')),
          ],
          validator: (value) {
            return ValidationUtils.validatePrice(value);
          },
          onChanged: (value) {
            // Simple formatting without complex logic for now
            setState(() {}); // Just trigger rebuild to clear duplicate error
          },
        ),
        const SizedBox(height: 4),
        Text(
          'Optional. Must be greater than 0, Maximum Rs 10,000.99',
          style: AppTextStyles.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildNeededCheckbox() {
    return CheckboxListTile(
      title: const Text(
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
        const Text(
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
            style: ElevatedButton.styleFrom(
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
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
      final currentListId = ref.read(itemsProvider.notifier).currentListId ?? 1;

      // Check for duplicate names
      final isDuplicate =
          await ref.read(itemsRepositoryProvider).nameExistsInList(
                name,
                currentListId,
                excludeId: _isEditing ? widget.itemToEdit!.id : null,
              );

      if (isDuplicate) {
        setState(() {
          _isLoading = false;
          _duplicateError =
              'An item with this name already exists in this list';
        });
        return;
      }

      final qtyValue = _qtyValueController.text.isNotEmpty
          ? double.parse(_qtyValueController.text)
          : null;

      final price = _priceController.text.isNotEmpty
          ? double.parse(_priceController.text)
          : 0.0;

      if (_isEditing) {
        final updatedItem = widget.itemToEdit!
            .copyWith(
              name: name.trim(),
              qtyValue: qtyValue,
              qtyUnit: _selectedUnit,
              price: price, // Added price update
              needed: _needed,
            )
            .withUpdatedTimestamp();

        await ref.read(itemsProvider.notifier).updateItem(updatedItem);
      } else {
        final position = await ref
            .read(itemsRepositoryProvider)
            .getNextPositionForList(currentListId);
        final newItem = GroceryItem.create(
          name: name,
          qtyValue: qtyValue,
          qtyUnit: _selectedUnit,
          price: price, // Added price to create
          needed: _needed,
          position: position,
          listId: currentListId,
        );

        await ref.read(itemsProvider.notifier).addItem(newItem);
      }

      ref.read(appStateProvider.notifier).markUnsaved();

      if (mounted) {
        Navigator.of(context).pop();

        // Trigger auto-renumbering and timestamp update
        // This will be handled by the parent screen's callback
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
