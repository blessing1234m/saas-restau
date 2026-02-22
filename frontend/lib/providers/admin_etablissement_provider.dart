import 'package:flutter/material.dart';
import 'package:frontend/models/index.dart';
import 'package:frontend/services/index.dart';

class AdminEtablissementProvider extends ChangeNotifier {
  Map<String, dynamic>? _etablissement;
  List<SousRestaurant> _sousRestaurants = [];
  List<dynamic> _serveurs = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Map<String, dynamic>? get etablissement => _etablissement;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get etablissementName => _etablissement?['nom'];
  String? get etablissementVille => _etablissement?['ville'];
  String? get etablissementTelephone => _etablissement?['telephone'];
  String? get etablissementEmail => _etablissement?['email'];
  
  List<SousRestaurant> get sousRestaurants => _sousRestaurants;
  List<dynamic> get serveurs => _serveurs;

  // Load admin's établissement data from API
  Future<void> loadEtablissement(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getAdminEtablissement(token);
      _etablissement = response;

      // Parse sous-restaurants list
      if (response['sousRestaurants'] != null) {
        _sousRestaurants = (response['sousRestaurants'] as List<dynamic>)
            .map((sr) => SousRestaurant.fromJson(sr as Map<String, dynamic>))
            .toList();
      }

      // Parse serveurs list
      if (response['serveurs'] != null) {
        _serveurs = response['serveurs'] as List<dynamic>;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      print('ERROR LOADING ETABLISSEMENT: $errorMsg'); // Debug log
      _errorMessage = errorMsg.isEmpty ? 'Erreur de chargement de l\'établissement' : errorMsg;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear data on logout
  void clear() {
    _etablissement = null;
    _sousRestaurants = [];
    _serveurs = [];
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
