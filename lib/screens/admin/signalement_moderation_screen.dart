import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/signalement_model.dart';
import '../../services/admin_service.dart';
import '../../widgets/empty_state_widget.dart';

class SignalementModerationScreen extends StatefulWidget {
  const SignalementModerationScreen({super.key});

  @override
  State<SignalementModerationScreen> createState() => _SignalementModerationScreenState();
}

class _SignalementModerationScreenState extends State<SignalementModerationScreen> {
  final _service = AdminService();
  List<SignalementModel> _signalements = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    try {
      final resultat = await _service.listerSignalements();
      if (!mounted) return;
      setState(() {
        _signalements = resultat.data;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  Future<void> _agir(int id, {required bool valider}) async {
    try {
      if (valider) {
        await _service.validerSignalement(id);
      } else {
        await _service.refuserSignalement(id);
      }
      await _charger();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(valider ? 'Signalement validé.' : 'Signalement refusé.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action impossible')));
    }
  }

  IconData _iconePourType(String type) {
    switch (type.toUpperCase()) {
      case 'SECURITE':
        return Icons.warning_amber_outlined;
      case 'FAUSSE_ANNONCE':
      case 'ARNAQUE':
        return Icons.flag_outlined;
      case 'CONTENU_INAPPROPRIE':
        return Icons.block_outlined;
      default:
        return Icons.report_gmailerrorred_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Signalements en attente')),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _signalements.isEmpty
              ? const EmptyStateWidget(
                  icone: Icons.shield_outlined,
                  titre: 'Aucun signalement en attente',
                  message: 'La communauté n\'a rien remonté pour le moment.',
                )
              : RefreshIndicator(
                  onRefresh: _charger,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.containerPadding),
                    itemCount: _signalements.length,
                    itemBuilder: (context, index) {
                      final signalement = _signalements[index];
                      return _CarteSignalement(
                        signalement: signalement,
                        icone: _iconePourType(signalement.type),
                        onRefuser: () => _agir(signalement.id, valider: false),
                        onValider: () => _agir(signalement.id, valider: true),
                      );
                    },
                  ),
                ),
    );
  }
}

class _CarteSignalement extends StatelessWidget {
  final SignalementModel signalement;
  final IconData icone;
  final VoidCallback onRefuser;
  final VoidCallback onValider;

  const _CarteSignalement({
    required this.signalement,
    required this.icone,
    required this.onRefuser,
    required this.onValider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.gutter),
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: AppColors.statusOrangeBg, shape: BoxShape.circle),
                child: Icon(icone, size: 18, color: AppColors.accent),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Text(
                  signalement.type.replaceAll('_', ' '),
                  style: AppTextStyles.labelLg,
                ),
              ),
              Text(
                DateFormatter.relatif(signalement.dateSignalement),
                style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            'Publication #${signalement.publicationId} • Signalé par ${signalement.auteurNomComplet ?? "un utilisateur"}',
            style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.gutter),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              signalement.commentaire,
              style: AppTextStyles.bodyMd,
            ),
          ),
          if (signalement.adresse.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    signalement.adresse,
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
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
      ),
    );
  }
}