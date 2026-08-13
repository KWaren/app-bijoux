class Periode {
  final DateTime debut;
  final DateTime fin;
  final String libelle;

  const Periode({required this.debut, required this.fin, required this.libelle});
}

DateTime _debutJournee(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _finJournee(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

Periode rangeJour(DateTime jour) {
  return Periode(
    debut: _debutJournee(jour),
    fin: _finJournee(jour),
    libelle: '${jour.day.toString().padLeft(2, '0')}/${jour.month.toString().padLeft(2, '0')}/${jour.year}',
  );
}

/// Semaine du lundi au dimanche contenant [jour].
Periode rangeSemaine(DateTime jour) {
  final lundi = _debutJournee(jour.subtract(Duration(days: jour.weekday - 1)));
  final dimanche = _finJournee(lundi.add(const Duration(days: 6)));
  return Periode(
    debut: lundi,
    fin: dimanche,
    libelle: 'Semaine du ${lundi.day.toString().padLeft(2, '0')}/${lundi.month.toString().padLeft(2, '0')}',
  );
}

/// Mois au format 'YYYY-MM'.
Periode rangeMois(String moisYYYYMM) {
  final parts = moisYYYYMM.split('-');
  final annee = int.parse(parts[0]);
  final mois = int.parse(parts[1]);
  final debut = DateTime(annee, mois, 1);
  final finMoisExclu = DateTime(annee, mois + 1, 1);
  final fin = finMoisExclu.subtract(const Duration(seconds: 1));
  const noms = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  return Periode(debut: debut, fin: fin, libelle: '${noms[mois - 1]} $annee');
}

String moisActuel() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
}
