import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import 'login_screen.dart';
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

    final authProvider = context.read<AuthProvider>();
    final succes = await authProvider.inscrire(
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      telephone: _telephoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      password: _passwordController.text,
      ville: _villeController.text.trim(),
      pays: _paysController.text.trim(),
    );

    if (!mounted) return;

    if (succes) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(telephone: _telephoneController.text.trim()),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.erreur ?? 'Erreur lors de l\'inscription')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerPadding,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tête : logo + titre + sous-titre
                Center(
                  child: Image.asset(
                    'assets/images/logoanti.png',
                    height: 96,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                const Text(
                  'Inscription',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displayLg,
                ),
                const SizedBox(height: AppSpacing.stackSm),
                Text(
                  'Rejoignez la communauté pour retrouver vos objets perdus.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                // Carte de formulaire (fond blanc, radius 20px, ombre douce) —
                // même traitement visuel que l'écran de connexion, pour que
                // les deux écrans du flux d'authentification soient cohérents.
                Container(
                  padding: const EdgeInsets.all(AppSpacing.containerPadding),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.surfaceContainer),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                      const SizedBox(height: AppSpacing.stackMd),
                      CustomTextField(
                        controller: _telephoneController,
                        label: 'Téléphone',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email (optionnel)',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.mail_outline,
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
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
                          onPressed: () => setState(
                            () => _motDePasseVisible = !_motDePasseVisible,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requis';
                          if (v.length < 8) return 'Minimum 8 caractères';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      CustomTextField(
                        controller: _villeController,
                        label: 'Ville',
                        prefixIcon: Icons.location_city_outlined,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      CustomTextField(
                        controller: _paysController,
                        label: 'Pays',
                        prefixIcon: Icons.public_outlined,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      PrimaryButton(
                        label: "S'inscrire",
                        chargement: authProvider.chargement,
                        onPressed: _sInscrire,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                // Lien vers la connexion — absent auparavant : un utilisateur
                // arrivé ici par erreur n'avait que la flèche retour pour s'en sortir.
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      children: [
                        const TextSpan(text: 'Déjà un compte ? '),
                        TextSpan(
                          text: 'Se connecter',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}