import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/errors/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/categorie_provider.dart';
import '../../services/publication_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import 'location_picker_screen.dart';

/// Formulaire de création d'une publication (objet perdu ou trouvé).
/// Retourne `true` via Navigator.pop si la publication a bien été créée,
/// pour que l'écran appelant sache qu'il doit rafraîchir sa liste.
class CreatePublicationScreen extends StatefulWidget {
  /// Catégorie à présélectionner dans le formulaire, par exemple quand
  /// l'utilisateur clique sur "Publier" alors qu'un filtre de catégorie
  /// est déjà actif sur le fil d'actualité. L'utilisateur peut toujours
  /// la changer, c'est juste la valeur de départ.
  final int? categorieInitialeId;

  const CreatePublicationScreen({super.key, this.categorieInitialeId});

  @override
  State<CreatePublicationScreen> createState() => _CreatePublicationScreenState();
}

class _CreatePublicationScreenState extends State<CreatePublicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = PublicationService();
  final _picker = ImagePicker();

  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _couleurController = TextEditingController();
  final _numeroSerieController = TextEditingController();
  final _plaqueController = TextEditingController();
  final _etatController = TextEditingController();
  final _recompenseController = TextEditingController();

  String _type = 'PERDU';
  late int? _categorieId = widget.categorieInitialeId;
  DateTime _dateEvenement = DateTime.now();
  LieuSelectionne? _lieu;
  final List<XFile> _images = [];
  bool _detailsOuverts = false;
  bool _envoiEnCours = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategorieProvider>().chargerSiNecessaire();
    });
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _couleurController.dispose();
    _numeroSerieController.dispose();
    _plaqueController.dispose();
    _etatController.dispose();
    _recompenseController.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateEvenement,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _dateEvenement = date);
  }

  Future<void> _choisirEmplacement() async {
    final resultat = await Navigator.of(context).push<LieuSelectionne>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(lieuInitial: _lieu),
      ),
    );
    if (resultat != null) setState(() => _lieu = resultat);
  }

  Future<void> _ajouterPhotos() async {
    final restant = 5 - _images.length;
    if (restant <= 0) return;

    final fichiers = await _picker.pickMultiImage(limit: restant, imageQuality: 80);
    if (fichiers.isEmpty) return;
    setState(() => _images.addAll(fichiers.take(restant)));
  }

  void _retirerPhoto(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categorieId == null) {
      setState(() => _erreur = 'Choisis une catégorie.');
      return;
    }
    if (_lieu == null) {
      setState(() => _erreur = "Choisis l'emplacement sur la carte.");
      return;
    }

    setState(() {
      _envoiEnCours = true;
      _erreur = null;
    });

    try {
      final recompenseTexte = _recompenseController.text.trim();
      await _service.creer(
        categorieId: _categorieId!,
        titre: _titreController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _type,
        marque: _marqueController.text.trim(),
        modele: _modeleController.text.trim(),
        couleur: _couleurController.text.trim(),
        numeroSerie: _numeroSerieController.text.trim(),
        plaque: _plaqueController.text.trim(),
        etat: _etatController.text.trim(),
        dateEvenement: _dateEvenement,
        latitude: _lieu!.latitude,
        longitude: _lieu!.longitude,
        adresse: _lieu!.adresse.isNotEmpty ? _lieu!.adresse : _lieu!.ville,
        quartier: _lieu!.quartier.isNotEmpty ? _lieu!.quartier : _lieu!.ville,
        ville: _lieu!.ville,
        pays: _lieu!.pays,
        recompense: recompenseTexte.isNotEmpty ? double.tryParse(recompenseTexte) : null,
        images: _images,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, stack) {
      debugPrint('Erreur création publication: $e\n$stack');
      setState(() {
        _erreur = e is ApiException ? e.toString() : 'Une erreur est survenue. Réessaie.';
      });
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Publier une annonce')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.containerPadding),
          children: [
            _buildSelecteurType(),
            const SizedBox(height: AppSpacing.stackMd),
            _buildSelecteurCategorie(),
            const SizedBox(height: AppSpacing.stackMd),
            CustomTextField(
              controller: _titreController,
              label: 'Titre (ex : iPhone 13 noir)',
              prefixIcon: Icons.title_outlined,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Le titre est obligatoire' : null,
            ),
            const SizedBox(height: AppSpacing.stackMd),
            CustomTextField(
              controller: _descriptionController,
              label: 'Description',
              keyboardType: TextInputType.multiline,
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'La description est obligatoire' : null,
            ),
            const SizedBox(height: AppSpacing.stackMd),
            _buildSelecteurDate(),
            const SizedBox(height: AppSpacing.stackMd),
            _buildSelecteurEmplacement(),
            const SizedBox(height: AppSpacing.stackMd),
            CustomTextField(
              controller: _recompenseController,
              label: 'Récompense en F CFA (optionnel)',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.card_giftcard_outlined,
            ),
            const SizedBox(height: AppSpacing.stackSm),
            _buildDetailsSupplementaires(),
            const SizedBox(height: AppSpacing.stackLg),
            _buildSectionPhotos(),
            const SizedBox(height: AppSpacing.stackLg),
            if (_erreur != null) ...[
              Container(
                width: double.infinity,
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
            PrimaryButton(
              label: 'Publier',
              chargement: _envoiEnCours,
              onPressed: _soumettre,
            ),
            const SizedBox(height: AppSpacing.stackLg),
          ],
        ),
      ),
    );
  }

  Widget _buildSelecteurType() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          _segmentType('PERDU', 'Perdu', AppColors.error),
          _segmentType('TROUVE', 'Trouvé', AppColors.primary),
        ],
      ),
    );
  }

  Widget _segmentType(String valeur, String libelle, Color couleur) {
    final selectionne = _type == valeur;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = valeur),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selectionne ? couleur : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm + 4),
          ),
          child: Text(
            libelle,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelLg.copyWith(
              color: selectionne ? Colors.white : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelecteurCategorie() {
    return Consumer<CategorieProvider>(
      builder: (context, categorieProvider, _) {
        if (categorieProvider.chargement) {
          return const LinearProgressIndicator(color: AppColors.primary);
        }

        return DropdownButtonFormField<int>(
          initialValue: _categorieId,
          decoration: const InputDecoration(
            labelText: 'Catégorie',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: categorieProvider.categories
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nom)))
              .toList(),
          onChanged: (valeur) => setState(() => _categorieId = valeur),
        );
      },
    );
  }

  Widget _buildSelecteurDate() {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.input),
      onTap: _choisirDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: "Date de l'événement",
          prefixIcon: Icon(Icons.event_outlined),
        ),
        child: Text(
          '${_dateEvenement.day.toString().padLeft(2, '0')}/${_dateEvenement.month.toString().padLeft(2, '0')}/${_dateEvenement.year}',
        ),
      ),
    );
  }

  Widget _buildSelecteurEmplacement() {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.input),
      onTap: _choisirEmplacement,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Emplacement',
          prefixIcon: Icon(Icons.location_on_outlined),
          suffixIcon: Icon(Icons.chevron_right),
        ),
        child: Text(
          _lieu != null
              ? [_lieu!.quartier, _lieu!.ville].where((s) => s.isNotEmpty).join(', ')
              : "Choisir l'emplacement",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildDetailsSupplementaires() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          title: Text('Détails supplémentaires (optionnel)', style: AppTextStyles.labelLg),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.onSurfaceVariant,
          initiallyExpanded: _detailsOuverts,
          onExpansionChanged: (ouvert) => setState(() => _detailsOuverts = ouvert),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.stackSm,
            AppSpacing.gutter,
            AppSpacing.gutter,
          ),
          children: [
            CustomTextField(controller: _marqueController, label: 'Marque'),
            const SizedBox(height: AppSpacing.gutter),
            CustomTextField(controller: _modeleController, label: 'Modèle'),
            const SizedBox(height: AppSpacing.gutter),
            CustomTextField(controller: _couleurController, label: 'Couleur'),
            const SizedBox(height: AppSpacing.gutter),
            CustomTextField(controller: _numeroSerieController, label: 'Numéro de série'),
            const SizedBox(height: AppSpacing.gutter),
            CustomTextField(controller: _plaqueController, label: 'Plaque (Ex: TG 1234 AB,)'),
            const SizedBox(height: AppSpacing.gutter),
            CustomTextField(controller: _etatController, label: 'État (neuf, usagé...)'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionPhotos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos (jusqu\'à 5)', style: AppTextStyles.labelLg),
        const SizedBox(height: AppSpacing.stackSm),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._images.asMap().entries.map(
                (entree) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.stackSm),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: kIsWeb
                            ? Image.network(
                                entree.value.path,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(entree.value.path),
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _retirerPhoto(entree.key),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_images.length < 5)
                GestureDetector(
                  onTap: _ajouterPhotos,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.statusGreenBg,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}