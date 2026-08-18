class Dette {
  final int? id;
  final String clientNom;
  final int? venteId;
  final double montant;
  final double montantPaye;
  final String? description;
  final String dateDette; // 'YYYY-MM-DD'
  final String statut; // 'en_cours' | 'payee'

  const Dette({
    this.id,
    required this.clientNom,
    this.venteId,
    required this.montant,
    this.montantPaye = 0,
    this.description,
    required this.dateDette,
    this.statut = 'en_cours',
  });

  bool get estPayee => statut == 'payee';

  /// Solde restant dû, en tenant compte des paiements partiels déjà enregistrés.
  double get resteAPayer => montant - montantPaye;

  Dette copyWith({String? statut, double? montantPaye}) {
    return Dette(
      id: id,
      clientNom: clientNom,
      venteId: venteId,
      montant: montant,
      montantPaye: montantPaye ?? this.montantPaye,
      description: description,
      dateDette: dateDette,
      statut: statut ?? this.statut,
    );
  }

  factory Dette.fromMap(Map<String, dynamic> map) {
    return Dette(
      id: map['id'] as int?,
      clientNom: map['client_nom'] as String,
      venteId: map['vente_id'] as int?,
      montant: (map['montant'] as num).toDouble(),
      montantPaye: (map['montant_paye'] as num?)?.toDouble() ?? 0,
      description: map['description'] as String?,
      dateDette: map['date_dette'] as String,
      statut: map['statut'] as String? ?? 'en_cours',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'client_nom': clientNom,
      'vente_id': venteId,
      'montant': montant,
      'montant_paye': montantPaye,
      'description': description,
      'date_dette': dateDette,
      'statut': statut,
    };
  }
}
