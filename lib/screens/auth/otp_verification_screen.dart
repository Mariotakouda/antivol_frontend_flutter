import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/primary_button.dart';
import '../home/home_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String telephone;

  const OtpVerificationScreen({super.key, required this.telephone});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const _dureeAvantRenvoi = 45;

  // Contrôleur unique conservé tel quel : c'est lui que _verifier() lit.
  // Les 6 cases ci-dessous ne font que le tenir à jour.
  final _codeController = TextEditingController();
  final _digitControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

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
    setState(() {}); // pour rafraîchir l'état (bordures, bouton actif/inactif)
  }

  bool get _codeComplet => _digitControllers.every((c) => c.text.isNotEmpty);

  Future<void> _verifier() async {
    final authProvider = context.read<AuthProvider>();
    final succes = await authProvider.verifierOtp(
      telephone: widget.telephone,
      code: _codeController.text.trim(),
    );

    if (!mounted) return;

    if (succes) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.popUntil((route) => route.isFirst);
      } else {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.erreur ?? 'Code invalide')),
      );
    }
  }

  Future<void> _renvoyerCode() async {
    setState(() => _envoiEnCours = true);
    await context.read<AuthProvider>().renvoyerOtp(widget.telephone);
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final peutRevenirEnArriere = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              title: 'Vérifie ton numéro',
              subtitle: 'Un code à 6 chiffres a été envoyé au ${widget.telephone}',
              showLogo: false,
              onBack: peutRevenirEnArriere ? () => Navigator.of(context).pop() : null,
            ),
            AuthSheet(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AuthIconBadge(icon: Icons.sms_outlined)),
                  const SizedBox(height: AppSpacing.stackLg),
                  OtpDigitsRow(
                    controllers: _digitControllers,
                    focusNodes: _focusNodes,
                    onChanged: _onDigitChanged,
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  OtpResendCountdown(
                    secondesRestantes: _secondesRestantes,
                    envoiEnCours: _envoiEnCours,
                    onRenvoyer: _renvoyerCode,
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  PrimaryButton(
                    label: 'Vérifier',
                    chargement: authProvider.chargement,
                    onPressed: _codeComplet ? _verifier : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
