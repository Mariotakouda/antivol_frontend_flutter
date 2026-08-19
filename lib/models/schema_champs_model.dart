/// Définition d'un champ dynamique (structuré ou JSON), tel que renvoyé par
/// GET /publications/champs. Pilote la construction du formulaire.
class ChampDefinition {
  final String cle;
  final String label;
  final String type; // text, textarea, number, select, boolean
  final bool requis;
  final List<String>? options;

  ChampDefinition({
    required this.cle,
    required this.label,
    required this.type,
    required this.requis,
    this.options,
  });

  factory ChampDefinition.fromEntry(String cle, Map<String, dynamic> json) {
    return ChampDefinition(
      cle: cle,
      label: json['label'] as String? ?? cle,
      type: json['type'] as String? ?? 'text',
      requis: json['requis'] as bool? ?? false,
      options: (json['options'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}

/// Schéma complet pour une catégorie + type donnés : quels champs
/// structurés (colonnes classiques : marque, couleur...) et quels champs
/// JSON (stockés dans `caracteristiques`) afficher dans le formulaire.
class SchemaChamps {
  final String profil;
  final List<ChampDefinition> structures;
  final List<ChampDefinition> json;

  SchemaChamps({required this.profil, required this.structures, required this.json});

  bool get estVide => structures.isEmpty && json.isEmpty;

  factory SchemaChamps.fromJson(Map<String, dynamic> data) {
    final structuresMap = Map<String, dynamic>.from(data['structures'] as Map? ?? {});
    final jsonMap = Map<String, dynamic>.from(data['json'] as Map? ?? {});

    return SchemaChamps(
      profil: data['profil'] as String? ?? 'autre',
      structures: structuresMap.entries
          .map((e) => ChampDefinition.fromEntry(e.key, Map<String, dynamic>.from(e.value as Map)))
          .toList(),
      json: jsonMap.entries
          .map((e) => ChampDefinition.fromEntry(e.key, Map<String, dynamic>.from(e.value as Map)))
          .toList(),
    );
  }
}