import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/auth_guard.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/register_screen.dart';

/// Affiche une page protégée par connexion.
///
/// Si l'utilisateur est connecté, le contenu est rendu via [builder].
/// Sinon, un écran invitant à se connecter est affiché.
class OngletProtege extends StatelessWidget {
  final String message;
  final IconData icone;
  final WidgetBuilder builder;

  const OngletProtege({
    super.key,
    required this.message,
    required this.icone,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final estConnecte = context.watch<AuthProvider>().estConnecte;

    if (estConnecte) {
      return builder(context);
    }

    return Container(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(color: AppColors.statusGreenBg, shape: BoxShape.circle),
                child: Icon(icone, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineSm,
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                'Cette fonctionnalité nécessite un compte. Connecte-toi pour accéder à ton espace personnel.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await exigerConnexion(context, message: message);
                      },
                      child: const Text('Connexion'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.stackSm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                      child: const Text('Inscription'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}