class Plat {
  final String id;
  final String nom;
  final String? description;
  final double prix;
  final String categorieId;
  final bool estActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<dynamic>? images;

  Plat({
    required this.id,
    required this.nom,
    this.description,
    required this.prix,
    required this.categorieId,
    required this.estActive,
    required this.createdAt,
    required this.updatedAt,
    this.images,
  });

  factory Plat.fromJson(Map<String, dynamic> json) {
    return Plat(
      id: json['id'] as String,
      nom: json['nom'] as String,
      description: json['description'] as String?,
      prix: (json['prix'] as num).toDouble(),
      categorieId: json['categorieId'] as String,
      estActive: json['estActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      images: json['images'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'prix': prix,
      'categorieId': categorieId,
      'estActive': estActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
