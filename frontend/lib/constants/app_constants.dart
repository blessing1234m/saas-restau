class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'http://192.168.1.71:3000/api';
  static const String authEndpoint = '/auth/login';
  static const String publicMenuEndpoint = '/public/sous-restaurants';
  
  // Secure Storage Keys
  static const String tokenStorageKey = 'auth_token';
  static const String userStorageKey = 'auth_user';
  
  // Error Messages
  static const String errorInvalidCredentials = 'Code agent ou mot de passe incorrect';
  static const String errorNetworkError = 'Erreur réseau. Veuillez vérifier votre connexion';
  static const String errorServerError = 'Erreur serveur. Veuillez réessayer plus tard';
  static const String errorUnknownError = 'Une erreur inconnue s\'est produite';
  
  // Success Messages
  static const String loginSuccess = 'Connexion réussie';
}
