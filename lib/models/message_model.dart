class MessageModel {
  final int id;
  final String? contenu;
  final String? image;
  final bool lu;
  final int userId;
  final String auteurNomComplet;
  final int conversationId;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    this.contenu,
    this.image,
    required this.lu,
    required this.userId,
    required this.auteurNomComplet,
    required this.conversationId,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return MessageModel(
      id: json['id'] as int,
      contenu: json['contenu'] as String?,
      image: json['image'] as String?,
      lu: json['lu'] as bool,
      userId: user?['id'] as int? ?? 0,
      auteurNomComplet: user != null ? '${user['prenom']} ${user['nom']}' : '',
      conversationId: json['conversation_id'] as int,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
