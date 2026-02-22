class AuthUser {
  final String utilisateurId;
  final String codeAgent;
  final String role;
  final bool? estActif;
  final String? etablissementId;
  final String? etablissementName;

  AuthUser({
    required this.utilisateurId,
    required this.codeAgent,
    required this.role,
    this.estActif,
    this.etablissementId,
    this.etablissementName,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      utilisateurId: json['utilisateurId'] as String,
      codeAgent: json['codeAgent'] as String,
      role: json['role'] as String,
      estActif: json['estActif'] as bool? ?? true,
      etablissementId: json['etablissementId'] as String?,
      etablissementName: json['etablissementName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'utilisateurId': utilisateurId,
      'codeAgent': codeAgent,
      'role': role,
      'estActif': estActif,
      'etablissementId': etablissementId,
      'etablissementName': etablissementName,
    };
  }

  bool get isSuperAdmin => role == 'SUPER_ADMIN';
  bool get isAdminEtablissement => role == 'ADMIN_ETABLISSEMENT';
  bool get isServeur => role == 'SERVEUR';
}
