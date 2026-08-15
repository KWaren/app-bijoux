/// Valeurs possibles de [Vente.modePaiement].
class ModePaiement {
  static const especes = 'especes';
  static const mtnMomo = 'mtn_momo';
  static const moovMomo = 'moov_momo';

  static const Map<String, String> libelles = {
    especes: 'Espèces',
    mtnMomo: 'MTN Momo',
    moovMomo: 'Moov Momo',
  };
}

class Vente {
  final int? id;
  final int arrivageId;
  final String clientNom;
  final String dateVente; // ISO 'YYYY-MM-DD'
  final int qteVendue;
  final double prixVenteTotal;
  final String? modePaiement;
  final String? note;

  /// Champs alimentés par jointure avec `arrivages`/`dettes` à la lecture (jamais stockés ici).
  final String? modeleNom;
  final String? photoPath;
  final double? resteAPayer;

  const Vente({
    this.id,
    required this.arrivageId,
    required this.clientNom,
    required this.dateVente,
    required this.qteVendue,
    required this.prixVenteTotal,
    this.modePaiement,
    this.note,
    this.modeleNom,
    this.photoPath,
    this.resteAPayer,
  });

  factory Vente.fromMap(Map<String, dynamic> map) {
    return Vente(
      id: map['id'] as int?,
      arrivageId: map['arrivage_id'] as int,
      clientNom: map['client_nom'] as String,
      dateVente: map['date_vente'] as String,
      qteVendue: map['qte_vendue'] as int,
      prixVenteTotal: (map['prix_vente_total'] as num).toDouble(),
      modePaiement: map['mode_paiement'] as String?,
      note: map['note'] as String?,
      modeleNom: map['modele'] as String?,
      photoPath: map['photo_path'] as String?,
      resteAPayer: (map['reste_a_payer'] as num?)?.toDouble(),
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
      'mode_paiement': modePaiement,
      'note': note,
    };
  }
}
