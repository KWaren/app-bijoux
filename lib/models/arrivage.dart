class Arrivage {
  final int? id;
  final String mois; // format 'YYYY-MM'
  final String modele;
  final int quantite;
  final double prixAchatUnitaire;
  final int qteEndommage;
  final double? prixVenteMax;
  final double? prixVenteLast;
  final double? prixVenteMin;
  final String? photoPath;
  final String dateAjout; // ISO 'YYYY-MM-DD'

  /// Somme des quantités vendues pour cet arrivage.
  /// Alimenté par une jointure au moment de la lecture, jamais stocké en base.
  final int qteVendue;

  /// Somme des dépenses (transport, douane...) rattachées à cet arrivage.
  /// Alimenté par une jointure au moment de la lecture, jamais stocké en base.
  final double depensesLiees;

  const Arrivage({
    this.id,
    required this.mois,
    required this.modele,
    required this.quantite,
    required this.prixAchatUnitaire,
    this.qteEndommage = 0,
    this.prixVenteMax,
    this.prixVenteLast,
    this.prixVenteMin,
    this.photoPath,
    required this.dateAjout,
    this.qteVendue = 0,
    this.depensesLiees = 0,
  });

  double get prixAchatTotal => quantite * prixAchatUnitaire;
  double get prixEndommage => qteEndommage * prixAchatUnitaire;
  int get bijouxRestant => quantite - qteEndommage - qteVendue;
  bool get stockEpuise => bijouxRestant <= 0;
  bool get stockBas => !stockEpuise && bijouxRestant <= 2;

  /// Coût total du lot, frais annexes (transport, douane...) inclus.
  double get coutTotalAvecFrais => prixAchatTotal + depensesLiees;

  /// Coût unitaire réel du lot, frais annexes répartis sur la quantité achetée.
  double get coutUnitaireAvecFrais => quantite > 0 ? coutTotalAvecFrais / quantite : prixAchatUnitaire;

  /// Bénéfice minimum garanti sur le stock restant si tout est vendu au prix
  /// de vente minimum fixé, frais annexes déduits. `null` tant qu'aucun prix
  /// minimum n'est renseigné.
  double? get beneficeEstime {
    if (prixVenteMin == null) return null;
    return bijouxRestant * (prixVenteMin! - coutUnitaireAvecFrais);
  }

  Arrivage copyWith({
    int? id,
    String? mois,
    String? modele,
    int? quantite,
    double? prixAchatUnitaire,
    int? qteEndommage,
    double? prixVenteMax,
    double? prixVenteLast,
    double? prixVenteMin,
    String? photoPath,
    String? dateAjout,
    int? qteVendue,
    double? depensesLiees,
  }) {
    return Arrivage(
      id: id ?? this.id,
      mois: mois ?? this.mois,
      modele: modele ?? this.modele,
      quantite: quantite ?? this.quantite,
      prixAchatUnitaire: prixAchatUnitaire ?? this.prixAchatUnitaire,
      qteEndommage: qteEndommage ?? this.qteEndommage,
      prixVenteMax: prixVenteMax ?? this.prixVenteMax,
      prixVenteLast: prixVenteLast ?? this.prixVenteLast,
      prixVenteMin: prixVenteMin ?? this.prixVenteMin,
      photoPath: photoPath ?? this.photoPath,
      dateAjout: dateAjout ?? this.dateAjout,
      qteVendue: qteVendue ?? this.qteVendue,
      depensesLiees: depensesLiees ?? this.depensesLiees,
    );
  }

  factory Arrivage.fromMap(Map<String, dynamic> map) {
    return Arrivage(
      id: map['id'] as int?,
      mois: map['mois'] as String,
      modele: map['modele'] as String,
      quantite: map['quantite'] as int,
      prixAchatUnitaire: (map['prix_achat_unitaire'] as num).toDouble(),
      qteEndommage: map['qte_endommage'] as int? ?? 0,
      prixVenteMax: (map['prix_vente_max'] as num?)?.toDouble(),
      prixVenteLast: (map['prix_vente_last'] as num?)?.toDouble(),
      prixVenteMin: (map['prix_vente_min'] as num?)?.toDouble(),
      photoPath: map['photo_path'] as String?,
      dateAjout: map['date_ajout'] as String,
      qteVendue: (map['qte_vendue'] as num?)?.toInt() ?? 0,
      depensesLiees: (map['depenses_liees'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'mois': mois,
      'modele': modele,
      'quantite': quantite,
      'prix_achat_unitaire': prixAchatUnitaire,
      'qte_endommage': qteEndommage,
      'prix_vente_max': prixVenteMax,
      'prix_vente_last': prixVenteLast,
      'prix_vente_min': prixVenteMin,
      'photo_path': photoPath,
      'date_ajout': dateAjout,
    };
  }
}
