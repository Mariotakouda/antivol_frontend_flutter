import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/auth_guard.dart';
import '../core/utils/date_formatter.dart';
import '../models/publication_model.dart';
import '../providers/favori_provider.dart';

/// Carte représentant une publication dans une liste (fil d'actualité,
/// recherche, favoris). Image plein format en haut avec badge type et
/// bouton favori en overlay, informations en dessous.
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
    // PERDU en rouge doux (alerte), TROUVÉ en vert ivoirien (positif).
    final couleurType = estPerdu ? AppColors.error : AppColors.primary;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerPadding,
        vertical: AppSpacing.stackSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(context, couleurType, estPerdu),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    publication.titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelLg.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: AppColors.outline,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${publication.quartier}, ${publication.ville}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMd.copyWith(
                            fontSize: 12.5,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatter.relatif(publication.dateEvenement),
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                  if (publication.recompense != null && publication.recompense! > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.statusOrangeBg,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'Récompense : ${publication.recompense!.toStringAsFixed(0)} F',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, Color couleurType, bool estPerdu) {
    final url = publication.imagePrincipaleUrl;

    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 180,
          child: url != null
              ? CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.surfaceContainerLow),
                  errorWidget: (_, __, ___) => _buildIconePlaceholder(couleurType, estPerdu),
                )
              : _buildIconePlaceholder(couleurType, estPerdu),
        ),
        // Badge type en overlay (haut-gauche)
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: couleurType.withValues(alpha: 0.3)),
            ),
            child: Text(
              estPerdu ? 'PERDU' : 'TROUVÉ',
              style: AppTextStyles.labelSm.copyWith(
                color: couleurType,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        // Bouton favori en overlay (haut-droite)
        Positioned(
          top: 10,
          right: 10,
          child: _buildBoutonFavori(context),
        ),
      ],
    );
  }

  Widget _buildIconePlaceholder(Color couleurType, bool estPerdu) {
    return Container(
      color: couleurType.withValues(alpha: 0.08),
      child: Icon(
        estPerdu ? Icons.search : Icons.check_circle_outline,
        color: couleurType,
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
              color: Colors.white.withValues(alpha: 0.9),
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
}