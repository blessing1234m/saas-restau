import 'package:flutter/material.dart';
import 'package:frontend/services/index.dart';

class AdminEtablissementProvider extends ChangeNotifier {
  Map<String, dynamic>? _etablissement;
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
  
  List<dynamic> get sousRestaurants => _etablissement?['sousRestaurants'] ?? [];
  List<dynamic> get serveurs => _etablissement?['serveurs'] ?? [];

  // Load admin's établissement data from API
  Future<void> loadEtablissement(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getAdminEtablissement(token);
      _etablissement = response;
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
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
