import 'package:flutter/material.dart';
import 'package:frontend/models/index.dart';
import 'package:frontend/services/index.dart';

class ServeurProvider extends ChangeNotifier {
  List<Serveur> _serveurs = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Serveur> get serveurs => _serveurs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load serveurs from API
  Future<void> loadServeurs(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _serveurs = await ApiService.getServeurs(token);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      _errorMessage = errorMsg.isEmpty ? 'Erreur de chargement des serveurs' : errorMsg;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new serveur
  Future<Serveur> createServeur({
    required String codeAgent,
    required String motDePasse,
    required String token,
  }) async {
    try {
      final newServeur = await ApiService.createServeur(
        codeAgent: codeAgent,
        motDePasse: motDePasse,
        token: token,
      );
      _serveurs.add(newServeur);
      _errorMessage = null;
      notifyListeners();
      return newServeur;
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      _errorMessage = errorMsg;
      notifyListeners();
      rethrow;
    }
  }

  // Create new serveur with sous-restaurant assignment
  Future<Serveur> createServeurWithSousRestaurant({
    required String codeAgent,
    required String motDePasse,
    required String sousRestaurantId,
    required String token,
  }) async {
    try {
      final newServeur = await ApiService.createServeurWithSousRestaurant(
        codeAgent: codeAgent,
        motDePasse: motDePasse,
        sousRestaurantId: sousRestaurantId,
        token: token,
      );
      _serveurs.add(newServeur);
      _errorMessage = null;
      notifyListeners();
      return newServeur;
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      _errorMessage = errorMsg;
      notifyListeners();
      rethrow;
    }
  }

  // Toggle serveur state
  Future<void> toggleServeurState(String serveurId, String token) async {
    try {
      await ApiService.toggleServeurState(serveurId, token);
      
      // Update local state
      final index = _serveurs.indexWhere((s) => s.id == serveurId);
      if (index != -1) {
        final serveur = _serveurs[index];
        _serveurs[index] = Serveur(
          id: serveur.id,
          utilisateurId: serveur.utilisateurId,
          codeAgent: serveur.codeAgent,
          etablissementId: serveur.etablissementId,
          estActif: !serveur.estActif,
          createdAt: serveur.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      _errorMessage = errorMsg;
      notifyListeners();
      rethrow;
    }
  }

  // Update serveur (e.g., change sous-restaurant)
  Future<Serveur> updateServeur({
    required String serveurId,
    required String token,
    String? sousRestaurantId,
  }) async {
    try {
      final updatedServeur = await ApiService.updateServeur(
        serveurId,
        token,
        sousRestaurantId: sousRestaurantId,
      );
      
      // Update the serveur in the list
      final index = _serveurs.indexWhere((s) => s.id == serveurId);
      if (index != -1) {
        _serveurs[index] = updatedServeur;
      }
      
      _errorMessage = null;
      notifyListeners();
      return updatedServeur;
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      _errorMessage = errorMsg;
      notifyListeners();
      rethrow;
    }
  }

  // Update serveur completely (code agent, sous-restaurant, password)
  Future<Serveur> updateServeurComplet({
    required String serveurId,
    required String token,
    required String codeAgent,
    required String sousRestaurantId,
    String? ancienMotDePasse,
    String? nouveauMotDePasse,
  }) async {
    try {
      final updatedServeur = await ApiService.updateServeurComplet(
        serveurId: serveurId,
        token: token,
        codeAgent: codeAgent,
        sousRestaurantId: sousRestaurantId,
        ancienMotDePasse: ancienMotDePasse,
        nouveauMotDePasse: nouveauMotDePasse,
      );
      
      // Update the serveur in the list
      final index = _serveurs.indexWhere((s) => s.id == serveurId);
      if (index != -1) {
        _serveurs[index] = updatedServeur;
      }
      
      _errorMessage = null;
      notifyListeners();
      return updatedServeur;
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      _errorMessage = errorMsg;
      notifyListeners();
      rethrow;
    }
  }

  // Delete serveur
  Future<void> deleteServeur(String serveurId, String token) async {
    try {
      await ApiService.deleteServeur(serveurId, token);
      _serveurs.removeWhere((s) => s.id == serveurId);
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      _errorMessage = errorMsg;
      notifyListeners();
      rethrow;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear data on logout
  void clear() {
    _serveurs = [];
    _errorMessage = null;
    notifyListeners();
  }
}
