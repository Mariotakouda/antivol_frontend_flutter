import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/paginated_response.dart';
import '../core/errors/api_exception.dart';
import '../models/publication_model.dart';
import '../models/signalement_model.dart';
import '../models/user_model.dart';
import '../models/verification_model.dart';

class AdminStats {
  final int totalUtilisateurs;
  final int utilisateursActifs;
  final int utilisateursSuspendus;
  final int totalPublications;
  final int publicationsPerdues;
  final int publicationsTrouvees;
  final int publicationsRetrouvees;
  final int correspondancesProposees;
  final int correspondancesValidees;
  final int signalementsEnAttente;

  AdminStats({
    required this.totalUtilisateurs,
    required this.utilisateursActifs,
    required this.utilisateursSuspendus,
    required this.totalPublications,
    required this.publicationsPerdues,
    required this.publicationsTrouvees,
    required this.publicationsRetrouvees,
    required this.correspondancesProposees,
    required this.correspondancesValidees,
    required this.signalementsEnAttente,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    final utilisateurs = json['utilisateurs'] as Map<String, dynamic>;
    final publications = json['publications'] as Map<String, dynamic>;
    final correspondances = json['correspondances'] as Map<String, dynamic>;

    return AdminStats(
      totalUtilisateurs: utilisateurs['total'] as int,
      utilisateursActifs: utilisateurs['actifs'] as int,
      utilisateursSuspendus: utilisateurs['suspendus'] as int,
      totalPublications: publications['total'] as int,
      publicationsPerdues: publications['perdues'] as int,
      publicationsTrouvees: publications['trouvees'] as int,
      publicationsRetrouvees: publications['retrouvees'] as int,
      correspondancesProposees: correspondances['proposees'] as int,
      correspondancesValidees: correspondances['validees'] as int,
      signalementsEnAttente: json['signalements_en_attente'] as int,
    );
  }
}

class AdminService {
  final Dio _dio = ApiClient.instance.dio;

  Future<AdminStats> statistiques() async {
    try {
      final response = await _dio.get('/admin/stats');
      return AdminStats.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  // --- Utilisateurs ---
  Future<PaginatedResponse<UserModel>> listerUtilisateurs({int page = 1, String? statut}) async {
    try {
      final response = await _dio.get('/admin/users', queryParameters: {
        'page': page,
        if (statut != null) 'statut': statut,
      });
      return PaginatedResponse.fromJson(response.data, (json) => UserModel.fromJson(json));
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> suspendreUtilisateur(int userId) async {
    try {
      await _dio.patch('/admin/users/$userId/suspendre');
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> bloquerUtilisateur(int userId) async {
    try {
      await _dio.patch('/admin/users/$userId/bloquer');
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> reactiverUtilisateur(int userId) async {
    try {
      await _dio.patch('/admin/users/$userId/reactiver');
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  // --- Publications ---
  Future<PaginatedResponse<PublicationModel>> listerPublications({int page = 1}) async {
    try {
      final response = await _dio.get('/admin/publications', queryParameters: {'page': page});
      return PaginatedResponse.fromJson(response.data, (json) => PublicationModel.fromJson(json));
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> masquerPublication(int id) async {
    try {
      await _dio.patch('/admin/publications/$id/masquer');
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> republierPublication(int id) async {
    try {
      await _dio.patch('/admin/publications/$id/republier');
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  // --- Signalements ---
  Future<PaginatedResponse<SignalementModel>> listerSignalements({int page = 1}) async {
    try {
      final response = await _dio.get('/admin/signalements', queryParameters: {'page': page});
      return PaginatedResponse.fromJson(response.data, (json) => SignalementModel.fromJson(json));
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> validerSignalement(int id) async {
    try {
      await _dio.patch('/admin/signalements/$id/valider');
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> refuserSignalement(int id) async {
    try {
      await _dio.patch('/admin/signalements/$id/refuser');
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  // --- Vérifications ---
  Future<PaginatedResponse<VerificationModel>> listerVerifications({int page = 1}) async {
    try {
      final response = await _dio.get('/admin/verifications', queryParameters: {'page': page});
      return PaginatedResponse.fromJson(response.data, (json) => VerificationModel.fromJson(json));
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> validerVerification(int id) async {
    try {
      await _dio.patch('/admin/verifications/$id/valider');
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> refuserVerification(int id) async {
    try {
      await _dio.patch('/admin/verifications/$id/refuser');
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  // --- Comptes Police ---
  Future<PaginatedResponse<UserModel>> listerComptesPolice({int page = 1}) async {
    try {
      final response = await _dio.get('/admin/comptes-police', queryParameters: {'page': page});
      return PaginatedResponse.fromJson(response.data, (json) => UserModel.fromJson(json));
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<UserModel> creerCompteApolice({
    required String nom,
    required String prenom,
    required String telephone,
    required String matricule,
    required String posteRattachement,
    required String password,
    String? ville,
    String? pays,
  }) async {
    try {
      final response = await _dio.post('/admin/comptes-police', data: {
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'matricule': matricule,
        'poste_rattachement': posteRattachement,
        'password': password,
        if (ville != null && ville.isNotEmpty) 'ville': ville,
        if (pays != null && pays.isNotEmpty) 'pays': pays,
      });
      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> revoquerCompteApolice(int userId) async {
    try {
      await _dio.patch('/admin/comptes-police/$userId/revoquer');
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }
}