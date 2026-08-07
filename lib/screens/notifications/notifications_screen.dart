import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../correspondances/correspondance_detail_screen.dart';
import '../messagerie/conversation_detail_screen.dart';
import '../publications/publication_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().charger();
    });
  }

  IconData _iconePour(String type) {
    switch (type) {
      case 'correspondance':
        return Icons.auto_awesome;
      case 'verification':
        return Icons.verified_user;
      case 'systeme':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }

  Color _couleurPour(String type) {
    switch (type) {
      case 'correspondance':
        return AppColors.primary;
      case 'verification':
        return AppColors.primary;
      case 'systeme':
        return AppColors.accent;
      default:
        return AppColors.outline;
    }
  }

  /// Le champ `lien` d'une notification est de la forme "/correspondances/12",
  /// "/publications/12" ou "/conversations/12" côté API (voir
  /// EnvoyerNotificationCorrespondance et les autres listeners Laravel).
  void _ouvrirLien(NotificationModel notif) {
    final lien = notif.lien;
    if (lien == null || lien.isEmpty) return;

    final segments = lien.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return;

    final type = segments[0];
    final id = int.tryParse(segments[1]);
    if (id == null) return;

    Widget? ecran;
    switch (type) {
      case 'correspondances':
        ecran = CorrespondanceDetailScreen(correspondanceId: id);
        break;
      case 'publications':
        ecran = PublicationDetailScreen(publicationId: id);
        break;
      case 'conversations':
        ecran = ConversationDetailScreen(conversationId: id, titre: 'Conversation');
        break;
    }

    if (ecran != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ecran!));
    }
  }

  /// Regroupe les notifications par période relative pour l'affichage
  /// (purement visuel, ne change ni le tri ni les données du provider).
  Map<String, List<NotificationModel>> _grouper(List<NotificationModel> notifications) {
    final maintenant = DateTime.now();
    final aujourdHui = <NotificationModel>[];
    final cetteSemaine = <NotificationModel>[];
    final plusAncien = <NotificationModel>[];

    for (final notif in notifications) {
      final difference = maintenant.difference(notif.createdAt);
      if (difference.inDays < 1 && notif.createdAt.day == maintenant.day) {
        aujourdHui.add(notif);
      } else if (difference.inDays < 7) {
        cetteSemaine.add(notif);
      } else {
        plusAncien.add(notif);
      }
    }

    return {
      if (aujourdHui.isNotEmpty) "Aujourd'hui": aujourdHui,
      if (cetteSemaine.isNotEmpty) 'Cette semaine': cetteSemaine,
      if (plusAncien.isNotEmpty) 'Plus ancien': plusAncien,
    };
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final groupes = _grouper(provider.notifications);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.nombreNonLues > 0)
            TextButton(
              onPressed: () => provider.marquerToutesLues(),
              child: const Text(
                'Tout marquer lu',
                style: TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: provider.chargement
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : provider.notifications.isEmpty
              ? const EmptyStateWidget(
                  icone: Icons.notifications_none,
                  titre: 'Aucune notification',
                  message: 'Tu seras prévenu ici dès qu\'il y aura du nouveau.',
                )
              : RefreshIndicator(
                  onRefresh: provider.charger,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackSm),
                    children: [
                      for (final entree in groupes.entries) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.containerPadding,
                            AppSpacing.stackMd,
                            AppSpacing.containerPadding,
                            AppSpacing.stackSm,
                          ),
                          child: Text(
                            entree.key,
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        for (final notif in entree.value)
                          _CarteNotification(
                            notif: notif,
                            icone: _iconePour(notif.type),
                            couleur: _couleurPour(notif.type),
                            onTap: () {
                              provider.marquerLue(notif.id);
                              _ouvrirLien(notif);
                            },
                          ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _CarteNotification extends StatelessWidget {
  final NotificationModel notif;
  final IconData icone;
  final Color couleur;
  final VoidCallback onTap;

  const _CarteNotification({
    required this.notif,
    required this.icone,
    required this.couleur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.containerPadding,
          vertical: AppSpacing.gutter,
        ),
        color: notif.lu ? Colors.transparent : AppColors.statusGreenBg.withValues(alpha: 0.4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 22, color: couleur),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.titre,
                          style: AppTextStyles.labelLg.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: notif.lu ? FontWeight.w500 : FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.stackSm),
                      Text(
                        DateFormatter.relatif(notif.createdAt),
                        style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.contenu,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (!notif.lu) ...[
              const SizedBox(width: AppSpacing.stackSm),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}