import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/auth_guard.dart';
import '../core/utils/date_formatter.dart';
import '../models/publication_model.dart';
import '../providers/auth_provider.dart';
import '../providers/conversation_provider.dart';
import '../providers/favori_provider.dart';
import '../screens/messagerie/conversation_detail_screen.dart';

/// Carte de publication du fil d'actualité — fidèle à la maquette Stitch :
/// badge PERDU (corail) / TROUVÉ (vert) en haut à gauche avec icône, bouton
/// favori flouté en haut à droite, bordure verte distinctive pour les objets
/// trouvés, bouton d'action contextuel ("Contacter" pour un objet perdu,
/// "Réclamer" pour un objet trouvé) en bas de carte.
class PublicationCard extends StatelessWidget {
  final PublicationModel publication;
  final VoidCallback onTap;

  const PublicationCard({
    super.key,
    required this.publication,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final estPerdu = publication.estPerdu;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerPadding,
        vertical: AppSpacing.stackSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: estPerdu ? AppColors.outlineVariant : AppColors.primaryContainer,
          width: estPerdu ? 1 : 1.5,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(context, estPerdu),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.stackMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    publication.titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headlineMd,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${publication.quartier}, ${publication.ville}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  if (publication.recompense != null && publication.recompense! > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.rewardBg,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'Récompense : ${publication.recompense!.toStringAsFixed(0)} F',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.reward,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.stackMd),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: AppColors.outline),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          DateFormatter.relatif(publication.dateEvenement),
                          style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
                        ),
                      ),
                      _buildBoutonAction(context, estPerdu),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, bool estPerdu) {
    final url = publication.imagePrincipaleUrl;
    final couleurBadge = estPerdu ? AppColors.accent : AppColors.primaryContainer;

    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 192,
          child: url != null
              ? CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.surfaceContainerLow),
                  errorWidget: (_, __, ___) => _buildIconePlaceholder(estPerdu),
                )
              : _buildIconePlaceholder(estPerdu),
        ),
        // Badge type en overlay (haut-gauche) : icône + texte, fond plein.
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: couleurBadge,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  estPerdu ? Icons.error : Icons.check_circle,
                  size: 14,
                  color: estPerdu ? AppColors.onAccent : AppColors.onPrimaryContainer,
                ),
                const SizedBox(width: 4),
                Text(
                  estPerdu ? 'PERDU' : 'TROUVÉ',
                  style: AppTextStyles.labelSm.copyWith(
                    color: estPerdu ? AppColors.onAccent : AppColors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(top: 10, right: 10, child: _buildBoutonFavori(context)),
      ],
    );
  }

  Widget _buildIconePlaceholder(bool estPerdu) {
    final couleur = estPerdu ? AppColors.accent : AppColors.primary;
    return Container(
      color: couleur.withValues(alpha: 0.08),
      child: Icon(
        estPerdu ? Icons.search : Icons.check_circle_outline,
        color: couleur,
        size: 40,
      ),
    );
  }

  Widget _buildBoutonFavori(BuildContext context) {
    return Consumer<FavoriProvider>(
      builder: (context, favoriProvider, _) {
        final estFavori = favoriProvider.estFavori(publication.id);
        return GestureDetector(
          onTap: () async {
            if (await exigerConnexion(context, message: 'Connecte-toi pour ajouter aux favoris')) {
              favoriProvider.basculer(publication);
            }
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: Icon(
              estFavori ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: estFavori ? AppColors.error : AppColors.outline,
            ),
          ),
        );
      },
    );
  }

  /// "Contacter" (objet perdu, bouton plein) ou "Réclamer" (objet trouvé,
  /// bouton contour) — les deux démarrent une conversation avec l'auteur.
  Widget _buildBoutonAction(BuildContext context, bool estPerdu) {
    return SizedBox(
      height: 36,
      child: estPerdu
          ? ElevatedButton(
              onPressed: () => _contacter(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                textStyle: AppTextStyles.labelLg,
              ),
              child: const Text('Contacter'),
            )
          : OutlinedButton(
              onPressed: () => _contacter(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                textStyle: AppTextStyles.labelLg,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              child: const Text('Réclamer'),
            ),
    );
  }

  Future<void> _contacter(BuildContext context) async {
    if (!await exigerConnexion(context, message: 'Connecte-toi pour contacter cette personne')) {
      return;
    }
    if (!context.mounted) return;

    final conversation = await context.read<ConversationProvider>().demarrerConversation(publication.id);
    if (!context.mounted) return;

    if (conversation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de démarrer la conversation')),
      );
      return;
    }

    final monUserId = context.read<AuthProvider>().utilisateur?.id ?? 0;
    final autre = conversation.autreParticipant(monUserId);

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversationDetailScreen(
          conversationId: conversation.id,
          titre: autre?.nomComplet ?? 'Conversation',
          photoUrl: autre?.photoProfil,
          publicationTitre: publication.titre,
          publicationImage: publication.imagePrincipaleUrl,
          publicationEstPerdue: publication.estPerdu,
        ),
      ),
    );
  }
}
