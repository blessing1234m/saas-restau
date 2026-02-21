import 'package:flutter/material.dart';
import 'package:frontend/services/index.dart';

class ServeurMenuProvider extends ChangeNotifier {
  Map<String, dynamic>? _sousRestaurantActuel;
  List<Map<String, dynamic>> _categories = [];
  Map<String, dynamic>? _categorieSelectionnee;
  List<Map<String, dynamic>> _plats = [];
  
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Map<String, dynamic>? get sousRestaurantActuel => _sousRestaurantActuel;
  List<Map<String, dynamic>> get categories => _categories;
  Map<String, dynamic>? get categorieSelectionnee => _categorieSelectionnee;
  List<Map<String, dynamic>> get plats => _plats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize server menu with their assigned sous-restaurant
  Future<void> initializeServerMenu(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get the server's assigned sous-restaurant
      final sousRestaurant = await ApiService.getSousRestaurantDuServeur(token);
      
      if (sousRestaurant != null) {
        final idValue = sousRestaurant['id'];
        final sousRestaurantId = idValue is String ? idValue : idValue.toString();
        // Load the menu for this sous-restaurant
        await loadMenu(sousRestaurantId, token);
      } else {
        _errorMessage = 'Aucun sous-restaurant assigné';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load menu for a sous-restaurant
  Future<void> loadMenu(String sousRestaurantId, String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final menu = await ApiService.getMenuSousRestaurant(sousRestaurantId, token);
      _sousRestaurantActuel = menu;
      
      // Extract categories safely
      final categoriesList = menu['categories'] ?? [];
      if (categoriesList is List) {
        _categories = List<Map<String, dynamic>>.from(categoriesList.cast<Map<String, dynamic>>());
      } else {
        _categories = [];
      }
      
      // Select first category by default
      if (_categories.isNotEmpty) {
        await selectCategorie(_categories[0], sousRestaurantId, token);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Select a category and load its plats
  Future<void> selectCategorie(
    Map<String, dynamic> categorie,
    String sousRestaurantId,
    String token,
  ) async {
    _categorieSelectionnee = categorie;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final idValue = categorie['id'];
      final categorieId = idValue is String ? idValue : idValue.toString();
      final plats = await ApiService.getPlatsDuCategorie(
        sousRestaurantId,
        categorieId,
        token,
      );
      
      _plats = plats;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear data on logout
  void clear() {
    _sousRestaurantActuel = null;
    _categories = [];
    _categorieSelectionnee = null;
    _plats = [];
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
