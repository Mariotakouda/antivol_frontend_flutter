import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../core/errors/api_exception.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _service = ProfileService();

  UserModel? _utilisateur;
  bool _chargement = false;
  String? _erreur;

  UserModel? get utilisateur => _utilisateur;
  bool get chargement => _chargement;
  String? get erreur => _erreur;

  Future<void> charger() async {
    _chargement = true;
    notifyListeners();

    try {
      _utilisateur = await _service.voir();
    } catch (_) {
      _erreur = 'Impossible de charger le profil.';
    } finally {
      _chargement = false;
      notifyListeners();
    }
  }

  Future<bool> modifier({
    String? nom,
    String? prenom,
    String? email,
    String? ville,
    String? pays,
    String? adresse,
    XFile? photo,
  }) async {
    _chargement = true;
    _erreur = null;
    notifyListeners();

    try {
      _utilisateur = await _service.modifier(
        nom: nom,
        prenom: prenom,
        email: email,
        ville: ville,
        pays: pays,
        adresse: adresse,
        photo: photo,
      );
      _chargement = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _erreur = e.toString();
      _chargement = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changerMotDePasse({required String ancien, required String nouveau}) async {
    try {
      await _service.changerMotDePasse(ancienMotDePasse: ancien, nouveauMotDePasse: nouveau);
      return true;
    } on ApiException catch (e) {
      _erreur = e.toString();
      notifyListeners();
      return false;
    }
  }
}