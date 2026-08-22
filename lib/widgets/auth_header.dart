import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// En-tête coloré partagé par les écrans d'authentification (Login,
/// Register, mot de passe oublié...). Casse le pattern "carte blanche sur
/// fond blanc" en donnant un vrai bloc de couleur en haut, sur lequel le
/// formulaire vient ensuite "flotter" en léger débordement — c'est ce
/// chevauchement qui sert de signature visuelle aux écrans d'auth.
class AuthHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showLogo;
  final VoidCallback? onBack;
  // Si renseigné, affiche un TextButton (ex. "Ignorer") à la place de la
  // flèche retour — utile en milieu de parcours multi-étapes où "retour"
  // suggérerait à tort qu'on peut revenir à l'étape précédente.
  final String? backLabel;

  const AuthHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showLogo = true,
    this.onBack,
    this.backLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPadding,
        4,
        AppSpacing.containerPadding,
        40,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 40,
              child: onBack == null
                  ? null
                  : backLabel != null
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: onBack,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.onPrimary,
                            ),
                            child: Text(backLabel!),
                          ),
                        )
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: AppColors.onPrimary),
                              onPressed: onBack,
                            ),
                          ),
                        ),
            ),
            if (showLogo) ...[
              const SizedBox(height: 4),
              Container(
                width: 172,
                height: 62,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadows.medium,
                ),
                child: Image.asset('assets/images/logo_wordmark.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: AppSpacing.stackMd),
            ],
            Text(
              title,
              style: AppTextStyles.headlineMd.copyWith(color: AppColors.onPrimary),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onPrimary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Feuille blanche qui chevauche légèrement l'AuthHeader (coins arrondis en
/// haut, marge négative) — contient le formulaire de l'écran.
class AuthSheet extends StatelessWidget {
  final Widget child;

  const AuthSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerPadding,
          AppSpacing.stackLg,
          AppSpacing.containerPadding,
          AppSpacing.stackLg,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: child,
      ),
    );
  }
}
