import 'package:flutter/material.dart';
import 'package:frontend/models/index.dart';
import 'package:frontend/services/index.dart';

class MenuManagementProvider extends ChangeNotifier {
  List<SousRestaurant> _sousRestaurants = [];
  Map<String, List<Categorie>> _categoriesBySousRestaurant = {};
  Map<String, List<Plat>> _platsByCategorie = {};
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedSousRestaurantId;
  String? _selectedCategorieId;

  // Getters
  List<SousRestaurant> get sousRestaurants => _sousRestaurants;
  Map<String, List<Categorie>> get categoriesBySousRestaurant => _categoriesBySousRestaurant;
  Map<String, List<Plat>> get platsByCategorie => _platsByCategorie;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedSousRestaurantId => _selectedSousRestaurantId;
  String? get selectedCategorieId => _selectedCategorieId;

  SousRestaurant? get selectedSousRestaurant {
    if (_selectedSousRestaurantId == null || _sousRestaurants.isEmpty) {
      return null;
    }
    try {
      return _sousRestaurants.firstWhere(
        (sr) => sr.id == _selectedSousRestaurantId,
      );
    } catch (e) {
      return null;
    }
  }

  List<Categorie> get selectedCategories => _selectedSousRestaurantId != null
      ? _categoriesBySousRestaurant[_selectedSousRestaurantId] ?? []
      : [];

  List<Plat> get selectedPlats => _selectedCategorieId != null
      ? _platsByCategorie[_selectedCategorieId] ?? []
      : [];

  Future<void> _reloadSousRestaurantsPreservingSelection(
    String token, {
    String? preferredSousRestaurantId,
  }) async {
    final previousSelectedId = preferredSousRestaurantId ?? _selectedSousRestaurantId;
    _sousRestaurants = await ApiService.getSousRestaurants(token);

    if (_sousRestaurants.isEmpty) {
      _selectedSousRestaurantId = null;
      _selectedCategorieId = null;
      _categoriesBySousRestaurant = {};
      _platsByCategorie = {};
      return;
    }

    final hasPrevious = previousSelectedId != null &&
        _sousRestaurants.any((sr) => sr.id == previousSelectedId);
    _selectedSousRestaurantId = hasPrevious
        ? previousSelectedId
        : _sousRestaurants.first.id;
    _selectedCategorieId = null;

    await loadCategories(_selectedSousRestaurantId!, token);
  }

  // Load all sous-restaurants
  Future<void> loadSousRestaurants(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reloadSousRestaurantsPreservingSelection(token);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load categories for a specific sous-restaurant
  Future<void> loadCategories(String sousRestaurantId, String token) async {
    try {
      final categories = await ApiService.getCategories(sousRestaurantId, token);
      _categoriesBySousRestaurant[sousRestaurantId] = categories;
      if (categories.isNotEmpty && _selectedCategorieId == null) {
        _selectedCategorieId = categories.first.id;
        await loadPlats(sousRestaurantId, categories.first.id, token);
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Load plats for a specific category
  Future<void> loadPlats(
    String sousRestaurantId,
    String categorieId,
    String token,
  ) async {
    try {
      final plats = await ApiService.getPlats(sousRestaurantId, categorieId, token);
      _platsByCategorie[categorieId] = plats;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Create a new sous-restaurant
  Future<bool> createSousRestaurant({
    required String nom,
    String? description,
    required String token,
  }) async {
    try {
      final sr = await ApiService.createSousRestaurant(
        nom: nom,
        description: description,
        token: token,
      );
      _sousRestaurants.add(sr);
      _selectedSousRestaurantId = sr.id;
      _categoriesBySousRestaurant[sr.id] = [];
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Update sous-restaurant
  Future<bool> updateSousRestaurant({
    required String sousRestaurantId,
    String? nom,
    String? description,
    required String token,
  }) async {
    try {
      final updated = await ApiService.updateSousRestaurant(
        sousRestaurantId: sousRestaurantId,
        nom: nom,
        description: description,
        token: token,
      );
      final index = _sousRestaurants.indexWhere((sr) => sr.id == sousRestaurantId);
      if (index >= 0) {
        _sousRestaurants[index] = updated;
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Delete sous-restaurant
  Future<bool> deleteSousRestaurant(
    String sousRestaurantId,
    String token,
  ) async {
    try {
      await ApiService.deleteSousRestaurant(sousRestaurantId, token);
      _sousRestaurants.removeWhere((sr) => sr.id == sousRestaurantId);
      _categoriesBySousRestaurant.remove(sousRestaurantId);
      if (_selectedSousRestaurantId == sousRestaurantId && _sousRestaurants.isNotEmpty) {
        _selectedSousRestaurantId = _sousRestaurants.first.id;
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Create a table in a sous-restaurant
  Future<bool> createTable({
    required String sousRestaurantId,
    required String numero,
    required String token,
  }) async {
    try {
      await ApiService.createTable(
        sousRestaurantId: sousRestaurantId,
        numero: numero,
        token: token,
      );
      await _reloadSousRestaurantsPreservingSelection(
        token,
        preferredSousRestaurantId: sousRestaurantId,
      );
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Update a table
  Future<bool> updateTable({
    required String sousRestaurantId,
    required String tableId,
    required String numero,
    required String token,
  }) async {
    try {
      await ApiService.updateTable(
        sousRestaurantId: sousRestaurantId,
        tableId: tableId,
        numero: numero,
        token: token,
      );
      await _reloadSousRestaurantsPreservingSelection(
        token,
        preferredSousRestaurantId: sousRestaurantId,
      );
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Delete a table
  Future<bool> deleteTable({
    required String sousRestaurantId,
    required String tableId,
    required String token,
  }) async {
    try {
      await ApiService.deleteTable(
        sousRestaurantId: sousRestaurantId,
        tableId: tableId,
        token: token,
      );
      await _reloadSousRestaurantsPreservingSelection(
        token,
        preferredSousRestaurantId: sousRestaurantId,
      );
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Create a new category
  Future<bool> createCategorie({
    required String sousRestaurantId,
    required String nom,
    String? description,
    int? ordre,
    String? photoBase64,
    required String token,
  }) async {
    try {
      final cat = await ApiService.createCategorie(
        sousRestaurantId: sousRestaurantId,
        nom: nom,
        description: description,
        ordre: ordre,
        photoAffichage: photoBase64,
        token: token,
      );
      if (!_categoriesBySousRestaurant.containsKey(sousRestaurantId)) {
        _categoriesBySousRestaurant[sousRestaurantId] = [];
      }
      _categoriesBySousRestaurant[sousRestaurantId]!.add(cat);
      _selectedCategorieId = cat.id;
      _platsByCategorie[cat.id] = [];
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Update category
  Future<bool> updateCategorie({
    required String sousRestaurantId,
    required String categorieId,
    String? nom,
    String? description,
    int? ordre,
    String? photoBase64,
    required String token,
  }) async {
    try {
      final updated = await ApiService.updateCategorie(
        sousRestaurantId: sousRestaurantId,
        categorieId: categorieId,
        nom: nom,
        description: description,
        ordre: ordre,
        photoAffichage: photoBase64,
        token: token,
      );
      final categories = _categoriesBySousRestaurant[sousRestaurantId];
      if (categories != null) {
        final index = categories.indexWhere((c) => c.id == categorieId);
        if (index >= 0) {
          categories[index] = updated;
        }
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Delete category
  Future<bool> deleteCategorie(
    String sousRestaurantId,
    String categorieId,
    String token,
  ) async {
    try {
      await ApiService.deleteCategorie(sousRestaurantId, categorieId, token);
      final categories = _categoriesBySousRestaurant[sousRestaurantId];
      if (categories != null) {
        categories.removeWhere((c) => c.id == categorieId);
      }
      _platsByCategorie.remove(categorieId);
      if (_selectedCategorieId == categorieId) {
        _selectedCategorieId = categories?.isNotEmpty == true ? categories!.first.id : null;
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Create a new plat
  Future<bool> createPlat({
    required String sousRestaurantId,
    required String categorieId,
    required String nom,
    String? description,
    required double prix,
    List<String>? imagesBase64,
    required String token,
  }) async {
    try {
      final plat = await ApiService.createPlat(
        sousRestaurantId: sousRestaurantId,
        categorieId: categorieId,
        nom: nom,
        description: description,
        prix: prix,
        images: imagesBase64,
        token: token,
      );
      if (!_platsByCategorie.containsKey(categorieId)) {
        _platsByCategorie[categorieId] = [];
      }
      _platsByCategorie[categorieId]!.add(plat);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Update plat
  Future<bool> updatePlat({
    required String sousRestaurantId,
    required String categorieId,
    required String platId,
    String? nom,
    String? description,
    double? prix,
    List<String>? imagesBase64,
    List<String>? removeImageIds,
    required String token,
  }) async {
    try {
      final updated = await ApiService.updatePlat(
        sousRestaurantId: sousRestaurantId,
        categorieId: categorieId,
        platId: platId,
        nom: nom,
        description: description,
        prix: prix,
        images: imagesBase64,
        removeImageIds: removeImageIds,
        token: token,
      );
      final plats = _platsByCategorie[categorieId];
      if (plats != null) {
        final index = plats.indexWhere((p) => p.id == platId);
        if (index >= 0) {
          plats[index] = updated;
        }
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Delete plat
  Future<bool> deletePlat(
    String sousRestaurantId,
    String categorieId,
    String platId,
    String token,
  ) async {
    try {
      await ApiService.deletePlat(sousRestaurantId, categorieId, platId, token);
      final plats = _platsByCategorie[categorieId];
      if (plats != null) {
        plats.removeWhere((p) => p.id == platId);
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Select sous-restaurant
  void selectSousRestaurant(String sousRestaurantId) {
    _selectedSousRestaurantId = sousRestaurantId;
    _selectedCategorieId = null;
    notifyListeners();
  }

  // Select category
  void selectCategorie(String categorieId) {
    _selectedCategorieId = categorieId;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _sousRestaurants = [];
    _categoriesBySousRestaurant = {};
    _platsByCategorie = {};
    _selectedSousRestaurantId = null;
    _selectedCategorieId = null;
    _errorMessage = null;
    notifyListeners();
  }
}
