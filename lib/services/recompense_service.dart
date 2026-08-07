import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/errors/api_exception.dart';
import '../models/recompense_model.dart';

class RecompenseService {
  final Dio _dio = ApiClient.instance.dio;

  /// Ne peut réussir que si une correspondance a été validée pour cette
  /// publication perdue — sinon l'API renvoie une 422 explicite que
  /// l'appelant peut afficher directement via ApiException.toString().
  Future<RecompenseModel> proposer({
    required int publicationId,
    required double montant,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        '/publications/$publicationId/recompense',
        data: {
          'montant': montant,
          if (description != null && description.isNotEmpty) 'description': description,
        },
      );
      return RecompenseModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<RecompenseModel> marquerPayee(int recompenseId) async {
    try {
      final response = await _dio.patch('/recompenses/$recompenseId/payee');
      return RecompenseModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }
}