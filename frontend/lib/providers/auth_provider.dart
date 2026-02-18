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
        // Parse user from JSON
        _user = AuthUser(
          utilisateurId: userJson.split('|')[0],
          codeAgent: userJson.split('|')[1],
          role: userJson.split('|')[2],
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
      final response = await ApiService.login(
        codeAgent: codeAgent,
        motDePasse: motDePasse,
      );

      // Create AuthUser from response
      _user = AuthUser(
        utilisateurId: response.utilisateurId,
        codeAgent: response.codeAgent,
        role: response.role,
      );
      _token = response.accessToken;
      _isAuthenticated = true;

      // Store token and user data securely
      await SecureStorageService.saveString(
        AppConstants.tokenStorageKey,
        response.accessToken,
      );
      
      // Store user data as pipe-separated string for simplicity
      await SecureStorageService.saveString(
        AppConstants.userStorageKey,
        '${response.utilisateurId}|${response.codeAgent}|${response.role}',
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
