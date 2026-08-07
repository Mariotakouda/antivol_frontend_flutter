import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<NotificationModel> _notifications = [];
  bool _chargement = false;

  List<NotificationModel> get notifications => _notifications;
  bool get chargement => _chargement;
  int get nombreNonLues => _notifications.where((n) => !n.lu).length;

  Future<void> charger() async {
    _chargement = true;
    notifyListeners();

    try {
      final resultat = await _service.lister();
      _notifications = resultat.data;
    } catch (_) {
      // Silencieux
    } finally {
      _chargement = false;
      notifyListeners();
    }
  }

  Future<void> marquerLue(int id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1 || _notifications[index].lu) return;

    // Optimistic update
    final ancienne = _notifications[index];
    _notifications[index] = NotificationModel(
      id: ancienne.id,
      titre: ancienne.titre,
      contenu: ancienne.contenu,
      type: ancienne.type,
      lien: ancienne.lien,
      icone: ancienne.icone,
      lu: true,
      createdAt: ancienne.createdAt,
    );
    notifyListeners();

    try {
      await _service.marquerLue(id);
    } catch (_) {
      // On laisse l'état optimiste même en cas d'échec réseau ponctuel.
    }
  }

  Future<void> marquerToutesLues() async {
    try {
      await _service.marquerToutesLues();
      await charger();
    } catch (_) {
      // Silencieux
    }
  }
}