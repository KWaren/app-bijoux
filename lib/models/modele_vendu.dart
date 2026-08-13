class ModeleVendu {
  final String modele;
  final int qteVendue;
  final double totalVentes;

  const ModeleVendu({required this.modele, required this.qteVendue, required this.totalVentes});

  factory ModeleVendu.fromMap(Map<String, dynamic> map) {
    return ModeleVendu(
      modele: map['modele'] as String,
      qteVendue: (map['qte'] as num).toInt(),
      totalVentes: (map['ca'] as num).toDouble(),
    );
  }
}
