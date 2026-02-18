class LoginResponse {
  final String accessToken;
  final String utilisateurId;
  final String codeAgent;
  final String role;

  LoginResponse({
    required this.accessToken,
    required this.utilisateurId,
    required this.codeAgent,
    required this.role,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      utilisateurId: json['utilisateurId'] as String,
      codeAgent: json['codeAgent'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'utilisateurId': utilisateurId,
      'codeAgent': codeAgent,
      'role': role,
    };
  }
}
