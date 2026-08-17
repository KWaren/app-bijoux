import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/db_helper.dart';
import '../models/modele_vendu.dart';
import '../models/resume.dart';
import '../state/app_state.dart';
import '../utils/date_ranges.dart';
import '../utils/error_log.dart';
import '../utils/formatters.dart';
import '../widgets/erreur_chargement.dart';
import '../widgets/evolution_mensuelle_chart.dart';
import '../widgets/month_selector.dart';
import '../widgets/price_hidden_widget.dart';
import 'depenses_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _futureData;
  String? _moisCharge;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mois = context.watch<AppState>().moisSelectionne;
    if (mois != _moisCharge) {
      _moisCharge = mois;
      _futureData = _charger(mois);
    }
  }

  Future<_HomeData> _charger(String mois) async {
    final periode = rangeMois(mois);
    final resume = await DbHelper.instance.getResume(periode.debut, periode.fin);
    final enStock = await DbHelper.instance.getArrivagesEnStock();
    final nbStockBas = enStock.where((a) => a.stockBas || a.stockEpuise).length;
    final beneficePotentielRestant = enStock
        .where((a) => a.beneficeEstime != null)
        .fold<double>(0, (total, a) => total + a.beneficeEstime!);
    final dettes = await DbHelper.instance.getTotalDettesEnCours();
    final topModeles = await DbHelper.instance.getTopModeles(periode.debut, periode.fin);
    final evolution = await DbHelper.instance.getResumeDerniersMois(mois, 6);
    return _HomeData(
      resume: resume,
      nbStockBas: nbStockBas,
      dettesEnCours: dettes,
      beneficePotentielRestant: beneficePotentielRestant,
      topModeles: topModeles,
      evolution: evolution,
    );
  }

  void _recharger() {
    setState(() {
      _futureData = _charger(_moisCharge ?? moisActuel());
    });
  }

  /// Journal des erreurs de mise en page/peinture, invisibles autrement en
  /// release (voir ErrorLog) — accessible ici pour diagnostiquer un écran
  /// qui resterait vide sans indice.
  Future<void> _voirJournalErreurs() async {
    final texte = await ErrorLog.lire();
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Journal des erreurs'),
        content: SingleChildScrollView(child: SelectableText(texte, style: const TextStyle(fontSize: 12))),
        actions: [
          TextButton(
            onPressed: () async {
              await ErrorLog.effacer();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Effacer'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Bijoux'),
        actions: [
          IconButton(
            tooltip: 'Journal des erreurs',
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: _voirJournalErreurs,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _recharger(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const MonthSelector(),
            const SizedBox(height: 16),
            FutureBuilder<_HomeData>(
              future: _futureData,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErreurChargement(erreur: snapshot.error, onReessayer: _recharger);
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final data = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResumeCards(data: data),
                    const SizedBox(height: 24),
                    Text('Modèles les plus vendus', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _TopModeles(topModeles: data.topModeles),
                    const SizedBox(height: 24),
                    Text('Évolution sur 6 mois', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: EvolutionMensuelleChart(resumes: data.evolution),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text('Accès rapide', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.receipt_long),
              label: const Text('Ajouter une dépense annexe'),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const DepensesScreen()));
                _recharger();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeData {
  final ResumePeriode resume;
  final int nbStockBas;
  final double dettesEnCours;
  final double beneficePotentielRestant;
  final List<ModeleVendu> topModeles;
  final List<ResumePeriode> evolution;

  _HomeData({
    required this.resume,
    required this.nbStockBas,
    required this.dettesEnCours,
    required this.beneficePotentielRestant,
    required this.topModeles,
    required this.evolution,
  });
}

class _ResumeCards extends StatelessWidget {
  final _HomeData data;
  const _ResumeCards({required this.data});

  @override
  Widget build(BuildContext context) {
    final cartes = [
      _StatCard(
        label: 'Ventes du mois',
        valeur: formatMontant(data.resume.totalVentes),
        icone: Icons.point_of_sale,
      ),
      _StatCard(
        label: 'Bénéfice du mois',
        valeur: data.resume.margeEnPourcent != null
            ? '${formatMontant(data.resume.benefice)}\n(${data.resume.margeEnPourcent!.toStringAsFixed(1)} %)'
            : formatMontant(data.resume.benefice),
        icone: Icons.trending_up,
        couleur: data.resume.benefice >= 0 ? Colors.green.shade700 : Colors.red.shade700,
      ),
      _StatCard(
        label: 'Modèles en stock bas',
        valeur: '${data.nbStockBas}',
        icone: Icons.warning_amber_rounded,
        couleur: data.nbStockBas > 0 ? Colors.orange.shade800 : null,
      ),
      _StatCard(
        label: 'Dettes en cours',
        valeur: formatMontant(data.dettesEnCours),
        icone: Icons.receipt_long,
      ),
      _StatCard(
        label: 'Bénéfice min. garanti sur le stock restant',
        icone: Icons.savings_outlined,
        valeurMasquee: data.beneficePotentielRestant,
      ),
    ];
    // Rangées de 2 cartes dont la hauteur s'adapte au contenu (plutôt qu'un
    // GridView à ratio fixe qui fait déborder le texte hors de la carte
    // quand une valeur est longue ou que la police système est agrandie).
    return Column(
      children: [
        for (var i = 0; i < cartes.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < cartes.length ? 12 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cartes[i]),
                const SizedBox(width: 12),
                Expanded(child: i + 1 < cartes.length ? cartes[i + 1] : const SizedBox()),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String? valeur;
  final double? valeurMasquee;
  final IconData icone;
  final Color? couleur;

  const _StatCard({
    required this.label,
    this.valeur,
    this.valeurMasquee,
    required this.icone,
    this.couleur,
  }) : assert(valeur != null || valeurMasquee != null);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: couleur),
            const SizedBox(height: 6),
            if (valeurMasquee != null)
              PrixAchatText(
                valeur: valeurMasquee!,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: couleur),
              )
            else
              Text(valeur!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: couleur)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _TopModeles extends StatelessWidget {
  final List<ModeleVendu> topModeles;
  const _TopModeles({required this.topModeles});

  @override
  Widget build(BuildContext context) {
    if (topModeles.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Aucune vente sur cette période.'),
        ),
      );
    }
    return Card(
      child: Column(
        children: topModeles.asMap().entries.map((entry) {
          final rang = entry.key + 1;
          final m = entry.value;
          return ListTile(
            leading: CircleAvatar(child: Text('$rang')),
            title: Text(m.modele),
            subtitle: Text('${m.qteVendue} vendu(s)'),
            trailing: Text(formatMontant(m.totalVentes), style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        }).toList(),
      ),
    );
  }
}
