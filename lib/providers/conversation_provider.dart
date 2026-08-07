import 'package:flutter/foundation.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/conversation_service.dart';
import '../services/message_service.dart';

class ConversationProvider extends ChangeNotifier {
  final ConversationService _service = ConversationService();
  final MessageService _messageService = MessageService();

  List<ConversationModel> _conversations = [];
  final Map<int, List<MessageModel>> _messages = {};
  bool _chargement = false;
  bool _chargementConversations = false;
  bool _chargementMessages = false;
  bool _envoiEnCours = false;

  List<ConversationModel> get conversations => _conversations;
  bool get chargement => _chargement;
  bool get chargementConversations => _chargementConversations;
  bool get chargementMessages => _chargementMessages;
  bool get envoiEnCours => _envoiEnCours;

  Future<void> charger() async {
    return chargerConversations();
  }

  Future<void> chargerConversations() async {
    _chargement = true;
    _chargementConversations = true;
    notifyListeners();

    try {
      _conversations = await _service.lister();
    } catch (_) {
      // Silencieux : l'écran peut afficher une liste vide + retry.
    } finally {
      _chargement = false;
      _chargementConversations = false;
      notifyListeners();
    }
  }

  Future<ConversationModel?> demarrerConversation(int publicationId) async {
    try {
      final conversation = await _service.demarrer(publicationId);

      final existeDeja = _conversations.any((c) => c.id == conversation.id);
      if (!existeDeja) {
        _conversations.insert(0, conversation);
        notifyListeners();
      }

      return conversation;
    } catch (_) {
      return null;
    }
  }

  Future<void> chargerMessages(int conversationId) async {
    _chargementMessages = true;
    notifyListeners();

    try {
      final messages = await _messageService.lister(conversationId);
      _messages[conversationId] = messages;
    } catch (_) {
      // Silencieux : conserver les messages existants si l'appel échoue.
    } finally {
      _chargementMessages = false;
      notifyListeners();
    }
  }

  Future<bool> envoyerMessage({required int conversationId, required String contenu}) async {
    _envoiEnCours = true;
    notifyListeners();

    try {
      final nouveauMessage = await _messageService.envoyer(
        conversationId: conversationId,
        contenu: contenu,
      );

      final messages = _messages[conversationId];
      if (messages == null) {
        _messages[conversationId] = [nouveauMessage];
      } else {
        messages.add(nouveauMessage);
      }

      return true;
    } catch (_) {
      return false;
    } finally {
      _envoiEnCours = false;
      notifyListeners();
    }
  }

  List<MessageModel> messagesDe(int conversationId) {
    return List.unmodifiable(_messages[conversationId] ?? []);
  }
}
