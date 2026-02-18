import 'package:flutter/material.dart';
import 'package:frontend/models/index.dart';
import 'package:frontend/services/api_service.dart';

class SuperAdminProvider extends ChangeNotifier {
  List<Etablissement> _etablissements = [];
  List<AdminEtablissement> _admins = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Etablissement> get etablissements => _etablissements;
  List<AdminEtablissement> get admins => _admins;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalEtablissements => _etablissements.length;
  int get actifEtablissements => _etablissements.where((e) => e.estActif).length;
  int get inactifEtablissements => _etablissements.where((e) => !e.estActif).length;

  /// Load all établissements
  Future<void> loadEtablissements(String token) async {
    _isLoading = true;
    _errorMessage = null;
    if (hasListeners) notifyListeners();

    try {
      _etablissements = await ApiService.getEtablissements(token);
      _isLoading = false;
      if (hasListeners) notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      if (hasListeners) notifyListeners();
    }
  }

  /// Load all admins
  Future<void> loadAdmins(String token) async {
    _isLoading = true;
    _errorMessage = null;
    if (hasListeners) notifyListeners();

    try {
      _admins = await ApiService.getAdminEtablissements(token);
      _isLoading = false;
      if (hasListeners) notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      if (hasListeners) notifyListeners();
    }
  }

  /// Create établissement
  Future<bool> createEtablissement(
    String token,
    String nom,
    String ville,
    String? telephone,
    String? email,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    if (hasListeners) notifyListeners();

    try {
      final nouveauEtablissement = await ApiService.createEtablissement(
        token,
        nom,
        ville,
        telephone,
        email,
      );
      _etablissements.add(nouveauEtablissement);
      _isLoading = false;
      if (hasListeners) notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      if (hasListeners) notifyListeners();
      return false;
    }
  }

  /// Crée un nouvel admin établissement. Retourne null si succès, sinon message d'erreur.
  Future<String?> createAdminEtablissement({
    required String codeAgent,
    required String motDePasse,
    required String etablissementId,
    required String token,
  }) async {
    try {
      _errorMessage = null;
      _isLoading = true;
      if (hasListeners) notifyListeners();
      await ApiService.createAdminEtablissement(
        codeAgent: codeAgent,
        motDePasse: motDePasse,
        etablissementId: etablissementId,
        token: token,
      );
      _isLoading = false;
      if (hasListeners) notifyListeners();
      
      // ✅ Recharge en arrière-plan sans attendre
      loadAdmins(token);
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      if (hasListeners) notifyListeners();
      return _errorMessage;
    }
  }

  /// Modifie un admin établissement. Retourne null si succès, sinon message d'erreur.
  Future<String?> updateAdminEtablissement({
    required String id,
    required String codeAgent,
    String? motDePasse,
    required String etablissementId,
    required String token,
  }) async {
    try {
      _errorMessage = null;
      _isLoading = true;
      if (hasListeners) notifyListeners();
      await ApiService.updateAdminEtablissement(
        id: id,
        codeAgent: codeAgent,
        motDePasse: motDePasse,
        etablissementId: etablissementId,
        token: token,
      );
      _isLoading = false;
      if (hasListeners) notifyListeners();
      
      // ✅ Recharge en arrière-plan sans attendre
      loadAdmins(token);
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      if (hasListeners) notifyListeners();
      return _errorMessage;
    }
  }

  /// Update établissement
  Future<bool> updateEtablissement(
    String id,
    String token,
    String nom,
    String ville,
    String? telephone,
    String? email,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    if (hasListeners) notifyListeners();

    try {
      final updated = await ApiService.updateEtablissement(
        id,
        token,
        nom,
        ville,
        telephone,
        email,
      );
      final index = _etablissements.indexWhere((e) => e.id == id);
      if (index != -1) {
        _etablissements[index] = updated;
      }
      _isLoading = false;
      if (hasListeners) notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      if (hasListeners) notifyListeners();
      return false;
    }
  }

  /// Toggle établissement state
  /// Si établissement devient inactif, tous ses admins sont désactivés
  Future<bool> toggleEtablissementState(String id, String token) async {
    try {
      final updated = await ApiService.toggleEtablissementState(id, token);
      final index = _etablissements.indexWhere((e) => e.id == id);
      if (index != -1) {
        _etablissements[index] = updated;
      }
      
      // ✅ Si établissement devient INACTIF, désactiver tous ses admins
      if (!updated.estActif) {
        // Récupérer les admins actifs de cet établissement
        final adminsADesactiver = _admins
            .where((admin) => admin.etablissementId == id && admin.estActif)
            .toList();
        
        // Désactiver chaque admin
        for (final admin in adminsADesactiver) {
          try {
            await ApiService.toggleAdminState(admin.id, token);
          } catch (e) {
            // Continuer même si un admin échoue
            print('Erreur désactivation admin ${admin.id}: $e');
          }
        }
        
        // ✅ Recharger les admins pour refléter les changements
        await loadAdmins(token);
      }
      
      if (hasListeners) notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      if (hasListeners) notifyListeners();
      return false;
    }
  }

  /// Delete établissement
  Future<bool> deleteEtablissement(String id, String token) async {
    try {
      await ApiService.deleteEtablissement(id, token);
      _etablissements.removeWhere((e) => e.id == id);
      if (hasListeners) notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      if (hasListeners) notifyListeners();
      return false;
    }
  }

  /// Toggle admin state
  Future<bool> toggleAdminState(String id, String token) async {
    try {
      await ApiService.toggleAdminState(id, token);
      // Reload admins
      await loadAdmins(token);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      if (hasListeners) notifyListeners();
      return false;
    }
  }

  /// Delete admin
  Future<bool> deleteAdmin(String id, String token) async {
    try {
      await ApiService.deleteAdminEtablissement(id, token);
      _admins.removeWhere((a) => a.id == id);
      if (hasListeners) notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      if (hasListeners) notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    if (hasListeners) notifyListeners();
  }
}
