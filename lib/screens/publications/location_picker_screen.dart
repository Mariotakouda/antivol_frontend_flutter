import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

/// Résultat renvoyé par [LocationPickerScreen] : coordonnées + adresse.
class LieuSelectionne {
  final double latitude;
  final double longitude;
  final String adresse;
  final String quartier;
  final String ville;
  final String pays;

  LieuSelectionne({
    required this.latitude,
    required this.longitude,
    required this.adresse,
    required this.quartier,
    required this.ville,
    required this.pays,
  });
}

/// Ecran de saisie de l'emplacement, sans carte (pas de dépendance payante) :
/// un bouton "Utiliser ma position actuelle" récupère les coordonnées GPS
/// et pré-remplit l'adresse par géocodage inverse (gratuit, service natif
/// Android/iOS). L'utilisateur peut ensuite corriger les champs à la main —
/// utile en intérieur ou si le GPS se trompe de quartier.
class LocationPickerScreen extends StatefulWidget {
  final LieuSelectionne? lieuInitial;

  const LocationPickerScreen({super.key, this.lieuInitial});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _adresseController = TextEditingController();
  final _quartierController = TextEditingController();
  final _villeController = TextEditingController();
  final _paysController = TextEditingController(text: 'Togo');

  double? _latitude;
  double? _longitude;
  bool _localisationEnCours = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    final lieu = widget.lieuInitial;
    if (lieu != null) {
      _latitude = lieu.latitude;
      _longitude = lieu.longitude;
      _adresseController.text = lieu.adresse;
      _quartierController.text = lieu.quartier;
      _villeController.text = lieu.ville;
      _paysController.text = lieu.pays;
    }
  }

  @override
  void dispose() {
    _adresseController.dispose();
    _quartierController.dispose();
    _villeController.dispose();
    _paysController.dispose();
    super.dispose();
  }

  Future<void> _utiliserPositionActuelle() async {
    setState(() {
      _localisationEnCours = true;
      _erreur = null;
    });

    try {
      final serviceActif = await Geolocator.isLocationServiceEnabled();
      if (!serviceActif) {
        throw Exception('Active la localisation dans les paramètres du téléphone.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception("Autorise l'accès à la localisation pour continuer.");
      }

      final position = await Geolocator.getCurrentPosition();
      _latitude = position.latitude;
      _longitude = position.longitude;

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final lieu = placemarks.first;
          _adresseController.text = [lieu.street, lieu.subLocality]
              .where((s) => s != null && s.isNotEmpty)
              .join(', ');
          _quartierController.text = lieu.subLocality ?? '';
          _villeController.text = lieu.locality ?? '';
          if (lieu.country != null && lieu.country!.isNotEmpty) {
            _paysController.text = lieu.country!;
          }
        }
      } catch (_) {
        // Le géocodage peut échouer (pas de réseau, pas de service dispo) :
        // on garde les coordonnées GPS et laisse l'utilisateur remplir
        // l'adresse à la main.
      }
    } catch (e) {
      _erreur = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _localisationEnCours = false);
    }
  }

  void _confirmer() {
    if (_latitude == null || _longitude == null) {
      setState(() => _erreur = 'Utilise ta position actuelle pour capter les coordonnées.');
      return;
    }
    if (_villeController.text.trim().isEmpty) {
      setState(() => _erreur = 'La ville est obligatoire.');
      return;
    }

    Navigator.of(context).pop(
      LieuSelectionne(
        latitude: _latitude!,
        longitude: _longitude!,
        adresse: _adresseController.text.trim(),
        quartier: _quartierController.text.trim(),
        ville: _villeController.text.trim(),
        pays: _paysController.text.trim().isNotEmpty ? _paysController.text.trim() : 'Togo',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text("Emplacement")),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.containerPadding),
        children: [
          // Bloc géolocalisation : carte verte claire avec bouton GPS
          Container(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            decoration: BoxDecoration(
              color: AppColors.statusGreenBg,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _localisationEnCours ? null : _utiliserPositionActuelle,
                  icon: _localisationEnCours
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _latitude != null ? Icons.check_circle : Icons.my_location,
                          color: AppColors.primary,
                        ),
                  label: Text(
                    _latitude != null ? 'Position mise à jour' : 'Utiliser ma position actuelle',
                  ),
                ),
                const SizedBox(height: AppSpacing.stackSm),
                Text(
                  "Ta position sert à afficher l'annonce à côté des autres autour de toi. Tu peux corriger les champs ci-dessous si besoin.",
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          CustomTextField(
            controller: _adresseController,
            label: 'Adresse / repère',
            prefixIcon: Icons.location_on_outlined,
          ),
          const SizedBox(height: AppSpacing.stackMd),
          CustomTextField(
            controller: _quartierController,
            label: 'Quartier',
            prefixIcon: Icons.holiday_village_outlined,
          ),
          const SizedBox(height: AppSpacing.stackMd),
          CustomTextField(
            controller: _villeController,
            label: 'Ville',
            prefixIcon: Icons.location_city_outlined,
          ),
          const SizedBox(height: AppSpacing.stackMd),
          CustomTextField(
            controller: _paysController,
            label: 'Pays',
            prefixIcon: Icons.public_outlined,
          ),
          const SizedBox(height: AppSpacing.stackLg),
          if (_erreur != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              decoration: BoxDecoration(
                color: AppColors.statusRedBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                _erreur!,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
          ],
          PrimaryButton(label: 'Confirmer', onPressed: _confirmer),
        ],
      ),
    );
  }
}