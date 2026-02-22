import 'package:flutter/material.dart';
import 'package:frontend/constants/app_constants.dart';
import 'package:frontend/models/index.dart';
import 'package:frontend/services/index.dart';

class AuthProvider extends ChangeNotifier {
  AuthUser? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  // Getters
  AuthUser? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  // Auth provider constructor - check if user is already logged in
  AuthProvider() {
    _initializeAuth();
  }

  /// Initialize authentication on app start
  Future<void> _initializeAuth() async {
    try {
      final token = await SecureStorageService.getString(
        AppConstants.tokenStorageKey,
      );
      final userJson = await SecureStorageService.getString(
        AppConstants.userStorageKey,
      );

      if (token != null && userJson != null) {
        _token = token;
        // Parse user from JSON format: utilisateurId|codeAgent|role|estActif|etablissementId|etablissementName
        final parts = userJson.split('|');
        _user = AuthUser(
          utilisateurId: parts[0],
          codeAgent: parts[1],
          role: parts[2],
          estActif: parts.length > 3 && parts[3].isNotEmpty ? parts[3].toLowerCase() == 'true' : true,
          etablissementId: parts.length > 4 && parts[4].isNotEmpty ? parts[4] : null,
          etablissementName: parts.length > 5 && parts[5].isNotEmpty ? parts[5] : null,
        );
        _isAuthenticated = true;
      }
    } catch (e) {
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  /// Login with code agent and password
  Future<bool> login(String codeAgent, String motDePasse) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Trim the inputs to remove leading/trailing whitespace
      final trimmedCodeAgent = codeAgent.trim();
      final trimmedMotDePasse = motDePasse.trim();
      
      final response = await ApiService.login(
        codeAgent: trimmedCodeAgent,
        motDePasse: trimmedMotDePasse,
      );

      // Create AuthUser from response
      _user = AuthUser(
        utilisateurId: response.utilisateurId,
        codeAgent: response.codeAgent,
        role: response.role,
        estActif: response.estActif ?? true,
        etablissementId: response.etablissementId,
        etablissementName: response.etablissementName,
      );
      _token = response.accessToken;
      _isAuthenticated = true;

      // Store token and user data securely
      await SecureStorageService.saveString(
        AppConstants.tokenStorageKey,
        response.accessToken,
      );
      
      // Store user data as pipe-separated string for simplicity
      // Format: utilisateurId|codeAgent|role|estActif|etablissementId|etablissementName
      final estActifStr = (response.estActif ?? true) ? 'true' : 'false';
      final etablissementStr = response.etablissementId ?? '';
      final etablissementNameStr = response.etablissementName ?? '';
      await SecureStorageService.saveString(
        AppConstants.userStorageKey,
        '${response.utilisateurId}|${response.codeAgent}|${response.role}|$estActifStr|$etablissementStr|$etablissementNameStr',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Change current user password
  Future<bool> changePassword({
    required String ancienMotDePasse,
    required String nouveauMotDePasse,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_token == null) {
        throw Exception('Aucun token d\'authentification');
      }

      late PasswordChangeResponse response;

      // Determine user role and call appropriate method
      if (_user?.isSuperAdmin == true) {
        response = await ApiService.changePasswordSuperAdmin(
          ancienMotDePasse: ancienMotDePasse,
          nouveauMotDePasse: nouveauMotDePasse,
          token: _token!,
        );
      } else if (_user?.isAdminEtablissement == true) {
        response = await ApiService.changePasswordAdminEtablissement(
          ancienMotDePasse: ancienMotDePasse,
          nouveauMotDePasse: nouveauMotDePasse,
          token: _token!,
        );
      } else if (_user?.isServeur == true) {
        response = await ApiService.changePasswordServeur(
          ancienMotDePasse: ancienMotDePasse,
          nouveauMotDePasse: nouveauMotDePasse,
          token: _token!,
        );
      } else {
        throw Exception('Rôle utilisateur non reconnu');
      }

      _isLoading = false;
      notifyListeners();
      return response.success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Change server password (for AdminEtablissement only)
  Future<bool> changeServerPassword({
    required String serveurId,
    required String nouveauMotDePasse,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_token == null) {
        throw Exception('Aucun token d\'authentification');
      }

      if (_user?.isAdminEtablissement != true) {
        throw Exception('Seul un admin établissement peut changer le mot de passe d\'un serveur');
      }

      final response = await ApiService.changeServerPassword(
        serveurId: serveurId,
        nouveauMotDePasse: nouveauMotDePasse,
        token: _token!,
      );

      _isLoading = false;
      notifyListeners();
      return response.success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _user = null;
    _token = null;
    _isAuthenticated = false;
    _errorMessage = null;

    // Clear secure storage
    await SecureStorageService.deleteAll();
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
