/// Résultat d'une vérification rapide (écran "Vérifier un objet").
/// Volontairement plus léger que PublicationModel : le backend ne renvoie
/// les coordonnées du déclarant que si le compte connecté est Police/Admin.
class ResultatVerification {
  final int id;
  final String titre;
  final String? categorie;
  final DateTime dateEvenement;
  final String ville;
  final String? quartier;
  final DeclarantVerification? declarant;

  ResultatVerification({
    required this.id,
    required this.titre,
    this.categorie,
    required this.dateEvenement,
    required this.ville,
    this.quartier,
    this.declarant,
  });

  factory ResultatVerification.fromJson(Map<String, dynamic> json) {
    return ResultatVerification(
      id: json['id'] as int,
      titre: json['titre'] as String,
      categorie: json['categorie'] as String?,
      dateEvenement: DateTime.parse(json['date_evenement']),
      ville: json['ville'] as String,
      quartier: json['quartier'] as String?,
      declarant: json['declarant'] != null
          ? DeclarantVerification.fromJson(json['declarant'])
          : null,
    );
  }
}

class DeclarantVerification {
  final String nomComplet;
  final String telephone;

  DeclarantVerification({required this.nomComplet, required this.telephone});

  factory DeclarantVerification.fromJson(Map<String, dynamic> json) {
    return DeclarantVerification(
      nomComplet: json['nom_complet'] as String,
      telephone: json['telephone'] as String,
    );
  }
}