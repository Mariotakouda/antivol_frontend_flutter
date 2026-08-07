import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/message_service.dart';

class ConversationDetailScreen extends StatefulWidget {
  final int conversationId;
  final String titre;

  const ConversationDetailScreen({super.key, required this.conversationId, required this.titre});

  @override
  State<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  final _service = MessageService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<MessageModel> _messages = [];
  bool _chargement = true;
  bool _envoiEnCours = false;
  Timer? _timerActualisation;

  @override
  void initState() {
    super.initState();
    _charger();

    // Polling simple toutes les 5 secondes tant que l'écran est ouvert.
    // Sera remplacé par du vrai temps réel (Reverb + Laravel Echo) plus tard.
    _timerActualisation = Timer.periodic(const Duration(seconds: 5), (_) => _charger(silencieux: true));
  }

  @override
  void dispose() {
    _timerActualisation?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _charger({bool silencieux = false}) async {
    if (!silencieux) setState(() => _chargement = true);

    try {
      final messages = await _service.lister(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  Future<void> _envoyer() async {
    final texte = _messageController.text.trim();
    if (texte.isEmpty) return;

    setState(() => _envoiEnCours = true);
    _messageController.clear();

    try {
      final message = await _service.envoyer(conversationId: widget.conversationId, contenu: texte);
      if (!mounted) return;
      setState(() {
        _messages.add(message);
        _envoiEnCours = false;
      });
      _scrollVersLeBas();
    } catch (_) {
      if (!mounted) return;
      setState(() => _envoiEnCours = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Échec de l'envoi du message")),
      );
    }
  }

  void _scrollVersLeBas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final monUserId = context.read<AuthProvider>().utilisateur?.id ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(widget.titre)),
      body: Column(
        children: [
          Expanded(
            child: _chargement
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('Aucun message. Dis bonjour !'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final estMoi = message.userId == monUserId;
                          return _BulleMessage(message: message, estMoi: estMoi);
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
                    onPressed: _envoiEnCours ? null : _envoyer,
                    icon: _envoiEnCours
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send),
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

class _BulleMessage extends StatelessWidget {
  final MessageModel message;
  final bool estMoi;

  const _BulleMessage({required this.message, required this.estMoi});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: estMoi ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: estMoi ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(message.image!, width: 180),
              ),
            if (message.contenu != null)
              Text(
                message.contenu!,
                style: TextStyle(color: estMoi ? Colors.white : Colors.black87),
              ),
          ],
        ),
      ),
    );
  }
}
