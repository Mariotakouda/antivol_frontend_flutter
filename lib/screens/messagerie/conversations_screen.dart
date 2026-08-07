import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/conversation_provider.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversationProvider>().chargerConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConversationProvider>();
    final monUserId = context.read<AuthProvider>().utilisateur?.id ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: provider.chargementConversations
          ? const Center(child: CircularProgressIndicator())
          : provider.conversations.isEmpty
              ? const Center(child: Text('Aucune conversation pour le moment'))
              : RefreshIndicator(
                  onRefresh: () => provider.chargerConversations(),
                  child: ListView.separated(
                    itemCount: provider.conversations.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final conversation = provider.conversations[index];
                      final autre = conversation.autreParticipant(monUserId);
                      final dernierMessage = conversation.dernierMessage;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: autre?.photoProfil != null
                              ? NetworkImage(autre!.photoProfil!)
                              : null,
                          child: autre?.photoProfil == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(autre?.nomComplet ?? 'Utilisateur'),
                        subtitle: Text(
                          conversation.publicationTitre ??
                              dernierMessage?.contenu ??
                              'Nouvelle conversation',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              conversationId: conversation.id,
                              nomInterlocuteur: autre?.nomComplet ?? 'Utilisateur',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
