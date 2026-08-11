import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_dashboard_screen.dart';
import '../publications/verification_objet_screen.dart';
import '../verification/verification_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final utilisateur = authProvider.utilisateur;

    if (utilisateur == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final estVerifie = utilisateur.telephoneVerifie && utilisateur.emailVerifie;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // En-tête vert avec avatar, nom et score de confiance.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPadding,
              AppSpacing.stackLg,
              AppSpacing.containerPadding,
              AppSpacing.stackLg + 8,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppRadius.card),
                bottomRight: Radius.circular(AppRadius.card),
              ),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.onPrimary),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    ),
                  ),
                ),
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.onPrimary,
                      backgroundImage: utilisateur.photoProfil != null
                          ? NetworkImage(utilisateur.photoProfil!)
                          : null,
                      child: utilisateur.photoProfil == null
                          ? const Icon(Icons.person, size: 44, color: AppColors.primary)
                          : null,
                    ),
                    if (estVerifie)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified, size: 18, color: AppColors.onAccent),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.gutter),
                Text(
                  utilisateur.nomComplet,
                  style: AppTextStyles.headlineSm.copyWith(color: AppColors.onPrimary),
                ),
                const SizedBox(height: AppSpacing.stackSm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield, size: 16, color: AppColors.onPrimary),
                      const SizedBox(width: 6),
                      Text(
                        '${utilisateur.scoreConfiance}% de confiance',
                        style: AppTextStyles.labelLg.copyWith(color: AppColors.onPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.containerPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Informations', style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                )),
                const SizedBox(height: AppSpacing.stackSm),
                _CarteInfo(icone: Icons.phone, label: 'Téléphone', valeur: utilisateur.telephone),
                if (utilisateur.email != null)
                  _CarteInfo(icone: Icons.email, label: 'Email', valeur: utilisateur.email!),
                _CarteInfo(icone: Icons.location_city, label: 'Ville', valeur: utilisateur.ville),
                _CarteInfo(icone: Icons.flag, label: 'Pays', valeur: utilisateur.pays),

                const SizedBox(height: AppSpacing.stackMd),
                Text('Compte', style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                )),
                const SizedBox(height: AppSpacing.stackSm),
                _TuileMenu(
                  icone: Icons.how_to_reg_outlined,
                  titre: 'Vérifications',
                  sousTitre: estVerifie
                      ? 'Téléphone et email vérifiés'
                      : 'Vérifie ton téléphone, ton email ou ton identité',
                  badge: estVerifie
                      ? const StatusBadge(label: 'Vérifié', type: StatusType.positive)
                      : null,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const VerificationScreen()),
                  ),
                ),
                _TuileMenu(
                  icone: Icons.qr_code_scanner_outlined,
                  titre: 'Vérifier un objet',
                  sousTitre: 'Plaque ou numéro de série — utile en contrôle',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const VerificationObjetScreen()),
                  ),
                ),
                if (utilisateur.role == 'Admin')
                  _TuileMenu(
                    icone: Icons.admin_panel_settings_outlined,
                    titre: 'Espace Admin',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                    ),
                  ),

                const SizedBox(height: AppSpacing.stackLg),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await authProvider.deconnecter();
                      if (!context.mounted) return;
                      // On revient à l'écran d'accueil déjà existant (route
                      // racine) plutôt que d'en pousser un nouveau : ça évite
                      // une double transition qui laissait apparaître un
                      // flash de la bannière "Connexion / S'inscrire" sur
                      // l'ancien HomeScreen pendant l'animation.
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Se déconnecter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarteInfo extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valeur;

  const _CarteInfo({required this.icone, required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.stackSm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.gutter),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.statusGreenBg, shape: BoxShape.circle),
            child: Icon(icone, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(valeur, style: AppTextStyles.bodyLg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TuileMenu extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String? sousTitre;
  final Widget? badge;
  final VoidCallback onTap;

  const _TuileMenu({
    required this.icone,
    required this.titre,
    this.sousTitre,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.stackSm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        leading: Icon(icone, color: AppColors.primary),
        title: Text(titre, style: AppTextStyles.labelLg),
        subtitle: sousTitre != null ? Text(sousTitre!, style: AppTextStyles.bodyMd) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null) ...[badge!, const SizedBox(width: 8)],
            const Icon(Icons.chevron_right, color: AppColors.outline),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}