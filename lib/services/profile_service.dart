import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api/api_client.dart';
import '../core/errors/api_exception.dart';
import '../models/user_model.dart';

class ProfileService {
  final Dio _dio = ApiClient.instance.dio;

  Future<UserModel> voir() async {
    try {
      final response = await _dio.get('/profile');
      return UserModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<UserModel> modifier({
    String? nom,
    String? prenom,
    String? email,
    String? ville,
    String? pays,
    String? adresse,
    XFile? photo,
  }) async {
    try {
      final formData = FormData.fromMap({
        if (nom != null) 'nom': nom,
        if (prenom != null) 'prenom': prenom,
        if (email != null) 'email': email,
        if (ville != null) 'ville': ville,
        if (pays != null) 'pays': pays,
        if (adresse != null) 'adresse': adresse,
        if (photo != null)
          'photo_profil': MultipartFile.fromBytes(await photo.readAsBytes(), filename: photo.name),
        '_method': 'PUT', // Laravel accepte le method spoofing pour les formulaires multipart
      });

      final response = await _dio.post('/profile', data: formData);
      return UserModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> changerMotDePasse({
    required String ancienMotDePasse,
    required String nouveauMotDePasse,
  }) async {
    try {
      await _dio.put('/profile/password', data: {
        'ancien_password': ancienMotDePasse,
        'nouveau_password': nouveauMotDePasse,
        'nouveau_password_confirmation': nouveauMotDePasse,
      });
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> supprimerCompte() async {
    try {
      await _dio.delete('/profile');
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }
}