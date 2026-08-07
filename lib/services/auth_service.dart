import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/errors/api_exception.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

/// Couche d'accès réseau pure : ne connaît rien de l'UI ni du state management.
/// AuthProvider s'appuie dessus.
class AuthService {
  final Dio _dio = ApiClient.instance.dio;

  Future<({UserModel user, String token})> inscrire({
    required String nom,
    required String prenom,
    required String telephone,
    String? email,
    required String password,
    required String ville,
    required String pays,
  }) async {
    try {
      final response = await _dio.post(ApiEndpoints.register, data: {
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        if (email != null && email.isNotEmpty) 'email': email,
        'password': password,
        'password_confirmation': password,
        'ville': ville,
        'pays': pays,
      });

      final user = UserModel.fromJson(response.data['user']);
      final token = response.data['token'] as String;

      await SecureStorageService.instance.sauvegarderToken(token);

      return (user: user, token: token);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<({UserModel user, String token})> connecter({
    String? telephone,
    String? email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(ApiEndpoints.login, data: {
        if (telephone != null && telephone.isNotEmpty) 'telephone': telephone,
        if (email != null && email.isNotEmpty) 'email': email,
        'password': password,
      });

      final user = UserModel.fromJson(response.data['user']);
      final token = response.data['token'] as String;

      await SecureStorageService.instance.sauvegarderToken(token);

      return (user: user, token: token);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> renvoyerOtp(String telephone) async {
    try {
      await _dio.post(ApiEndpoints.otpRenvoyer, data: {'telephone': telephone});
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> verifierOtp({required String telephone, required String code}) async {
    try {
      await _dio.post(ApiEndpoints.otpVerifier, data: {
        'telephone': telephone,
        'code': code,
      });
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> demanderReinitialisationMotDePasse(String telephone) async {
    try {
      await _dio.post(ApiEndpoints.motDePasseOublie, data: {'telephone': telephone});
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<({UserModel user, String token})> reinitialiserMotDePasse({
    required String telephone,
    required String code,
    required String password,
  }) async {
    try {
      final response = await _dio.post(ApiEndpoints.motDePasseReinitialiser, data: {
        'telephone': telephone,
        'code': code,
        'password': password,
        'password_confirmation': password,
      });

      final user = UserModel.fromJson(response.data['user']);
      final token = response.data['token'] as String;

      await SecureStorageService.instance.sauvegarderToken(token);

      return (user: user, token: token);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<UserModel> profilActuel() async {
    try {
      final response = await _dio.get(ApiEndpoints.profile);
      return UserModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> deconnecter() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } on DioException {
      // Même si l'appel réseau échoue, on nettoie le token localement.
    } finally {
      await SecureStorageService.instance.effacerToken();
    }
  }
}