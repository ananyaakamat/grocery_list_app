import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/csv_repository.dart';
import '../providers/app_providers.dart';

enum ImportAction { referenceList, importMerge, importReplace, exportTemplate }

class ImportCsvModal extends ConsumerStatefulWidget {
  final int listId;

  const ImportCsvModal({
    super.key,
    required this.listId,
  });

  @override
  ConsumerState<ImportCsvModal> createState() => _ImportCsvModalState();
}

class _ImportCsvModalState extends ConsumerState<ImportCsvModal> {
  bool _isLoading = false;
  ImportAction _selectedAction = ImportAction.referenceList;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.upload_file,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Import Grocery Items'),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose how you want to add items to your list:',
                style: AppTextStyles.bodyMedium.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 20),
              _buildActionSelection(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: _getActionColor(),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_getActionButtonText()),
        ),
      ],
    );
  }

  Widget _buildActionSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Option 1: Grocery Reference List (For 2A + 2C) - FIRST
        _buildActionCard(
          action: ImportAction.referenceList,
          title: 'Grocery Reference List (For 2A + 2C)',
          subtitle: 'Load predefined default items into your blank list',
          icon: Icons.list_alt,
          color: Theme.of(context).colorScheme.primary,
          isRecommended: true,
        ),
        const SizedBox(height: 12),

        // Option 2: Import from CSV file (Merge)
        _buildActionCard(
          action: ImportAction.importMerge,
          title: 'Merge with existing items',
          subtitle: 'Keep current items and add new ones from CSV file',
          icon: Icons.file_upload,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(height: 12),

        // Option 3: Replace all from CSV
        _buildActionCard(
          action: ImportAction.importReplace,
          title: 'Replace all items',
          subtitle: 'Remove existing items and import only new ones from CSV',
          icon: Icons.swap_horiz,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        const SizedBox(height: 20),

        // Divider
        Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
        const SizedBox(height: 12),

        // Export Template Option
        _buildActionCard(
          action: ImportAction.exportTemplate,
          title: 'Export CSV template',
          subtitle: 'Download a sample CSV template with example items',
          icon: Icons.download,
          color: Theme.of(context).colorScheme.outline,
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required ImportAction action,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isRecommended = false,
  }) {
    final isSelected = _selectedAction == action;

    return GestureDetector(
      onTap: () => setState(() => _selectedAction = action),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? color
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? color.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          children: [
            // Radio button
            Radio<ImportAction>(
              value: action,
              groupValue: _selectedAction,
              onChanged: (value) => setState(() => _selectedAction = value!),
              activeColor: color,
            ),
            const SizedBox(width: 12),

            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? color : null,
                          ),
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'RECOMMENDED',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getActionColor() {
    switch (_selectedAction) {
      case ImportAction.referenceList:
        return Theme.of(context).colorScheme.primary;
      case ImportAction.importMerge:
        return Theme.of(context).colorScheme.secondary;
      case ImportAction.importReplace:
        return Theme.of(context).colorScheme.tertiary;
      case ImportAction.exportTemplate:
        return Theme.of(context).colorScheme.outline;
    }
  }

  String _getActionButtonText() {
    switch (_selectedAction) {
      case ImportAction.referenceList:
        return 'Load Reference List';
      case ImportAction.importMerge:
        return 'Import & Merge';
      case ImportAction.importReplace:
        return 'Import & Replace';
      case ImportAction.exportTemplate:
        return 'Export Template';
    }
  }

  Future<void> _handleAction() async {
    setState(() => _isLoading = true);

    try {
      switch (_selectedAction) {
        case ImportAction.referenceList:
          await _handleReferenceListImport();
          break;
        case ImportAction.importMerge:
          await _handleCsvImport(ImportMode.merge);
          break;
        case ImportAction.importReplace:
          await _handleCsvImport(ImportMode.replace);
          break;
        case ImportAction.exportTemplate:
          await _handleExportTemplate();
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReferenceListImport() async {
    // First check if the current list is blank
    final currentItems = ref.read(itemsProvider).value ?? [];
    if (currentItems.isNotEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                const Text('List Not Empty'),
              ],
            ),
            content: const Text(
              'The reference list can only be imported into a blank list. '
              'Please remove all existing items first, or use one of the CSV import options instead.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Load reference items and convert to grocery items
    final referenceRepository = ref.read(referenceItemRepositoryProvider);
    final referenceItems = await referenceRepository.getReferenceItems();
    final groceryItems = referenceRepository.convertToGroceryItems(
      referenceItems,
      widget.listId,
    );

    // Save to the current list
    await ref.read(itemsProvider.notifier).saveAllItems(groceryItems);
    ref.read(appStateProvider.notifier).markUnsaved();

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Successfully loaded ${groceryItems.length} reference items'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          action: SnackBarAction(
            label: 'Save',
            textColor: Colors.white,
            onPressed: () async {
              await ref.read(itemsProvider.notifier).saveAllItems(groceryItems);
              ref.read(appStateProvider.notifier).markSaved();
            },
          ),
        ),
      );
    }
  }

  Future<void> _handleCsvImport(ImportMode mode) async {
    final csvRepository = ref.read(csvRepositoryProvider);

    // Pick CSV file
    final filePath = await csvRepository.pickCsvFile();
    if (filePath == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Parse CSV
    final importResult =
        await csvRepository.parseCsvFile(filePath, widget.listId);

    // If there are validation errors, show them
    if (importResult.hasErrors) {
      setState(() => _isLoading = false);
      if (mounted) {
        Navigator.of(context).pop(importResult.errors);
      }
      return;
    }

    if (!importResult.hasValidItems) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid items found in CSV')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    // Apply import
    final currentItems = ref.read(itemsProvider).value ?? [];
    final updatedItems = await csvRepository.applyImport(
      currentItems,
      importResult.validItems,
      mode,
    );

    // Update the items list
    await ref.read(itemsProvider.notifier).saveAllItems(updatedItems);
    ref.read(appStateProvider.notifier).markUnsaved();

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Successfully imported ${importResult.validItems.length} items'),
          action: SnackBarAction(
            label: 'Save',
            onPressed: () async {
              await ref.read(itemsProvider.notifier).saveAllItems(updatedItems);
              ref.read(appStateProvider.notifier).markSaved();
            },
          ),
        ),
      );
    }
  }

  Future<void> _handleExportTemplate() async {
    final csvRepository = ref.read(csvRepositoryProvider);
    await csvRepository.exportSampleTemplate();

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sample template exported successfully!'),
        ),
      );
    }
  }
}
