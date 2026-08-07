import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/errors/api_exception.dart';

class SignalementService {
  final Dio _dio = ApiClient.instance.dio;

  Future<void> signaler({
    required int publicationId,
    required String commentaire,
    required String type, // VU | TROUVE | FAUSSE_ALERTE
    required double latitude,
    required double longitude,
    required String adresse,
  }) async {
    try {
      await _dio.post('/publications/$publicationId/signalements', data: {
        'commentaire': commentaire,
        'type': type,
        'latitude': latitude,
        'longitude': longitude,
        'adresse': adresse,
      });
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }
}
