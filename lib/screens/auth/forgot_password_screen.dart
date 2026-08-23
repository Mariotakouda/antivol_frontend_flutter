import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/primary_button.dart';
import 'reset_password_screen.dart';

/// Première étape du parcours "mot de passe oublié" : l'utilisateur saisit
/// son numéro de téléphone pour recevoir un code de réinitialisation
/// (réutilise le même mécanisme SMS que l'OTP d'inscription).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telephoneController = TextEditingController();

  @override
  void dispose() {
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _envoyerCode() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final telephone = _telephoneController.text.trim();
    final succes = await authProvider.demanderReinitialisationMotDePasse(telephone);

    if (!mounted) return;

    if (succes) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(telephone: telephone),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.erreur ?? 'Numéro introuvable')),
      );
    }
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
              title: 'Mot de passe oublié',
              subtitle: 'Pas de panique, ça arrive à tout le monde.',
              showLogo: false,
              onBack: () => Navigator.of(context).pop(),
            ),
            AuthSheet(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AuthIconBadge(icon: Icons.lock_reset)),
                    const SizedBox(height: AppSpacing.stackLg),
                    Text(
                      'Entre ton numéro de téléphone, on t\'envoie un code pour réinitialiser ton mot de passe.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    CustomTextField(
                      controller: _telephoneController,
                      label: 'Téléphone',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.person_outline,
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Le téléphone est requis'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    PrimaryButton(
                      label: 'Recevoir le code',
                      chargement: authProvider.chargement,
                      onPressed: _envoyerCode,
                    ),
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
