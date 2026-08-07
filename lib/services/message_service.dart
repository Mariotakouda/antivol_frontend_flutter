import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/errors/api_exception.dart';
import '../models/message_model.dart';

class MessageService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<MessageModel>> lister(int conversationId) async {
    try {
      final response = await _dio.get('/conversations/$conversationId/messages');
      final data = response.data['data'] as List;
      return data.map((json) => MessageModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<MessageModel> envoyer({required int conversationId, required String contenu}) async {
    try {
      final response = await _dio.post(
        '/conversations/$conversationId/messages',
        data: {'contenu': contenu},
      );
      return MessageModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> marquerLu(int messageId) async {
    try {
      await _dio.patch('/messages/$messageId/lu');
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }
}
