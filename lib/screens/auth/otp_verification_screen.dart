import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
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

  String get _minutesSecondes {
    final m = (_secondesRestantes ~/ 60).toString().padLeft(2, '0');
    final s = (_secondesRestantes % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final peutRenvoyer = _secondesRestantes == 0 && !_envoiEnCours;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.containerPadding,
            ),
            child: Container(
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icône dans un cercle vert clair
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.statusGreenBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smartphone_outlined,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  const Text(
                    'Vérifiez votre numéro',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineMd,
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Un code à 6 chiffres a été envoyé au ${widget.telephone}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  // 6 cases OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      final actif = _focusNodes[index].hasFocus ||
                          _digitControllers[index].text.isNotEmpty;
                      return SizedBox(
                        width: 44,
                        height: 56,
                        child: TextField(
                          controller: _digitControllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: AppTextStyles.headlineSm,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.input),
                              borderSide: BorderSide(
                                color: actif
                                    ? AppColors.primary
                                    : AppColors.outlineVariant,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.input),
                              borderSide: BorderSide(
                                color: actif
                                    ? AppColors.primary
                                    : AppColors.outlineVariant,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.input),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (value) => _onDigitChanged(index, value),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  // Compte à rebours / lien de renvoi
                  if (_secondesRestantes > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text.rich(
                          TextSpan(
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                            children: [
                              const TextSpan(text: 'Renvoyer le code dans '),
                              TextSpan(
                                text: _minutesSecondes,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    TextButton(
                      onPressed: peutRenvoyer ? _renvoyerCode : null,
                      child: Text(_envoiEnCours ? 'Envoi...' : 'Renvoyer le code'),
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
          ),
        ),
      ),
    );
  }
}