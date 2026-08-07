class CommentaireModel {
  final int id;
  final String contenu;
  final int userId;
  final String auteurNomComplet;
  final String? auteurPhoto;
  final DateTime createdAt;

  CommentaireModel({
    required this.id,
    required this.contenu,
    required this.userId,
    required this.auteurNomComplet,
    this.auteurPhoto,
    required this.createdAt,
  });

  factory CommentaireModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return CommentaireModel(
      id: json['id'] as int,
      contenu: json['contenu'] as String,
      userId: user?['id'] as int? ?? 0,
      auteurNomComplet: user != null ? '${user['prenom']} ${user['nom']}' : '',
      auteurPhoto: user?['photo_profil'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
