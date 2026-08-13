class ResumePeriode {
  final DateTime debut;
  final DateTime fin;
  final double totalAchat;
  final double totalVentes;
  final double totalDepenses;
  final double totalPertes;
  final int nbVentes;
  final double dettesCreees;

  const ResumePeriode({
    required this.debut,
    required this.fin,
    required this.totalAchat,
    required this.totalVentes,
    required this.totalDepenses,
    required this.totalPertes,
    required this.nbVentes,
    required this.dettesCreees,
  });

  double get depensesEtPertes => totalDepenses + totalPertes;
  double get benefice => totalVentes - totalAchat - depensesEtPertes;
}
