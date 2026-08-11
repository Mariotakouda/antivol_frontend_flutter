import 'package:flutter/material.dart';
import '../../core/storage/onboarding_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/logo_anime.dart';
import '../home/home_screen.dart';

/// Ecran affiché uniquement au tout premier lancement de l'app : une page
/// d'intro avec le logo animé, suivie de 3 slides explicatives (signalement,
/// matching IA, messagerie sécurisée), swipeables, avec pagination par
/// points et bouton "Passer" / "Commencer".
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _storage = OnboardingStorage();
  final _pageController = PageController();
  int _page = 0;

  static const _slides = [
    _OnboardingSlide(
      icon: Icons.campaign_outlined,
      title: 'Signalez un objet perdu ou trouvé',
      description:
          'Publiez rapidement une annonce avec photos et détails pour alerter la communauté.',
    ),
    _OnboardingSlide(
      icon: Icons.auto_awesome_outlined,
      title: 'Notre IA trouve les correspondances',
      description:
          "Grâce à notre algorithme intelligent, nous détectons automatiquement les objets qui pourraient vous appartenir.",
    ),
    _OnboardingSlide(
      icon: Icons.chat_bubble_outline,
      title: 'Discutez en toute sécurité et récupérez votre bien',
      description:
          'Échangez via notre messagerie sécurisée pour organiser la remise de l\'objet en toute confiance.',
    ),
  ];

  // +1 pour la page logo, insérée avant les slides de contenu (index 0).
  int get _totalPages => _slides.length + 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _terminer() async {
    await _storage.marquerOnboardingVu();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _suivant() {
    if (_page == _totalPages - 1) {
      _terminer();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _precedent() {
    if (_page == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final estDerniere = _page == _totalPages - 1;
    final estPremiere = _page == 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Bouton retour à gauche (masqué sur la page logo, rien avant),
            // bouton "Passer" à droite (masqué sur la dernière slide).
            Padding(
              padding: const EdgeInsets.all(AppSpacing.containerPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Opacity(
                    opacity: estPremiere ? 0 : 1,
                    child: IconButton(
                      onPressed: estPremiere ? null : _precedent,
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Précédent',
                    ),
                  ),
                  Opacity(
                    opacity: estDerniere ? 0 : 1,
                    child: TextButton(
                      onPressed: estDerniere ? null : _terminer,
                      child: const Text('Passer'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _totalPages,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) =>
                    index == 0 ? _buildLogoSlide() : _buildSlide(_slides[index - 1]),
              ),
            ),
            // Pagination + bouton d'action
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPadding,
                AppSpacing.stackMd,
                AppSpacing.containerPadding,
                AppSpacing.stackLg,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (index) {
                      final actif = index == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: actif ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: actif
                              ? AppColors.primary
                              : AppColors.outlineVariant,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _suivant,
                      child: Text(estDerniere ? 'Commencer' : 'Suivant'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Première page de l'onboarding : juste le logo animé (même widget que
  /// l'écran de démarrage), en guise d'accueil avant les slides explicatives.
  Widget _buildLogoSlide() {
    return const Center(
      child: LogoAnime(width: 260, height: 130),
    );
  }

  Widget _buildSlide(_OnboardingSlide slide) {
    final screenWidth = MediaQuery.of(context).size.width;
    final petitEcran = screenWidth < 380;

    final tailleCercle = petitEcran ? 150.0 : 220.0;
    final tailleIcone = petitEcran ? 64.0 : 96.0;
    final tailleTitre = petitEcran ? 16.0 : AppTextStyles.headlineMd.fontSize;
    final tailleDescription = petitEcran ? 13.0 : AppTextStyles.bodyLg.fontSize;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: petitEcran ? 8 : AppSpacing.containerPadding,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Container(
            width: tailleCercle,
            height: tailleCercle,
            margin: EdgeInsets.symmetric(
              vertical: petitEcran ? AppSpacing.stackMd : AppSpacing.stackLg,
            ),
            decoration: const BoxDecoration(
              color: AppColors.statusGreenBg,
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: tailleIcone, color: AppColors.primary),
          ),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMd.copyWith(fontSize: tailleTitre),
          ),
          SizedBox(height: petitEcran ? AppSpacing.stackSm : AppSpacing.stackMd),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLg.copyWith(
              fontSize: tailleDescription,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}