import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api/api_client.dart';
import '../core/api/paginated_response.dart';
import '../core/errors/api_exception.dart';
import '../models/publication_model.dart';
import '../models/resultat_verification_model.dart';
import '../models/schema_champs_model.dart';

class PublicationService {
  final Dio _dio = ApiClient.instance.dio;

  Future<PaginatedResponse<PublicationModel>> lister({
    int page = 1,
    String? type,
    int? categorieId,
    String? ville,
    String? recherche,
  }) async {
    try {
      final response = await _dio.get('/publications', queryParameters: {
        'page': page,
        if (type != null) 'type': type,
        if (categorieId != null) 'categorie_id': categorieId,
        if (ville != null && ville.isNotEmpty) 'ville': ville,
        if (recherche != null && recherche.isNotEmpty) 'q': recherche,
      });

      return PaginatedResponse.fromJson(
        response.data,
        (json) => PublicationModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  /// Vérification rapide pour les forces de l'ordre : recherche exacte
  /// par plaque d'immatriculation ou numéro de série, uniquement parmi
  /// les publications PERDU encore ouvertes. Les coordonnées du déclarant
  /// ne sont incluses par le backend que pour les comptes Police/Admin.
  Future<List<ResultatVerification>> verifierObjet(String identifiant) async {
    try {
      final response = await _dio.get('/publications-verification', queryParameters: {
        'identifiant': identifiant,
      });
      final data = response.data['data'] as List;
      return data.map((json) => ResultatVerification.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<PublicationModel> voir(int id) async {
    try {
      final response = await _dio.get('/publications/$id');
      return PublicationModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  /// Récupère la liste des champs (structurés + JSON) attendus pour cette
  /// catégorie + type, pour construire le formulaire dynamiquement.
  Future<SchemaChamps> champsPour({required int categorieId, required String type}) async {
    try {
      final response = await _dio.get('/publications/champs', queryParameters: {
        'categorie_id': categorieId,
        'type': type,
      });
      return SchemaChamps.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<PublicationModel> creer({
    required int categorieId,
    required String titre,
    required String description,
    required String type,
    String? marque,
    String? modele,
    String? couleur,
    String? numeroSerie,
    String? plaque,
    String? etat,
    required DateTime dateEvenement,
    required double latitude,
    required double longitude,
    required String adresse,
    required String quartier,
    required String ville,
    required String pays,
    double? recompense,
    Map<String, dynamic>? caracteristiques,
    List<XFile> images = const [],
  }) async {
    try {
      final formData = FormData();

      formData.fields.addAll([
        MapEntry('categorie_id', categorieId.toString()),
        MapEntry('titre', titre),
        MapEntry('description', description),
        MapEntry('type', type),
        MapEntry('date_evenement', dateEvenement.toIso8601String().split('T').first),
        MapEntry('latitude', latitude.toString()),
        MapEntry('longitude', longitude.toString()),
        MapEntry('adresse', adresse),
        MapEntry('quartier', quartier),
        MapEntry('ville', ville),
        MapEntry('pays', pays),
        if (marque != null && marque.isNotEmpty) MapEntry('marque', marque),
        if (modele != null && modele.isNotEmpty) MapEntry('modele', modele),
        if (couleur != null && couleur.isNotEmpty) MapEntry('couleur', couleur),
        if (numeroSerie != null && numeroSerie.isNotEmpty) MapEntry('numero_serie', numeroSerie),
        if (plaque != null && plaque.isNotEmpty) MapEntry('plaque', plaque),
        if (etat != null && etat.isNotEmpty) MapEntry('etat', etat),
        if (recompense != null) MapEntry('recompense', recompense.toString()),
        // Envoyé en JSON stringifié : le backend le décode via
        // prepareForValidation() (multipart/form-data ne transporte pas
        // d'objets imbriqués nativement).
        if (caracteristiques != null && caracteristiques.isNotEmpty)
          MapEntry('caracteristiques', jsonEncode(caracteristiques)),
      ]);

      for (final image in images) {
        formData.files.add(MapEntry(
          'images[]',
          MultipartFile.fromBytes(await image.readAsBytes(), filename: image.name),
        ));
      }

      final response = await _dio.post('/publications', data: formData);
      return PublicationModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  /// Modification d'une publication existante. Uniquement les champs texte —
  /// la gestion des images se fait séparément via ImageController côté API
  /// (endpoints /publications/{id}/images), pas encore branché côté Flutter.
  Future<PublicationModel> modifier({
    required int id,
    int? categorieId,
    String? titre,
    String? description,
    String? marque,
    String? modele,
    String? couleur,
    String? numeroSerie,
    String? plaque,
    String? etat,
    double? recompense,
    String? statut,
    bool? estVisible,
  }) async {
    try {
      final response = await _dio.put('/publications/$id', data: {
        if (categorieId != null) 'categorie_id': categorieId,
        if (titre != null) 'titre': titre,
        if (description != null) 'description': description,
        if (marque != null) 'marque': marque,
        if (modele != null) 'modele': modele,
        if (couleur != null) 'couleur': couleur,
        if (numeroSerie != null) 'numero_serie': numeroSerie,
        if (plaque != null) 'plaque': plaque,
        if (etat != null) 'etat': etat,
        if (recompense != null) 'recompense': recompense,
        if (statut != null) 'statut': statut,
        if (estVisible != null) 'est_visible': estVisible,
      });
      return PublicationModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> supprimer(int id) async {
    try {
      await _dio.delete('/publications/$id');
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<PublicationModel> marquerRetrouvee(int id) async {
    try {
      final response = await _dio.patch('/publications/$id/marquer-retrouvee');
      return PublicationModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> ajouterFavori(int publicationId) async {
    try {
      await _dio.post('/publications/$publicationId/favori');
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }

  Future<void> retirerFavori(int publicationId) async {
    try {
      await _dio.delete('/publications/$publicationId/favori');
    } on DioException catch (e) {
      throw ApiException.depuisDioException(e);
    }
  }
}