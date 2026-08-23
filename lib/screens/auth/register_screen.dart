import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _villeController = TextEditingController();
  final _paysController = TextEditingController(text: 'Togo');
  bool _motDePasseVisible = false;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _villeController.dispose();
    _paysController.dispose();
    super.dispose();
  }

  Future<void> _sInscrire() async {
    if (!_formKey.currentState!.validate()) return;

    final telephone = _telephoneController.text.trim();
    final confirme = await _confirmerNumero(telephone);
    if (!confirme) return;

    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final succes = await authProvider.inscrire(
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      telephone: telephone,
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      password: _passwordController.text,
      ville: _villeController.text.trim(),
      pays: _paysController.text.trim(),
    );

    if (!mounted) return;

    if (succes) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(telephone: telephone),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.erreur ?? 'Erreur lors de l\'inscription')),
      );
    }
  }

  /// Confirmation du numéro avant envoi réel, façon WhatsApp : attrape les
  /// fautes de frappe avant même d'appeler l'API (l'OTP qui suit vérifie
  /// autre chose — que le SMS est bien reçu — les deux se complètent).
  Future<bool> _confirmerNumero(String telephone) async {
    final resultat = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.smartphone_outlined, color: AppColors.primary, size: 32),
        title: const Text('Ce numéro est-il correct ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Tu recevras un code de vérification à ce numéro :"),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              telephone,
              style: AppTextStyles.headlineSm.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Modifier'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );

    return resultat == true;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              title: 'Créer un compte',
              subtitle: 'Rejoins la communauté pour retrouver tes objets.',
              showLogo: false,
              onBack: () => Navigator.of(context).pop(),
            ),
            AuthSheet(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionLabel('Identité'),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _prenomController,
                            label: 'Prénom',
                            prefixIcon: Icons.person_outline,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Requis' : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.gutter),
                        Expanded(
                          child: CustomTextField(
                            controller: _nomController,
                            label: 'Nom',
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Requis' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    const _SectionLabel('Contact'),
                    CustomTextField(
                      controller: _telephoneController,
                      label: 'Téléphone',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email (optionnel)',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.mail_outline,
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    const _SectionLabel('Sécurité'),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      obscureText: !_motDePasseVisible,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _motDePasseVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _motDePasseVisible = !_motDePasseVisible),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        if (v.length < 8) return 'Minimum 8 caractères';
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '8 caractères minimum.',
                      style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    const _SectionLabel('Localisation'),
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
                      prefixIcon: Icons.public_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    PrimaryButton(
                      label: "S'inscrire",
                      chargement: authProvider.chargement,
                      onPressed: _sInscrire,
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Petit intitulé de section (eyebrow) pour donner une hiérarchie au long
/// formulaire d'inscription — 7 champs à plat sans repère sont difficiles
/// à scanner visuellement, ces libellés découpent le parcours.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.stackSm),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}