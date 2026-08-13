import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
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
          child: DropdownButtonFormField<String>(
            value: valeurActuelle,
            decoration: const InputDecoration(labelText: 'Mois'),
            items: moisListe
                .map((m) => DropdownMenuItem(value: m, child: Text(formatMoisLibelle(m))))
                .toList(),
            onChanged: (valeur) {
              if (valeur != null) context.read<AppState>().changerMois(valeur);
            },
          ),
        ),
        IconButton(
          tooltip: 'Choisir un autre mois',
          icon: const Icon(Icons.calendar_month),
          onPressed: () => _choisirAutreMois(context),
        ),
      ],
    );
  }

  Future<void> _choisirAutreMois(BuildContext context) async {
    final appState = context.read<AppState>();
    final maintenant = DateTime.now();
    final choix = await showDatePicker(
      context: context,
      initialDate: maintenant,
      firstDate: DateTime(maintenant.year - 5),
      lastDate: DateTime(maintenant.year + 1),
      helpText: 'Choisir un mois',
    );
    if (choix != null) {
      final mois = '${choix.year.toString().padLeft(4, '0')}-${choix.month.toString().padLeft(2, '0')}';
      appState.ajouterMoisSiAbsent(mois);
      appState.changerMois(mois);
    }
  }
}
