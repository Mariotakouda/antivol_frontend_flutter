import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Etat vide générique réutilisé sur les écrans à liste (fil d'actualité,
/// favoris, notifications, résultats de recherche...).
class EmptyStateWidget extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String? message;
  final String? libelleAction;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icone,
    required this.titre,
    this.message,
    this.libelleAction,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.statusGreenBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Text(
              titre,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSm,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
            if (libelleAction != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.stackLg),
              OutlinedButton(onPressed: onAction, child: Text(libelleAction!)),
            ],
          ],
        ),
      ),
    );
  }
}