import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Fixit GH';
  static const String appTagline = 'Find trusted artisans near you';

  // Brand colors inspired by Ghana
  static const Color primaryGreen = Color(0xFF006B3F);
  static const Color accentGold = Color(0xFFFCD116);
  static const Color accentRed = Color(0xFFCE1126);
  static const Color darkText = Color(0xFF1A1A2E);
  static const Color lightBackground = Color(0xFFF8F9FA);

  static const List<String> serviceCategories = [
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Painting',
    'Cleaning',
    'AC Repair',
    'Masonry',
    'Welding',
  ];

  /// Category → profession title shown in registration/skill dropdowns.
  static const Map<String, String> categoryProfessions = {
    'Plumbing': 'Plumber',
    'Electrical': 'Electrician',
    'Carpentry': 'Carpenter',
    'Painting': 'Painter',
    'Cleaning': 'Cleaner',
    'AC Repair': 'AC Technician',
    'Masonry': 'Mason',
    'Welding': 'Welder',
  };

  /// Skills available per category (prevents free-text skill entry).
  static const Map<String, List<String>> categorySkills = {
    'Plumbing': [
      'Pipe Fitting',
      'Leak Repair',
      'Toilet Installation',
      'Water Heater',
      'Drain Cleaning',
    ],
    'Electrical': [
      'Wiring',
      'Socket Installation',
      'Lighting',
      'Panel Repair',
      'Generator Setup',
    ],
    'Carpentry': [
      'Furniture Making',
      'Door Installation',
      'Cabinet Work',
      'Roof Framing',
      'Flooring',
    ],
    'Painting': [
      'Interior Painting',
      'Exterior Painting',
      'Wall Finishing',
      'Spray Painting',
      'Wallpaper',
    ],
    'Cleaning': [
      'Home Cleaning',
      'Office Cleaning',
      'Deep Cleaning',
      'Carpet Cleaning',
      'Post-Construction',
    ],
    'AC Repair': [
      'AC Installation',
      'AC Servicing',
      'Gas Refill',
      'Fault Diagnosis',
      'Duct Cleaning',
    ],
    'Masonry': [
      'Block Laying',
      'Tiling',
      'Plastering',
      'Foundation Work',
      'Concrete Casting',
    ],
    'Welding': [
      'Metal Fabrication',
      'Gate Welding',
      'Pipe Welding',
      'Structural Welding',
      'Aluminium Works',
    ],
  };

  static const List<String> nationalIdTypes = [
    'Ghana Card',
    'Voters ID',
    'NHIS Card',
    'Passport',
  ];

  /// Common Ghana locations for search / profile / booking autocomplete.
  static const List<String> ghanaLocations = [
    'Accra',
    'Kumasi',
    'Tamale',
    'Takoradi',
    'Cape Coast',
    'Tema',
    'Ashaiman',
    'Madina',
    'East Legon',
    'Osu',
    'Labadi',
    'Spintex',
    'Dansoman',
    'Kaneshie',
    'Adenta',
    'Kasoa',
    'Ablekuma',
    'Achimota',
    'Nungua',
    'Teshie',
    'Haatso',
    'Dome',
    'Kwabenya',
    'Legon',
    'Airport Residential',
    'Cantonments',
    'Ridge',
    'Roman Ridge',
    'Dzorwulu',
    'Abelemkpe',
    'Kokomlemle',
    'Circle',
    'Korle Bu',
    'Jamestown',
    'Chorkor',
    'Weija',
    'Mallam',
    'Gbawe',
    'McCarthy Hill',
    'Sakumono',
    'Community 25',
    'Community 18',
    'Afienya',
    'Prampram',
    'Dodowa',
    'Nsawam',
    'Koforidua',
    'Ho',
    'Sunyani',
    'Techiman',
    'Obuasi',
    'Tarkwa',
    'Wa',
    'Bolgatanga',
    'Sekondi',
    'Elmina',
    'Winneba',
    'Nkawkaw',
    'Konongo',
  ];

  static String professionLabel(String category) {
    final profession = categoryProfessions[category];
    if (profession == null) return category;
    return '$category — $profession';
  }

  static List<String> skillsForCategory(String category) {
    return List<String>.from(categorySkills[category] ?? const <String>[]);
  }

  /// Maps free-text / legacy profession names onto a known category.
  static String? normalizeCategory(String? raw) {
    if (raw == null) return null;
    final value = raw.trim();
    if (value.isEmpty) return null;
    if (serviceCategories.contains(value)) return value;

    for (final entry in categoryProfessions.entries) {
      if (entry.value.toLowerCase() == value.toLowerCase()) {
        return entry.key;
      }
    }

    final lower = value.toLowerCase();
    if (lower.contains('plumb')) return 'Plumbing';
    if (lower.contains('electric')) return 'Electrical';
    if (lower.contains('carpent')) return 'Carpentry';
    if (lower.contains('paint')) return 'Painting';
    if (lower.contains('clean')) return 'Cleaning';
    if (lower.contains('ac') || lower.contains('air con')) return 'AC Repair';
    if (lower.contains('mason')) return 'Masonry';
    if (lower.contains('weld')) return 'Welding';
    return null;
  }
}
