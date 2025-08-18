import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/grocery_list.dart';
import '../providers/app_providers.dart';

class AddEditListModal extends ConsumerStatefulWidget {
  final GroceryList? listToEdit;

  const AddEditListModal({super.key, this.listToEdit});

  @override
  ConsumerState<AddEditListModal> createState() => _AddEditListModalState();
}

class _AddEditListModalState extends ConsumerState<AddEditListModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEditing => widget.listToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.listToEdit!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                _isEditing ? 'Edit List' : 'Create New List',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _isEditing
                    ? 'Update the name of your grocery list'
                    : 'Give your grocery list a unique name',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),

              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Name Input
                      TextFormField(
                        controller: _nameController,
                        enabled: !_isLoading,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'List Name',
                          hintText: 'e.g., Weekly Groceries, Quick Shopping',
                          prefixIcon: const Icon(Icons.shopping_cart_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorText: _errorMessage,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a list name';
                          }
                          if (value.trim().length > 50) {
                            return 'List name must be 50 characters or less';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (_errorMessage != null) {
                            setState(() {
                              _errorMessage = null;
                            });
                          }
                        },
                        onFieldSubmitted: (value) {
                          if (_formKey.currentState!.validate()) {
                            _saveList();
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton(
                              onPressed: _isLoading ? null : _saveList,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(_isEditing ? 'Update' : 'Create'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveList() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check for duplicate names
      final excludeId = _isEditing ? widget.listToEdit!.id : null;
      final nameExists = await ref
          .read(groceryListsProvider.notifier)
          .nameExists(name, excludeId: excludeId);

      if (nameExists) {
        setState(() {
          _errorMessage = 'List name already exists. Please choose another.';
          _isLoading = false;
        });
        return;
      }

      if (_isEditing) {
        // Update existing list
        final updatedList = widget.listToEdit!.updateName(name);
        await ref.read(groceryListsProvider.notifier).updateList(updatedList);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated "$name"'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } else {
        // Create new list
        final newList = GroceryList.create(name: name);
        final listId =
            await ref.read(groceryListsProvider.notifier).addList(newList);

        if (mounted && listId != null) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Created "$name"'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to save list. Please try again.';
        _isLoading = false;
      });
    }
  }
}
