class AdminEtablissement {
  final String id;
  final String utilisateurId;
  final String etablissementId;
  final String codeAgent;
  final String etablissementNom;
  final bool estActif;
  final DateTime createdAt;

  AdminEtablissement({
    required this.id,
    required this.utilisateurId,
    required this.etablissementId,
    required this.codeAgent,
    required this.etablissementNom,
    required this.estActif,
    required this.createdAt,
  });

  factory AdminEtablissement.fromJson(Map<String, dynamic> json) {
    return AdminEtablissement(
      id: json['id'] as String,
      utilisateurId: json['utilisateurId'] as String,
      etablissementId: json['etablissementId'] as String,
      codeAgent: json['utilisateur']['codeAgent'] as String? ?? 'N/A',
      etablissementNom: json['etablissement']['nom'] as String? ?? 'N/A',
      estActif: json['utilisateur']['estActif'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
