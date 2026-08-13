class Depense {
  final int? id;
  final String mois; // 'YYYY-MM'
  final String dateDepense; // 'YYYY-MM-DD'
  final String designation;
  final double cout;

  const Depense({
    this.id,
    required this.mois,
    required this.dateDepense,
    required this.designation,
    required this.cout,
  });

  factory Depense.fromMap(Map<String, dynamic> map) {
    return Depense(
      id: map['id'] as int?,
      mois: map['mois'] as String,
      dateDepense: map['date_depense'] as String,
      designation: map['designation'] as String,
      cout: (map['cout'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'mois': mois,
      'date_depense': dateDepense,
      'designation': designation,
      'cout': cout,
    };
  }
}
