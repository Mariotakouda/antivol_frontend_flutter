class UserModel {
  final int id;
  final String nom;
  final String prenom;
  final String telephone;
  final String? email;
  final String? photoProfil;
  final String ville;
  final String pays;
  final String role;
  final String? matricule;
  final String? posteRattachement;
  final String statut;
  final int scoreConfiance;
  final bool telephoneVerifie;
  final bool emailVerifie;

  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.email,
    this.photoProfil,
    required this.ville,
    required this.pays,
    required this.role,
    this.matricule,
    this.posteRattachement,
    required this.statut,
    required this.scoreConfiance,
    required this.telephoneVerifie,
    required this.emailVerifie,
  });

  String get nomComplet => '$prenom $nom';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      telephone: json['telephone'] as String,
      email: json['email'] as String?,
      photoProfil: json['photo_profil'] as String?,
      ville: json['ville'] as String,
      pays: json['pays'] as String,
      role: json['role'] as String,
      matricule: json['matricule'] as String?,
      posteRattachement: json['poste_rattachement'] as String?,
      statut: json['statut'] as String,
      scoreConfiance: json['score_confiance'] as int,
      telephoneVerifie: json['telephone_verifie'] as bool,
      emailVerifie: json['email_verifie'] as bool,
    );
  }
}