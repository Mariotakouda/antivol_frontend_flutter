import 'publication_model.dart';

class CorrespondanceModel {
  final int id;
  final double score;
  final String statut; // PROPOSEE | VALIDEE | REFUSEE
  final PublicationModel publicationPerdue;
  final PublicationModel publicationTrouvee;
  final DateTime createdAt;

  CorrespondanceModel({
    required this.id,
    required this.score,
    required this.statut,
    required this.publicationPerdue,
    required this.publicationTrouvee,
    required this.createdAt,
  });

  bool get estEnAttente => statut == 'PROPOSEE';
  bool get estValidee => statut == 'VALIDEE';
  bool get estRefusee => statut == 'REFUSEE';

  /// Score arrondi en pourcentage entier pour l'affichage (0-100).
  int get scorePourcentage => score.round();

  factory CorrespondanceModel.fromJson(Map<String, dynamic> json) {
    return CorrespondanceModel(
      id: json['id'] as int,
      score: double.parse(json['score'].toString()),
      statut: json['statut'] as String,
      publicationPerdue: PublicationModel.fromJson(json['publication_perdue']),
      publicationTrouvee: PublicationModel.fromJson(json['publication_trouvee']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}