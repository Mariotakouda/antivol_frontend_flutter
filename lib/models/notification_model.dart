class NotificationModel {
  final int id;
  final String titre;
  final String contenu;
  final String type;
  final String? lien;
  final String? icone;
  final bool lu;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.titre,
    required this.contenu,
    required this.type,
    this.lien,
    this.icone,
    required this.lu,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      titre: json['titre'] as String,
      contenu: json['contenu'] as String,
      type: json['type'] as String,
      lien: json['lien'] as String?,
      icone: json['icone'] as String?,
      lu: json['lu'] as bool,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
