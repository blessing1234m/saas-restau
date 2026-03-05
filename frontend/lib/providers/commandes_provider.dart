import 'package:flutter/material.dart';
import 'package:frontend/services/index.dart';

class CommandesProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _commandes = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedSousRestaurantId;
  String _selectedStatut = 'TOUS';

  List<Map<String, dynamic>> get commandes => _commandes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedSousRestaurantId => _selectedSousRestaurantId;
  String get selectedStatut => _selectedStatut;

  Future<void> loadCommandes(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _commandes = await ApiService.getAdminCommandes(
        token: token,
        sousRestaurantId: _selectedSousRestaurantId,
        statut: _selectedStatut == 'TOUS' ? null : _selectedStatut,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCommandeStatut({
    required String token,
    required String commandeId,
    required String statut,
  }) async {
    try {
      await ApiService.updateAdminCommandeStatut(
        token: token,
        commandeId: commandeId,
        statut: statut,
      );
      await loadCommandes(token);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void setSousRestaurantFilter(String? sousRestaurantId) {
    _selectedSousRestaurantId = sousRestaurantId;
    notifyListeners();
  }

  void setStatutFilter(String statut) {
    _selectedStatut = statut;
    notifyListeners();
  }

  void clear() {
    _commandes = [];
    _isLoading = false;
    _errorMessage = null;
    _selectedSousRestaurantId = null;
    _selectedStatut = 'TOUS';
    notifyListeners();
  }
}
