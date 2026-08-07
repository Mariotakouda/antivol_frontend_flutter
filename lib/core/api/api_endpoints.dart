class ApiEndpoints {
  // Emulateur Android : 10.0.2.2 pointe vers le localhost de ta machine hôte.
  // Emulateur iOS / navigateur web : 127.0.0.1 fonctionne directement.
  // Téléphone physique : remplace par l'IP locale de ta machine (ex: 192.168.1.X).
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String otpRenvoyer = '/auth/otp/renvoyer';
  static const String otpVerifier = '/auth/otp/verifier';
  static const String motDePasseOublie = '/auth/mot-de-passe/oublie';
  static const String motDePasseReinitialiser = '/auth/mot-de-passe/reinitialiser';
  static const String google = '/auth/google';

  // Profile
  static const String profile = '/profile';
  static const String profilePassword = '/profile/password';
}