class Serveur {
  final String id;
  final String utilisateurId;
  final String codeAgent;
  final String etablissementId;
  final String? sousRestaurantId;
  final bool estActif;
  final DateTime createdAt;
  final DateTime updatedAt;

  Serveur({
    required this.id,
    required this.utilisateurId,
    required this.codeAgent,
    required this.etablissementId,
    this.sousRestaurantId,
    required this.estActif,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Serveur.fromJson(Map<String, dynamic> json) {
    return Serveur(
      id: json['id'] as String,
      utilisateurId: json['utilisateurId'] as String,
      codeAgent: json['utilisateur']['codeAgent'] as String? ?? 'N/A',
      etablissementId: json['etablissementId'] as String,
      sousRestaurantId: json['sousRestaurantId'] as String?,
      estActif: json['utilisateur']['estActif'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'utilisateurId': utilisateurId,
      'codeAgent': codeAgent,
      'etablissementId': etablissementId,
      'sousRestaurantId': sousRestaurantId,
      'estActif': estActif,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
