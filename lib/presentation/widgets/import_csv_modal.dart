import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/csv_repository.dart';
import '../providers/app_providers.dart';

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
  bool _isExportingTemplate = false;
  ImportMode _selectedMode = ImportMode.merge;
  bool _exportSampleTemplate = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import CSV'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Import grocery items from a CSV file.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 16),
          _buildModeSelection(),
          const SizedBox(height: 16),
          _buildInstructions(),
          if (_exportSampleTemplate) ...[
            const SizedBox(height: 16),
            _buildExportTemplateSection(),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading || _isExportingTemplate
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (_exportSampleTemplate)
          ElevatedButton(
            onPressed: _isExportingTemplate ? null : _exportTemplate,
            child: _isExportingTemplate
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Export Template'),
          )
        else
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
        const Text(
          'Options:',
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: 8),
        RadioListTile<bool>(
          title: const Text('Import from file'),
          subtitle: const Text('Import grocery items from your CSV file'),
          value: false,
          groupValue: _exportSampleTemplate,
          onChanged: (value) => setState(() {
            _exportSampleTemplate = false;
            _selectedMode = ImportMode.merge;
          }),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<bool>(
          title: const Text('Export sample template'),
          subtitle: const Text('Download a CSV template with sample data'),
          value: true,
          groupValue: _exportSampleTemplate,
          onChanged: (value) => setState(() => _exportSampleTemplate = true),
          contentPadding: EdgeInsets.zero,
        ),
        if (!_exportSampleTemplate) ...[
          const SizedBox(height: 8),
          const Text(
            'Import Mode:',
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: 4),
          RadioListTile<ImportMode>(
            title: const Text('Merge with existing'),
            subtitle: const Text('Keep existing items, add new ones'),
            value: ImportMode.merge,
            groupValue: _selectedMode,
            onChanged: (value) => setState(() => _selectedMode = value!),
            contentPadding: const EdgeInsets.only(left: 16.0),
          ),
          RadioListTile<ImportMode>(
            title: const Text('Replace all'),
            subtitle: const Text('Remove existing items, import only new ones'),
            value: ImportMode.replace,
            groupValue: _selectedMode,
            onChanged: (value) => setState(() => _selectedMode = value!),
            contentPadding: const EdgeInsets.only(left: 16.0),
          ),
        ],
      ],
    );
  }

  Widget _buildInstructions() {
    if (_exportSampleTemplate) {
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
              'Sample Template Info:',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '• Contains proper CSV headers and format\n'
              '• Includes 4 sample grocery items\n'
              '• Sl No column is auto-generated during import\n'
              '• Shows correct format for Needed field (Y/N)\n'
              '• Ready to use as import template',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      );
    } else {
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
            const SizedBox(height: 4),
            const Text(
              'Note: Sl No is auto-generated, values in this column are ignored',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildExportTemplateSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.file_download_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to export template',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Click Export Template to download',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportTemplate() async {
    setState(() => _isExportingTemplate = true);

    try {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      setState(() => _isExportingTemplate = false);
    }
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
      final importResult =
          await csvRepository.parseCsvFile(filePath, widget.listId);

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
