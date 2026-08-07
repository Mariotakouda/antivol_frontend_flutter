import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/conversation_provider.dart';
import 'conversation_detail_screen.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversationProvider>().charger();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConversationProvider>();
    final monUserId = context.read<AuthProvider>().utilisateur?.id ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: provider.chargement
          ? const Center(child: CircularProgressIndicator())
          : provider.conversations.isEmpty
              ? const Center(child: Text('Aucune conversation pour le moment'))
              : RefreshIndicator(
                  onRefresh: provider.charger,
                  child: ListView.separated(
                    itemCount: provider.conversations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
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
                        title: Text(autre?.nomComplet ?? 'Conversation'),
                        subtitle: Text(
                          conversation.publicationTitre ?? (dernierMessage?.contenu ?? 'Aucun message'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ConversationDetailScreen(
                              conversationId: conversation.id,
                              titre: autre?.nomComplet ?? 'Conversation',
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
