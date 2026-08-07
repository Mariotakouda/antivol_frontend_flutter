import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/errors/api_exception.dart';
import '../models/commentaire_model.dart';

class CommentaireService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<CommentaireModel>> lister(int publicationId) async {
    try {
      final response = await _dio.get('/publications/$publicationId/commentaires');
      final data = response.data['data'] as List;
      return data.map((json) => CommentaireModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<CommentaireModel> ajouter({required int publicationId, required String contenu}) async {
    try {
      final response = await _dio.post(
        '/publications/$publicationId/commentaires',
        data: {'contenu': contenu},
      );
      return CommentaireModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> supprimer(int commentaireId) async {
    try {
      await _dio.delete('/commentaires/$commentaireId');
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }
}
