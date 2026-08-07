import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../theme/app_theme.dart';

/// A appeler avant toute action qui nécessite un compte (favori, contacter,
/// commenter, publier, signaler...). Si l'utilisateur est déjà connecté,
/// ne fait rien et retourne true immédiatement. Sinon, affiche une feuille
/// invitant à se connecter/s'inscrire, et retourne true seulement si la
/// personne s'est effectivement connectée derrière (pour que l'appelant
/// puisse enchaîner l'action d'origine).
Future<bool> exigerConnexion(BuildContext context, {String? message}) async {
  final estConnecte = context.read<AuthProvider>().estConnecte;
  if (estConnecte) return true;

  final resultat = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.containerPadding,
        AppSpacing.stackLg,
        AppSpacing.containerPadding,
        AppSpacing.stackLg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.only(bottom: AppSpacing.gutter),
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.statusGreenBg, shape: BoxShape.circle),
            child: const Icon(Icons.lock_outline, size: 28, color: AppColors.primary),
          ),
          Text(
            message ?? 'Connecte-toi pour continuer',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSm,
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            "La consultation des annonces reste libre, mais cette action nécessite un compte.",
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          ElevatedButton(
            onPressed: () async {
              final connecte = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
              if (context.mounted) Navigator.of(context).pop(connecte ?? false);
            },
            child: const Text('Se connecter / créer un compte'),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Plus tard'),
          ),
        ],
      ),
    ),
  );

  // Après un retour de LoginScreen (avec succès), l'état AuthProvider est à
  // jour : on revérifie plutôt que de faire confiance au seul résultat du pop.
  return resultat == true && context.mounted && context.read<AuthProvider>().estConnecte;
}