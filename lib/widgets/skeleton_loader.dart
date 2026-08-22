import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Bloc animé (effet de "respiration" d'opacité, léger et peu coûteux —
/// pas de shimmer en dégradé qui bougerait tout le temps) utilisé comme
/// brique de base pour les états de chargement.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = AppRadius.sm,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacite;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacite = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacite,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Silhouette d'une PublicationCard pendant le chargement du fil — donne
/// une impression immédiate de la structure à venir (image + titre +
/// localisation) plutôt qu'un spinner nu déconnecté du contenu réel.
class PublicationCardSkeleton extends StatelessWidget {
  const PublicationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerPadding,
        vertical: AppSpacing.stackSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(height: 180, radius: 0),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 160, height: 16, radius: AppRadius.sm),
                const SizedBox(height: 8),
                SkeletonBox(width: 120, height: 12, radius: AppRadius.sm),
                const SizedBox(height: 6),
                SkeletonBox(width: 80, height: 11, radius: AppRadius.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Liste de skeletons pour remplacer le CircularProgressIndicator nu lors
/// du premier chargement d'un fil de publications.
class PublicationFeedSkeleton extends StatelessWidget {
  final int count;

  const PublicationFeedSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: AppSpacing.stackSm),
      itemCount: count,
      itemBuilder: (_, __) => const PublicationCardSkeleton(),
    );
  }
}
