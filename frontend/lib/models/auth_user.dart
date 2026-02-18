class AuthUser {
  final String utilisateurId;
  final String codeAgent;
  final String role;

  AuthUser({
    required this.utilisateurId,
    required this.codeAgent,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      utilisateurId: json['utilisateurId'] as String,
      codeAgent: json['codeAgent'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'utilisateurId': utilisateurId,
      'codeAgent': codeAgent,
      'role': role,
    };
  }

  bool get isSuperAdmin => role == 'SUPER_ADMIN';
  bool get isAdminEtablissement => role == 'ADMIN_ETABLISSEMENT';
  bool get isServeur => role == 'SERVEUR';
}
