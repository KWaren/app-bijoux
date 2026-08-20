import 'package:flutter_test/flutter_test.dart';
import 'package:stock_flow/utils/formatters.dart';

void main() {
  group('formatMontant', () {
    test('ajoute la devise', () {
      expect(formatMontant(50), '50 FCFA');
    });

    test('regroupe les milliers', () {
      final resultat = formatMontant(1500);
      expect(resultat, contains('500'));
      expect(resultat, contains('FCFA'));
      expect(resultat.startsWith('1'), isTrue);
    });
  });

  group('formatDateAffichage', () {
    test('convertit une date ISO en format jj/mm/aaaa', () {
      expect(formatDateAffichage('2026-03-05'), '05/03/2026');
    });
  });

  group('dateDuJourIso', () {
    test('retourne une date au format YYYY-MM-DD', () {
      expect(dateDuJourIso(), matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });
  });

  group('moisDepuisIso', () {
    test("extrait le mois YYYY-MM d'une date ISO", () {
      expect(moisDepuisIso('2026-03-05'), '2026-03');
    });
  });

  group('formatMoisLibelle', () {
    test('formate un mois YYYY-MM en libellé français', () {
      expect(formatMoisLibelle('2026-03'), 'Mars 2026');
    });
  });
}
