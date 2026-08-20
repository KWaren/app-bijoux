import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/db_helper.dart';
import '../models/vente.dart';
import '../state/app_state.dart';
import '../utils/date_ranges.dart';
import '../utils/formatters.dart';
import '../widgets/erreur_chargement.dart';
import '../widgets/modele_photo.dart';
import '../widgets/month_selector.dart';
import '../widgets/paiement_dette_dialog.dart';
import 'vente_form_screen.dart';

class VenteScreen extends StatefulWidget {
  const VenteScreen({super.key});

  @override
  State<VenteScreen> createState() => _VenteScreenState();
}

class _VenteScreenState extends State<VenteScreen> {
  Future<List<Vente>>? _futureVentes;
  String? _moisCharge;
  int? _versionChargee;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.watch<AppState>();
    final mois = appState.moisSelectionne;
    if (mois != _moisCharge || appState.dataVersion != _versionChargee) {
      _moisCharge = mois;
      _versionChargee = appState.dataVersion;
      _recharger();
    }
  }

  void _recharger() {
    final periode = rangeMois(_moisCharge!);
    setState(() {
      _futureVentes = DbHelper.instance.getVentesByPeriode(periode.debut, periode.fin);
    });
  }

  Future<void> _supprimer(Vente v) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette vente ?'),
        content: const Text(
          'La quantité vendue sera de nouveau disponible en stock. Une dette éventuellement liée à cette vente sera aussi supprimée. Cette action est irréversible.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirme == true) {
      await DbHelper.instance.deleteVente(v.id!);
      if (mounted) context.read<AppState>().signalerChangement();
      _recharger();
    }
  }

  Future<void> _payerDette(Vente v) async {
    if (v.detteId == null || v.resteAPayer == null) return;
    final paye = await afficherDialoguePaiementDette(
      context,
      clientNom: v.clientNom,
      reste: v.resteAPayer!,
    );
    if (paye == null) return;

    await DbHelper.instance.payerDette(v.detteId!, paye);
    if (mounted) context.read<AppState>().signalerChangement();
    _recharger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ventes')),
      body: Column(
        children: [
          const Padding(padding: EdgeInsets.all(16), child: MonthSelector()),
          Expanded(
            child: FutureBuilder<List<Vente>>(
              future: _futureVentes,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErreurChargement(erreur: snapshot.error, onReessayer: _recharger);
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final ventes = snapshot.data!;
                if (ventes.isEmpty) {
                  return const Center(
                    child: Padding(padding: EdgeInsets.all(24), child: Text('Aucune vente ce mois-ci.')),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: ventes.length,
                  itemBuilder: (context, index) {
                    final v = ventes[index];
                    final aDette = v.resteAPayer != null && v.resteAPayer! > 0;
                    final unSeulModele = v.lignes.length == 1;
                    final titreModele = unSeulModele ? (v.lignes.first.modeleNom ?? '') : '${v.lignes.length} modèles';
                    return Card(
                      child: ListTile(
                        leading: ModelePhoto(photoPath: v.lignes.isEmpty ? null : v.lignes.first.photoPath, taille: 48),
                        title: Text('$titreModele — ${v.clientNom}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!unSeulModele) Text(v.modelesResume),
                            Text('${formatDateAffichage(v.dateVente)} · Qté ${v.qteVendueTotal}'),
                            if (aDette)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(4),
                                  onTap: () => _payerDette(v),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'À crédit · reste ${formatMontant(v.resteAPayer!)}',
                                          style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(Icons.payments_outlined, size: 14, color: Colors.orange.shade900),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        isThreeLine: aDette || !unSeulModele,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatMontant(v.prixVenteTotal),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => _supprimer(v),
                            ),
                          ],
                        ),
                        onTap: () async {
                          final modifie = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(builder: (_) => VenteFormScreen(vente: v)),
                          );
                          if (modifie == true) _recharger();
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Nouvelle vente'),
        onPressed: () async {
          final cree = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const VenteFormScreen()),
          );
          if (cree == true) _recharger();
        },
      ),
    );
  }
}
