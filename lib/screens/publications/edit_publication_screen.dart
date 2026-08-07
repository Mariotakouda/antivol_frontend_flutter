import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/errors/api_exception.dart';
import '../../models/publication_model.dart';
import '../../providers/categorie_provider.dart';
import '../../services/image_service.dart';
import '../../services/publication_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import 'location_picker_screen.dart';

/// Formulaire de modification complet d'une publication existante :
/// champs texte, catégorie, date, emplacement, récompense, statut, et
/// gestion des photos (ajout immédiat / suppression immédiate, séparée
/// de l'enregistrement des autres champs car ce sont deux endpoints API
/// distincts côté backend).
class EditPublicationScreen extends StatefulWidget {
  final PublicationModel publication;

  const EditPublicationScreen({super.key, required this.publication});

  @override
  State<EditPublicationScreen> createState() => _EditPublicationScreenState();
}

class _EditPublicationScreenState extends State<EditPublicationScreen> {
  final _service = PublicationService();
  final _imageService = ImageService();
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  late PublicationModel _publication;

  late final TextEditingController _titreController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _marqueController;
  late final TextEditingController _modeleController;
  late final TextEditingController _couleurController;
  late final TextEditingController _numeroSerieController;
  late final TextEditingController _plaqueController;
  late final TextEditingController _etatController;
  late final TextEditingController _recompenseController;

  late int? _categorieId;
  late DateTime _dateEvenement;
  late String _statut;
  LieuSelectionne? _lieu;

  bool _envoiEnCours = false;
  bool _photoEnCours = false;
  String? _erreur;

  static const _statuts = ['OUVERTE', 'RETROUVEE', 'FERMEE'];

  @override
  void initState() {
    super.initState();
    _publication = widget.publication;

    _titreController = TextEditingController(text: _publication.titre);
    _descriptionController = TextEditingController(text: _publication.description);
    _marqueController = TextEditingController(text: _publication.marque ?? '');
    _modeleController = TextEditingController(text: _publication.modele ?? '');
    _couleurController = TextEditingController(text: _publication.couleur ?? '');
    _numeroSerieController = TextEditingController(text: _publication.numeroSerie ?? '');
    _plaqueController = TextEditingController(text: _publication.plaque ?? '');
    _etatController = TextEditingController(text: _publication.etat ?? '');
    _recompenseController = TextEditingController(
      text: _publication.recompense != null ? _publication.recompense!.toStringAsFixed(0) : '',
    );

    _categorieId = _publication.categorie?.id;
    _dateEvenement = _publication.dateEvenement;
    _statut = _publication.statut;
    _lieu = LieuSelectionne(
      latitude: _publication.latitude,
      longitude: _publication.longitude,
      adresse: _publication.adresse,
      quartier: _publication.quartier,
      ville: _publication.ville,
      pays: _publication.pays,
    );

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
      MaterialPageRoute(builder: (_) => LocationPickerScreen(lieuInitial: _lieu)),
    );
    if (resultat != null) setState(() => _lieu = resultat);
  }

  Future<void> _ajouterPhotos() async {
    final restant = 5 - _publication.images.length;
    if (restant <= 0) return;

    final fichiers = await _picker.pickMultiImage(limit: restant, imageQuality: 80);
    if (fichiers.isEmpty) return;

    setState(() => _photoEnCours = true);
    try {
      await _imageService.ajouter(
        publicationId: _publication.id,
        images: fichiers,
      );
      await _rechargerPublication();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Échec de l'ajout des photos")),
      );
    } finally {
      if (mounted) setState(() => _photoEnCours = false);
    }
  }

  Future<void> _supprimerPhoto(int imageId) async {
    setState(() => _photoEnCours = true);
    try {
      await _imageService.supprimer(imageId);
      await _rechargerPublication();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de la suppression de la photo')),
      );
    } finally {
      if (mounted) setState(() => _photoEnCours = false);
    }
  }

  Future<void> _rechargerPublication() async {
    try {
      final publication = await _service.voir(_publication.id);
      if (!mounted) return;
      setState(() => _publication = publication);
    } catch (_) {
      // Silencieux : les listes de photos resteront simplement inchangées
      // à l'écran jusqu'au prochain rechargement réussi.
    }
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categorieId == null) {
      setState(() => _erreur = 'Choisis une catégorie.');
      return;
    }

    setState(() {
      _envoiEnCours = true;
      _erreur = null;
    });

    try {
      final recompenseTexte = _recompenseController.text.trim();
      final publication = await _service.modifier(
        id: _publication.id,
        categorieId: _categorieId,
        titre: _titreController.text.trim(),
        description: _descriptionController.text.trim(),
        marque: _marqueController.text.trim(),
        modele: _modeleController.text.trim(),
        couleur: _couleurController.text.trim(),
        numeroSerie: _numeroSerieController.text.trim(),
        plaque: _plaqueController.text.trim(),
        etat: _etatController.text.trim(),
        recompense: recompenseTexte.isNotEmpty ? double.tryParse(recompenseTexte) : null,
        statut: _statut,
      );
      if (!mounted) return;
      Navigator.of(context).pop(publication);
    } catch (e, stack) {
      debugPrint('Erreur modification publication: $e\n$stack');
      setState(() {
        _erreur = e is ApiException ? e.toString() : 'Une erreur est survenue. Réessaie.';
        _envoiEnCours = false;
      });
    }
  }

  Future<void> _supprimer() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette publication ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    try {
      await _service.supprimer(_publication.id);
      if (!mounted) return;
      Navigator.of(context).pop('supprimee');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de la suppression')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier la publication'),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _supprimer),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionPhotos(),
            const SizedBox(height: 18),
            _buildSelecteurCategorie(),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _titreController,
              label: 'Titre',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Le titre est obligatoire' : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _descriptionController,
              label: 'Description',
              keyboardType: TextInputType.multiline,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'La description est obligatoire' : null,
            ),
            const SizedBox(height: 14),
            _buildSelecteurDate(),
            const SizedBox(height: 14),
            _buildSelecteurEmplacement(),
            const SizedBox(height: 14),
            _buildSelecteurStatut(),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _recompenseController,
              label: 'Récompense en F CFA (optionnel)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            _buildDetailsSupplementaires(),
            const SizedBox(height: 20),
            if (_erreur != null) ...[
              Text(_erreur!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            PrimaryButton(label: 'Enregistrer', chargement: _envoiEnCours, onPressed: _enregistrer),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionPhotos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Photos', style: TextStyle(fontWeight: FontWeight.w600)),
            if (_photoEnCours) ...[
              const SizedBox(width: 10),
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._publication.images.map(
                (image) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(image.url, width: 90, height: 90, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: _photoEnCours ? null : () => _supprimerPhoto(image.id),
                          child: const CircleAvatar(
                            radius: 11,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_publication.images.length < 5)
                GestureDetector(
                  onTap: _photoEnCours ? null : _ajouterPhotos,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade600),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelecteurCategorie() {
    return Consumer<CategorieProvider>(
      builder: (context, categorieProvider, _) {
        if (categorieProvider.chargement) return const LinearProgressIndicator();

        return DropdownButtonFormField<int>(
          initialValue: _categorieId,
          decoration: InputDecoration(
            labelText: 'Catégorie',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      onTap: _choisirDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Date de l'événement",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        child: Text(
          '${_dateEvenement.day.toString().padLeft(2, '0')}/${_dateEvenement.month.toString().padLeft(2, '0')}/${_dateEvenement.year}',
        ),
      ),
    );
  }

  Widget _buildSelecteurEmplacement() {
    return InkWell(
      onTap: _choisirEmplacement,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Emplacement',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: const Icon(Icons.place_outlined),
        ),
        child: Text(
          _lieu != null
              ? [_lieu!.quartier, _lieu!.ville].where((s) => s.isNotEmpty).join(', ')
              : 'Choisir un emplacement',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildSelecteurStatut() {
    return DropdownButtonFormField<String>(
      initialValue: _statut,
      decoration: InputDecoration(
        labelText: 'Statut',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: _statuts
          .map((s) => DropdownMenuItem(value: s, child: Text(_libelleStatut(s))))
          .toList(),
      onChanged: (valeur) => setState(() => _statut = valeur!),
    );
  }

  String _libelleStatut(String statut) {
    switch (statut) {
      case 'RETROUVEE':
        return 'Retrouvée';
      case 'FERMEE':
        return 'Fermée';
      default:
        return 'Ouverte';
    }
  }

  Widget _buildDetailsSupplementaires() {
    return ExpansionTile(
      title: const Text('Détails supplémentaires'),
      childrenPadding: const EdgeInsets.only(top: 8, bottom: 4),
      children: [
        CustomTextField(controller: _marqueController, label: 'Marque'),
        const SizedBox(height: 12),
        CustomTextField(controller: _modeleController, label: 'Modèle'),
        const SizedBox(height: 12),
        CustomTextField(controller: _couleurController, label: 'Couleur'),
        const SizedBox(height: 12),
        CustomTextField(controller: _numeroSerieController, label: 'Numéro de série'),
        const SizedBox(height: 12),
        CustomTextField(controller: _plaqueController, label: 'Plaque (véhicule)'),
        const SizedBox(height: 12),
        CustomTextField(controller: _etatController, label: 'État (neuf, usagé...)'),
      ],
    );
  }
}