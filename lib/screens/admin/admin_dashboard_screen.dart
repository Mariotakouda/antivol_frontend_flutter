import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/admin_service.dart';
import 'police_accounts_screen.dart';
import 'publication_moderation_screen.dart';
import 'signalement_moderation_screen.dart';
import 'user_moderation_screen.dart';
import 'verification_moderation_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _service = AdminService();
  AdminStats? _stats;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final stats = await _service.statistiques();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Administration')),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _charger,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.containerPadding),
                children: [
                  if (_stats != null) _construireStats(_stats!),
                  const SizedBox(height: AppSpacing.stackLg),
                  Text(
                    'Accès rapide',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gutter),
                  _CarteNavigation(
                    icone: Icons.manage_accounts_outlined,
                    couleur: AppColors.primary,
                    titre: 'Gestion utilisateurs',
                    sousTitre: _stats != null ? '${_stats!.utilisateursSuspendus} suspendu(s)' : null,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UserModerationScreen()),
                    ),
                  ),
                  _CarteNavigation(
                    icone: Icons.playlist_add_check_outlined,
                    couleur: AppColors.primary,
                    titre: 'Modération publications',
                    sousTitre: 'Masquer, republier',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PublicationModerationScreen()),
                    ),
                  ),
                  _CarteNavigation(
                    icone: Icons.warning_amber_outlined,
                    couleur: AppColors.accent,
                    titre: 'Modération signalements',
                    sousTitre: _stats != null ? '${_stats!.signalementsEnAttente} en attente' : null,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignalementModerationScreen()),
                    ),
                  ),
                  _CarteNavigation(
                    icone: Icons.verified_user_outlined,
                    couleur: AppColors.primary,
                    titre: "Vérifications d'identité",
                    sousTitre: 'Valider ou refuser les pièces soumises',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const VerificationModerationScreen()),
                    ),
                  ),
                  _CarteNavigation(
                    icone: Icons.local_police_outlined,
                    couleur: AppColors.primary,
                    titre: 'Comptes Police',
                    sousTitre: 'Créer ou révoquer des accès forces de l\'ordre',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PoliceAccountsScreen()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _construireStats(AdminStats stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      crossAxisSpacing: AppSpacing.gutter,
      mainAxisSpacing: AppSpacing.gutter,
      children: [
        _CarteStat(
          icone: Icons.article_outlined,
          valeur: stats.totalPublications,
          label: 'Publications',
          couleur: AppColors.primary,
        ),
        _CarteStat(
          icone: Icons.group_outlined,
          valeur: stats.totalUtilisateurs,
          label: 'Utilisateurs',
          couleur: AppColors.primary,
        ),
        _CarteStat(
          icone: Icons.auto_awesome_outlined,
          valeur: stats.correspondancesValidees,
          label: 'Correspondances validées',
          couleur: AppColors.primary,
        ),
        _CarteStat(
          icone: Icons.report_problem_outlined,
          valeur: stats.signalementsEnAttente,
          label: 'Signalements en attente',
          couleur: AppColors.accent,
        ),
      ],
    );
  }
}

class _CarteStat extends StatelessWidget {
  final IconData icone;
  final int valeur;
  final String label;
  final Color couleur;

  const _CarteStat({
    required this.icone,
    required this.valeur,
    required this.label,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, size: 20, color: couleur),
          const SizedBox(height: 6),
          Text(
            '$valeur',
            style: AppTextStyles.headlineMd.copyWith(color: AppColors.onSurface, fontSize: 20),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _CarteNavigation extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final String titre;
  final String? sousTitre;
  final VoidCallback onTap;

  const _CarteNavigation({
    required this.icone,
    required this.couleur,
    required this.titre,
    this.sousTitre,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.gutter),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: couleur.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icone, color: couleur),
        ),
        title: Text(titre, style: AppTextStyles.labelLg),
        subtitle: sousTitre != null
            ? Text(sousTitre!, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant))
            : null,
        trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
        onTap: onTap,
      ),
    );
  }
}