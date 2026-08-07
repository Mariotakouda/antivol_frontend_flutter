import 'package:flutter/material.dart';
import '../../core/storage/onboarding_storage.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';

/// Ecran affiché uniquement au tout premier lancement de l'app : 3 slides
/// explicatives (signalement, matching IA, messagerie sécurisée),
/// swipeables, avec pagination par points et bouton "Passer" / "Commencer".
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
    if (_page == _slides.length - 1) {
      _terminer();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final estDerniere = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Bouton "Passer" en haut à droite (masqué sur la dernière slide)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.containerPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) => _buildSlide(_slides[index]),
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
                    children: List.generate(_slides.length, (index) {
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

  Widget _buildSlide(_OnboardingSlide slide) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth < 380 ? 8 : AppSpacing.containerPadding,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Container(
            width: 220,
            height: 220,
            margin: const EdgeInsets.only(bottom: AppSpacing.stackLg),
            decoration: BoxDecoration(
              color: AppColors.statusGreenBg,
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 96, color: AppColors.primary),
          ),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMd.copyWith(
              fontSize: screenWidth < 380
                  ? 18
                  : AppTextStyles.headlineMd.fontSize,
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                slide.description,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLg.copyWith(
                  fontSize: screenWidth < 380
                      ? 14
                      : AppTextStyles.bodyLg.fontSize,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
