import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/auth_guard.dart';
import '../../models/publication_model.dart';
import '../../models/recompense_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/favori_provider.dart';
import '../../providers/publication_provider.dart';
import '../../services/publication_service.dart';
import '../../services/recompense_service.dart';
import '../../widgets/comment_section_widget.dart';
import '../../widgets/report_publication_sheet.dart';
import '../messagerie/conversation_detail_screen.dart';
import 'edit_publication_screen.dart';

class PublicationDetailScreen extends StatefulWidget {
  final int publicationId;

  const PublicationDetailScreen({super.key, required this.publicationId});

  @override
  State<PublicationDetailScreen> createState() => _PublicationDetailScreenState();
}

class _PublicationDetailScreenState extends State<PublicationDetailScreen> {
  final _service = PublicationService();
  final _recompenseService = RecompenseService();
  PublicationModel? _publication;
  bool _chargement = true;
  String? _erreur;
  bool _demarrageConversationEnCours = false;
  bool _actionStatutEnCours = false;
  bool _actionRecompenseEnCours = false;
  int _pageCarrousel = 0;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _charger();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthProvider>().estConnecte) {
        context.read<FavoriProvider>().charger();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final publication = await _service.voir(widget.publicationId);
      if (!mounted) return;
      setState(() {
        _publication = publication;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erreur = 'Impossible de charger cette publication.';
        _chargement = false;
      });
    }
  }

  bool get _estMonAnnonce {
    final monUserId = context.read<AuthProvider>().utilisateur?.id;
    return monUserId != null && monUserId == _publication?.auteur?.id;
  }

  Future<void> _contacter() async {
    if (!await exigerConnexion(context, message: 'Connecte-toi pour contacter cette personne')) {
      return;
    }
    if (!mounted) return;

    setState(() => _demarrageConversationEnCours = true);

    final conversation = await context
        .read<ConversationProvider>()
        .demarrerConversation(_publication!.id);

    if (!mounted) return;
    setState(() => _demarrageConversationEnCours = false);

    if (conversation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de démarrer la conversation')),
      );
      return;
    }

    final monUserId = context.read<AuthProvider>().utilisateur?.id ?? 0;
    final autre = conversation.autreParticipant(monUserId);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversationDetailScreen(
          conversationId: conversation.id,
          titre: autre?.nomComplet ?? 'Conversation',
        ),
      ),
    );
  }

  Future<void> _ouvrirModification() async {
    final resultat = await Navigator.of(context).push<Object>(
      MaterialPageRoute(builder: (_) => EditPublicationScreen(publication: _publication!)),
    );

    if (resultat == 'supprimee') {
      if (!mounted) return;
      context.read<PublicationProvider>().retirer(widget.publicationId);
      Navigator.of(context).pop();
      return;
    }

    if (resultat is PublicationModel) {
      if (!mounted) return;
      setState(() => _publication = resultat);
      context.read<PublicationProvider>().remplacer(resultat);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annonce mise à jour avec succès.')),
      );
    }
  }

  Future<void> _marquerRetrouvee() async {
    setState(() => _actionStatutEnCours = true);
    try {
      final publication = await _service.marquerRetrouvee(_publication!.id);
      if (!mounted) return;
      setState(() => _publication = publication);
      context.read<PublicationProvider>().remplacer(publication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de mettre à jour le statut pour le moment.')),
      );
    } finally {
      if (mounted) setState(() => _actionStatutEnCours = false);
    }
  }

  Future<void> _proposerRecompense() async {
    final controllerMontant = TextEditingController();
    final controllerDescription = TextEditingController();

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Proposer une récompense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controllerMontant,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Montant en F CFA'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controllerDescription,
              decoration: const InputDecoration(labelText: 'Modalités (optionnel)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Proposer')),
        ],
      ),
    );

    if (confirme != true) return;

    final montant = double.tryParse(controllerMontant.text.trim());
    if (montant == null || montant <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montant invalide')),
      );
      return;
    }

    setState(() => _actionRecompenseEnCours = true);
    try {
      final recompense = await _recompenseService.proposer(
        publicationId: _publication!.id,
        montant: montant,
        description: controllerDescription.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _publication = _publication!.copyWith(
          recompenses: [..._publication!.recompenses, recompense],
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Récompense proposée avec succès.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _actionRecompenseEnCours = false);
    }
  }

  Future<void> _marquerRecompensePayee(RecompenseModel recompense) async {
    setState(() => _actionRecompenseEnCours = true);
    try {
      final miseAJour = await _recompenseService.marquerPayee(recompense.id);
      if (!mounted) return;
      setState(() {
        final autres = _publication!.recompenses.where((r) => r.id != recompense.id).toList();
        _publication = _publication!.copyWith(recompenses: [...autres, miseAJour]);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Récompense marquée comme payée.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de la mise à jour.')),
      );
    } finally {
      if (mounted) setState(() => _actionRecompenseEnCours = false);
    }
  }

  void _ouvrirSignalement() {
    final publication = _publication!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReportPublicationSheet(
        publicationId: publication.id,
        latitude: publication.latitude,
        longitude: publication.longitude,
        adresse: publication.adresse,
      ),
    ).then((succes) {
      if (succes == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signalement envoyé, merci.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_erreur != null || _publication == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(),
        body: Center(child: Text(_erreur ?? 'Erreur', style: AppTextStyles.bodyLg)),
      );
    }

    final publication = _publication!;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(publication.titre, overflow: TextOverflow.ellipsis),
        actions: [
          if (_estMonAnnonce) ...[
            if (publication.statut == 'OUVERTE')
              IconButton(
                icon: _actionStatutEnCours
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline),
                tooltip: 'Marquer comme retrouvée',
                onPressed: _actionStatutEnCours ? null : _marquerRetrouvee,
              ),
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _ouvrirModification),
          ] else
            IconButton(icon: const Icon(Icons.flag_outlined), onPressed: _ouvrirSignalement),
        ],
      ),
      body: ListView(
        children: [
          if (publication.images.isNotEmpty)
            _buildCarrousel(publication)
          else
            Container(
              height: 220,
              color: AppColors.statusGreenBg,
              child: Icon(
                publication.estPerdu ? Icons.search : Icons.check_circle_outline,
                size: 56,
                color: publication.estPerdu ? AppColors.error : AppColors.primary,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.containerPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusBadge(
                      label: publication.estPerdu ? 'Perdu' : 'Trouvé',
                      type: publication.estPerdu ? StatusType.negative : StatusType.positive,
                    ),
                    if (publication.categorie != null) ...[
                      const SizedBox(width: AppSpacing.stackSm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          publication.categorie!.nom,
                          style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    ],
                    if (publication.statut != 'OUVERTE') ...[
                      const SizedBox(width: AppSpacing.stackSm),
                      StatusBadge(
                        label: publication.statut == 'RETROUVEE' ? 'Retrouvée' : 'Fermée',
                        type: StatusType.warning,
                      ),
                    ],
                  ],
                ),
                if (publication.statut != 'OUVERTE') ...[
                  const SizedBox(height: AppSpacing.stackMd),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.gutter),
                    decoration: BoxDecoration(
                      color: AppColors.statusOrangeBg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: AppColors.accent),
                        const SizedBox(width: AppSpacing.stackSm),
                        Expanded(
                          child: Text(
                            publication.statut == 'RETROUVEE'
                                ? "Cette annonce est marquée comme retrouvée."
                                : "Cette annonce n'est plus active.",
                            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.stackLg),
                Text(publication.titre, style: AppTextStyles.headlineMd.copyWith(color: AppColors.onSurface)),
                const SizedBox(height: AppSpacing.stackSm),
                Text(publication.description, style: AppTextStyles.bodyLg),
                const SizedBox(height: AppSpacing.stackLg),
                _ligneInfo(Icons.location_on_outlined, '${publication.adresse}, ${publication.quartier}, ${publication.ville}'),
                _ligneInfo(Icons.calendar_today_outlined, publication.dateEvenement.toLocal().toString().split(' ').first),
                if (publication.marque != null) _ligneInfo(Icons.label_outline, 'Marque : ${publication.marque}'),
                if (publication.couleur != null) _ligneInfo(Icons.palette_outlined, 'Couleur : ${publication.couleur}'),
                if (publication.recompense != null)
                  _ligneInfo(Icons.card_giftcard_outlined, 'Récompense : ${publication.recompense} FCFA', accent: true),
                const SizedBox(height: AppSpacing.stackLg),
                if (publication.auteur != null) _buildCarteAuteur(publication),
                _buildSectionRecompense(publication),
                const SizedBox(height: AppSpacing.stackLg),
                Divider(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                const SizedBox(height: AppSpacing.stackMd),
                CommentSectionWidget(publicationId: publication.id),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Consumer<FavoriProvider>(
                  builder: (context, favoriProvider, _) {
                    final estFavori = favoriProvider.estFavori(publication.id);
                    return OutlinedButton.icon(
                      onPressed: () async {
                        if (await exigerConnexion(context, message: 'Connecte-toi pour ajouter aux favoris')) {
                          favoriProvider.basculer(publication);
                        }
                      },
                      icon: Icon(
                        estFavori ? Icons.favorite : Icons.favorite_border,
                        color: estFavori ? AppColors.error : null,
                      ),
                      label: const Text('Favori'),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_estMonAnnonce ||
                          _demarrageConversationEnCours ||
                          publication.statut != 'OUVERTE')
                      ? null
                      : _contacter,
                  icon: _demarrageConversationEnCours
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.chat_bubble_outline),
                  label: const Text('Contacter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarrousel(PublicationModel publication) {
    return Stack(
      children: [
        SizedBox(
          height: 260,
          child: PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _pageCarrousel = i),
            children: publication.images
                .map((img) => Image.network(img.url, fit: BoxFit.cover, width: double.infinity))
                .toList(),
          ),
        ),
        // Badges type/statut en overlay (haut-gauche)
        Positioned(
          top: 16,
          left: 16,
          child: Row(
            children: [
              StatusBadge(
                label: publication.estPerdu ? 'Perdu' : 'Trouvé',
                type: publication.estPerdu ? StatusType.negative : StatusType.positive,
              ),
            ],
          ),
        ),
        // Pagination (bas, centrée)
        if (publication.images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(publication.images.length, (index) {
                final actif = index == _pageCarrousel;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: actif ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: actif ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildCarteAuteur(PublicationModel publication) {
    final auteur = publication.auteur!;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.stackMd),
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.surfaceContainer),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.statusGreenBg,
            backgroundImage: auteur.photoProfil != null ? NetworkImage(auteur.photoProfil!) : null,
            child: auteur.photoProfil == null
                ? const Icon(Icons.person, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auteur.nomComplet, style: AppTextStyles.labelLg),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.verified, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Confiance : ${auteur.scoreConfiance}',
                      style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSectionRecompense(PublicationModel publication) {
    // Une récompense formelle ne peut exister que si une correspondance a
    // été validée : donc uniquement pertinent pour une annonce PERDU déjà
    // marquée RETROUVEE.
    if (!publication.estPerdu || publication.statut != 'RETROUVEE') {
      return const SizedBox.shrink();
    }

    if (publication.recompenses.isEmpty) {
      if (!_estMonAnnonce) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: AppColors.statusOrangeBg,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
          leading: const Icon(Icons.card_giftcard_outlined, color: AppColors.accent),
          title: const Text('Proposer une récompense'),
          subtitle: const Text('À la personne qui a retrouvé ton objet'),
          trailing: _actionRecompenseEnCours
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
              : const Icon(Icons.chevron_right),
          onTap: _actionRecompenseEnCours ? null : _proposerRecompense,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: publication.recompenses.map((recompense) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.stackSm),
          decoration: BoxDecoration(
            color: recompense.estPaye ? AppColors.statusGreenBg : AppColors.statusOrangeBg,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
            leading: Icon(
              Icons.card_giftcard_outlined,
              color: recompense.estPaye ? AppColors.primary : AppColors.accent,
            ),
            title: Text('${recompense.montant.toStringAsFixed(0)} F CFA', style: AppTextStyles.labelLg),
            subtitle: Text(
              [
                if (recompense.description != null && recompense.description!.isNotEmpty)
                  recompense.description!,
                recompense.estPaye ? 'Payée' : 'En attente de paiement',
                if (recompense.beneficiaire != null) 'Pour ${recompense.beneficiaire!.nomComplet}',
              ].join(' · '),
              style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
            ),
            trailing: !recompense.estPaye && _estMonAnnonce
                ? TextButton(
                    onPressed: _actionRecompenseEnCours ? null : () => _marquerRecompensePayee(recompense),
                    child: _actionRecompenseEnCours
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Marquer payée'),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _ligneInfo(IconData icone, String texte, {bool accent = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.stackSm),
      child: Row(
        children: [
          Icon(icone, size: 18, color: accent ? AppColors.accent : AppColors.outline),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Text(
              texte,
              style: AppTextStyles.bodyMd.copyWith(
                color: accent ? AppColors.accent : AppColors.onSurfaceVariant,
                fontWeight: accent ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}