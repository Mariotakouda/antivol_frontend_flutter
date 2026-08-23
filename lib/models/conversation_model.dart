import 'message_model.dart';
import 'participant_model.dart';

class ConversationModel {
  final int id;
  final int? publicationId;
  final String? publicationTitre;
  final String? publicationType; // PERDU | TROUVE
  final String? publicationImage;
  final List<ParticipantModel> participants;
  final MessageModel? dernierMessage;
  final DateTime dateCreation;

  ConversationModel({
    required this.id,
    this.publicationId,
    this.publicationTitre,
    this.publicationType,
    this.publicationImage,
    required this.participants,
    this.dernierMessage,
    required this.dateCreation,
  });

  bool get publicationEstPerdue => publicationType?.toUpperCase() == 'PERDU';

  /// Renvoie l'autre participant (pas l'utilisateur courant), pratique pour l'affichage.
  ParticipantModel? autreParticipant(int monUserId) {
    try {
      return participants.firstWhere((p) => p.userId != monUserId);
    } catch (_) {
      return participants.isNotEmpty ? participants.first : null;
    }
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final publication = json['publication'] as Map<String, dynamic>?;
    return ConversationModel(
      id: json['id'] as int,
      publicationId: publication != null && publication.isNotEmpty ? publication['id'] as int? : null,
      publicationTitre: publication != null && publication.isNotEmpty ? publication['titre'] as String? : null,
      publicationType: publication != null && publication.isNotEmpty ? publication['type'] as String? : null,
      publicationImage: publication != null &&
              publication.isNotEmpty &&
              publication['images'] is List &&
              (publication['images'] as List).isNotEmpty
          ? (publication['images'] as List).first['url'] as String?
          : null,
      participants: json['participants'] != null
          ? (json['participants'] as List).map((p) => ParticipantModel.fromJson(p)).toList()
          : [],
      dernierMessage: json['dernier_message'] != null && (json['dernier_message'] as Map).isNotEmpty
          ? MessageModel.fromJson(json['dernier_message'])
          : null,
      dateCreation: DateTime.parse(json['date_creation']),
    );
  }
}
