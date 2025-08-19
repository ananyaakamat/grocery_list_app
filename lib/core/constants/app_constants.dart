class AppConstants {
  static const String appName = 'Grocery List';
  static const String appDescription =
      'A simple, beautiful, offline-first grocery list app for South Indian households';

  // Database
  static const String databaseName = 'annadaata_grocery.db';
  static const int databaseVersion = 3; // Updated for list reordering support

  // Tables
  static const String itemsTable = 'items';
  static const String groceryListsTable = 'grocery_lists';
  static const String appMetaTable = 'app_meta';

  // CSV
  static const String csvPrefix = 'annadaata_grocery_';
  static const String csvExtension = '.csv';
  static const List<String> csvHeaders = [
    'Sl No',
    'Item',
    'Qty Value',
    'Qty Unit',
    'Needed'
  ];

  // App Meta Keys
  static const String lastSavedAtKey = 'last_saved_at';

  // Validation
  static const int maxItemNameLength = 60;
  static const int minItemNameLength = 1;
}

class QuantityUnits {
  // Solids
  static const List<String> solids = [
    'kg',
    'g',
    'mg',
    'piece',
    'pieces',
    'packet',
    'packets',
    'box',
    'boxes',
    'tin',
    'bag',
    'bags',
    'bunch',
    'bundle',
    'dozen',
    'tray'
  ];

  // Semi-solids/Powders
  static const List<String> semiSolids = [
    'kg',
    'g',
    'mg',
    'packet',
    'box',
    'jar',
    'pouch',
    'sachet'
  ];

  // Liquids
  static const List<String> liquids = [
    'L',
    'ml',
    'bottle',
    'bottles',
    'can',
    'tetra-pack'
  ];

  // Small measures
  static const List<String> smallMeasures = ['tbsp', 'tsp', 'cup', 'pinch'];

  // All units combined
  static const List<String> allUnits = [
    ...solids,
    ...liquids,
    ...smallMeasures,
  ];

  // Grouped units for UI
  static const Map<String, List<String>> groupedUnits = {
    'Solids': solids,
    'Liquids': liquids,
    'Small Measures': smallMeasures,
  };
}

// Preset South Indian grocery items as specified in PRD Section 10
class PresetGroceries {
  static const Map<String, List<String>> categories = {
    'Rice': ['Sona Masoori', 'Idli Rice', 'Ponni Raw Rice', 'Basmati'],
    'Dals/Legumes': [
      'Toor Dal',
      'Urad Dal (Split)',
      'Urad Dal (Whole)',
      'Moong Dal',
      'Chana Dal'
    ],
    'Flours/Batter': ['Idli/Dosa Batter', 'Ragi Flour', 'Rice Flour', 'Besan'],
    'Oils/Fats': [
      'Groundnut Oil',
      'Coconut Oil',
      'Gingelly (Sesame) Oil',
      'Ghee'
    ],
    'Spices/Mixes': [
      'Sambar Powder',
      'Rasam Powder',
      'Garam Masala',
      'Red Chilli',
      'Turmeric',
      'Mustard',
      'Jeera',
      'Pepper'
    ],
    'Condiments': ['Tamarind', 'Jaggery', 'Salt'],
    'Dairy': ['Milk', 'Curd', 'Paneer', 'Butter'],
    'Vegetables': [
      'Drumstick',
      'Brinjal',
      'Tomato',
      'Onion',
      'Potato',
      'Green Chilli',
      'Curry Leaves',
      'Coriander'
    ],
    'Others': ['Coconut', 'Banana Leaf', 'Incense', 'Camphor'],
  };

  // Flat list of all preset items
  static List<String> get allItems {
    return categories.values.expand((items) => items).toList();
  }
}
