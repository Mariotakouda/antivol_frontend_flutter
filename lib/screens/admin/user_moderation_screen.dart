import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../widgets/empty_state_widget.dart';

class UserModerationScreen extends StatefulWidget {
  const UserModerationScreen({super.key});

  @override
  State<UserModerationScreen> createState() => _UserModerationScreenState();
}

class _UserModerationScreenState extends State<UserModerationScreen> {
  final _service = AdminService();
  List<UserModel> _utilisateurs = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    try {
      final resultat = await _service.listerUtilisateurs();
      if (!mounted) return;
      setState(() {
        _utilisateurs = resultat.data;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  Future<void> _agir(Future<void> Function() action, {required String messageSucces}) async {
    try {
      await action();
      await _charger();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageSucces)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action impossible')));
    }
  }

  StatusType _typePourStatut(String statut) {
    switch (statut) {
      case 'Actif':
        return StatusType.positive;
      case 'Suspendu':
        return StatusType.warning;
      default:
        return StatusType.negative;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Utilisateurs')),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _utilisateurs.isEmpty
              ? const EmptyStateWidget(
                  icone: Icons.group_outlined,
                  titre: 'Aucun utilisateur',
                  message: 'La liste des utilisateurs est vide.',
                )
              : RefreshIndicator(
                  onRefresh: _charger,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackSm),
                    itemCount: _utilisateurs.length,
                    itemBuilder: (context, index) {
                      final user = _utilisateurs[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.containerPadding,
                          vertical: AppSpacing.stackSm,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.surfaceContainer)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.statusGreenBg,
                              backgroundImage:
                                  user.photoProfil != null ? NetworkImage(user.photoProfil!) : null,
                              child: user.photoProfil == null
                                  ? const Icon(Icons.person, color: AppColors.primary)
                                  : null,
                            ),
                            const SizedBox(width: AppSpacing.gutter),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.nomComplet, style: AppTextStyles.labelLg),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${user.telephone} · ${user.ville}',
                                    style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.stackSm),
                            PopupMenuButton<String>(
                              tooltip: 'Actions',
                              child: IgnorePointer(
                                child: StatusBadge(label: user.statut, type: _typePourStatut(user.statut)),
                              ),
                              onSelected: (action) {
                                switch (action) {
                                  case 'suspendre':
                                    _agir(() => _service.suspendreUtilisateur(user.id),
                                        messageSucces: 'Utilisateur suspendu.');
                                    break;
                                  case 'bloquer':
                                    _agir(() => _service.bloquerUtilisateur(user.id),
                                        messageSucces: 'Utilisateur bloqué.');
                                    break;
                                  case 'reactiver':
                                    _agir(() => _service.reactiverUtilisateur(user.id),
                                        messageSucces: 'Utilisateur réactivé.');
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'suspendre', child: Text('Suspendre')),
                                const PopupMenuItem(value: 'bloquer', child: Text('Bloquer')),
                                const PopupMenuItem(value: 'reactiver', child: Text('Réactiver')),
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