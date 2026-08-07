class SignalementModel {
  final int id;
  final String commentaire;
  final String? photo;
  final String type;
  final String statut;
  final String adresse;
  final int publicationId;
  final int userId;
  final String? auteurNomComplet;
  final DateTime dateSignalement;

  SignalementModel({
    required this.id,
    required this.commentaire,
    this.photo,
    required this.type,
    required this.statut,
    required this.adresse,
    required this.publicationId,
    required this.userId,
    this.auteurNomComplet,
    required this.dateSignalement,
  });

  factory SignalementModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return SignalementModel(
      id: json['id'] as int,
      commentaire: json['commentaire'] as String,
      photo: json['photo'] as String?,
      type: json['type'] as String,
      statut: json['statut'] as String,
      adresse: json['adresse'] as String,
      publicationId: json['publication_id'] as int,
      userId: user?['id'] as int? ?? 0,
      auteurNomComplet: user != null ? '${user['prenom']} ${user['nom']}' : null,
      dateSignalement: DateTime.parse(json['date_signalement']),
    );
  }
}
