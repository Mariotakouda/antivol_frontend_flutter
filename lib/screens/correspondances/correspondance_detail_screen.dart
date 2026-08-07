import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/correspondance_model.dart';
import '../../models/publication_model.dart';
import '../../providers/correspondance_provider.dart';
import '../../services/correspondance_service.dart';

class CorrespondanceDetailScreen extends StatefulWidget {
  final int correspondanceId;

  const CorrespondanceDetailScreen({super.key, required this.correspondanceId});

  @override
  State<CorrespondanceDetailScreen> createState() => _CorrespondanceDetailScreenState();
}

class _CorrespondanceDetailScreenState extends State<CorrespondanceDetailScreen> {
  final _service = CorrespondanceService();
  CorrespondanceModel? _correspondance;
  bool _chargement = true;
  bool _actionEnCours = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final correspondance = await _service.voir(widget.correspondanceId);
      if (!mounted) return;
      setState(() {
        _correspondance = correspondance;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  Future<void> _agir({required bool valider}) async {
    setState(() => _actionEnCours = true);

    final provider = context.read<CorrespondanceProvider>();
    final succes = valider
        ? await provider.valider(widget.correspondanceId)
        : await provider.refuser(widget.correspondanceId);

    if (!mounted) return;
    setState(() => _actionEnCours = false);

    if (succes) {
      await _charger();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(valider ? 'Correspondance validée !' : 'Correspondance refusée.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.erreur ?? 'Une erreur est survenue')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_correspondance == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: const Center(child: Text('Correspondance introuvable', style: AppTextStyles.bodyLg)),
      );
    }

    final correspondance = _correspondance!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Détail correspondance')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.containerPadding),
        children: [
          // En-tête : anneau de score + résumé du match.
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: correspondance.score.clamp(0, 100) / 100,
                      strokeWidth: 8,
                      backgroundColor: AppColors.surfaceContainer,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${correspondance.scorePourcentage}%',
                        style: AppTextStyles.displayLg.copyWith(fontSize: 30),
                      ),
                      Text(
                        'Match',
                        style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Text(
            'Correspondance à ${correspondance.scorePourcentage}%',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSm,
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            "L'intelligence artificielle a détecté une forte probabilité que ces deux annonces concernent le même objet.",
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.stackLg),

          _BlocPublication(
            titre: 'Objet perdu',
            icone: Icons.error_outline,
            couleur: AppColors.error,
            publication: correspondance.publicationPerdue,
          ),
          Center(
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.stackSm),
              decoration: const BoxDecoration(color: AppColors.statusGreenBg, shape: BoxShape.circle),
              child: const Icon(Icons.link, size: 18, color: AppColors.primary),
            ),
          ),
          _BlocPublication(
            titre: 'Objet trouvé',
            icone: Icons.check_circle_outline,
            couleur: AppColors.primary,
            publication: correspondance.publicationTrouvee,
          ),

          const SizedBox(height: AppSpacing.stackLg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            decoration: BoxDecoration(
              color: AppColors.statusGreenBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.gutter),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                      children: [
                        TextSpan(
                          text: 'Critères de matching : ',
                          style: AppTextStyles.labelLg.copyWith(color: AppColors.onSurface),
                        ),
                        TextSpan(
                          text: 'catégorie, description, lieu et date rapprochés par notre IA.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.stackLg),
          if (correspondance.estEnAttente) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _actionEnCours ? null : () => _agir(valider: true),
                icon: _actionEnCours
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onAccent),
                      )
                    : const Icon(Icons.handshake_outlined),
                label: const Text('Confirmer la correspondance'),
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _actionEnCours ? null : () => _agir(valider: false),
                icon: const Icon(Icons.close),
                label: const Text("Ce n'est pas la même chose"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                ),
              ),
            ),
          ] else
            Center(
              child: StatusBadge(
                label: correspondance.estValidee ? 'Correspondance validée' : 'Correspondance refusée',
                type: correspondance.estValidee ? StatusType.positive : StatusType.negative,
              ),
            ),
        ],
      ),
    );
  }
}

class _BlocPublication extends StatelessWidget {
  final String titre;
  final IconData icone;
  final Color couleur;
  final PublicationModel publication;

  const _BlocPublication({
    required this.titre,
    required this.icone,
    required this.couleur,
    required this.publication,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: couleur.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 8),
            child: Row(
              children: [
                Icon(icone, size: 16, color: couleur),
                const SizedBox(width: 6),
                Text(titre, style: AppTextStyles.labelLg.copyWith(color: couleur)),
              ],
            ),
          ),
          if (publication.imagePrincipaleUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(publication.imagePrincipaleUrl!, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(publication.titre, style: AppTextStyles.labelLg),
                const SizedBox(height: 4),
                Text(
                  publication.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.stackSm),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${publication.quartier}, ${publication.ville}',
                        style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                if (publication.auteur != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        publication.auteur!.nomComplet,
                        style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
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