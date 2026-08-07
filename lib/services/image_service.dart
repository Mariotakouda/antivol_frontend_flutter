import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api/api_client.dart';
import '../core/errors/api_exception.dart';
import '../models/image_model.dart';

/// Gestion des images d'une publication, séparée de PublicationService
/// car côté API elles ont leurs propres endpoints (ImageController).
///
/// NB : vérifie que ces routes correspondent bien à celles de ton
/// contrôleur Laravel — je les ai calquées sur le pattern déjà utilisé
/// ailleurs dans l'app (ex: /commentaires/{id} pour la suppression).
class ImageService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<ImageModel>> ajouter({
    required int publicationId,
    required List<XFile> images,
  }) async {
    try {
      final formData = FormData();
      for (final image in images) {
        formData.files.add(MapEntry(
          'images[]',
          MultipartFile.fromBytes(await image.readAsBytes(), filename: image.name),
        ));
      }

      final response = await _dio.post('/publications/$publicationId/images', data: formData);
      final data = response.data['data'] as List;
      return data.map((json) => ImageModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> supprimer(int imageId) async {
    try {
      await _dio.delete('/images/$imageId');
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }
}