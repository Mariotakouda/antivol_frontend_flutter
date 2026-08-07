import 'package:flutter/foundation.dart';
import '../core/errors/api_exception.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum StatutAuth { inconnu, nonConnecte, connecte }

/// Source de vérité unique pour l'état d'authentification dans toute l'app.
/// Écouté via Consumer<AuthProvider> ou context.watch<AuthProvider>().
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  StatutAuth _statut = StatutAuth.inconnu;
  UserModel? _utilisateur;
  bool _chargement = false;
  String? _erreur;

  StatutAuth get statut => _statut;
  UserModel? get utilisateur => _utilisateur;
  bool get chargement => _chargement;
  String? get erreur => _erreur;
  bool get estConnecte => _statut == StatutAuth.connecte;

  /// A appeler au démarrage de l'app (splash screen) pour savoir si un token
  /// valide est déjà stocké localement.
  Future<void> verifierSessionExistante() async {
    final token = await SecureStorageService.instance.lireToken();

    if (token == null) {
      _statut = StatutAuth.nonConnecte;
      notifyListeners();
      return;
    }

    try {
      _utilisateur = await _authService.profilActuel();
      _statut = StatutAuth.connecte;
    } catch (_) {
      await SecureStorageService.instance.effacerToken();
      _statut = StatutAuth.nonConnecte;
    }
    notifyListeners();
  }

  Future<bool> inscrire({
    required String nom,
    required String prenom,
    required String telephone,
    String? email,
    required String password,
    required String ville,
    required String pays,
  }) async {
    return _executerAvecChargement(() async {
      final resultat = await _authService.inscrire(
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        email: email,
        password: password,
        ville: ville,
        pays: pays,
      );
      _utilisateur = resultat.user;
      _statut = StatutAuth.connecte;
    });
  }

  Future<bool> connecter({String? telephone, String? email, required String password}) async {
    return _executerAvecChargement(() async {
      final resultat = await _authService.connecter(
        telephone: telephone,
        email: email,
        password: password,
      );
      _utilisateur = resultat.user;
      _statut = StatutAuth.connecte;
    });
  }

  Future<bool> verifierOtp({required String telephone, required String code}) async {
    return _executerAvecChargement(() async {
      await _authService.verifierOtp(telephone: telephone, code: code);
    });
  }

  Future<void> renvoyerOtp(String telephone) async {
    try {
      await _authService.renvoyerOtp(telephone);
    } catch (_) {
      // Erreur silencieuse : l'UI peut proposer un nouveau essai après un délai.
    }
  }

  Future<bool> demanderReinitialisationMotDePasse(String telephone) async {
    return _executerAvecChargement(() async {
      await _authService.demanderReinitialisationMotDePasse(telephone);
    });
  }

  Future<bool> reinitialiserMotDePasse({
    required String telephone,
    required String code,
    required String password,
  }) async {
    return _executerAvecChargement(() async {
      final resultat = await _authService.reinitialiserMotDePasse(
        telephone: telephone,
        code: code,
        password: password,
      );
      _utilisateur = resultat.user;
      _statut = StatutAuth.connecte;
    });
  }

  Future<void> deconnecter() async {
    await _authService.deconnecter();
    _utilisateur = null;
    _statut = StatutAuth.nonConnecte;
    notifyListeners();
  }

  /// A appeler après une modification réussie du profil (ProfileProvider.modifier)
  /// pour que le reste de l'app (AppBar, écran détail, etc.) reflète les nouvelles infos.
  void mettreAJourUtilisateur(UserModel utilisateur) {
    _utilisateur = utilisateur;
    notifyListeners();
  }

  /// Factorise la gestion chargement/erreur autour d'un appel async.
  /// Retourne true en cas de succès, false en cas d'échec (avec `erreur` renseigné).
  Future<bool> _executerAvecChargement(Future<void> Function() action) async {
    _chargement = true;
    _erreur = null;
    notifyListeners();

    try {
      await action();
      _chargement = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _erreur = e.toString();
      _chargement = false;
      notifyListeners();
      return false;
    } catch (e) {
      _erreur = 'Une erreur inattendue est survenue.';
      _chargement = false;
      notifyListeners();
      return false;
    }
  }
}