import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/errors/api_exception.dart';
import '../models/categorie_model.dart';

class CategorieService {
  final Dio _dio = ApiClient.instance.dio;

  /// Les catégories changent rarement : pas de pagination côté API,
  /// on récupère la liste complète en une fois.
  Future<List<CategorieModel>> lister() async {
    try {
      final response = await _dio.get('/categories');
      final data = response.data['data'] as List;
      return data
          .map((json) => CategorieModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }
}