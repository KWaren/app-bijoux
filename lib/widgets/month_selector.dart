import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class MonthSelector extends StatelessWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final moisListe = appState.moisDisponibles;
    final valeurActuelle = moisListe.contains(appState.moisSelectionne) ? appState.moisSelectionne : null;

    return Row(
      children: [
        Expanded(
          child: PopupMenuButton<String>(
            tooltip: 'Choisir le mois',
            offset: const Offset(0, 46),
            itemBuilder: (context) => moisListe
                .map((m) => PopupMenuItem(value: m, child: Text(formatMoisLibelle(m))))
                .toList(),
            onSelected: (valeur) => context.read<AppState>().changerMois(valeur),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.ombreDouce,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MOIS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        valeurActuelle != null ? formatMoisLibelle(valeurActuelle) : 'Choisir',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Icon(Icons.expand_more, color: AppTheme.bleuMarine),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _choisirAutreMois(context),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.ombreDouce,
            ),
            child: const Icon(Icons.calendar_month_outlined, color: AppTheme.bleuMarine, size: 20),
          ),
        ),
      ],
    );
  }

  Future<void> _choisirAutreMois(BuildContext context) async {
    final appState = context.read<AppState>();
    final maintenant = DateTime.now();
    final actuel = DateTime.tryParse('${appState.moisSelectionne}-01') ?? maintenant;
    final choix = await showDialog<DateTime>(
      context: context,
      builder: (_) => _MoisAnneePickerDialog(
        initial: actuel,
        anneeMin: maintenant.year - 5,
        anneeMax: maintenant.year + 1,
      ),
    );
    if (choix != null) {
      final mois = '${choix.year.toString().padLeft(4, '0')}-${choix.month.toString().padLeft(2, '0')}';
      appState.ajouterMoisSiAbsent(mois);
      appState.changerMois(mois);
    }
  }
}

/// Sélecteur mois/année (sans jour) : évite de faire choisir une date
/// précise à l'utilisateur·rice alors que seul le mois compte ici.
class _MoisAnneePickerDialog extends StatefulWidget {
  final DateTime initial;
  final int anneeMin;
  final int anneeMax;

  const _MoisAnneePickerDialog({required this.initial, required this.anneeMin, required this.anneeMax});

  @override
  State<_MoisAnneePickerDialog> createState() => _MoisAnneePickerDialogState();
}

class _MoisAnneePickerDialogState extends State<_MoisAnneePickerDialog> {
  late int _annee = widget.initial.year;

  static const _nomsMois = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _annee > widget.anneeMin ? () => setState(() => _annee--) : null,
          ),
          Text('$_annee'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _annee < widget.anneeMax ? () => setState(() => _annee++) : null,
          ),
        ],
      ),
      content: SizedBox(
        width: 280,
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          childAspectRatio: 1.6,
          children: List.generate(12, (i) {
            final mois = i + 1;
            final estSelectionne = _annee == widget.initial.year && mois == widget.initial.month;
            return Padding(
              padding: const EdgeInsets.all(4),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: estSelectionne ? Theme.of(context).colorScheme.primaryContainer : null,
                ),
                onPressed: () => Navigator.pop(context, DateTime(_annee, mois)),
                child: Text(_nomsMois[i]),
              ),
            );
          }),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
      ],
    );
  }
}
