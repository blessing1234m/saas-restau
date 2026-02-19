class Categorie {
  final String id;
  final String nom;
  final String? description;
  final String? photoAffichage;
  final String? photoTypeContenu;
  final String? photoNomFichier;
  final int? photoTaille;
  final int ordre;
  final String sousRestaurantId;
  final bool estActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<dynamic>? plats;

  Categorie({
    required this.id,
    required this.nom,
    this.description,
    this.photoAffichage,
    this.photoTypeContenu,
    this.photoNomFichier,
    this.photoTaille,
    required this.ordre,
    required this.sousRestaurantId,
    required this.estActive,
    required this.createdAt,
    required this.updatedAt,
    this.plats,
  });

  factory Categorie.fromJson(Map<String, dynamic> json) {
    return Categorie(
      id: json['id'] as String,
      nom: json['nom'] as String,
      description: json['description'] as String?,
      photoAffichage: json['photoAffichage'] as String?,
      photoTypeContenu: json['photoTypeContenu'] as String?,
      photoNomFichier: json['photoNomFichier'] as String?,
      photoTaille: json['photoTaille'] as int?,
      ordre: json['ordre'] as int? ?? 0,
      sousRestaurantId: json['sousRestaurantId'] as String,
      estActive: json['estActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      plats: json['plats'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'ordre': ordre,
      'sousRestaurantId': sousRestaurantId,
      'estActive': estActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
