import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool chargement;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.chargement = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      // Pas de `style` explicite ici : le bouton hérite du style pill-shape
      // orange ivoirien défini dans AppTheme.light (elevatedButtonTheme).
      child: ElevatedButton(
        onPressed: chargement ? null : onPressed,
        child: chargement
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.onAccent,
                ),
              )
            : Text(label),
      ),
    );
  }
}