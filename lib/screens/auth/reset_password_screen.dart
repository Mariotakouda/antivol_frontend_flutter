import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/primary_button.dart';
import '../home/home_screen.dart';

/// Deuxième étape du parcours "mot de passe oublié" : saisie du code à 6
/// chiffres reçu par SMS, puis du nouveau mot de passe. En cas de succès,
/// le backend renvoie un token valide, donc l'utilisateur est reconnecté
/// automatiquement — pas besoin de repasser par l'écran de login.
class ResetPasswordScreen extends StatefulWidget {
  final String telephone;

  const ResetPasswordScreen({super.key, required this.telephone});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const _dureeAvantRenvoi = 45;

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _digitControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _motDePasseVisible = false;
  bool _envoiEnCours = false;
  Timer? _timer;
  int _secondesRestantes = _dureeAvantRenvoi;

  @override
  void initState() {
    super.initState();
    _demarrerCompteARebours();
    for (final f in _focusNodes) {
      f.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _passwordController.dispose();
    _confirmationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _demarrerCompteARebours() {
    _timer?.cancel();
    setState(() => _secondesRestantes = _dureeAvantRenvoi);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondesRestantes <= 1) {
        timer.cancel();
        setState(() => _secondesRestantes = 0);
      } else {
        setState(() => _secondesRestantes--);
      }
    });
  }

  void _majCodeComplet() {
    _codeController.text = _digitControllers.map((c) => c.text).join();
  }

  void _onDigitChanged(int index, String value) {
    _majCodeComplet();
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  bool get _codeComplet => _digitControllers.every((c) => c.text.isNotEmpty);

  Future<void> _renvoyerCode() async {
    setState(() => _envoiEnCours = true);
    await context.read<AuthProvider>().demanderReinitialisationMotDePasse(widget.telephone);
    if (!mounted) return;
    setState(() => _envoiEnCours = false);
    for (final c in _digitControllers) {
      c.clear();
    }
    _codeController.clear();
    _demarrerCompteARebours();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Un nouveau code a été envoyé.')),
    );
  }

  Future<void> _reinitialiser() async {
    if (!_codeComplet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entre le code à 6 chiffres reçu par SMS.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final succes = await authProvider.reinitialiserMotDePasse(
      telephone: widget.telephone,
      code: _codeController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (succes) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe réinitialisé avec succès.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.erreur ?? 'Code invalide ou expiré.')),
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
              title: 'Nouveau mot de passe',
              subtitle: 'Code envoyé au ${widget.telephone}',
              showLogo: false,
              // Étape 2 d'un parcours de récupération : "Ignorer" plutôt
              // qu'une flèche retour, pour ne pas laisser croire qu'on peut
              // revenir à l'étape précédente en gardant le code déjà saisi.
              backLabel: 'Ignorer',
              onBack: () => Navigator.of(context).popUntil((route) => route.isFirst),
            ),
            AuthSheet(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OtpDigitsRow(
                      controllers: _digitControllers,
                      focusNodes: _focusNodes,
                      onChanged: _onDigitChanged,
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    OtpResendCountdown(
                      secondesRestantes: _secondesRestantes,
                      envoiEnCours: _envoiEnCours,
                      onRenvoyer: _renvoyerCode,
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Nouveau mot de passe',
                      obscureText: !_motDePasseVisible,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _motDePasseVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(() => _motDePasseVisible = !_motDePasseVisible),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Le mot de passe est requis';
                        if (value.length < 8) return '8 caractères minimum';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    CustomTextField(
                      controller: _confirmationController,
                      label: 'Confirmer le mot de passe',
                      obscureText: !_motDePasseVisible,
                      prefixIcon: Icons.lock_outline,
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    PrimaryButton(
                      label: 'Réinitialiser',
                      chargement: authProvider.chargement,
                      onPressed: _reinitialiser,
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
