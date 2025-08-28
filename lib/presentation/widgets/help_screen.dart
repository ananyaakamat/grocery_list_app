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
            'Create multiple grocery lists from the home screen. Tap the + button to add a new list. Edit list names by tapping the edit icon. Copy existing lists with all their items using the copy icon - perfect for creating similar shopping lists or making backups. Delete lists using the delete icon with confirmation.',
          ),
          _buildSection(
            'Copy List Feature',
            'Duplicate any grocery list instantly with the copy icon on the home screen. When you copy a list, all items including their quantities, units of measure, prices, and "needed" status are copied to the new list. The copied list gets a default name like "Copy of [Original Name]" which you can customize. This feature is perfect for creating weekly shopping lists, making backups, or sharing lists with family members.',
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
            'Grocery Reference List (Smart Import)',
            'The "Grocery Reference List" is a curated collection of common grocery items built into the app. This smart import feature adds 100+ commonly purchased items to your list instantly, saving you time typing. The reference list includes categorized items like fruits, vegetables, dairy, meat, household essentials, and more. Each item comes with suggested quantities and units of measure. Use this feature to:\n\n• Quickly create comprehensive shopping lists\n• Get ideas for items you might have forgotten\n• Start with a complete template and customize as needed\n• Save time on weekly grocery planning\n\nThis is especially helpful for new users or when planning large shopping trips. The imported items are fully editable - you can modify quantities, prices, and needed status after import.',
          ),
          _buildSection(
            'Recipe Details & Website Links',
            'Use the Recipe Details icon (restaurant menu) to add descriptions and website links to your grocery lists. This is perfect for storing recipe notes, cooking instructions, or YouTube cooking video links. Click the restaurant menu icon in the toolbar to add a description and website URL. Saved URLs become clickable links that open in your browser or YouTube app. The description field is great for storing recipe details, cooking notes, or shopping reminders. Both fields automatically trim extra spaces for clean storage.',
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
              'Q: How do I copy a grocery list?',
              'A: Tap the copy icon (duplicate symbol) next to any list on the home screen. Enter a name for the new list, and all items will be copied with their quantities, prices, and needed status. This creates an independent copy that you can modify separately.',
            ),
            _buildFaqItem(
              'Q: What units of measure are available?',
              'A: The app supports comprehensive units including solids (kg, g, pieces, packets, boxes, bags, pound, loaf, dozen, etc.), liquids (L, ml, bottles, cans), and small measures (tbsp, tsp, cups). Recent additions include "pound" and "loaf" for better international and bakery item support.',
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
              'Q: What is the Grocery Reference List?',
              'A: It\'s a built-in collection of 100+ common grocery items that you can import instantly. This saves time by providing a comprehensive starting point for your shopping list.',
            ),
            _buildFaqItem(
              'Q: How do I use the Grocery Reference List?',
              'A: Tap the import icon and select "Grocery Reference List (For 2A + 2C)" - the recommended option. This imports all reference items which you can then customize by editing quantities, adding prices, and marking items as needed.',
            ),
            _buildFaqItem(
              'Q: Can I modify items from the Reference List?',
              'A: Absolutely! Once imported, reference list items become regular grocery items. You can edit their names, quantities, prices, units, and needed status just like manually added items.',
            ),
            _buildFaqItem(
              'Q: Does the Reference List include prices?',
              'A: Yes, but it\'s better to update them as per your purchase pattern like online or offline, as prices differ slightly on various online platforms or offline grocery shops, location, etc. The reference prices provide a starting point, but you should adjust them based on your preferred shopping method and local market rates.',
            ),
            _buildFaqItem(
              'Q: How do I backup my lists?',
              'A: You have multiple backup options: Use the Copy List feature to create duplicates within the app, or export lists as CSV files. Both methods preserve all item details including quantities, units, prices, and needed status.',
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
              'Q: How do I add recipe details to my list?',
              'A: Click the restaurant menu icon in the toolbar to open Recipe Details. Add a description for recipe notes and a website URL for cooking videos or recipes. URLs automatically open in your browser or YouTube app when clicked.',
            ),
            _buildFaqItem(
              'Q: Why won\'t my recipe URL open?',
              'A: Make sure the URL is properly formatted (e.g., https://youtube.com/...). The app automatically adds "https://" if missing. Ensure you have a browser or YouTube app installed to handle the link.',
            ),
            _buildFaqItem(
              'Q: How do I reorder my grocery list?',
              'A: Long press any item and drag it to a new position. This helps organize items by store sections or priority.',
            ),
            _buildFaqItem(
              'Q: Does the total update automatically?',
              'A: Yes! The total cost updates instantly when you add prices, mark items as needed/not needed, or delete items.',
            ),
            _buildFaqItem(
              'Q: Can I create weekly shopping templates?',
              'A: Absolutely! Create a master grocery list with all your regular items, then use the copy feature to duplicate it for each shopping trip. You can then modify the copied list as needed while keeping your template intact.',
            ),
            _buildFaqItem(
              'Q: How do I backup my grocery lists?',
              'A: You have two backup options: 1) Use the copy feature to duplicate your lists within the app, or 2) Export each list to CSV files using the export feature. Both methods preserve all your item details including prices.',
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
