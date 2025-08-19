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
            'Within any list, tap the + button to add items. Enter the item name and quantity (optional). Use "Y/N" to mark if the item is needed. The Quick Add section provides common item chips for faster entry. The app automatically trims extra spaces and prevents duplicate names. If you try to add a duplicate item, an error message will appear directly in the Add Item window with a red border around the text field.',
          ),
          _buildSection(
            'Editing & Deleting Items',
            'Tap the edit icon on any item to modify it. Use the delete icon to remove items. Select multiple items using checkboxes for bulk operations. Use "Delete All" to clear the entire list with confirmation.',
          ),
          _buildSection(
            'Enhanced Performance & Reliability',
            'The app now includes advanced database optimization with automatic constraint repair systems. If you encounter any "unique constraint failed" errors, the app automatically fixes position conflicts in the background. Database migrations ensure your data remains stable and consistent across app updates. The improved performance means faster loading and smoother operations, especially with larger grocery lists.',
          ),
          _buildSection(
            'Comprehensive Timestamp Tracking',
            'The "Last Saved" timestamp now updates consistently across ALL operations: adding items, editing items, deleting items (both individual and bulk), toggling needed checkboxes, clicking the Save button, and importing data. No more missed timestamps - every action that modifies your grocery list is properly tracked. The timestamp appears at the bottom of each list in an easy-to-read format like "18 Aug 25, 4:19 PM".',
          ),
          _buildSection(
            'Enhanced Bulk Delete Feature',
            'The bulk operations panel features a smart delete icon that changes based on your selection state. When no items are selected, click the icon to "Select All Items". Once items are selected, the same icon becomes red and allows you to "Delete Selected Items". The icon is perfectly aligned above the selection checkboxes for intuitive use. The needed checkbox remains available for toggling all items\' needed status.',
          ),
          _buildSection(
            'Smart Selection & Visual Feedback',
            'Individual item selection checkboxes now update immediately when clicked - no need to navigate away and back to see the changes. The selection state is fully reactive, providing instant visual feedback. This improvement makes bulk operations smoother and more responsive.',
          ),
          _buildSection(
            'Smart Filter Display',
            'The item count display is now context-aware based on your selected filter. When viewing "All Items", you\'ll see the full count with needed items breakdown (e.g., "5 items (3 needed)"). When you apply "Needed" or "Not Needed" filters, the display shows just the clean item count (e.g., "3 items") without confusing brackets. This makes the interface cleaner and more intuitive when filtering your grocery list.',
          ),
          _buildSection(
            'Optimized User Experience',
            'The "Needed" checkbox now operates smoothly without screen refreshes, matching the seamless experience of selection checkboxes. The bulk operations panel is perfectly aligned with individual item controls for better visual consistency. All interactions feel more responsive and polished.',
          ),
          _buildSection(
            'Improved User Interface',
            'The Add Item floating action button now has proper spacing to prevent it from blocking the last item in your list. Extra scroll space is added at the bottom of the list for better visibility. Visual feedback includes colored icons that become active when items are selected for bulk operations. The delete icon shows in red when items are selected and becomes inactive (grayed out) when no items are selected.',
          ),
          _buildSection(
            'Reordering Items',
            'Long press and drag any item to reorder your list using the drag handle icon. This helps organize your grocery list by categories, store layout, or priority. The visual drag handles make it clear which items can be moved. The new order is automatically saved.',
          ),
          _buildSection(
            'Dark Mode & Themes',
            'The app defaults to dark mode for better battery life and night viewing. The theme automatically adapts all colors, including visual boundaries and cards, for optimal contrast in both light and dark modes. Item quantities are displayed with clean white text in dark mode for better readability.',
          ),
          _buildSection(
            'Visual Organization',
            'Items are displayed with clear visual boundaries using cards and spacing. This helps distinguish between different items and makes the list easier to scan, especially with longer lists.',
          ),
          _buildSection(
            'Advanced Database Features',
            'The app includes sophisticated database management with automatic constraint repair, two-phase update systems for data consistency, and automatic migration handling. Position indices are maintained automatically, ensuring your grocery list always stays in the correct order even during complex operations. The database is optimized for performance and reliability.',
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
            'Use Select All to choose multiple items, then delete them together using the delete icon next to the checkbox. The "Delete All" option clears the entire list with a confirmation dialog to prevent accidental deletion. Both bulk operations automatically update serial numbers and timestamps.',
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
              'Q: How do I delete multiple items at once?',
              'A: First, uncheck the items you want to delete (mark as "not needed"). The delete icon next to "Select All" will show the count like "3 out of 8 selected". Click the delete icon to remove all selected items after confirming in the dialog.',
            ),
            _buildFaqItem(
              'Q: Why do my item numbers keep changing?',
              'A: Items are automatically renumbered to maintain a consistent sequence whenever you make changes (add, delete, edit, or toggle needed status). This ensures your list stays organized.',
            ),
            _buildFaqItem(
              'Q: When does the "Last Saved" time update?',
              'A: The timestamp updates automatically whenever you update an item, delete an item, toggle the "Needed" checkbox, click the Save button, or import data. This comprehensive tracking helps you know exactly when any changes were made to your list.',
            ),
            _buildFaqItem(
              'Q: Why can\'t I add a duplicate item?',
              'A: The app prevents duplicate item names within the same list to avoid confusion. When you try to add a duplicate, the text field will show a red border and display an error message directly in the Add Item window.',
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
              'Q: How do I clear search and filters quickly?',
              'A: Use the X icon that appears in the search field when you have text entered. This will clear both the search text and any applied filters in one click.',
            ),
            _buildFaqItem(
              'Q: How do I reorder my grocery list?',
              'A: Long press any item and drag it to a new position using the drag handle icon. This is useful for organizing items by store sections or shopping priority. The new order is automatically saved.',
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
