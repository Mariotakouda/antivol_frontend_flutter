import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/paginated_response.dart';
import '../core/errors/api_exception.dart';
import '../models/correspondance_model.dart';

class CorrespondanceService {
  final Dio _dio = ApiClient.instance.dio;

  Future<PaginatedResponse<CorrespondanceModel>> lister({int page = 1}) async {
    try {
      final response = await _dio.get('/correspondances', queryParameters: {'page': page});
      return PaginatedResponse.fromJson(
        response.data,
        (json) => CorrespondanceModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<CorrespondanceModel> voir(int id) async {
    try {
      final response = await _dio.get('/correspondances/$id');
      return CorrespondanceModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<CorrespondanceModel> valider(int id) async {
    try {
      final response = await _dio.patch('/correspondances/$id/valider');
      return CorrespondanceModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<CorrespondanceModel> refuser(int id) async {
    try {
      final response = await _dio.patch('/correspondances/$id/refuser');
      return CorrespondanceModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }
}
