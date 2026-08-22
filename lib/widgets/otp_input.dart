import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';

/// Rangée de 6 cases pour la saisie d'un code OTP, avec avancement
/// automatique du focus. Auparavant dupliqué à l'identique dans
/// otp_verification_screen.dart et reset_password_screen.dart — un seul
/// bug ou ajustement visuel devait sinon être répété deux fois.
class OtpDigitsRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;

  const OtpDigitsRow({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(controllers.length, (index) {
        final actif = focusNodes[index].hasFocus || controllers[index].text.isNotEmpty;
        return SizedBox(
          width: 44,
          height: 56,
          child: TextField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: AppTextStyles.headlineSm,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide(
                  color: actif ? AppColors.primary : AppColors.outlineVariant,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: BorderSide(
                  color: actif ? AppColors.primary : AppColors.outlineVariant,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onChanged: (value) => onChanged(index, value),
          ),
        );
      }),
    );
  }
}

/// Compte à rebours "Renvoyer le code dans MM:SS" / lien de renvoi actif —
/// même logique d'affichage dupliquée dans les deux écrans OTP.
class OtpResendCountdown extends StatelessWidget {
  final int secondesRestantes;
  final bool envoiEnCours;
  final VoidCallback onRenvoyer;

  const OtpResendCountdown({
    super.key,
    required this.secondesRestantes,
    required this.envoiEnCours,
    required this.onRenvoyer,
  });

  String get _minutesSecondes {
    final m = (secondesRestantes ~/ 60).toString().padLeft(2, '0');
    final s = (secondesRestantes % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (secondesRestantes > 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.schedule, size: 14, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text.rich(
            TextSpan(
              style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
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
      );
    }
    final peutRenvoyer = !envoiEnCours;
    return Center(
      child: TextButton(
        onPressed: peutRenvoyer ? onRenvoyer : null,
        child: Text(envoiEnCours ? 'Envoi...' : 'Renvoyer le code'),
      ),
    );
  }
}

/// Icône ronde teintée utilisée en tête des écrans "mot de passe oublié" /
/// OTP / réinitialisation — même badge dupliqué trois fois auparavant.
class AuthIconBadge extends StatelessWidget {
  final IconData icon;

  const AuthIconBadge({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.statusGreenBg,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primary, size: 32),
    );
  }
}
