import 'package:flutter/material.dart';

/// Message d'erreur affiché à la place d'un écran vide quand le chargement
/// des données échoue, avec le détail technique et un bouton pour réessayer.
class ErreurChargement extends StatelessWidget {
  final Object? erreur;
  final VoidCallback onReessayer;

  const ErreurChargement({super.key, required this.erreur, required this.onReessayer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Erreur lors du chargement.'),
            const SizedBox(height: 4),
            Text('$erreur', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onReessayer, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
