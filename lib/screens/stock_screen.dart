import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/db_helper.dart';
import '../models/arrivage.dart';
import '../state/app_state.dart';
import '../utils/formatters.dart';
import '../widgets/erreur_chargement.dart';
import '../widgets/modele_photo.dart';
import '../widgets/month_selector.dart';
import '../widgets/price_hidden_widget.dart';
import 'depenses_screen.dart';
import 'stock_form_screen.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  Future<List<Arrivage>>? _futureArrivages;
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
    setState(() {
      _futureArrivages = DbHelper.instance.getArrivagesByMois(_moisCharge!);
    });
  }

  @override
  void dispose() {
    context.read<AppState>().masquerPrixAchat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrivage / Stock'),
        actions: [
          IconButton(
            tooltip: 'Autres dépenses',
            icon: const Icon(Icons.receipt_long),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const DepensesScreen()));
            },
          ),
          IconButton(
            tooltip: appState.prixAchatVisible ? "Masquer le prix d'achat" : "Afficher le prix d'achat",
            icon: Icon(appState.prixAchatVisible ? Icons.visibility_off : Icons.visibility),
            onPressed: () => context.read<AppState>().toggleVisibilitePrixAchat(),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(padding: EdgeInsets.all(16), child: MonthSelector()),
          Expanded(
            child: FutureBuilder<List<Arrivage>>(
              future: _futureArrivages,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErreurChargement(erreur: snapshot.error, onReessayer: _recharger);
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final arrivages = snapshot.data!;
                if (arrivages.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Aucun modèle pour ce mois. Ajoute ton premier arrivage.'),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: arrivages.length,
                  itemBuilder: (context, index) =>
                      _ArrivageTile(arrivage: arrivages[index], onModifie: _recharger),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un modèle'),
        onPressed: () async {
          final mois = context.read<AppState>().moisSelectionne;
          final cree = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => StockFormScreen(mois: mois)),
          );
          if (cree == true) _recharger();
        },
      ),
    );
  }
}

class _ArrivageTile extends StatelessWidget {
  final Arrivage arrivage;
  final VoidCallback onModifie;

  const _ArrivageTile({required this.arrivage, required this.onModifie});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: ModelePhoto(photoPath: arrivage.photoPath, taille: 52),
        title: Text(arrivage.modele, style: const TextStyle(fontWeight: FontWeight.bold)),
        isThreeLine: true,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Restant : ${arrivage.qteRestante} / ${arrivage.quantite}'),
            if (arrivage.qteEndommage > 0) Text('Endommagé : ${arrivage.qteEndommage}'),
            Wrap(
              children: [
                const Text('Prix achat unit. : '),
                PrixAchatText(valeur: arrivage.prixAchatUnitaire),
              ],
            ),
            if (arrivage.depensesLiees > 0)
              Wrap(
                children: [
                  const Text('Frais liés (transport, douane...) : '),
                  PrixAchatText(valeur: arrivage.depensesLiees),
                ],
              ),
            if (arrivage.prixVenteMax != null) Text('Prix vente max : ${formatMontant(arrivage.prixVenteMax!)}'),
            if (arrivage.beneficeEstime != null)
              Wrap(
                children: [
                  const Text('Bénéfice min. estimé sur le restant : '),
                  PrixAchatText(valeur: arrivage.beneficeEstime!),
                ],
              ),
          ],
        ),
        trailing: arrivage.stockEpuise
            ? const Chip(label: Text('Épuisé'))
            : (arrivage.stockBas ? Chip(label: const Text('Stock bas'), backgroundColor: Colors.orange.shade100) : null),
        onTap: () async {
          final modifie = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => StockFormScreen(mois: arrivage.mois, arrivage: arrivage)),
          );
          if (modifie == true) onModifie();
        },
      ),
    );
  }
}
