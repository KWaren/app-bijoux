import 'package:intl/intl.dart';

/// Devise utilisée dans toute l'appli. À changer ici si besoin (FCFA par défaut).
const String devise = 'FCFA';

final NumberFormat _formatMontant = NumberFormat.decimalPattern('fr_FR');

String formatMontant(num valeur) => '${_formatMontant.format(valeur)} $devise';

String formatDateAffichage(String isoDate) {
  final d = DateTime.parse(isoDate);
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

String dateDuJourIso() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String moisDepuisIso(String isoDate) => isoDate.substring(0, 7);

const List<String> _nomsMois = [
  'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
];

String formatMoisLibelle(String moisYYYYMM) {
  final parts = moisYYYYMM.split('-');
  final annee = parts[0];
  final mois = int.parse(parts[1]);
  return '${_nomsMois[mois - 1]} $annee';
}
