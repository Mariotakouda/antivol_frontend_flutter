import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/paginated_response.dart';
import '../core/errors/api_exception.dart';
import '../models/publication_model.dart';

class SearchService {
  final Dio _dio = ApiClient.instance.dio;

  Future<PaginatedResponse<PublicationModel>> rechercher({
    int page = 1,
    String? motCle,
    String? type,
    int? categorieId,
    String? ville,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    try {
      final response = await _dio.get('/search', queryParameters: {
        'page': page,
        if (motCle != null && motCle.isNotEmpty) 'q': motCle,
        if (type != null) 'type': type,
        if (categorieId != null) 'categorie_id': categorieId,
        if (ville != null && ville.isNotEmpty) 'ville': ville,
        if (dateDebut != null) 'date_debut': dateDebut.toIso8601String().split('T').first,
        if (dateFin != null) 'date_fin': dateFin.toIso8601String().split('T').first,
      });

      return PaginatedResponse.fromJson(
        response.data,
        (json) => PublicationModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }
}
