import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stocke le token Sanctum de façon chiffrée (Keychain sur iOS, Keystore sur Android).
/// Ne jamais utiliser SharedPreferences pour un token d'authentification.
class SecureStorageService {
  SecureStorageService._internal();

  static final SecureStorageService instance = SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _cleTokenAuth = 'auth_token';

  Future<void> sauvegarderToken(String token) async {
    await _storage.write(key: _cleTokenAuth, value: token);
  }

  Future<String?> lireToken() async {
    return _storage.read(key: _cleTokenAuth);
  }

  Future<void> effacerToken() async {
    await _storage.delete(key: _cleTokenAuth);
  }
}
