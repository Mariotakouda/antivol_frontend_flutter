import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/correspondance_model.dart';
import '../../providers/correspondance_provider.dart';
import '../../widgets/empty_state_widget.dart';
import 'correspondance_detail_screen.dart';

class CorrespondancesListScreen extends StatefulWidget {
  const CorrespondancesListScreen({super.key});

  @override
  State<CorrespondancesListScreen> createState() => _CorrespondancesListScreenState();
}

class _CorrespondancesListScreenState extends State<CorrespondancesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CorrespondanceProvider>().charger();
    });
  }

  Future<void> _confirmerAction(CorrespondanceModel correspondance, {required bool valider}) async {
    final titre = valider ? 'Valider cette correspondance ?' : 'Refuser cette correspondance ?';
    final message = valider
        ? 'Les deux publications seront marquées comme retrouvées et une conversation sera créée avec l\'autre utilisateur.'
        : 'Cette correspondance sera écartée. Les publications restent ouvertes.';

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: Text(titre, style: AppTextStyles.headlineSm),
        content: Text(message, style: AppTextStyles.bodyMd),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmer')),
        ],
      ),
    );

    if (confirme != true) return;
    if (!mounted) return;

    final provider = context.read<CorrespondanceProvider>();
    final succes = valider
        ? await provider.valider(correspondance.id)
        : await provider.refuser(correspondance.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(
        succes
            ? (valider ? 'Correspondance validée !' : 'Correspondance refusée.')
            : (provider.erreur ?? 'Une erreur est survenue'),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CorrespondanceProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Correspondances IA')),
      body: provider.chargement
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : provider.correspondances.isEmpty
              ? EmptyStateWidget(
                  icone: Icons.auto_awesome,
                  titre: 'Aucune correspondance détectée',
                  message: provider.erreur ??
                      "Notre IA t'informera ici dès qu'une annonce pourrait correspondre à la tienne.",
                )
              : RefreshIndicator(
                  onRefresh: provider.charger,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.containerPadding),
                    itemCount: provider.correspondances.length,
                    itemBuilder: (context, index) {
                      final correspondance = provider.correspondances[index];
                      return _CarteCorrespondance(
                        correspondance: correspondance,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CorrespondanceDetailScreen(correspondanceId: correspondance.id),
                          ),
                        ),
                        onValider: () => _confirmerAction(correspondance, valider: true),
                        onRefuser: () => _confirmerAction(correspondance, valider: false),
                      );
                    },
                  ),
                ),
    );
  }
}

class _CarteCorrespondance extends StatelessWidget {
  final CorrespondanceModel correspondance;
  final VoidCallback onTap;
  final VoidCallback onValider;
  final VoidCallback onRefuser;

  const _CarteCorrespondance({
    required this.correspondance,
    required this.onTap,
    required this.onValider,
    required this.onRefuser,
  });

  Color get _couleurScore {
    if (correspondance.scorePourcentage >= 80) return AppColors.primary;
    if (correspondance.scorePourcentage >= 60) return AppColors.accent;
    return AppColors.outline;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.gutter),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _couleurScore.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 14, color: _couleurScore),
                        const SizedBox(width: 4),
                        Text(
                          '${correspondance.scorePourcentage}% de correspondance',
                          style: AppTextStyles.labelSm.copyWith(color: _couleurScore, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (!correspondance.estEnAttente)
                    StatusBadge(
                      label: correspondance.estValidee ? 'Validée' : 'Refusée',
                      type: correspondance.estValidee ? StatusType.positive : StatusType.negative,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.gutter),
              Row(
                children: [
                  Expanded(
                    child: _MiniPublication(
                      label: 'PERDU',
                      couleur: AppColors.error,
                      titre: correspondance.publicationPerdue.titre,
                      imageUrl: correspondance.publicationPerdue.imagePrincipaleUrl,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(color: AppColors.statusGreenBg, shape: BoxShape.circle),
                    child: const Icon(Icons.compare_arrows, size: 16, color: AppColors.primary),
                  ),
                  Expanded(
                    child: _MiniPublication(
                      label: 'TROUVÉ',
                      couleur: AppColors.primary,
                      titre: correspondance.publicationTrouvee.titre,
                      imageUrl: correspondance.publicationTrouvee.imagePrincipaleUrl,
                    ),
                  ),
                ],
              ),
              if (correspondance.estEnAttente) ...[
                const SizedBox(height: AppSpacing.gutter),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onRefuser,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error, width: 1.5),
                        ),
                        child: const Text('Refuser'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    Expanded(
                      child: ElevatedButton(onPressed: onValider, child: const Text('Valider')),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPublication extends StatelessWidget {
  final String label;
  final Color couleur;
  final String titre;
  final String? imageUrl;

  const _MiniPublication({
    required this.label,
    required this.couleur,
    required this.titre,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSm.copyWith(color: couleur, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: AspectRatio(
            aspectRatio: 1.4,
            child: imageUrl != null
                ? Image.network(imageUrl!, fit: BoxFit.cover)
                : Container(
                    color: AppColors.surfaceContainerLow,
                    child: const Icon(Icons.image_outlined, color: AppColors.outline),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          titre,
          style: AppTextStyles.bodyMd,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}