import 'package:flutter/foundation.dart';
import '../models/categorie_model.dart';
import '../services/categorie_service.dart';

/// Etat partagé des catégories (utilisées pour les filtres du fil d'actualité
/// et le sélecteur de catégorie dans le formulaire de création de publication).
/// Chargées une seule fois puis mises en cache pour toute la session.
class CategorieProvider extends ChangeNotifier {
  final CategorieService _service = CategorieService();

  List<CategorieModel> _categories = [];
  bool _chargement = false;
  String? _erreur;
  bool _dejaChargees = false;

  List<CategorieModel> get categories => _categories;
  bool get chargement => _chargement;
  String? get erreur => _erreur;

  CategorieModel? parId(int id) {
    for (final categorie in _categories) {
      if (categorie.id == id) return categorie;
    }
    return null;
  }

  /// Charge les catégories si elles ne l'ont pas déjà été (idempotent).
  /// Utile à appeler depuis initState() de plusieurs écrans sans dupliquer
  /// les appels réseau.
  Future<void> chargerSiNecessaire() async {
    if (_dejaChargees || _chargement) return;
    await charger();
  }

  Future<void> charger() async {
    _chargement = true;
    _erreur = null;
    notifyListeners();

    try {
      _categories = await _service.lister();
      _dejaChargees = true;
    } catch (e) {
      _erreur = e.toString();
    } finally {
      _chargement = false;
      notifyListeners();
    }
  }
}