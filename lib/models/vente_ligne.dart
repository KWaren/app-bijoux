/// Une ligne d'une [Vente] : un modèle, une quantité et un prix.
/// Une vente peut contenir plusieurs lignes (plusieurs modèles achetés en une fois).
class VenteLigne {
  final int? id;
  final int? venteId;
  final int arrivageId;
  final int qteVendue;
  final double prixLigne;

  /// Champs alimentés par jointure avec `arrivages` à la lecture (jamais stockés ici).
  final String? modeleNom;
  final String? photoPath;

  const VenteLigne({
    this.id,
    this.venteId,
    required this.arrivageId,
    required this.qteVendue,
    required this.prixLigne,
    this.modeleNom,
    this.photoPath,
  });

  VenteLigne copyWith({int? venteId}) {
    return VenteLigne(
      id: id,
      venteId: venteId ?? this.venteId,
      arrivageId: arrivageId,
      qteVendue: qteVendue,
      prixLigne: prixLigne,
      modeleNom: modeleNom,
      photoPath: photoPath,
    );
  }

  factory VenteLigne.fromMap(Map<String, dynamic> map) {
    return VenteLigne(
      id: map['id'] as int?,
      venteId: map['vente_id'] as int?,
      arrivageId: map['arrivage_id'] as int,
      qteVendue: map['qte_vendue'] as int,
      prixLigne: (map['prix_ligne'] as num).toDouble(),
      modeleNom: map['modele'] as String?,
      photoPath: map['photo_path'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (venteId != null) 'vente_id': venteId,
      'arrivage_id': arrivageId,
      'qte_vendue': qteVendue,
      'prix_ligne': prixLigne,
    };
  }
}
