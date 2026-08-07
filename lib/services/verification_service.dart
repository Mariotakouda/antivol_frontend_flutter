import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/errors/api_exception.dart';
import '../models/verification_model.dart';

/// Demandes de vérification soumises par l'utilisateur lui-même
/// (téléphone, email, identité) — distinct de la modération admin qui
/// valide/refuse ces demandes (voir AdminService).
class VerificationService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<VerificationModel>> mesVerifications() async {
    try {
      final response = await _dio.get('/verifications');
      final data = response.data['data'] as List;
      return data.map((json) => VerificationModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  /// [type] doit être 'TELEPHONE', 'EMAIL' ou 'IDENTITE'.
  /// [documentBytes]/[documentNom] sont obligatoires côté API uniquement
  /// pour le type IDENTITE. Prend des bytes bruts plutôt qu'un XFile pour
  /// rester agnostique de la source (image_picker ou file_picker, qui
  /// permet d'accepter aussi les PDF en plus des photos).
  Future<VerificationModel> soumettre({
    required String type,
    List<int>? documentBytes,
    String? documentNom,
  }) async {
    try {
      final formData = FormData.fromMap({
        'type': type,
        if (documentBytes != null)
          'document': MultipartFile.fromBytes(documentBytes, filename: documentNom ?? 'document'),
      });

      final response = await _dio.post('/verifications', data: formData);
      return VerificationModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }
}