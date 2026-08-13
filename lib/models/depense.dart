class Depense {
  final int? id;
  final String mois; // 'YYYY-MM'
  final String dateDepense; // 'YYYY-MM-DD'
  final String designation;
  final double cout;

  /// Arrivage auquel cette dépense est rattachée (ex: transport, douane pour ce
  /// lot précis) — `null` pour une dépense générale (loyer, sachets...).
  final int? arrivageId;

  /// Nom du modèle lié, alimenté par jointure à la lecture (jamais stocké ici).
  final String? modeleNom;

  const Depense({
    this.id,
    required this.mois,
    required this.dateDepense,
    required this.designation,
    required this.cout,
    this.arrivageId,
    this.modeleNom,
  });

  factory Depense.fromMap(Map<String, dynamic> map) {
    return Depense(
      id: map['id'] as int?,
      mois: map['mois'] as String,
      dateDepense: map['date_depense'] as String,
      designation: map['designation'] as String,
      cout: (map['cout'] as num).toDouble(),
      arrivageId: map['arrivage_id'] as int?,
      modeleNom: map['modele'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'mois': mois,
      'date_depense': dateDepense,
      'designation': designation,
      'cout': cout,
      'arrivage_id': arrivageId,
    };
  }
}
