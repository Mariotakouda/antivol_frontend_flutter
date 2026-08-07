import 'message_model.dart';
import 'participant_model.dart';

class ConversationModel {
  final int id;
  final int? publicationId;
  final String? publicationTitre;
  final List<ParticipantModel> participants;
  final MessageModel? dernierMessage;
  final DateTime dateCreation;

  ConversationModel({
    required this.id,
    this.publicationId,
    this.publicationTitre,
    required this.participants,
    this.dernierMessage,
    required this.dateCreation,
  });

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
