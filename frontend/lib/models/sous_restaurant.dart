class SousRestaurant {
  final String id;
  final String nom;
  final String? description;
  final String etablissementId;
  final bool estActif;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<dynamic>? tables;
  final List<dynamic>? categories;

  SousRestaurant({
    required this.id,
    required this.nom,
    this.description,
    required this.etablissementId,
    required this.estActif,
    required this.createdAt,
    required this.updatedAt,
    this.tables,
    this.categories,
  });

  factory SousRestaurant.fromJson(Map<String, dynamic> json) {
    return SousRestaurant(
      id: json['id'] as String,
      nom: json['nom'] as String,
      description: json['description'] as String?,
      etablissementId: json['etablissementId'] as String,
      estActif: json['estActif'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      tables: json['tables'] as List<dynamic>?,
      categories: json['categories'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'etablissementId': etablissementId,
      'estActif': estActif,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
