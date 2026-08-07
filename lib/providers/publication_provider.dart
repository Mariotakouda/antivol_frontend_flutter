import 'package:flutter/foundation.dart';
import '../models/publication_model.dart';
import '../services/publication_service.dart';

/// Etat partagé du fil d'actualité des publications (écran d'accueil et
/// recherche). Gère la pagination et les filtres, et sert de source de
/// vérité pour que les mises à jour faites depuis l'écran de détail
/// (marquer retrouvée, modifier, supprimer) se répercutent immédiatement
/// dans la liste sans recharger tout le fil.
class PublicationProvider extends ChangeNotifier {
  final PublicationService _service = PublicationService();

  List<PublicationModel> _publications = [];
  bool _chargementInitial = false;
  bool _chargementPageSuivante = false;
  bool _aPlusDePages = true;
  String? _erreur;
  int _pageActuelle = 0;

  // Filtres courants du fil (persistés pour que "charger la page suivante"
  // et "rafraîchir" réutilisent les mêmes critères).
  String? _type;
  int? _categorieId;
  String? _ville;
  String? _recherche;

  List<PublicationModel> get publications => _publications;
  bool get chargementInitial => _chargementInitial;
  bool get chargementPageSuivante => _chargementPageSuivante;
  bool get aPlusDePages => _aPlusDePages;
  String? get erreur => _erreur;

  String? get typeFiltre => _type;
  int? get categorieIdFiltre => _categorieId;
  String? get villeFiltre => _ville;
  String? get rechercheFiltre => _recherche;

  /// (Re)charge la première page avec les filtres donnés. Si aucun filtre
  /// n'est passé, conserve les filtres actuellement appliqués (utile pour
  /// le pull-to-refresh).
  Future<void> charger({
    String? type,
    int? categorieId,
    String? ville,
    String? recherche,
    bool reinitialiserFiltres = false,
  }) async {
    if (reinitialiserFiltres) {
      _type = null;
      _categorieId = null;
      _ville = null;
      _recherche = null;
    }
    if (type != null) _type = type;
    if (categorieId != null) _categorieId = categorieId;
    if (ville != null) _ville = ville;
    if (recherche != null) _recherche = recherche;

    _chargementInitial = true;
    _erreur = null;
    notifyListeners();

    try {
      final resultat = await _service.lister(
        page: 1,
        type: _type,
        categorieId: _categorieId,
        ville: _ville,
        recherche: _recherche,
      );
      _publications = resultat.data;
      _pageActuelle = resultat.pageActuelle;
      _aPlusDePages = resultat.aPlusDePages;
    } catch (e) {
      _erreur = e.toString();
    } finally {
      _chargementInitial = false;
      notifyListeners();
    }
  }

  /// Applique un nouveau filtre de type (PERDU/TROUVE, ou null pour tout
  /// afficher) et recharge le fil depuis la première page.
  Future<void> filtrerParType(String? type) async {
    _type = type;
    await charger();
  }

  Future<void> filtrerParCategorie(int? categorieId) async {
    _categorieId = categorieId;
    await charger();
  }

  Future<void> rechercher(String? recherche) async {
    _recherche = recherche;
    await charger();
  }

  Future<void> rafraichir() => charger();

  Future<void> chargerPageSuivante() async {
    if (_chargementPageSuivante || !_aPlusDePages || _chargementInitial) return;

    _chargementPageSuivante = true;
    notifyListeners();

    try {
      final resultat = await _service.lister(
        page: _pageActuelle + 1,
        type: _type,
        categorieId: _categorieId,
        ville: _ville,
        recherche: _recherche,
      );
      _publications = [..._publications, ...resultat.data];
      _pageActuelle = resultat.pageActuelle;
      _aPlusDePages = resultat.aPlusDePages;
    } catch (_) {
      // Echec silencieux sur la pagination : l'utilisateur peut retenter
      // en scrollant à nouveau, pas besoin de bloquer tout l'écran.
    } finally {
      _chargementPageSuivante = false;
      notifyListeners();
    }
  }

  /// Insère une publication tout juste créée en tête de fil, sans requête
  /// réseau supplémentaire (appelé juste après un `creer()` réussi).
  void ajouterEnTete(PublicationModel publication) {
    _publications = [publication, ..._publications];
    notifyListeners();
  }

  /// Remplace une publication existante dans la liste (après modification
  /// ou changement de statut) si elle y figure déjà.
  void remplacer(PublicationModel publication) {
    final index = _publications.indexWhere((p) => p.id == publication.id);
    if (index == -1) return;
    final copie = [..._publications];
    copie[index] = publication;
    _publications = copie;
    notifyListeners();
  }

  void retirer(int publicationId) {
    _publications = _publications.where((p) => p.id != publicationId).toList();
    notifyListeners();
  }
}