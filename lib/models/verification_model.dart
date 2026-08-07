class VerificationModel {
  final int id;
  final String type; // TELEPHONE | EMAIL | IDENTITE
  final String? document;
  final String statut; // EN_ATTENTE | VALIDE | REFUSE
  final DateTime? dateValidation;

  VerificationModel({
    required this.id,
    required this.type,
    this.document,
    required this.statut,
    this.dateValidation,
  });

  factory VerificationModel.fromJson(Map<String, dynamic> json) {
    return VerificationModel(
      id: json['id'] as int,
      type: json['type'] as String,
      document: json['document'] as String?,
      statut: json['statut'] as String,
      dateValidation: json['date_validation'] != null ? DateTime.parse(json['date_validation']) : null,
    );
  }
}
