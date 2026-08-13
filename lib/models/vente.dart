class Vente {
  final int? id;
  final int arrivageId;
  final String clientNom;
  final String dateVente; // ISO 'YYYY-MM-DD'
  final int qteVendue;
  final double prixVenteTotal;

  /// Champs alimentés par jointure avec `arrivages` à la lecture (jamais stockés ici).
  final String? modeleNom;
  final String? photoPath;

  const Vente({
    this.id,
    required this.arrivageId,
    required this.clientNom,
    required this.dateVente,
    required this.qteVendue,
    required this.prixVenteTotal,
    this.modeleNom,
    this.photoPath,
  });

  factory Vente.fromMap(Map<String, dynamic> map) {
    return Vente(
      id: map['id'] as int?,
      arrivageId: map['arrivage_id'] as int,
      clientNom: map['client_nom'] as String,
      dateVente: map['date_vente'] as String,
      qteVendue: map['qte_vendue'] as int,
      prixVenteTotal: (map['prix_vente_total'] as num).toDouble(),
      modeleNom: map['modele'] as String?,
      photoPath: map['photo_path'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'arrivage_id': arrivageId,
      'client_nom': clientNom,
      'date_vente': dateVente,
      'qte_vendue': qteVendue,
      'prix_vente_total': prixVenteTotal,
    };
  }
}
