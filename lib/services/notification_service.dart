import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/paginated_response.dart';
import '../core/errors/api_exception.dart';
import '../models/notification_model.dart';

class NotificationService {
  final Dio _dio = ApiClient.instance.dio;

  Future<PaginatedResponse<NotificationModel>> lister({int page = 1}) async {
    try {
      final response = await _dio.get('/notifications', queryParameters: {'page': page});
      return PaginatedResponse.fromJson(
        response.data,
        (json) => NotificationModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> marquerLue(int id) async {
    try {
      await _dio.patch('/notifications/$id/lu');
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> marquerToutesLues() async {
    try {
      await _dio.patch('/notifications/toutes-lues');
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }
}
