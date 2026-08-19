import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/errors/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/schema_champs_model.dart';
import '../../providers/categorie_provider.dart';
import '../../services/publication_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import 'location_picker_screen.dart';

/// Formulaire de création d'une publication (objet perdu ou trouvé).
/// Les champs "Détails spécifiques" changent dynamiquement selon la
/// catégorie ET le type (PERDU/TROUVE) choisis — voir
/// config/publication_champs.php côté Laravel pour le schéma complet.
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
  final _recompenseController = TextEditingController();
  final Map<String, TextEditingController> _controllersStructures = {};
  final Map<String, TextEditingController> _controllersJson = {};
  final Map<String, String?> _valeursSelect = {};
  final Map<String, bool> _valeursBooleennes = {};

  String _type = 'PERDU';
  late int? _categorieId = widget.categorieInitialeId;
  DateTime _dateEvenement = DateTime.now();
  LieuSelectionne? _lieu;
  final List<XFile> _images = [];
  bool _envoiEnCours = false;
  String? _erreur;

  SchemaChamps? _schema;
  bool _chargementSchema = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategorieProvider>().chargerSiNecessaire();
      _chargerSchema();
    });
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _recompenseController.dispose();
    for (final c in _controllersStructures.values) {
      c.dispose();
    }
    for (final c in _controllersJson.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerStructure(String cle) {
    return _controllersStructures.putIfAbsent(cle, () => TextEditingController());
  }

  TextEditingController _controllerJson(String cle) {
    return _controllersJson.putIfAbsent(cle, () => TextEditingController());
  }

  Future<void> _chargerSchema() async {
    if (_categorieId == null) {
      setState(() => _schema = null);
      return;
    }

    setState(() => _chargementSchema = true);
    try {
      final schema = await _service.champsPour(categorieId: _categorieId!, type: _type);
      if (!mounted) return;
      setState(() => _schema = schema);
    } catch (_) {
      if (!mounted) return;
      // Formulaire toujours utilisable même si le schéma ne charge pas —
      // juste sans les champs spécifiques à la catégorie.
      setState(() => _schema = null);
    } finally {
      if (mounted) setState(() => _chargementSchema = false);
    }
  }

  void _changerCategorie(int? valeur) {
    setState(() => _categorieId = valeur);
    _chargerSchema();
  }

  void _changerType(String valeur) {
    if (_type == valeur) return;
    setState(() => _type = valeur);
    _chargerSchema();
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

  /// Construit le Map à envoyer comme `caracteristiques` (JSON) à partir
  /// des champs dynamiques actuellement affichés dans le schéma.
  Map<String, dynamic> _construireCaracteristiques() {
    if (_schema == null) return {};

    final resultat = <String, dynamic>{};
    for (final champ in _schema!.json) {
      switch (champ.type) {
        case 'select':
          final valeur = _valeursSelect[champ.cle];
          if (valeur != null && valeur.isNotEmpty) resultat[champ.cle] = valeur;
          break;
        case 'boolean':
          resultat[champ.cle] = _valeursBooleennes[champ.cle] ?? false;
          break;
        case 'number':
          final texte = _controllerJson(champ.cle).text.trim();
          if (texte.isNotEmpty) {
            resultat[champ.cle] = num.tryParse(texte) ?? texte;
          }
          break;
        default: // text, textarea
          final texte = _controllerJson(champ.cle).text.trim();
          if (texte.isNotEmpty) resultat[champ.cle] = texte;
      }
    }
    return resultat;
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
        marque: _controllersStructures['marque']?.text.trim(),
        modele: _controllersStructures['modele']?.text.trim(),
        couleur: _controllersStructures['couleur']?.text.trim(),
        numeroSerie: _controllersStructures['numero_serie']?.text.trim(),
        plaque: _controllersStructures['plaque']?.text.trim(),
        dateEvenement: _dateEvenement,
        latitude: _lieu!.latitude,
        longitude: _lieu!.longitude,
        adresse: _lieu!.adresse.isNotEmpty ? _lieu!.adresse : _lieu!.ville,
        quartier: _lieu!.quartier.isNotEmpty ? _lieu!.quartier : _lieu!.ville,
        ville: _lieu!.ville,
        pays: _lieu!.pays,
        recompense: recompenseTexte.isNotEmpty ? double.tryParse(recompenseTexte) : null,
        caracteristiques: _construireCaracteristiques(),
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
              label: 'Le nom de l\'objet perdu',
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
            const SizedBox(height: AppSpacing.stackLg),
            _buildChampsDynamiques(),
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
        onTap: () => _changerType(valeur),
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
          onChanged: _changerCategorie,
          validator: (v) => v == null ? 'Choisis une catégorie' : null,
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

  /// Section "Détails spécifiques" : construite dynamiquement selon le
  /// schéma renvoyé par l'API pour la catégorie + le type sélectionnés.
  /// Vide (ex: catégorie "Autre") -> section masquée entièrement.
  Widget _buildChampsDynamiques() {
    if (_categorieId == null) return const SizedBox.shrink();

    if (_chargementSchema) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.stackMd),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_schema == null || _schema!.estVide) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Détails spécifiques', style: AppTextStyles.labelLg),
          const SizedBox(height: AppSpacing.stackSm),
          for (final champ in _schema!.structures) ...[
            CustomTextField(
              controller: _controllerStructure(champ.cle),
              label: champ.requis ? '${champ.label} *' : champ.label,
              validator: champ.requis
                  ? (v) => (v == null || v.trim().isEmpty) ? '${champ.label} est requis' : null
                  : null,
            ),
            const SizedBox(height: AppSpacing.gutter),
          ],
          for (final champ in _schema!.json) ...[
            _buildChampJson(champ),
            const SizedBox(height: AppSpacing.gutter),
          ],
        ],
      ),
    );
  }

  Widget _buildChampJson(ChampDefinition champ) {
    final label = champ.requis ? '${champ.label} *' : champ.label;

    switch (champ.type) {
      case 'select':
        return DropdownButtonFormField<String>(
          initialValue: _valeursSelect[champ.cle],
          decoration: InputDecoration(labelText: label),
          items: (champ.options ?? [])
              .map((option) => DropdownMenuItem(value: option, child: Text(option)))
              .toList(),
          onChanged: (valeur) => setState(() => _valeursSelect[champ.cle] = valeur),
          validator: champ.requis
              ? (v) => (v == null || v.isEmpty) ? '${champ.label} est requis' : null
              : null,
        );

      case 'boolean':
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(champ.label, style: AppTextStyles.bodyMd),
          activeColor: AppColors.primary,
          value: _valeursBooleennes[champ.cle] ?? false,
          onChanged: (valeur) => setState(() => _valeursBooleennes[champ.cle] = valeur),
        );

      case 'number':
        return CustomTextField(
          controller: _controllerJson(champ.cle),
          label: label,
          keyboardType: TextInputType.number,
          validator: champ.requis
              ? (v) => (v == null || v.trim().isEmpty) ? '${champ.label} est requis' : null
              : null,
        );

      case 'textarea':
        return CustomTextField(
          controller: _controllerJson(champ.cle),
          label: label,
          keyboardType: TextInputType.multiline,
          maxLines: 3,
          validator: champ.requis
              ? (v) => (v == null || v.trim().isEmpty) ? '${champ.label} est requis' : null
              : null,
        );

      default: // text
        return CustomTextField(
          controller: _controllerJson(champ.cle),
          label: label,
          validator: champ.requis
              ? (v) => (v == null || v.trim().isEmpty) ? '${champ.label} est requis' : null
              : null,
        );
    }
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