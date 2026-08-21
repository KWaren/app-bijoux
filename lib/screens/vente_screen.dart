import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/db_helper.dart';
import '../models/vente.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  itemCount: ventes.length,
                  itemBuilder: (context, index) {
                    final v = ventes[index];
                    final aDette = v.resteAPayer != null && v.resteAPayer! > 0;
                    final unSeulModele = v.lignes.length == 1;
                    final titreModele = unSeulModele ? (v.lignes.first.modeleNom ?? '') : '${v.lignes.length} modèles';
                    // Mise en page du mockup : la corbeille est alignée sur le
                    // titre et le montant occupe sa propre ligne. Un ListTile
                    // mettait les deux dans `trailing`, ce qui rognait la
                    // largeur du titre et le faisait passer à la ligne.
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () async {
                          final modifie = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(builder: (_) => VenteFormScreen(vente: v)),
                          );
                          if (modifie == true) _recharger();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ModelePhoto(
                                photoPath: v.lignes.isEmpty ? null : v.lignes.first.photoPath,
                                taille: 48,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '$titreModele — ${v.clientNom}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          borderRadius: BorderRadius.circular(6),
                                          onTap: () => _supprimer(v),
                                          child: const Padding(
                                            padding: EdgeInsets.all(2),
                                            child: Icon(Icons.delete_outline, size: 18, color: AppTheme.grisIcone),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!unSeulModele)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          v.modelesResume,
                                          style: const TextStyle(fontSize: 11, color: AppTheme.grisTexte),
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${formatDateAffichage(v.dateVente)} · Qté ${v.qteVendueTotal}',
                                            style: const TextStyle(fontSize: 11, color: AppTheme.grisTexte),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          formatMontant(v.prixVenteTotal),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: AppTheme.bleuMarine,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (aDette)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(6),
                                          onTap: () => _payerDette(v),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: AppTheme.creditBg,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    'À crédit · reste ${formatMontant(v.resteAPayer!)}',
                                                    style: const TextStyle(
                                                      color: AppTheme.creditFg,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                const Icon(Icons.payments_outlined, size: 13, color: AppTheme.creditFg),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
          final mois = context.read<AppState>().moisSelectionne;
          final cree = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => VenteFormScreen(mois: mois)),
          );
          if (cree == true) _recharger();
        },
      ),
    );
  }
}
