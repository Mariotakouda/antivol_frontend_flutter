import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _prenomController;
  late final TextEditingController _emailController;
  late final TextEditingController _villeController;
  late final TextEditingController _paysController;

  @override
  void initState() {
    super.initState();
    final utilisateur = context.read<AuthProvider>().utilisateur!;
    _nomController = TextEditingController(text: utilisateur.nom);
    _prenomController = TextEditingController(text: utilisateur.prenom);
    _emailController = TextEditingController(text: utilisateur.email ?? '');
    _villeController = TextEditingController(text: utilisateur.ville);
    _paysController = TextEditingController(text: utilisateur.pays);
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _villeController.dispose();
    _paysController.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;

    final profileProvider = context.read<ProfileProvider>();
    final succes = await profileProvider.modifier(
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      ville: _villeController.text.trim(),
      pays: _paysController.text.trim(),
    );

    if (!mounted) return;

    if (succes) {
      // Propage les nouvelles infos à AuthProvider pour que le reste de l'app soit à jour.
      context.read<AuthProvider>().mettreAJourUtilisateur(profileProvider.utilisateur!);
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(profileProvider.erreur ?? 'Erreur lors de la mise à jour')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final utilisateur = context.watch<AuthProvider>().utilisateur;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Modifier le profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.statusGreenBg,
                  backgroundImage: utilisateur?.photoProfil != null
                      ? NetworkImage(utilisateur!.photoProfil!)
                      : null,
                  child: utilisateur?.photoProfil == null
                      ? const Icon(Icons.person, size: 44, color: AppColors.primary)
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Text(
                'Informations personnelles',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.gutter),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _prenomController,
                      label: 'Prénom',
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: CustomTextField(
                      controller: _nomController,
                      label: 'Nom',
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackMd),
              CustomTextField(
                controller: _emailController,
                label: 'Email (optionnel)',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: AppSpacing.stackMd),
              CustomTextField(
                controller: _villeController,
                label: 'Ville',
                prefixIcon: Icons.location_city_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: AppSpacing.stackMd),
              CustomTextField(
                controller: _paysController,
                label: 'Pays',
                prefixIcon: Icons.flag_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: AppSpacing.stackLg),
              PrimaryButton(
                label: 'Enregistrer',
                chargement: profileProvider.chargement,
                onPressed: _enregistrer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}