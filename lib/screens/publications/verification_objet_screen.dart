import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/resultat_verification_model.dart';
import '../../services/publication_service.dart';
import '../../widgets/primary_button.dart';

/// Écran volontairement minimaliste : pensé pour être utilisé debout, en
/// pleine rue, en quelques secondes (contrôle routier, vérification d'un
/// objet). Un seul champ, un seul bouton, un résultat immédiat et clair —
/// pas de fil d'actualité, pas de filtres, pas de distraction.
class VerificationObjetScreen extends StatefulWidget {
  const VerificationObjetScreen({super.key});

  @override
  State<VerificationObjetScreen> createState() => _VerificationObjetScreenState();
}

class _VerificationObjetScreenState extends State<VerificationObjetScreen> {
  final _controller = TextEditingController();
  final _service = PublicationService();

  bool _recherche = false;
  bool _dejaRecherche = false;
  List<ResultatVerification> _resultats = [];
  String? _erreur;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verifier() async {
    final identifiant = _controller.text.trim();
    if (identifiant.isEmpty) return;

    setState(() {
      _recherche = true;
      _dejaRecherche = true;
      _erreur = null;
    });

    try {
      final resultats = await _service.verifierObjet(identifiant);
      if (!mounted) return;
      setState(() => _resultats = resultats);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = 'Erreur de connexion. Réessaie.');
    } finally {
      if (mounted) setState(() => _recherche = false);
    }
  }

  Future<void> _appeler(String telephone) async {
    final uri = Uri(scheme: 'tel', path: telephone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Vérification rapide'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.containerPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Plaque d\'immatriculation ou numéro de série',
                style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.stackSm),
              TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                style: AppTextStyles.headlineSm,
                decoration: InputDecoration(
                  hintText: 'Ex: TG 1234 AB',
                  prefixIcon: const Icon(Icons.qr_code_scanner_outlined),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _verifier(),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              PrimaryButton(
                label: 'Vérifier',
                chargement: _recherche,
                onPressed: _verifier,
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Expanded(child: _buildResultat()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultat() {
    if (!_dejaRecherche) {
      return const SizedBox.shrink();
    }

    if (_erreur != null) {
      return Center(
        child: Text(_erreur!, style: AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
      );
    }

    if (_resultats.isEmpty) {
      return _buildBandeauStatut(
        couleurFond: AppColors.statusGreenBg,
        couleurTexte: AppColors.primary,
        icone: Icons.check_circle_outline,
        titre: 'Aucun signalement',
        sousTitre: 'Cet identifiant ne correspond à aucune déclaration de perte active.',
      );
    }

    return ListView(
      children: [
        _buildBandeauStatut(
          couleurFond: AppColors.statusRedBg,
          couleurTexte: AppColors.error,
          icone: Icons.warning_amber_rounded,
          titre: '${_resultats.length} déclaration${_resultats.length > 1 ? 's' : ''} trouvée${_resultats.length > 1 ? 's' : ''}',
          sousTitre: 'Cet identifiant correspond à un objet signalé PERDU.',
        ),
        const SizedBox(height: AppSpacing.stackMd),
        ..._resultats.map(_buildCarteResultat),
      ],
    );
  }

  Widget _buildBandeauStatut({
    required Color couleurFond,
    required Color couleurTexte,
    required IconData icone,
    required String titre,
    required String sousTitre,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.containerPadding),
      decoration: BoxDecoration(
        color: couleurFond,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(icone, color: couleurTexte, size: 32),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: AppTextStyles.headlineSm.copyWith(color: couleurTexte)),
                const SizedBox(height: 4),
                Text(sousTitre, style: AppTextStyles.labelSm.copyWith(color: couleurTexte)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarteResultat(ResultatVerification pub) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.stackMd),
      padding: const EdgeInsets.all(AppSpacing.containerPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(pub.titre, style: AppTextStyles.headlineSm),
          const SizedBox(height: 4),
          if (pub.categorie != null)
            Text(pub.categorie!, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.stackSm),
          _ligneInfo(Icons.calendar_today_outlined,
              'Signalé le ${pub.dateEvenement.day}/${pub.dateEvenement.month}/${pub.dateEvenement.year}'),
          _ligneInfo(Icons.location_on_outlined, [pub.quartier, pub.ville].where((s) => s != null && s.isNotEmpty).join(', ')),
          if (pub.declarant != null) ...[
            _ligneInfo(Icons.person_outline, 'Déclarant : ${pub.declarant!.nomComplet}'),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.stackSm),
              child: OutlinedButton.icon(
                onPressed: () => _appeler(pub.declarant!.telephone),
                icon: const Icon(Icons.call_outlined, size: 18),
                label: Text('Appeler ${pub.declarant!.telephone}'),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.stackSm),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Coordonnées réservées aux comptes Police',
                      style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _ligneInfo(IconData icone, String texte) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icone, size: 14, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(child: Text(texte, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant))),
        ],
      ),
    );
  }
}