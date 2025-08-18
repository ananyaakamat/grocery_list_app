import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/csv_repository.dart';
import '../providers/app_providers.dart';

class ImportCsvModal extends ConsumerStatefulWidget {
  const ImportCsvModal({super.key});

  @override
  ConsumerState<ImportCsvModal> createState() => _ImportCsvModalState();
}

class _ImportCsvModalState extends ConsumerState<ImportCsvModal> {
  bool _isLoading = false;
  ImportMode _selectedMode = ImportMode.merge;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import CSV'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Import grocery items from a CSV file.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 16),
          _buildModeSelection(),
          const SizedBox(height: 16),
          _buildInstructions(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _importCsv,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Import'),
        ),
      ],
    );
  }

  Widget _buildModeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Import Mode:',
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: 8),
        RadioListTile<ImportMode>(
          title: const Text('Merge with existing'),
          subtitle: const Text('Keep existing items, add new ones'),
          value: ImportMode.merge,
          groupValue: _selectedMode,
          onChanged: (value) => setState(() => _selectedMode = value!),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<ImportMode>(
          title: const Text('Replace all'),
          subtitle: const Text('Remove existing items, import only new ones'),
          value: ImportMode.replace,
          groupValue: _selectedMode,
          onChanged: (value) => setState(() => _selectedMode = value!),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CSV Format Required:',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sl No, Item, Qty Value, Qty Unit, Needed',
            style: AppTextStyles.bodySmall.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importCsv() async {
    setState(() => _isLoading = true);

    try {
      final csvRepository = ref.read(csvRepositoryProvider);

      // Pick CSV file
      final filePath = await csvRepository.pickCsvFile();
      if (filePath == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Parse CSV
      final importResult = await csvRepository.parseCsvFile(filePath);

      if (!importResult.hasValidItems) {
        throw Exception('No valid items found in CSV');
      }

      // Apply import
      final currentItems = ref.read(itemsProvider).value ?? [];
      final updatedItems = await csvRepository.applyImport(
        currentItems,
        importResult.validItems,
        _selectedMode,
      );

      // Update the items list
      await ref.read(itemsProvider.notifier).saveAllItems(updatedItems);
      ref.read(appStateProvider.notifier).markUnsaved();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported ${importResult.validItems.length} items'
              '${importResult.hasErrors ? ' with ${importResult.errors.length} errors' : ''}',
            ),
            action: SnackBarAction(
              label: 'Save',
              onPressed: () async {
                await ref
                    .read(itemsProvider.notifier)
                    .saveAllItems(updatedItems);
                ref.read(appStateProvider.notifier).markSaved();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
