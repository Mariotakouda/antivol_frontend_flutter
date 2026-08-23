class ApiEndpoints {
  // Backend en ligne sur Render (accessible depuis n'importe quel appareil,
  // émulateur ou téléphone physique — plus besoin de jongler entre
  // 10.0.2.2 / 127.0.0.1 / IP locale).
  static const String baseUrl = 'https://antivole-api.onrender.com/api/v1';

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