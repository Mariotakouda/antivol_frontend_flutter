import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/verification_model.dart';
import '../../services/admin_service.dart';
import '../../widgets/empty_state_widget.dart';

class VerificationModerationScreen extends StatefulWidget {
  const VerificationModerationScreen({super.key});

  @override
  State<VerificationModerationScreen> createState() => _VerificationModerationScreenState();
}

class _VerificationModerationScreenState extends State<VerificationModerationScreen> {
  final _service = AdminService();
  List<VerificationModel> _verifications = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    try {
      final resultat = await _service.listerVerifications();
      if (!mounted) return;
      setState(() {
        _verifications = resultat.data;
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
        await _service.validerVerification(id);
      } else {
        await _service.refuserVerification(id);
      }
      await _charger();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(valider ? 'Vérification validée.' : 'Vérification refusée.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action impossible')));
    }
  }

  IconData _iconePourType(String type) {
    switch (type) {
      case 'TELEPHONE':
        return Icons.phone_iphone;
      case 'EMAIL':
        return Icons.email_outlined;
      case 'IDENTITE':
        return Icons.badge_outlined;
      default:
        return Icons.verified_user_outlined;
    }
  }

  String _libellePourType(String type) {
    switch (type) {
      case 'TELEPHONE':
        return 'Téléphone';
      case 'EMAIL':
        return 'Email';
      case 'IDENTITE':
        return "Pièce d'identité";
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Vérifications en attente')),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _verifications.isEmpty
              ? const EmptyStateWidget(
                  icone: Icons.verified_user_outlined,
                  titre: 'Aucune vérification en attente',
                  message: 'Tous les dossiers soumis ont été traités.',
                )
              : RefreshIndicator(
                  onRefresh: _charger,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.containerPadding),
                    itemCount: _verifications.length,
                    itemBuilder: (context, index) {
                      final verification = _verifications[index];
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
                                  decoration: const BoxDecoration(
                                    color: AppColors.statusGreenBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(_iconePourType(verification.type), size: 18, color: AppColors.primary),
                                ),
                                const SizedBox(width: AppSpacing.gutter),
                                Text(_libellePourType(verification.type), style: AppTextStyles.labelLg),
                              ],
                            ),
                            if (verification.document != null) ...[
                              const SizedBox(height: AppSpacing.stackSm),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                child: Image.network(
                                  verification.document!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.gutter),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _agir(verification.id, valider: false),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(color: AppColors.error, width: 1.5),
                                    ),
                                    child: const Text('Refuser'),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.stackSm),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _agir(verification.id, valider: true),
                                    child: const Text('Valider'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}