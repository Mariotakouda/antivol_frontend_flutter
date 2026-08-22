import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Avatar utilisateur : photo si disponible, sinon un rond teinté corail
/// avec les initiales (jamais l'icône "personne" grise générique).
/// Bordure verte quand [bordureAccentuee] est vraie (ex: message non lu),
/// grise sinon — cf. les cartes de conversation de la maquette Stitch.
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String nomComplet;
  final double taille;
  final bool bordureAccentuee;
  final bool afficherBordure;

  const UserAvatar({
    super.key,
    required this.nomComplet,
    this.photoUrl,
    this.taille = 48,
    this.bordureAccentuee = false,
    this.afficherBordure = true,
  });

  String get _initiales {
    final mots = nomComplet.trim().split(RegExp(r'\s+'));
    if (mots.isEmpty || mots.first.isEmpty) return '?';
    final premiere = mots.first[0];
    final derniere = mots.length > 1 && mots.last.isNotEmpty ? mots.last[0] : '';
    return '$premiere$derniere'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bordure = !afficherBordure
        ? null
        : Border.all(
            color: bordureAccentuee ? AppColors.primary : AppColors.outlineVariant,
            width: 2,
          );

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return Container(
        width: taille,
        height: taille,
        decoration: BoxDecoration(shape: BoxShape.circle, border: bordure),
        padding: const EdgeInsets.all(1),
        child: ClipOval(
          child: Image.network(photoUrl!, fit: BoxFit.cover),
        ),
      );
    }

    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        color: AppColors.accentContainer,
        shape: BoxShape.circle,
        border: bordure,
      ),
      alignment: Alignment.center,
      child: Text(
        _initiales,
        style: AppTextStyles.headlineMd.copyWith(
          color: AppColors.onAccentContainer,
          fontSize: taille * 0.36,
        ),
      ),
    );
  }
}
