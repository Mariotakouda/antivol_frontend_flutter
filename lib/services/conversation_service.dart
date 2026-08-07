import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/errors/api_exception.dart';
import '../models/conversation_model.dart';

class ConversationService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<ConversationModel>> lister() async {
    try {
      final response = await _dio.get('/conversations');
      final data = response.data['data'] as List;
      return data.map((json) => ConversationModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<ConversationModel> voir(int id) async {
    try {
      final response = await _dio.get('/conversations/$id');
      return ConversationModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  /// Démarre (ou récupère si elle existe déjà) une conversation liée à une publication.
  Future<ConversationModel> demarrer(int publicationId) async {
    try {
      final response = await _dio.post('/publications/$publicationId/conversations');
      return ConversationModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }
}
