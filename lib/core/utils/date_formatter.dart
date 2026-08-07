import 'package:intl/intl.dart';

/// Utilitaires de formatage de dates utilisés dans les cartes de publication,
/// les messages et les notifications.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateCourte = DateFormat('dd/MM/yyyy');
  static final DateFormat _heure = DateFormat('HH:mm');

  /// Formate en relatif type "il y a 3 min", "il y a 2 h", "hier",
  /// puis bascule sur une date courte au-delà d'une semaine.
  static String relatif(DateTime date) {
    final difference = DateTime.now().difference(date);

    if (difference.inSeconds < 60) return "à l'instant";
    if (difference.inMinutes < 60) return 'il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'il y a ${difference.inHours} h';
    if (difference.inDays == 1) return 'hier';
    if (difference.inDays < 7) return 'il y a ${difference.inDays} j';

    return _dateCourte.format(date);
  }

  static String court(DateTime date) => _dateCourte.format(date);

  static String heure(DateTime date) => _heure.format(date);
}