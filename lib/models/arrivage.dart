class Arrivage {
  final int? id;
  final String mois; // format 'YYYY-MM'
  final String modele;
  final int quantite;
  final double prixAchatUnitaire;
  final int qteEndommage;
  final double? prixVenteMax;
  final double? prixVenteLast;
  final String? photoPath;
  final String dateAjout; // ISO 'YYYY-MM-DD'

  /// Somme des quantités vendues pour cet arrivage.
  /// Alimenté par une jointure au moment de la lecture, jamais stocké en base.
  final int qteVendue;

  const Arrivage({
    this.id,
    required this.mois,
    required this.modele,
    required this.quantite,
    required this.prixAchatUnitaire,
    this.qteEndommage = 0,
    this.prixVenteMax,
    this.prixVenteLast,
    this.photoPath,
    required this.dateAjout,
    this.qteVendue = 0,
  });

  double get prixAchatTotal => quantite * prixAchatUnitaire;
  double get prixEndommage => qteEndommage * prixAchatUnitaire;
  int get bijouxRestant => quantite - qteEndommage - qteVendue;
  bool get stockEpuise => bijouxRestant <= 0;
  bool get stockBas => !stockEpuise && bijouxRestant <= 2;

  Arrivage copyWith({
    int? id,
    String? mois,
    String? modele,
    int? quantite,
    double? prixAchatUnitaire,
    int? qteEndommage,
    double? prixVenteMax,
    double? prixVenteLast,
    String? photoPath,
    String? dateAjout,
    int? qteVendue,
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
      photoPath: photoPath ?? this.photoPath,
      dateAjout: dateAjout ?? this.dateAjout,
      qteVendue: qteVendue ?? this.qteVendue,
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
      photoPath: map['photo_path'] as String?,
      dateAjout: map['date_ajout'] as String,
      qteVendue: (map['qte_vendue'] as num?)?.toInt() ?? 0,
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
      'photo_path': photoPath,
      'date_ajout': dateAjout,
    };
  }
}
