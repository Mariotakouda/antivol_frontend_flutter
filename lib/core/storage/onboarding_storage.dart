import 'package:shared_preferences/shared_preferences.dart';

/// Mémorise si l'utilisateur a déjà vu l'écran d'introduction, pour ne le
/// montrer qu'une seule fois (au tout premier lancement de l'app sur cet
/// appareil). Utilise SharedPreferences plutôt que le stockage sécurisé :
/// ce n'est pas une donnée sensible, juste une préférence d'affichage.
class OnboardingStorage {
  static const String _cleAVuOnboarding = 'a_vu_onboarding';

  Future<bool> aVuOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cleAVuOnboarding) ?? false;
  }

  Future<void> marquerOnboardingVu() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cleAVuOnboarding, true);
  }
}