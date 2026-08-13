import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../utils/formatters.dart';

/// Affiche un montant lié au prix d'achat, masqué par défaut ("••••••")
/// tant que l'utilisatrice n'a pas volontairement appuyé sur "Afficher"
/// (voir bouton oeil dans l'écran Stock). Jamais affiché sur l'écran Vente.
class PrixAchatText extends StatelessWidget {
  final num valeur;
  final TextStyle? style;

  const PrixAchatText({super.key, required this.valeur, this.style});

  @override
  Widget build(BuildContext context) {
    final visible = context.watch<AppState>().prixAchatVisible;
    return Text(visible ? formatMontant(valeur) : '••••••', style: style);
  }
}
