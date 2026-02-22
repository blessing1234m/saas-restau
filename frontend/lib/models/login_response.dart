class LoginResponse {
  final String accessToken;
  final String utilisateurId;
  final String codeAgent;
  final String role;
  final bool? estActif;
  final String? etablissementId;
  final String? etablissementName;

  LoginResponse({
    required this.accessToken,
    required this.utilisateurId,
    required this.codeAgent,
    required this.role,
    this.estActif,
    this.etablissementId,
    this.etablissementName,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      utilisateurId: json['utilisateurId'] as String,
      codeAgent: json['codeAgent'] as String,
      role: json['role'] as String,
      estActif: json['estActif'] as bool?,
      etablissementId: json['etablissementId'] as String?,
      etablissementName: json['etablissementName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'utilisateurId': utilisateurId,
      'codeAgent': codeAgent,
      'role': role,
      'estActif': estActif,
      'etablissementId': etablissementId,
      'etablissementName': etablissementName,
    };
  }
}
