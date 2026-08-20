import 'package:flutter/material.dart';

import '../models/resume.dart';
import '../theme/app_theme.dart';

/// Petit graphique en barres (ventes vs bénéfice) sur les derniers mois,
/// construit avec les widgets Flutter de base — aucune dépendance externe.
class EvolutionMensuelleChart extends StatelessWidget {
  final List<ResumePeriode> resumes;
  static const double _hauteurMax = 90;

  const EvolutionMensuelleChart({super.key, required this.resumes});

  @override
  Widget build(BuildContext context) {
    if (resumes.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final maxValeur = resumes
        .expand((r) => [r.totalVentes, r.benefice.abs()])
        .fold<double>(1, (max, v) => v > max ? v : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LegendeItem(couleur: colorScheme.primary, label: 'Ventes'),
            const SizedBox(width: 16),
            _LegendeItem(couleur: AppTheme.vertSucces, label: 'Bénéfice'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: resumes.map((r) {
            final hVentes = (r.totalVentes / maxValeur) * _hauteurMax;
            final hBenefice = (r.benefice.abs() / maxValeur) * _hauteurMax;
            final couleurBenefice = r.benefice >= 0 ? AppTheme.vertSucces : AppTheme.rougeAlerte;
            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: _hauteurMax,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _Barre(hauteur: hVentes, couleur: colorScheme.primary),
                        const SizedBox(width: 3),
                        _Barre(hauteur: hBenefice, couleur: couleurBenefice),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_libelleMoisCourt(r.debut), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _libelleMoisCourt(DateTime d) {
    const noms = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    return noms[d.month - 1];
  }
}

class _Barre extends StatelessWidget {
  final double hauteur;
  final Color couleur;

  const _Barre({required this.hauteur, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: hauteur < 2 ? 2 : hauteur,
      decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(3)),
    );
  }
}

class _LegendeItem extends StatelessWidget {
  final Color couleur;
  final String label;

  const _LegendeItem({required this.couleur, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: couleur, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
