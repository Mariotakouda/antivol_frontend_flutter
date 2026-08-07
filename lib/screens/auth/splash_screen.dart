import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/storage/onboarding_storage.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';

/// Premier écran affiché au lancement de l'app : vérifie s'il existe déjà
/// un token valide en stockage sécurisé avant de router vers Home, et
/// affiche l'onboarding une seule fois au tout premier lancement.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _onboardingStorage = OnboardingStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verifierSession());
  }

  Future<void> _verifierSession() async {
    final authProvider = context.read<AuthProvider>();
    final aVuOnboarding = await _onboardingStorage.aVuOnboarding();
    await authProvider.verifierSessionExistante();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => aVuOnboarding ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Cercles décoratifs dans les coins, à moitié hors écran — opacité
          // réduite pour rester en arrière-plan et ne pas concurrencer le logo.
          Positioned(top: -50, left: -60, child: _decorCircle(140, AppColors.primary)),
          Positioned(top: -70, right: -60, child: _decorCircle(180, AppColors.accent)),
          Positioned(bottom: -80, left: -70, child: _decorCircle(200, AppColors.primary)),
          Positioned(bottom: -60, right: -70, child: _decorCircle(150, AppColors.accent)),

          // Logo centré + accroche + indicateur de chargement en dessous.
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _YaKoWordmark(),
                const SizedBox(height: AppSpacing.stackSm),
                Text(
                  'Retrouvez ce qui compte',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg * 1.5),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.10),
      ),
    );
  }
}

/// Logotype "YaKo" bicolore avec relief léger, utilisé sur l'écran de
/// démarrage. En-tête de l'accueil : voir home_screen.dart pour la version
/// image.
class _YaKoWordmark extends StatelessWidget {
  const _YaKoWordmark();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logoanti.png',
      width: 320,   // ajuste la taille
      height: 160,   // ajuste la taille
      fit: BoxFit.contain,
    );
  }
}