import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/storage/onboarding_storage.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/logo_anime.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';

/// Fond légèrement crème plutôt que blanc pur, pour l'écran de démarrage.
const _splashBackground = Color(0xFFFBF9F4);

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
      backgroundColor: _splashBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LogoAnime(),
            const SizedBox(height: AppSpacing.stackLg),
            const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}