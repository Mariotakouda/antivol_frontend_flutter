import 'package:flutter/material.dart';

/// Logo YaKo avec une légère pulsation d'opacité en boucle, pour donner un
/// effet "vivant" — utilisé sur l'écran de démarrage et la première slide
/// de l'onboarding.
class LogoAnime extends StatefulWidget {
  final double width;
  final double height;

  const LogoAnime({super.key, this.width = 320, this.height = 160});

  @override
  State<LogoAnime> createState() => _LogoAnimeState();
}

class _LogoAnimeState extends State<LogoAnime> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacite;
  late final Animation<double> _echelle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    // Pulsation légère : entre 60% et 100% d'opacité, jamais totalement
    // invisible, pour un effet subtil plutôt qu'un vrai clignotement dur.
    _opacite = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    // Très léger effet de respiration en taille, pour renforcer l'effet
    // "vivant" sans que ce soit distrayant.
    _echelle = Tween<double>(begin: 0.97, end: 1.0).animate(
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
      child: ScaleTransition(
        scale: _echelle,
        child: Image.asset(
          'assets/images/logo1.png',
          width: widget.width,
          height: widget.height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}