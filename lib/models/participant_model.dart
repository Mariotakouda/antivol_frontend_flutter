class ParticipantModel {
  final int userId;
  final String nomComplet;
  final String? photoProfil;
  final String role; // Membre | Createur

  ParticipantModel({
    required this.userId,
    required this.nomComplet,
    this.photoProfil,
    required this.role,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return ParticipantModel(
      userId: user['id'] as int,
      nomComplet: '${user['prenom']} ${user['nom']}',
      photoProfil: user['photo_profil'] as String?,
      role: json['role'] as String,
    );
  }
}
