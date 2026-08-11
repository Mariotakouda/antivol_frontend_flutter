import 'package:flutter/material.dart';
import '../../core/errors/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/primary_button.dart';

/// Écran admin : liste des comptes Police existants + création d'un
/// nouveau compte. Remplace la commande CLI `police:creer` utilisée
/// pour les tout premiers tests.
class PoliceAccountsScreen extends StatefulWidget {
  const PoliceAccountsScreen({super.key});

  @override
  State<PoliceAccountsScreen> createState() => _PoliceAccountsScreenState();
}

class _PoliceAccountsScreenState extends State<PoliceAccountsScreen> {
  final _service = AdminService();
  List<UserModel> _agents = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _ouvrirDetailAgent(UserModel agent) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _FicheDetailAgent(
        agent: agent,
        onRevoquer: () {
          Navigator.of(sheetContext).pop();
          _revoquer(agent);
        },
      ),
    );
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    try {
      final resultat = await _service.listerComptesPolice();
      if (!mounted) return;
      setState(() {
        _agents = resultat.data;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  Future<void> _revoquer(UserModel agent) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Révoquer cet accès ?'),
        content: Text(
          '${agent.nomComplet} repassera en compte utilisateur classique et sera déconnecté de tous ses appareils.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Révoquer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    try {
      await _service.revoquerCompteApolice(agent.id);
      await _charger();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Accès de ${agent.nomComplet} révoqué.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action impossible.')),
      );
    }
  }

  Future<void> _ouvrirFormulaireCreation() async {
    final cree = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FormulaireCreationAgent(),
    );

    if (cree == true) {
      _charger();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Comptes Police')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ouvrirFormulaireCreation,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau compte'),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _agents.isEmpty
              ? const EmptyStateWidget(
                  icone: Icons.local_police_outlined,
                  titre: 'Aucun compte Police',
                  message: 'Crée le premier compte avec le bouton ci-dessous.',
                )
              : RefreshIndicator(
                  onRefresh: _charger,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.containerPadding,
                      AppSpacing.stackSm,
                      AppSpacing.containerPadding,
                      88, // place pour le FAB
                    ),
                    itemCount: _agents.length,
                    itemBuilder: (context, index) {
                      final agent = _agents[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        onTap: () => _ouvrirDetailAgent(agent),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.stackSm),
                          padding: const EdgeInsets.all(AppSpacing.gutter),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.surfaceContainer),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: AppColors.statusGreenBg,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.local_police_outlined, color: AppColors.primary),
                              ),
                              const SizedBox(width: AppSpacing.gutter),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(agent.nomComplet, style: AppTextStyles.labelLg),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Matricule ${agent.matricule ?? '—'} · ${agent.posteRattachement ?? '—'}',
                                      style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                                    ),
                                    Text(
                                      agent.telephone,
                                      style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

/// Formulaire de création, en bottom sheet pour rester léger — pas besoin
/// d'un écran entier pour 6 champs.
class _FormulaireCreationAgent extends StatefulWidget {
  const _FormulaireCreationAgent();

  @override
  State<_FormulaireCreationAgent> createState() => _FormulaireCreationAgentState();
}

class _FormulaireCreationAgentState extends State<_FormulaireCreationAgent> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _matriculeController = TextEditingController();
  final _posteController = TextEditingController();
  final _passwordController = TextEditingController();

  final _service = AdminService();
  bool _envoiEnCours = false;
  bool _motDePasseVisible = false;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _matriculeController.dispose();
    _posteController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _creer() async {
    if (_envoiEnCours) return; // garde anti-double-clic (double-tap rapide sur web)
    if (!_formKey.currentState!.validate()) return;

    setState(() => _envoiEnCours = true);

    try {
      final agent = await _service.creerCompteApolice(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        telephone: _telephoneController.text.trim(),
        matricule: _matriculeController.text.trim(),
        posteRattachement: _posteController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _envoiEnCours = false);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 32),
          title: const Text('Compte créé'),
          content: Text(
            '${agent.nomComplet} peut maintenant se connecter avec le téléphone '
            '${agent.telephone} et le mot de passe que tu lui communiques : '
            '${_passwordController.text}',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(); // ferme le dialogue
                Navigator.of(context).pop(true); // ferme le formulaire, retour à la liste
              },
              child: const Text('Retour à la liste'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _envoiEnCours = false);
      final message = e is ApiException ? e.toString() : 'Création impossible.';

      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.error_outline, color: AppColors.error, size: 32),
          title: const Text('Échec de la création'),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(), // reste sur le formulaire pour corriger
              child: const Text('Retour au formulaire'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerPadding,
          AppSpacing.stackMd,
          AppSpacing.containerPadding,
          AppSpacing.stackLg,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Nouveau compte Police', style: AppTextStyles.headlineSm),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Fermer',
                      onPressed: _envoiEnCours ? null : () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackSm),
                Text(
                  'À ne créer qu\'après avoir vérifié l\'identité de l\'agent (badge, poste).',
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                CustomTextField(
                  controller: _prenomController,
                  label: 'Prénom',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: AppSpacing.stackMd),
                CustomTextField(
                  controller: _nomController,
                  label: 'Nom',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: AppSpacing.stackMd),
                CustomTextField(
                  controller: _telephoneController,
                  label: 'Téléphone',
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: AppSpacing.stackMd),
                CustomTextField(
                  controller: _matriculeController,
                  label: 'Matricule (numéro de badge)',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: AppSpacing.stackMd),
                CustomTextField(
                  controller: _posteController,
                  label: 'Poste de rattachement',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: AppSpacing.stackMd),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Mot de passe initial',
                  obscureText: !_motDePasseVisible,
                  suffixIcon: IconButton(
                    icon: Icon(_motDePasseVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _motDePasseVisible = !_motDePasseVisible),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if (v.length < 8) return '8 caractères minimum';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.stackLg),
                PrimaryButton(
                  label: 'Créer le compte',
                  chargement: _envoiEnCours,
                  onPressed: _creer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fiche détaillée d'un agent, ouverte en tapant sur une ligne de la liste.
/// Lecture seule (pas d'édition ici) + accès rapide à la révocation.
class _FicheDetailAgent extends StatelessWidget {
  final UserModel agent;
  final VoidCallback onRevoquer;

  const _FicheDetailAgent({required this.agent, required this.onRevoquer});

  Widget _ligne(String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(valeur, style: AppTextStyles.bodyMd),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPadding,
        AppSpacing.stackMd,
        AppSpacing.containerPadding,
        AppSpacing.stackLg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.statusGreenBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_police_outlined, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: AppSpacing.gutter),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(agent.nomComplet, style: AppTextStyles.headlineSm),
                      Text(
                        agent.statut == 'Actif' ? 'Compte actif' : agent.statut,
                        style: AppTextStyles.labelSm.copyWith(
                          color: agent.statut == 'Actif' ? AppColors.primary : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Fermer',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackLg),
            _ligne('Téléphone', agent.telephone),
            _ligne('Matricule', agent.matricule ?? '—'),
            _ligne('Poste de rattachement', agent.posteRattachement ?? '—'),
            _ligne('Ville', agent.ville),
            if (agent.email != null && agent.email!.isNotEmpty) _ligne('Email', agent.email!),
            _ligne('Téléphone vérifié', agent.telephoneVerifie ? 'Oui' : 'Non'),
            const SizedBox(height: AppSpacing.stackMd),
            OutlinedButton.icon(
              onPressed: onRevoquer,
              icon: const Icon(Icons.person_remove_outlined, color: AppColors.error),
              label: const Text('Révoquer l\'accès', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}