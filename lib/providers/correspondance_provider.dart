import 'package:flutter/foundation.dart';
import '../core/errors/api_exception.dart';
import '../models/correspondance_model.dart';
import '../services/correspondance_service.dart';

class CorrespondanceProvider extends ChangeNotifier {
  final CorrespondanceService _service = CorrespondanceService();

  List<CorrespondanceModel> _correspondances = [];
  bool _chargement = false;
  String? _erreur;

  List<CorrespondanceModel> get correspondances => _correspondances;
  bool get chargement => _chargement;
  String? get erreur => _erreur;

  /// Nombre de correspondances encore en attente de décision — utile pour un badge.
  int get nombreEnAttente => _correspondances.where((c) => c.estEnAttente).length;

  Future<void> charger() async {
    _chargement = true;
    _erreur = null;
    notifyListeners();

    try {
      final resultat = await _service.lister();
      _correspondances = resultat.data;
    } on ApiException catch (e) {
      _erreur = e.toString();
    } catch (_) {
      _erreur = 'Impossible de charger les correspondances.';
    } finally {
      _chargement = false;
      notifyListeners();
    }
  }

  Future<bool> valider(int correspondanceId) async {
    try {
      final maj = await _service.valider(correspondanceId);
      _remplacerDansLaListe(maj);
      return true;
    } on ApiException catch (e) {
      _erreur = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> refuser(int correspondanceId) async {
    try {
      final maj = await _service.refuser(correspondanceId);
      _remplacerDansLaListe(maj);
      return true;
    } on ApiException catch (e) {
      _erreur = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _remplacerDansLaListe(CorrespondanceModel maj) {
    final index = _correspondances.indexWhere((c) => c.id == maj.id);
    if (index != -1) {
      _correspondances[index] = maj;
      notifyListeners();
    }
  }
}
