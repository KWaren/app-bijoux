class Dette {
  final int? id;
  final String clientNom;
  final int? venteId;
  final double montant;
  final String? description;
  final String dateDette; // 'YYYY-MM-DD'
  final String statut; // 'en_cours' | 'payee'

  const Dette({
    this.id,
    required this.clientNom,
    this.venteId,
    required this.montant,
    this.description,
    required this.dateDette,
    this.statut = 'en_cours',
  });

  bool get estPayee => statut == 'payee';

  Dette copyWith({String? statut}) {
    return Dette(
      id: id,
      clientNom: clientNom,
      venteId: venteId,
      montant: montant,
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
      'description': description,
      'date_dette': dateDette,
      'statut': statut,
    };
  }
}
