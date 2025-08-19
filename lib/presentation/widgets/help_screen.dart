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
            'The "Select All" checkbox is positioned on the right side of the screen for easy thumb access. Use it to select or deselect all visible items at once. The checkbox shows the current selection state and count.',
          ),
          _buildSection(
            'Search & Filter',
            'Use the search box at the top to find items by name. Apply filters to show All items, only Needed items, or Not Needed items. The search and filter work together - you can search within filtered results for precise item location.',
          ),
          _buildSection(
            'Reordering Items',
            'Long press and drag any item to reorder your list. This helps organize your grocery list by categories, store layout, or priority. The new order is automatically saved.',
          ),
          _buildSection(
            'Dark Mode & Themes',
            'The app defaults to dark mode for better battery life and night viewing. The theme automatically adapts all colors, including visual boundaries and cards, for optimal contrast in both light and dark modes.',
          ),
          _buildSection(
            'Visual Organization',
            'Items are displayed with clear visual boundaries using cards and spacing. This helps distinguish between different items and makes the list easier to scan, especially with longer lists.',
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
            'Tap the export icon to save your list as a CSV file. The export respects your current filter settings - if you have "Needed" items filtered, only those items will be exported. Use "All" filter to export the complete list. The export creates a backup you can share or reimport later.',
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
            _buildFaqItem(
              'Q: How do I search for items?',
              'A: Use the search box at the top of any list. Type part of an item name to filter results. Combine with filter buttons to search within specific item categories.',
            ),
            _buildFaqItem(
              'Q: Can I export only needed items?',
              'A: Yes! Use the filter buttons to show only "Needed" items, then tap export. The CSV will contain only the filtered items. The export message will confirm which filter was applied.',
            ),
            _buildFaqItem(
              'Q: How do I reorder my grocery list?',
              'A: Long press any item and drag it to a new position. This is useful for organizing items by store sections or shopping priority. The new order is automatically saved.',
            ),
            _buildFaqItem(
              'Q: How do I change between light and dark mode?',
              'A: The app defaults to dark mode for better battery life. Theme switching may be added in future updates based on user feedback.',
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
