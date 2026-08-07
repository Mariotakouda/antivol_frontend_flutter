import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/verification_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/verification_service.dart';

/// Permet à l'utilisateur de consulter le statut de ses vérifications
/// (téléphone, email, identité) et de soumettre une demande pour celles
/// qui manquent. Le téléphone/email sont considérés vérifiés directement
/// via les booléens du profil (source la plus fiable) ; l'identité n'a
/// pas d'équivalent sur User, donc on se base sur la dernière demande de
/// vérification de type IDENTITE.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _service = VerificationService();

  List<VerificationModel> _verifications = [];
  bool _chargement = true;
  String? _erreur;
  final Set<String> _envoiEnCours = {};

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final verifications = await _service.mesVerifications();
      // La plus récente d'abord, peu importe l'ordre renvoyé par l'API.
      verifications.sort((a, b) => b.id.compareTo(a.id));
      if (!mounted) return;
      setState(() {
        _verifications = verifications;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erreur = 'Impossible de charger tes vérifications.';
        _chargement = false;
      });
    }
  }

  VerificationModel? _derniere(String type) {
    for (final v in _verifications) {
      if (v.type == type) return v;
    }
    return null;
  }

  Future<void> _soumettre(String type, {List<int>? documentBytes, String? documentNom}) async {
    setState(() => _envoiEnCours.add(type));
    try {
      await _service.soumettre(type: type, documentBytes: documentBytes, documentNom: documentNom);
      await _charger();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande envoyée, en attente de validation.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Échec de l'envoi de la demande")),
      );
    } finally {
      if (mounted) setState(() => _envoiEnCours.remove(type));
    }
  }

  Future<void> _soumettreIdentite() async {
    final resultat = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true, // indispensable sur le web : pas d'accès à un chemin de fichier réel
    );
    final fichier = resultat?.files.single;
    if (fichier?.bytes == null) return;

    await _soumettre('IDENTITE', documentBytes: fichier!.bytes, documentNom: fichier.name);
  }

  @override
  Widget build(BuildContext context) {
    final utilisateur = context.watch<AuthProvider>().utilisateur;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Vérifications')),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _erreur != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_erreur!, style: AppTextStyles.bodyMd),
                      const SizedBox(height: AppSpacing.gutter),
                      OutlinedButton(onPressed: _charger, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _charger,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.containerPadding),
                    children: [
                      Text(
                        "Un profil vérifié inspire davantage confiance aux autres utilisateurs et augmente ton score de confiance.",
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      _CarteVerification(
                        icone: Icons.phone_iphone,
                        titre: 'Téléphone',
                        dejaVerifie: utilisateur?.telephoneVerifie ?? false,
                        verification: _derniere('TELEPHONE'),
                        enCours: _envoiEnCours.contains('TELEPHONE'),
                        onSoumettre: () => _soumettre('TELEPHONE'),
                      ),
                      const SizedBox(height: AppSpacing.gutter),
                      _CarteVerification(
                        icone: Icons.email_outlined,
                        titre: 'Email',
                        dejaVerifie: utilisateur?.emailVerifie ?? false,
                        verification: _derniere('EMAIL'),
                        enCours: _envoiEnCours.contains('EMAIL'),
                        onSoumettre: () => _soumettre('EMAIL'),
                      ),
                      const SizedBox(height: AppSpacing.gutter),
                      _CarteVerification(
                        icone: Icons.badge_outlined,
                        titre: "Pièce d'identité",
                        dejaVerifie: _derniere('IDENTITE')?.statut == 'VALIDE',
                        verification: _derniere('IDENTITE'),
                        enCours: _envoiEnCours.contains('IDENTITE'),
                        onSoumettre: _soumettreIdentite,
                        libelleAction: 'Téléverser (photo ou PDF)',
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _CarteVerification extends StatelessWidget {
  final IconData icone;
  final String titre;
  final bool dejaVerifie;
  final VerificationModel? verification;
  final bool enCours;
  final VoidCallback onSoumettre;
  final String libelleAction;

  const _CarteVerification({
    required this.icone,
    required this.titre,
    required this.dejaVerifie,
    required this.verification,
    required this.enCours,
    required this.onSoumettre,
    this.libelleAction = 'Envoyer une demande',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.containerPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.surfaceContainer),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.statusGreenBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icone, size: 24, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: AppTextStyles.labelLg),
                const SizedBox(height: 6),
                _buildStatut(),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          _buildAction(),
        ],
      ),
    );
  }

  Widget _buildStatut() {
    if (dejaVerifie) {
      return const StatusBadge(label: 'Vérifié', type: StatusType.positive);
    }
    switch (verification?.statut) {
      case 'EN_ATTENTE':
        return const StatusBadge(label: 'En attente', type: StatusType.warning);
      case 'REFUSE':
        return const StatusBadge(label: 'Refusée', type: StatusType.negative);
      default:
        return Text(
          'Non vérifié',
          style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
        );
    }
  }

  Widget _buildAction() {
    if (dejaVerifie) {
      return const Icon(Icons.check_circle, color: AppColors.primary);
    }
    if (verification?.statut == 'EN_ATTENTE') {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
      );
    }
    if (enCours) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
      );
    }
    return TextButton(
      onPressed: onSoumettre,
      child: Text(verification?.statut == 'REFUSE' ? 'Réessayer' : libelleAction),
    );
  }
}
