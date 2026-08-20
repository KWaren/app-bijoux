import 'vente_ligne.dart';

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
  final String clientNom;
  final String dateVente; // ISO 'YYYY-MM-DD'
  final double prixVenteTotal;
  final String? modePaiement;
  final String? note;

  /// Une vente peut porter sur plusieurs modèles. Alimenté par une requête
  /// séparée à la lecture (jamais stocké tel quel sur l'en-tête `ventes`).
  final List<VenteLigne> lignes;

  /// Champs alimentés par jointure avec `dettes` à la lecture (jamais stockés ici).
  final double? resteAPayer;
  final int? detteId;

  const Vente({
    this.id,
    required this.clientNom,
    required this.dateVente,
    required this.prixVenteTotal,
    this.modePaiement,
    this.note,
    this.lignes = const [],
    this.resteAPayer,
    this.detteId,
  });

  /// Quantité totale vendue, toutes lignes confondues.
  int get qteVendueTotal => lignes.fold(0, (somme, l) => somme + l.qteVendue);

  /// Résumé lisible des modèles vendus, ex. "Bague X (2), Collier Y (1)".
  String get modelesResume => lignes.map((l) => '${l.modeleNom ?? ''} (${l.qteVendue})').join(', ');

  factory Vente.fromMap(Map<String, dynamic> map, {List<VenteLigne> lignes = const []}) {
    return Vente(
      id: map['id'] as int?,
      clientNom: map['client_nom'] as String,
      dateVente: map['date_vente'] as String,
      prixVenteTotal: (map['prix_vente_total'] as num).toDouble(),
      modePaiement: map['mode_paiement'] as String?,
      note: map['note'] as String?,
      lignes: lignes,
      resteAPayer: (map['reste_a_payer'] as num?)?.toDouble(),
      detteId: map['dette_id'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'client_nom': clientNom,
      'date_vente': dateVente,
      'prix_vente_total': prixVenteTotal,
      'mode_paiement': modePaiement,
      'note': note,
    };
  }
}
