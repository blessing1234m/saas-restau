/// Classe pour les requêtes de changement de mot de passe
/// Utilisée quand l'utilisateur doit fournir l'ancien et le nouveau mot de passe
class ChangePasswordRequest {
  final String ancienMotDePasse;
  final String nouveauMotDePasse;

  ChangePasswordRequest({
    required this.ancienMotDePasse,
    required this.nouveauMotDePasse,
  });

  Map<String, dynamic> toJson() {
    return {
      'ancienMotDePasse': ancienMotDePasse,
      'nouveauMotDePasse': nouveauMotDePasse,
    };
  }

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) {
    return ChangePasswordRequest(
      ancienMotDePasse: json['ancienMotDePasse'] as String,
      nouveauMotDePasse: json['nouveauMotDePasse'] as String,
    );
  }
}

/// Classe pour les requêtes de changement de mot de passe d'un utilisateur
/// Utilisée par les AdminEtablissement quand ils changent le mot de passe d'un serveur
class ChangeUserPasswordRequest {
  final String nouveauMotDePasse;

  ChangeUserPasswordRequest({
    required this.nouveauMotDePasse,
  });

  Map<String, dynamic> toJson() {
    return {
      'nouveauMotDePasse': nouveauMotDePasse,
    };
  }

  factory ChangeUserPasswordRequest.fromJson(Map<String, dynamic> json) {
    return ChangeUserPasswordRequest(
      nouveauMotDePasse: json['nouveauMotDePasse'] as String,
    );
  }
}

/// Classe de réponse générique pour les changements de mot de passe
class PasswordChangeResponse {
  final String message;
  final bool success;

  PasswordChangeResponse({
    required this.message,
    this.success = true,
  });

  factory PasswordChangeResponse.fromJson(Map<String, dynamic> json) {
    return PasswordChangeResponse(
      message: json['message'] as String? ?? 'Mot de passe changé avec succès',
      success: json['success'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'success': success,
    };
  }
}
