import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/conversation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/conversation_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/user_avatar.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Messages')),
      body: provider.chargement && provider.conversations.isEmpty
          ? _buildSquelette()
          : provider.conversations.isEmpty
              ? const EmptyStateWidget(
                  icone: Icons.chat_bubble_outline,
                  titre: 'Aucune conversation',
                  message: 'Quand tu discuteras avec quelqu\'un à propos '
                      'd\'un objet perdu ou trouvé, ça apparaîtra ici.',
                )
              : RefreshIndicator(
                  onRefresh: provider.charger,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.containerPadding,
                      vertical: AppSpacing.stackMd,
                    ),
                    itemCount: provider.conversations.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.stackSm),
                        child: _CarteConversation(
                          conversation: provider.conversations[index],
                          monUserId: monUserId,
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildSquelette() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerPadding,
        vertical: AppSpacing.stackMd,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.stackSm),
        child: _SquelleteCarteConversation(),
      ),
    );
  }
}

/// Carte de conversation : vignette de l'objet concerné, avatar, nom, heure,
/// aperçu du dernier message. Fond légèrement teinté + texte en gras tant
/// que le dernier message n'est pas lu (pas d'ombre — la hiérarchie se fait
/// par variation de fond, cf. section "Elevation" du design system).
/// Glisser vers la gauche pour supprimer.
class _CarteConversation extends StatelessWidget {
  final ConversationModel conversation;
  final int monUserId;

  const _CarteConversation({required this.conversation, required this.monUserId});

  @override
  Widget build(BuildContext context) {
    final autre = conversation.autreParticipant(monUserId);
    final dernierMessage = conversation.dernierMessage;
    final nonLu = dernierMessage != null &&
        dernierMessage.userId != monUserId &&
        !dernierMessage.lu;

    String apercu;
    if (dernierMessage == null) {
      apercu = 'Aucun message pour le moment';
    } else if (dernierMessage.contenu != null && dernierMessage.contenu!.isNotEmpty) {
      apercu = dernierMessage.contenu!;
    } else if (dernierMessage.image != null) {
      apercu = '📷 Photo';
    } else {
      apercu = '...';
    }

    return Dismissible(
      key: ValueKey('conversation-${conversation.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmerSuppression(context),
      onDismissed: (_) => _supprimer(context),
      child: Material(
        color: nonLu ? AppColors.surfaceContainerLow : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ConversationDetailScreen(
                conversationId: conversation.id,
                titre: autre?.nomComplet ?? 'Conversation',
                photoUrl: autre?.photoProfil,
                publicationTitre: conversation.publicationTitre,
                publicationImage: conversation.publicationImage,
                publicationEstPerdue: conversation.publicationEstPerdue,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.stackMd),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (conversation.publicationImage != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Image.network(
                      conversation.publicationImage!,
                      width: 48,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 48,
                        height: 64,
                        color: AppColors.surfaceContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.stackMd),
                ],
                UserAvatar(
                  nomComplet: autre?.nomComplet ?? '?',
                  photoUrl: autre?.photoProfil,
                  bordureAccentuee: nonLu,
                ),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              autre?.nomComplet ?? 'Conversation',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.headlineMd,
                            ),
                          ),
                          if (dernierMessage != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              DateFormatter.relatif(dernierMessage.createdAt),
                              style: AppTextStyles.labelSm.copyWith(
                                color: nonLu ? AppColors.primary : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        apercu,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: nonLu ? AppColors.onSurface : AppColors.onSurfaceVariant,
                          fontWeight: nonLu ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (nonLu) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmerSuppression(BuildContext context) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('Supprimer la conversation ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    return confirme ?? false;
  }

  Future<void> _supprimer(BuildContext context) async {
    final provider = context.read<ConversationProvider>();
    final succes = await provider.supprimerConversation(conversation.id);
    if (!succes && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de la suppression, réessaie.')),
      );
    }
  }
}

class _SquelleteCarteConversation extends StatelessWidget {
  const _SquelleteCarteConversation();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 48, height: 64, radius: AppRadius.md),
          const SizedBox(width: AppSpacing.stackMd),
          const SkeletonBox(width: 48, height: 48, radius: 24),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 120, height: 16, radius: AppRadius.sm),
                const SizedBox(height: 8),
                SkeletonBox(width: 180, height: 14, radius: AppRadius.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
