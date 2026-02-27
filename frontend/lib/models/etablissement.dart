class Etablissement {
  final String id;
  final String nom;
  final String ville;
  final String? telephone;
  final String? email;
  final String categorie;
  final bool estActif;
  final DateTime createdAt;

  Etablissement({
    required this.id,
    required this.nom,
    required this.ville,
    this.telephone,
    this.email,
    required this.categorie,
    required this.estActif,
    required this.createdAt,
  });

  factory Etablissement.fromJson(Map<String, dynamic> json) {
    return Etablissement(
      id: json['id'] as String,
      nom: json['nom'] as String,
      ville: json['ville'] as String,
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
      categorie: json['categorie'] as String? ?? 'SIMPLE',
      estActif: json['estActif'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'ville': ville,
      'telephone': telephone,
      'email': email,
      'categorie': categorie,
      'estActif': estActif,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
