import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/message_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/user_avatar.dart';

class ConversationDetailScreen extends StatefulWidget {
  final int conversationId;
  final String titre;
  final String? photoUrl;
  final String? publicationTitre;
  final String? publicationImage;
  final bool publicationEstPerdue;

  const ConversationDetailScreen({
    super.key,
    required this.conversationId,
    required this.titre,
    this.photoUrl,
    this.publicationTitre,
    this.publicationImage,
    this.publicationEstPerdue = true,
  });

  @override
  State<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  final _service = MessageService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<MessageModel> _messages = [];
  bool _chargement = true;
  bool _envoiEnCours = false;
  Timer? _timerActualisation;

  @override
  void initState() {
    super.initState();
    _charger();

    // Polling simple toutes les 5 secondes. À remplacer par du temps réel
    // (Reverb + Laravel Echo) le jour où le backend l'expose.
    _timerActualisation = Timer.periodic(const Duration(seconds: 5), (_) => _charger(silencieux: true));
  }

  @override
  void dispose() {
    _timerActualisation?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _charger({bool silencieux = false}) async {
    if (!silencieux) setState(() => _chargement = true);

    try {
      final messages = await _service.lister(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  Future<void> _envoyer() async {
    final texte = _messageController.text.trim();
    if (texte.isEmpty) return;

    setState(() => _envoiEnCours = true);
    _messageController.clear();

    try {
      final message = await _service.envoyer(conversationId: widget.conversationId, contenu: texte);
      if (!mounted) return;
      setState(() {
        _messages.add(message);
        _envoiEnCours = false;
      });
      _scrollVersLeBas();
    } catch (_) {
      if (!mounted) return;
      setState(() => _envoiEnCours = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Échec de l'envoi du message")),
      );
    }
  }

  void _scrollVersLeBas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _memeJour(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final monUserId = context.read<AuthProvider>().utilisateur?.id ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 4,
        title: Row(
          children: [
            UserAvatar(
              nomComplet: widget.titre,
              photoUrl: widget.photoUrl,
              taille: 40,
              afficherBordure: false,
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelLg.copyWith(color: AppColors.onSurface),
                  ),
                  if (widget.publicationTitre != null)
                    Text(
                      widget.publicationTitre!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            onSelected: (valeur) {
              if (valeur == 'signaler') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signalement bientôt disponible')),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'signaler', child: Text('Signaler la conversation')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.publicationTitre != null) _buildBandeauPublication(),
          Expanded(
            child: _chargement
                ? _buildSquelette()
                : _messages.isEmpty
                    ? const EmptyStateWidget(
                        icone: Icons.waving_hand_outlined,
                        titre: 'Aucun message',
                        message: 'Dis bonjour pour démarrer la conversation.',
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppSpacing.containerPadding),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final estMoi = message.userId == monUserId;
                          final precedent = index > 0 ? _messages[index - 1] : null;
                          final afficherSeparateurJour = precedent == null ||
                              !_memeJour(precedent.createdAt, message.createdAt);

                          return Column(
                            children: [
                              if (afficherSeparateurJour) _SeparateurJour(date: message.createdAt),
                              _BulleMessage(message: message, estMoi: estMoi),
                            ],
                          );
                        },
                      ),
          ),
          _buildZoneSaisie(),
        ],
      ),
    );
  }

  /// Bandeau contextuel : rappelle l'objet à propos duquel on discute,
  /// avec sa vignette et son statut. Tappable pour ouvrir la publication.
  Widget _buildBandeauPublication() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerPadding,
        vertical: AppSpacing.stackSm,
      ),
      color: AppColors.surfaceContainerLow,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () {
            // TODO: naviguer vers publication_detail_screen une fois
            // l'id de la publication disponible sur cet écran.
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: widget.publicationImage != null
                      ? Image.network(
                          widget.publicationImage!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 40,
                            height: 40,
                            color: AppColors.surfaceContainer,
                          ),
                        )
                      : Container(width: 40, height: 40, color: AppColors.surfaceContainer),
                ),
                const SizedBox(width: AppSpacing.stackSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.publicationTitre!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelLg,
                      ),
                      Text(
                        widget.publicationEstPerdue ? 'PERDU' : 'TROUVÉ',
                        style: AppTextStyles.labelSm.copyWith(
                          color: widget.publicationEstPerdue ? AppColors.accent : AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new, size: 18, color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSquelette() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.containerPadding),
      children: const [
        Align(alignment: Alignment.centerLeft, child: SkeletonBox(width: 180, height: 40, radius: 16)),
        SizedBox(height: 10),
        Align(alignment: Alignment.centerRight, child: SkeletonBox(width: 140, height: 40, radius: 16)),
        SizedBox(height: 10),
        Align(alignment: Alignment.centerLeft, child: SkeletonBox(width: 210, height: 40, radius: 16)),
      ],
    );
  }

  Widget _buildZoneSaisie() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerPadding,
          AppSpacing.stackSm,
          AppSpacing.containerPadding,
          AppSpacing.stackSm,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.surfaceContainerHigh)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Envoi de photo bientôt disponible')),
                ),
                icon: const Icon(Icons.attach_file, color: AppColors.onSurfaceVariant),
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTextStyles.bodyMd,
                  decoration: const InputDecoration(
                    hintText: 'Votre message...',
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _envoyer(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: _envoiEnCours ? null : _envoyer,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: _envoiEnCours
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                            )
                          : const Icon(Icons.send, color: AppColors.onPrimary, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bulle de message : vert plein pour mes messages (coin cassé en bas à
/// droite), fond neutre pour l'interlocuteur (coin cassé en bas à gauche).
/// Coche double verte sous mes messages une fois lus par le destinataire.
class _BulleMessage extends StatelessWidget {
  final MessageModel message;
  final bool estMoi;

  const _BulleMessage({required this.message, required this.estMoi});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(estMoi ? 16 : 4),
      bottomRight: Radius.circular(estMoi ? 4 : 16),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: estMoi ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: estMoi ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.stackMd),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
              decoration: BoxDecoration(
                color: estMoi ? AppColors.primary : AppColors.surfaceContainer,
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: estMoi
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: estMoi ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.image != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm + 4),
                      child: Image.network(message.image!, width: 180),
                    ),
                  if (message.contenu != null)
                    Text(
                      message.contenu!,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: estMoi ? AppColors.onPrimary : AppColors.onSurface,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormatter.heure(message.createdAt),
                  style: AppTextStyles.labelSm,
                ),
                if (estMoi) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: message.lu ? AppColors.primary : AppColors.outline,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Séparateur "Aujourd'hui / Hier / date" entre deux groupes de messages de
/// jours différents.
class _SeparateurJour extends StatelessWidget {
  final DateTime date;

  const _SeparateurJour({required this.date});

  String get _libelle {
    final maintenant = DateTime.now();
    final aujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);
    final jour = DateTime(date.year, date.month, date.day);
    final difference = aujourdhui.difference(jour).inDays;

    if (difference == 0) return "Aujourd'hui";
    if (difference == 1) return 'Hier';
    return DateFormatter.court(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackSm),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(_libelle, style: AppTextStyles.labelSm),
        ),
      ),
    );
  }
}
