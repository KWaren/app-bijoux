class ResumePeriode {
  final DateTime debut;
  final DateTime fin;

  /// Coût des marchandises effectivement vendues sur la période (quantité
  /// vendue × coût unitaire du lot d'origine, frais liés inclus) — pas le
  /// coût de tout ce qui a été acheté/réceptionné sur la période, pour que
  /// le bénéfice corresponde aux ventes réalisées et non aux achats de stock.
  final double coutMarchandisesVendues;
  final double totalVentes;
  final double totalDepenses;
  final double totalPertes;
  final int nbVentes;
  final double dettesCreees;

  /// Total payé pour les arrivages reçus sur la période (prix de gros, vendus
  /// ou non) — distinct du coût des marchandises vendues ci-dessus.
  final double totalAchats;

  /// Nombre total de pièces reçues (arrivages) sur la période.
  final int nbMarchandisesAchetees;

  const ResumePeriode({
    required this.debut,
    required this.fin,
    required this.coutMarchandisesVendues,
    required this.totalVentes,
    required this.totalDepenses,
    required this.totalPertes,
    required this.nbVentes,
    required this.dettesCreees,
    this.totalAchats = 0,
    this.nbMarchandisesAchetees = 0,
  });

  double get depensesEtPertes => totalDepenses + totalPertes;
  double get benefice => totalVentes - coutMarchandisesVendues - depensesEtPertes;

  /// Marge nette en % du chiffre d'affaires. `null` si aucune vente sur la période.
  double? get margeEnPourcent => totalVentes == 0 ? null : (benefice / totalVentes) * 100;
}
