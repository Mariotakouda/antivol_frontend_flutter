import 'package:dio/dio.dart';

/// Transforme une erreur Dio brute en message lisible pour l'UI,
/// en gérant le format de validation Laravel (422: { message, errors: {champ: [msg]} }).
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, List<String>>? erreursValidation;

  ApiException({required this.message, this.statusCode, this.erreursValidation});

  factory ApiException.depuisDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return ApiException(message: 'Impossible de contacter le serveur. Vérifie ta connexion.');
    }

    final response = e.response;
    if (response == null) {
      return ApiException(message: 'Une erreur inconnue est survenue.');
    }

    final data = response.data;
    String message = 'Une erreur est survenue.';
    Map<String, List<String>>? erreurs;

    if (data is Map<String, dynamic>) {
      message = data['message']?.toString() ?? message;

      if (data['errors'] is Map) {
        erreurs = (data['errors'] as Map).map(
          (key, value) => MapEntry(
            key.toString(),
            (value as List).map((e) => e.toString()).toList(),
          ),
        );
      }
    }

    return ApiException(
      message: message,
      statusCode: response.statusCode,
      erreursValidation: erreurs,
    );
  }

  /// Retourne le premier message d'erreur de validation, utile pour l'afficher directement.
  String? premierMessageValidation() {
    if (erreursValidation == null || erreursValidation!.isEmpty) return null;
    return erreursValidation!.values.first.first;
  }

  @override
  String toString() => premierMessageValidation() ?? message;
}
