import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/conversation_provider.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String nomInterlocuteur;

  const ChatScreen({super.key, required this.conversationId, required this.nomInterlocuteur});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _minuteurRafraichissement;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ConversationProvider>().chargerMessages(widget.conversationId);
      _defilerVersLeBas();
    });

    // Polling simple en attendant l'intégration Reverb/WebSocket (temps réel).
    // 5s est un compromis raisonnable en dev ; à retirer une fois Echo branché.
    _minuteurRafraichissement = Timer.periodic(const Duration(seconds: 5), (_) {
      context.read<ConversationProvider>().chargerMessages(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _minuteurRafraichissement?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _defilerVersLeBas() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _envoyer() async {
    final texte = _messageController.text.trim();
    if (texte.isEmpty) return;

    _messageController.clear();
    final succes = await context.read<ConversationProvider>().envoyerMessage(
          conversationId: widget.conversationId,
          contenu: texte,
        );

    if (succes) _defilerVersLeBas();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConversationProvider>();
    final monUserId = context.read<AuthProvider>().utilisateur?.id ?? 0;
    final messages = provider.messagesDe(widget.conversationId);

    return Scaffold(
      appBar: AppBar(title: Text(widget.nomInterlocuteur)),
      body: Column(
        children: [
          Expanded(
            child: provider.chargementMessages
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? const Center(child: Text('Dis bonjour 👋'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final estMoi = message.userId == monUserId;

                          return Align(
                            alignment: estMoi ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                              decoration: BoxDecoration(
                                color: estMoi
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                message.contenu ?? '[Image]',
                                style: TextStyle(color: estMoi ? Colors.white : Colors.black87),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Écris un message...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _envoyer(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: provider.envoiEnCours ? null : _envoyer,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
