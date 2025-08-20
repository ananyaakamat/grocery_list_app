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
            'Welcome to ${AppConstants.appName}! This app helps you manage multiple grocery lists offline with features like price tracking, CSV import/export, and automatic saving.',
          ),
          _buildSection(
            'Managing Lists',
            'Create multiple grocery lists from the home screen. Tap the + button to add a new list. Edit list names by tapping the edit icon. Delete lists using the delete icon with confirmation.',
          ),
          _buildSection(
            'Adding Items',
            'Within any list, tap the + button to add items. Enter the item name, quantity, and price (all optional except the name). Use the "Needed" toggle to mark items you still need to buy. The app prevents duplicate item names and automatically saves your changes.',
          ),
          _buildSection(
            'Price Tracking',
            'Add prices to your items to track your grocery budget. Enter any amount up to Rs 10,000.99 in the "Price (Rs)" field. When you add items with prices, you\'ll see the total cost of needed items displayed in the bulk operations panel when you select items. Prices are optional - leave blank for items you don\'t want to track.',
          ),
          _buildSection(
            'Editing & Managing Items',
            'Tap the edit icon on any item to modify its name, quantity, price, or needed status. Use the delete icon to remove items. Toggle the "Needed" checkbox to mark items as purchased. Select multiple items using checkboxes for bulk operations.',
          ),
          _buildSection(
            'Bulk Operations & Total Calculation',
            'Select multiple items using the checkboxes to delete them together. When items are selected, the delete icon turns red and you can press it to delete the selected items. Use "Delete All" to clear your entire list. When you have items with prices, the total cost of needed items appears in the bulk operations panel, making it easy to stay within budget.',
          ),
          _buildSection(
            'Organizing Your List',
            'Long press and drag any item to reorder your list using the drag handle. This helps organize by store sections or shopping priority. Use the search box to quickly find items. Filter by "All", "Needed", or "Not Needed" to focus on specific items.',
          ),
          _buildSection(
            'Import & Export with Prices',
            'Tap the import icon to import items from a CSV file or download a sample template. Your CSV files can now include prices! Choose "Merge" to add items to your current list or "Replace" to clear the list first. Export your lists as CSV files to backup your data or share with others. The export includes all item information including prices.',
          ),
          _buildSection(
            'Auto-Save & Data Safety',
            'The app automatically saves all your changes. You can see the "Last Saved" time at the bottom of each list. Your data is stored safely on your device and never sent to external servers.',
          ),
          _buildSection(
            'Dark Mode & Visual Design',
            'The app uses dark mode by default for better battery life and comfortable viewing. Items are clearly separated with cards and spacing to make your lists easy to read and navigate.',
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
              'A: Select the items you want to delete by tapping their checkboxes. The delete icon will turn red when items are selected. Press the red delete icon to remove all selected items after confirming in the dialog.',
            ),
            _buildFaqItem(
              'Q: Why do my item numbers keep changing?',
              'A: Items are automatically renumbered to maintain a consistent sequence whenever you make changes (add, delete, edit, or toggle needed status). This ensures your list stays organized.',
            ),
            _buildFaqItem(
              'Q: How do I add prices to my items?',
              'A: When adding or editing an item, enter the price in the "Price (Rs)" field. Prices are optional and can be up to Rs 10,000.99. Leave blank if you don\'t want to track the price.',
            ),
            _buildFaqItem(
              'Q: Where do I see the total cost of my groceries?',
              'A: The total cost of items marked as "Needed" appears in the bulk operations panel when you start selecting items. This helps you stay within budget while shopping.',
            ),
            _buildFaqItem(
              'Q: Can I import and export prices in CSV files?',
              'A: Yes! The CSV format now includes a "Price" column. When you export your list, all prices are included. When importing, include prices in the last column.',
            ),
            _buildFaqItem(
              'Q: Why can\'t I add a duplicate item?',
              'A: The app prevents duplicate item names to avoid confusion. Each item in a list must have a unique name.',
            ),
            _buildFaqItem(
              'Q: CSV import failed?',
              'A: Check that your CSV has the correct headers: Sl No, Item, Qty Value, Qty Unit, Needed, Price. Use the "Export Sample Template" option to get the right format.',
            ),
            _buildFaqItem(
              'Q: How do I backup my lists?',
              'A: Use the Export CSV feature from any list to create a backup file. You can import this file later to restore your list with all items and prices.',
            ),
            _buildFaqItem(
              'Q: Where is my data stored?',
              'A: All your data is stored safely on your device. Nothing is sent to external servers, ensuring your privacy.',
            ),
            _buildFaqItem(
              'Q: How do I search for items?',
              'A: Use the search box at the top of any list. Type part of an item name to filter results. Combine with "All", "Needed", or "Not Needed" buttons to narrow your search.',
            ),
            _buildFaqItem(
              'Q: Can I export only needed items?',
              'A: Yes! Filter to show only "Needed" items, then tap export. The CSV will contain only those items with their prices.',
            ),
            _buildFaqItem(
              'Q: How do I reorder my grocery list?',
              'A: Long press any item and drag it to a new position. This helps organize items by store sections or priority.',
            ),
            _buildFaqItem(
              'Q: Does the total update automatically?',
              'A: Yes! The total cost updates instantly when you add prices, mark items as needed/not needed, or delete items.',
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
