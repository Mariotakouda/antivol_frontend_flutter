import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/publication_model.dart';
import '../../services/admin_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../publications/publication_detail_screen.dart';

class PublicationModerationScreen extends StatefulWidget {
  const PublicationModerationScreen({super.key});

  @override
  State<PublicationModerationScreen> createState() => _PublicationModerationScreenState();
}

class _PublicationModerationScreenState extends State<PublicationModerationScreen> {
  final _service = AdminService();
  List<PublicationModel> _publications = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    try {
      final resultat = await _service.listerPublications();
      if (!mounted) return;
      setState(() {
        _publications = resultat.data;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  Future<void> _basculerVisibilite(PublicationModel publication) async {
    try {
      if (publication.estVisible) {
        await _service.masquerPublication(publication.id);
      } else {
        await _service.republierPublication(publication.id);
      }
      await _charger();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(publication.estVisible ? 'Publication masquée.' : 'Publication republiée.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action impossible')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Modération publications')),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _publications.isEmpty
              ? const EmptyStateWidget(
                  icone: Icons.article_outlined,
                  titre: 'Aucune publication',
                  message: 'Il n\'y a rien à modérer pour le moment.',
                )
              : RefreshIndicator(
                  onRefresh: _charger,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackSm),
                    itemCount: _publications.length,
                    itemBuilder: (context, index) {
                      final publication = _publications[index];
                      return _LignePublication(
                        publication: publication,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PublicationDetailScreen(publicationId: publication.id),
                          ),
                        ),
                        onToggle: () => _basculerVisibilite(publication),
                      );
                    },
                  ),
                ),
    );
  }
}

class _LignePublication extends StatelessWidget {
  final PublicationModel publication;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _LignePublication({
    required this.publication,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final estPerdu = publication.estPerdu;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.containerPadding,
          vertical: AppSpacing.gutter,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.surfaceContainer)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: 52,
                height: 52,
                child: publication.imagePrincipaleUrl != null
                    ? Image.network(publication.imagePrincipaleUrl!, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.surfaceContainerLow,
                        child: const Icon(Icons.image_outlined, color: AppColors.outline),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    publication.titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelLg,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${publication.auteur?.nomComplet ?? 'Utilisateur'} • ${DateFormatter.relatif(publication.createdAt)}',
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      StatusBadge(
                        label: estPerdu ? 'Perdu' : 'Trouvé',
                        type: estPerdu ? StatusType.negative : StatusType.positive,
                      ),
                      StatusBadge(
                        label: publication.statut,
                        type: publication.statut == 'RETROUVEE'
                            ? StatusType.positive
                            : publication.statut == 'FERMEE'
                                ? StatusType.negative
                                : StatusType.warning,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Switch(
              value: publication.estVisible,
              activeThumbColor: AppColors.primary,
              onChanged: (_) => onToggle(),
            ),
          ],
        ),
      ),
    );
  }
}