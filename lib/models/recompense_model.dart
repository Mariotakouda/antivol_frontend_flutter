import 'publication_model.dart';

class RecompenseModel {
  final int id;
  final int publicationId;
  final double montant;
  final String? description;
  final bool estPaye;
  final DateTime? datePaiement;
  final PublicationAuteur? beneficiaire;

  RecompenseModel({
    required this.id,
    required this.publicationId,
    required this.montant,
    this.description,
    required this.estPaye,
    this.datePaiement,
    this.beneficiaire,
  });

  factory RecompenseModel.fromJson(Map<String, dynamic> json) {
    return RecompenseModel(
      id: json['id'] as int,
      publicationId: json['publication_id'] as int,
      montant: double.parse(json['montant'].toString()),
      description: json['description'] as String?,
      estPaye: json['est_paye'] as bool? ?? false,
      datePaiement: json['date_paiement'] != null ? DateTime.parse(json['date_paiement']) : null,
      beneficiaire: json['beneficiaire'] != null && (json['beneficiaire'] as Map).isNotEmpty
          ? PublicationAuteur.fromJson(json['beneficiaire'])
          : null,
    );
  }
}