import 'package:flutter_test/flutter_test.dart';
import 'package:stock_flow/utils/date_ranges.dart';

void main() {
  group('rangeJour', () {
    test('couvre toute la journée', () {
      final jour = DateTime(2026, 3, 5, 14, 30);
      final p = rangeJour(jour);
      expect(p.debut, DateTime(2026, 3, 5));
      expect(p.fin, DateTime(2026, 3, 5, 23, 59, 59));
      expect(p.libelle, '05/03/2026');
    });
  });

  group('rangeSemaine', () {
    test('renvoie la semaine du lundi au dimanche', () {
      // 2024-01-01 est un lundi, donc le 3 janvier est un mercredi.
      final mercredi = DateTime(2024, 1, 3, 10, 0);
      final p = rangeSemaine(mercredi);
      expect(p.debut, DateTime(2024, 1, 1));
      expect(p.fin, DateTime(2024, 1, 7, 23, 59, 59));
      expect(p.libelle, 'Semaine du 01/01');
    });
  });

  group('rangeMois', () {
    test('couvre le mois entier, y compris année bissextile', () {
      final p = rangeMois('2024-02');
      expect(p.debut, DateTime(2024, 2, 1));
      expect(p.fin, DateTime(2024, 2, 29, 23, 59, 59));
      expect(p.libelle, 'février 2024');
    });
  });

  group('moisActuel', () {
    test('retourne le mois courant au format YYYY-MM', () {
      expect(moisActuel(), matches(RegExp(r'^\d{4}-\d{2}$')));
    });
  });
}
