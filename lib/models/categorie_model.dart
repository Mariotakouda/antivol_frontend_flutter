class CategorieModel {
  final int id;
  final String nom;
  final String icone;
  final String? description;
  final int? nombrePublications;

  CategorieModel({
    required this.id,
    required this.nom,
    required this.icone,
    this.description,
    this.nombrePublications,
  });

  factory CategorieModel.fromJson(Map<String, dynamic> json) {
    return CategorieModel(
      id: json['id'] as int,
      nom: json['nom'] as String,
      icone: json['icone'] as String,
      description: json['description'] as String?,
      nombrePublications: json['nombre_publications'] as int?,
    );
  }
}
