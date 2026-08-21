import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/db_helper.dart';
import '../models/arrivage.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
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
    const styleSub = TextStyle(fontSize: 12, color: Color(0xFF3F4550));
    // Le badge est placé sur la ligne du nom (mise en page du mockup) : en
    // `trailing` d'un ListTile il se retrouvait centré au milieu d'une carte
    // haute de 4 à 6 lignes, et amputait la largeur de tout le sous-titre.
    final badge = arrivage.stockEpuise
        ? const _BadgeStock(texte: 'Épuisé', fond: AppTheme.epuiseBg, encre: AppTheme.epuiseFg)
        : (arrivage.stockBas
            ? const _BadgeStock(texte: 'Stock bas', fond: AppTheme.stockBasBg, encre: AppTheme.stockBasFg)
            : null);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final modifie = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => StockFormScreen(mois: arrivage.mois, arrivage: arrivage)),
          );
          if (modifie == true) onModifie();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModelePhoto(photoPath: arrivage.photoPath, taille: 52),
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
                            arrivage.modele,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        if (badge != null) ...[const SizedBox(width: 8), badge],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Restant : ${arrivage.qteRestante} / ${arrivage.quantite}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    if (arrivage.qteEndommage > 0)
                      Text('Endommagé : ${arrivage.qteEndommage}', style: styleSub),
                    Wrap(
                      children: [
                        const Text('Prix achat unit. : ', style: styleSub),
                        PrixAchatText(valeur: arrivage.prixAchatUnitaire, style: styleSub),
                      ],
                    ),
                    if (arrivage.depensesLiees > 0)
                      Wrap(
                        children: [
                          const Text('Frais liés (transport, douane...) : ', style: styleSub),
                          PrixAchatText(valeur: arrivage.depensesLiees, style: styleSub),
                        ],
                      ),
                    if (arrivage.prixVenteMax != null)
                      Text('Prix vente max : ${formatMontant(arrivage.prixVenteMax!)}', style: styleSub),
                    if (arrivage.beneficeEstime != null)
                      Wrap(
                        children: [
                          const Text('Bénéfice min. estimé sur le restant : ', style: styleSub),
                          PrixAchatText(valeur: arrivage.beneficeEstime!, style: styleSub),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeStock extends StatelessWidget {
  final String texte;
  final Color fond;
  final Color encre;

  const _BadgeStock({required this.texte, required this.fond, required this.encre});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(100)),
      child: Text(
        texte,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: encre),
      ),
    );
  }
}
