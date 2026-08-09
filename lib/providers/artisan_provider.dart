import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/services/firestore_service.dart';
import '../models/artisan_model.dart';

class ArtisanProvider extends ChangeNotifier {
  ArtisanProvider({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  List<ArtisanModel> _allArtisans = [];
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedLocation;
  double _minRating = 0;
  bool? _availableOnly;
  bool _sortByRating = false;
  bool _isLoading = false;
  String? _errorMessage;

  List<ArtisanModel> get artisans => _applyFilters(_allArtisans);

  List<ArtisanModel> get allArtisans => List.unmodifiable(_allArtisans);

  String get searchQuery => _searchQuery;

  String? get selectedCategory => _selectedCategory;

  String? get selectedLocation => _selectedLocation;

  double get minRating => _minRating;

  bool? get availableOnly => _availableOnly;

  bool get sortByRating => _sortByRating;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  ArtisanModel? _currentArtisan;

  ArtisanModel? get currentArtisan => _currentArtisan;

  Future<bool> loadCurrentArtisan(String userId) async {
    return _runAction(() async {
      _currentArtisan = await _firestoreService.getArtisan(userId);
    });
  }

  Future<bool> updateArtisanProfile(ArtisanModel artisan) async {
    return _runAction(() async {
      await _firestoreService.saveArtisan(artisan);
      _currentArtisan = artisan;
      final index = _allArtisans.indexWhere((a) => a.id == artisan.id);
      if (index != -1) {
        _allArtisans = [
          ..._allArtisans.sublist(0, index),
          artisan,
          ..._allArtisans.sublist(index + 1),
        ];
      }
    });
  }

  List<ArtisanModel> get popularArtisans {
    final sorted = [..._allArtisans]..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(5).toList();
  }

  List<ArtisanModel> get nearbyArtisans {
    final withLocation = _allArtisans
        .where((a) => a.location != null && a.location!.trim().isNotEmpty)
        .toList();

    if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
      final q = _selectedLocation!.toLowerCase();
      return withLocation
          .where((a) => a.location!.toLowerCase().contains(q))
          .take(5)
          .toList();
    }

    return withLocation.take(5).toList();
  }

  ArtisanModel? getArtisanById(String id) {
    try {
      return _allArtisans.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  void updateArtisanRating({
    required String artisanId,
    required double rating,
    required int reviewCount,
  }) {
    final index = _allArtisans.indexWhere((a) => a.id == artisanId);
    if (index == -1) return;

    _allArtisans = [
      ..._allArtisans.sublist(0, index),
      _allArtisans[index].copyWith(rating: rating, reviewCount: reviewCount),
      ..._allArtisans.sublist(index + 1),
    ];

    if (_currentArtisan?.id == artisanId) {
      _currentArtisan = _currentArtisan!.copyWith(
        rating: rating,
        reviewCount: reviewCount,
      );
    }

    notifyListeners();
  }

  Future<void> refreshArtisan(String id) async {
    try {
      final artisan = await _firestoreService.getArtisan(id);
      if (artisan == null) return;

      final index = _allArtisans.indexWhere((a) => a.id == id);
      if (index != -1) {
        _allArtisans = [
          ..._allArtisans.sublist(0, index),
          artisan,
          ..._allArtisans.sublist(index + 1),
        ];
      }

      if (_currentArtisan?.id == id) {
        _currentArtisan = artisan;
      }

      notifyListeners();
    } catch (_) {
      // Non-critical: rating will refresh on next load.
    }
  }

  Future<ArtisanModel?> fetchArtisan(String id) async {
    final local = getArtisanById(id);
    if (local != null) return local;
    try {
      return await _firestoreService.getArtisan(id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> loadArtisans() async {
    return _runAction(() async {
      _allArtisans = await _firestoreService.getArtisans(
        category: _selectedCategory,
        isAvailable: _availableOnly,
      );
    });
  }

  void search(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void filter({
    String? category,
    String? location,
    double? minRating,
    bool? availableOnly,
  }) {
    if (category != null) {
      _selectedCategory = category.isEmpty ? null : category;
    }
    if (location != null) {
      _selectedLocation = location.isEmpty ? null : location;
    }
    if (minRating != null) _minRating = minRating;
    if (availableOnly != null) _availableOnly = availableOnly;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedLocation = null;
    _minRating = 0;
    _availableOnly = null;
    _sortByRating = false;
    notifyListeners();
  }

  void setSortByRating(bool value) {
    _sortByRating = value;
    notifyListeners();
  }

  List<ArtisanModel> getArtisansByRating({double minimum = 0}) {
    return _allArtisans.where((artisan) => artisan.rating >= minimum).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
  }

  List<ArtisanModel> _applyFilters(List<ArtisanModel> source) {
    final query = _searchQuery.toLowerCase();

    var results = source.where((artisan) {
      final location = artisan.location?.toLowerCase() ?? '';

      final matchesSearch = query.isEmpty ||
          artisan.name.toLowerCase().contains(query) ||
          artisan.category.toLowerCase().contains(query) ||
          location.contains(query) ||
          AppConstants.categoryProfessions[artisan.category]
                  ?.toLowerCase()
                  .contains(query) ==
              true ||
          artisan.skills.any(
            (skill) => skill.toLowerCase().contains(query),
          );

      final matchesCategory =
          _selectedCategory == null || artisan.category == _selectedCategory;

      final matchesLocation = _selectedLocation == null ||
          location.contains(_selectedLocation!.toLowerCase());

      final matchesRating = artisan.rating >= _minRating;

      final matchesAvailability =
          _availableOnly == null || artisan.isAvailable == _availableOnly;

      return matchesSearch &&
          matchesCategory &&
          matchesLocation &&
          matchesRating &&
          matchesAvailability;
    }).toList();

    if (_sortByRating) {
      results.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return results;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runAction(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
