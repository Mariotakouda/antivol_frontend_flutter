import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerPadding,
            vertical: AppSpacing.stackLg,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.statusGreenBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                const Text(
                  'Mot de passe oublié',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displayLg,
                ),
                const SizedBox(height: AppSpacing.stackSm),
                Text(
                  'Entre ton numéro de téléphone, on t\'envoie un code pour réinitialiser ton mot de passe.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.stackLg),
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
                      CustomTextField(
                        controller: _telephoneController,
                        label: 'Téléphone',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.person_outline,
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Le téléphone est requis'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      PrimaryButton(
                        label: 'Recevoir le code',
                        chargement: authProvider.chargement,
                        onPressed: _envoyerCode,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}