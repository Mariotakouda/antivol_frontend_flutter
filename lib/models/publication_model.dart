import 'categorie_model.dart';
import 'image_model.dart';
import 'recompense_model.dart';

class PublicationAuteur {
  final int id;
  final String nomComplet;
  final String? photoProfil;
  final int scoreConfiance;

  PublicationAuteur({
    required this.id,
    required this.nomComplet,
    this.photoProfil,
    required this.scoreConfiance,
  });

  factory PublicationAuteur.fromJson(Map<String, dynamic> json) {
    return PublicationAuteur(
      id: json['id'] as int,
      nomComplet: '${json['prenom']} ${json['nom']}',
      photoProfil: json['photo_profil'] as String?,
      scoreConfiance: int.tryParse(json['score_confiance'].toString()) ?? 0,
    );
  }
}

class PublicationModel {
  final int id;
  final String titre;
  final String description;
  final String type; // PERDU | TROUVE
  final String statut; // OUVERTE | RETROUVEE | FERMEE
  final CategorieModel? categorie;
  final PublicationAuteur? auteur;
  final List<ImageModel> images;
  final String? marque;
  final String? modele;
  final String? couleur;
  final String? numeroSerie;
  final String? plaque;
  final String? etat;
  final DateTime dateEvenement;
  final double latitude;
  final double longitude;
  final String adresse;
  final String quartier;
  final String ville;
  final String pays;
  final double? recompense;
  final bool estVisible;
  final int nombreVues;
  final int? nombreCommentaires;
  final DateTime createdAt;
  final List<RecompenseModel> recompenses;

  PublicationModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.type,
    required this.statut,
    this.categorie,
    this.auteur,
    required this.images,
    this.marque,
    this.modele,
    this.couleur,
    this.numeroSerie,
    this.plaque,
    this.etat,
    required this.dateEvenement,
    required this.latitude,
    required this.longitude,
    required this.adresse,
    required this.quartier,
    required this.ville,
    required this.pays,
    this.recompense,
    required this.estVisible,
    required this.nombreVues,
    this.nombreCommentaires,
    required this.createdAt,
    this.recompenses = const [],
  });

  String? get imagePrincipaleUrl {
    if (images.isEmpty) return null;
    final principale = images.where((i) => i.principale).toList();
    return (principale.isNotEmpty ? principale.first : images.first).url;
  }

  bool get estPerdu => type == 'PERDU';

  PublicationModel copyWith({
    String? statut,
    List<RecompenseModel>? recompenses,
  }) {
    return PublicationModel(
      id: id,
      titre: titre,
      description: description,
      type: type,
      statut: statut ?? this.statut,
      categorie: categorie,
      auteur: auteur,
      images: images,
      marque: marque,
      modele: modele,
      couleur: couleur,
      numeroSerie: numeroSerie,
      plaque: plaque,
      etat: etat,
      dateEvenement: dateEvenement,
      latitude: latitude,
      longitude: longitude,
      adresse: adresse,
      quartier: quartier,
      ville: ville,
      pays: pays,
      recompense: recompense,
      estVisible: estVisible,
      nombreVues: nombreVues,
      nombreCommentaires: nombreCommentaires,
      createdAt: createdAt,
      recompenses: recompenses ?? this.recompenses,
    );
  }

  factory PublicationModel.fromJson(Map<String, dynamic> json) {
    return PublicationModel(
      id: json['id'] as int,
      titre: json['titre'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      statut: json['statut'] as String,
      categorie: json['categorie'] != null && (json['categorie'] as Map).isNotEmpty
          ? CategorieModel.fromJson(json['categorie'])
          : null,
      auteur: json['user'] != null && (json['user'] as Map).isNotEmpty
          ? PublicationAuteur.fromJson(json['user'])
          : null,
      images: json['images'] != null
          ? (json['images'] as List).map((i) => ImageModel.fromJson(i)).toList()
          : [],
      marque: json['marque'] as String?,
      modele: json['modele'] as String?,
      couleur: json['couleur'] as String?,
      numeroSerie: json['numero_serie'] as String?,
      plaque: json['plaque'] as String?,
      etat: json['etat'] as String?,
      dateEvenement: DateTime.parse(json['date_evenement']),
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      adresse: json['adresse'] as String,
      quartier: json['quartier'] as String,
      ville: json['ville'] as String,
      pays: json['pays'] as String,
      recompense: json['recompense'] != null ? double.tryParse(json['recompense'].toString()) : null,
      estVisible: json['est_visible'] as bool? ?? true,
      nombreVues: json['nombre_vues'] as int? ?? 0,
      nombreCommentaires: json['nombre_commentaires'] as int?,
      createdAt: DateTime.parse(json['created_at']),
      recompenses: json['recompenses'] != null
          ? (json['recompenses'] as List).map((r) => RecompenseModel.fromJson(r)).toList()
          : [],
    );
  }
}