import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// Affiche la boîte de dialogue de paiement d'une dette (partiel ou total).
/// Retourne le montant payé à enregistrer via `DbHelper.payerDette`, ou
/// `null` si l'utilisateur annule.
Future<double?> afficherDialoguePaiementDette(
  BuildContext context, {
  required String clientNom,
  required double reste,
}) {
  final montantCtrl = TextEditingController();

  return showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Paiement — $clientNom'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reste à payer : ${formatMontant(reste)}'),
          const SizedBox(height: 12),
          TextField(
            controller: montantCtrl,
            autofocus: true,
            decoration: InputDecoration(labelText: 'Montant payé maintenant ($devise)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        TextButton(
          onPressed: () => Navigator.pop(context, reste),
          child: const Text('Tout payer'),
        ),
        FilledButton(
          onPressed: () {
            final montant = double.tryParse(montantCtrl.text.replaceAll(',', '.'));
            if (montant == null || montant <= 0) return;
            Navigator.pop(context, montant);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    ),
  );
}
