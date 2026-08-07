import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/errors/api_exception.dart';
import '../models/publication_model.dart';

class FavoriService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<PublicationModel>> lister() async {
    try {
      final response = await _dio.get('/favoris');
      final data = response.data['data'] as List;
      return data
          .map((json) => PublicationModel.fromJson(json['publication']))
          .toList();
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> ajouter(int publicationId) async {
    try {
      await _dio.post('/publications/$publicationId/favori');
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> retirer(int publicationId) async {
    try {
      await _dio.delete('/publications/$publicationId/favori');
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }
}
