import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            'Getting Started',
            'Welcome to ${AppConstants.appName}! This app helps you manage multiple grocery lists offline with features like CSV import/export, automatic text formatting, and persistent storage.',
          ),
          _buildSection(
            'Managing Lists',
            'Create multiple grocery lists from the home screen. Tap the + button to add a new list. Edit list names by tapping the edit icon. Delete lists using the delete icon with confirmation.',
          ),
          _buildSection(
            'Adding Items',
            'Within any list, tap the + button to add items. Enter the item name and quantity (optional). Use "Y/N" to mark if the item is needed. The Quick Add section provides common item chips for faster entry. The app automatically trims extra spaces and prevents duplicate names.',
          ),
          _buildSection(
            'Editing & Deleting Items',
            'Tap the edit icon on any item to modify it. Use the delete icon to remove items. Select multiple items using checkboxes for bulk operations. Use "Delete All" to clear the entire list with confirmation.',
          ),
          _buildSection(
            'Select All Feature',
            'Use the checkbox in the app bar to select or deselect all items at once. The Select All option is positioned for easy access on mobile devices.',
          ),
          _buildSection(
            'CSV Import Options',
            'Tap the import icon for two options: 1) Import from your CSV file (choose Merge to keep existing items or Replace to clear first), 2) Export Sample Template to get a properly formatted example file.',
          ),
          _buildSection(
            'CSV Template Guide',
            'The sample template shows the correct format: Item, Qty Value, Qty Unit, Needed. The Sl No column is auto-generated during import - you can put any values there. Template includes 4 example items.',
          ),
          _buildSection(
            'Exporting Your Data',
            'Tap the export icon to save your list as a CSV file. This creates a backup you can share or reimport later. The export includes all your current items with proper formatting.',
          ),
          _buildSection(
            'Auto-Save & Status',
            'The app automatically saves changes and shows the last saved time in format "18 Aug 25, 4:19 PM". You\'ll see "Not saved yet" until the first save, then timestamps for each update.',
          ),
          _buildSection(
            'App Navigation',
            'The app has two main screens: Lists (home) and Items. Use the back arrow to return from Items to Lists. The app bar in Items view uses two lines - list name on top, action icons below for better mobile viewing.',
          ),
          _buildSection(
            'Data Validation',
            'The app automatically trims spaces from item and list names. It prevents saving empty names and duplicate names. Maximum item name length is 60 characters for optimal display.',
          ),
          _buildSection(
            'Bulk Operations',
            'Use Select All to choose multiple items, then delete them together. The "Delete All" option clears the entire list with a confirmation dialog to prevent accidental deletion.',
          ),
          _buildUnitsGuide(),
          _buildTroubleshooting(),
          _buildPrivacy(),
          _buildContact(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitsGuide() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Units Guide',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 12),
            ...QuantityUnits.groupedUnits.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: AppTextStyles.labelLarge,
                    ),
                    Text(
                      entry.value.join(', '),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshooting() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Troubleshooting & FAQs',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildFaqItem(
              'Q: How do I create multiple lists?',
              'A: From the home screen, tap the + button to create a new list. Each list can have its own set of items and is saved separately.',
            ),
            _buildFaqItem(
              'Q: Why can\'t I save duplicate names?',
              'A: The app prevents duplicate list names and duplicate item names within the same list to avoid confusion.',
            ),
            _buildFaqItem(
              'Q: CSV import failed?',
              'A: Check that your CSV has the correct headers: Sl No, Item, Qty Value, Qty Unit, Needed. Use the "Export Sample Template" option to get the right format.',
            ),
            _buildFaqItem(
              'Q: What happens to the Sl No column?',
              'A: The Sl No (serial number) is auto-generated during import. Any values you put in this column are ignored - the app creates its own sequence.',
            ),
            _buildFaqItem(
              'Q: How to backup my data?',
              'A: Use the Export CSV feature from any list to create a backup file that you can import later. Export each list separately.',
            ),
            _buildFaqItem(
              'Q: Where is the Save button?',
              'A: The app auto-saves your changes. You can see the last saved time displayed at the bottom of each list screen.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacy() {
    return _buildSection(
      'Privacy',
      'All your data is stored locally on your device. No personal information is sent to external servers. Only file access permission is requested for CSV import/export.',
    );
  }

  Widget _buildContact() {
    return _buildSection(
      'Contact & Feedback',
      'For questions or feedback about ${AppConstants.appName}, please contact the developer. Your input helps improve the app!',
    );
  }
}
