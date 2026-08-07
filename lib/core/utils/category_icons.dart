import 'package:flutter/material.dart';

/// Convertit le nom d'icône stocké côté API (`CategorieModel.icone`, ex:
/// "smartphone", "car", "motorcycle"...) en IconData Flutter. Complétez
/// cette map au fur et à mesure que de nouvelles catégories sont ajoutées
/// côté backend (voir CategorieSeeder.php pour la liste des valeurs).
IconData iconePourCategorie(String nomIcone) {
  switch (nomIcone.toLowerCase().trim()) {
    case 'smartphone':
    case 'devices':
    case 'electronique':
    case 'électronique':
      return Icons.smartphone_outlined;
    case 'file-text':
    case 'description':
    case 'papiers':
    case 'documents':
      return Icons.description_outlined;
    case 'key':
    case 'cles':
    case 'clés':
      return Icons.key_outlined;
    case 'wallet':
    case 'portefeuille':
      return Icons.account_balance_wallet_outlined;
    case 'briefcase':
    case 'work':
    case 'sacs':
    case 'sac':
      return Icons.work_outline;
    case 'car':
    case 'voiture':
      return Icons.directions_car_outlined;
    case 'motorcycle':
    case 'moto':
    case 'two-wheeler':
      return Icons.two_wheeler;
    case 'checkroom':
    case 'vetements':
    case 'vêtements':
      return Icons.checkroom_outlined;
    case 'paw-print':
    case 'pets':
    case 'animaux':
      return Icons.pets_outlined;
    case 'gem':
    case 'bijoux':
      return Icons.diamond_outlined;
    case 'help-circle':
    case 'autre':
      return Icons.help_outline;
    default:
      return Icons.category_outlined;
  }
}