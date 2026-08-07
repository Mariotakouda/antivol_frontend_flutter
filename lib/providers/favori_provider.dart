import 'package:flutter/foundation.dart';
import '../models/publication_model.dart';
import '../services/favori_service.dart';

class FavoriProvider extends ChangeNotifier {
  final FavoriService _service = FavoriService();

  List<PublicationModel> _favoris = [];
  final Set<int> _idsFavoris = {};
  bool _chargement = false;
  String? _erreur;

  List<PublicationModel> get favoris => _favoris;
  bool get chargement => _chargement;
  String? get erreur => _erreur;

  bool estFavori(int publicationId) => _idsFavoris.contains(publicationId);

  Future<void> charger() async {
    _chargement = true;
    _erreur = null;
    notifyListeners();

    try {
      _favoris = await _service.lister();
      _idsFavoris
        ..clear()
        ..addAll(_favoris.map((p) => p.id));
    } catch (e) {
      _erreur = 'Impossible de charger tes favoris.';
    } finally {
      _chargement = false;
      notifyListeners();
    }
  }

  /// Bascule l'état favori d'une publication. Met à jour l'état local
  /// immédiatement (optimistic update) puis appelle l'API.
  Future<void> basculer(PublicationModel publication) async {
    final etaitFavori = _idsFavoris.contains(publication.id);

    if (etaitFavori) {
      _idsFavoris.remove(publication.id);
      _favoris.removeWhere((p) => p.id == publication.id);
    } else {
      _idsFavoris.add(publication.id);
      _favoris.insert(0, publication);
    }
    notifyListeners();

    try {
      if (etaitFavori) {
        await _service.retirer(publication.id);
      } else {
        await _service.ajouter(publication.id);
      }
    } catch (_) {
      // En cas d'échec réseau, on annule le changement optimiste.
      if (etaitFavori) {
        _idsFavoris.add(publication.id);
        _favoris.insert(0, publication);
      } else {
        _idsFavoris.remove(publication.id);
        _favoris.removeWhere((p) => p.id == publication.id);
      }
      notifyListeners();
    }
  }
}