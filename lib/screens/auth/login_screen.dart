import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../home/home_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _motDePasseVisible = false;

  @override
  void dispose() {
    _telephoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final succes = await authProvider.connecter(
      telephone: _telephoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (succes) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop(true);
      } else {
        navigator.pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.erreur ?? 'Erreur de connexion')),
      );
    }
  }

  void _motDePasseOublie() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
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
                const SizedBox(height: 11),
                Center(
                  child: Image(
                    image: const AssetImage('assets/images/logoanti.png'),
                    width: 150,
                    height: 159,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                const Text(
                  'Connexion',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displayLg,
                ),
                const SizedBox(height: AppSpacing.stackLg),
                // Carte de formulaire (fond blanc, radius 20px, ombre douce)
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
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'Le mot de passe est requis' : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _motDePasseOublie,
                          child: const Text('Mot de passe oublié ?'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.stackSm),
                      PrimaryButton(
                        label: 'Se connecter',
                        chargement: authProvider.chargement,
                        onPressed: _seConnecter,
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                            children: [
                              const TextSpan(text: "Pas encore de compte ? "),
                              TextSpan(
                                text: "S'inscrire",
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const RegisterScreen(),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
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