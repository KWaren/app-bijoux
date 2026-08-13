import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/db_helper.dart';
import '../models/resume.dart';
import '../state/app_state.dart';
import '../utils/date_ranges.dart';
import '../utils/formatters.dart';
import '../widgets/month_selector.dart';
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
    final dettes = await DbHelper.instance.getTotalDettesEnCours();
    return _HomeData(resume: resume, nbStockBas: nbStockBas, dettesEnCours: dettes);
  }

  void _recharger() {
    setState(() {
      _futureData = _charger(_moisCharge ?? moisActuel());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Bijoux')),
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
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _ResumeCards(data: snapshot.data!);
              },
            ),
            const SizedBox(height: 24),
            Text('Accès rapide', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ActionChip(
              avatar: const Icon(Icons.receipt_long, size: 18),
              label: const Text('Autres dépenses'),
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

  _HomeData({required this.resume, required this.nbStockBas, required this.dettesEnCours});
}

class _ResumeCards extends StatelessWidget {
  final _HomeData data;
  const _ResumeCards({required this.data});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          label: 'Ventes du mois',
          valeur: formatMontant(data.resume.totalVentes),
          icone: Icons.point_of_sale,
        ),
        _StatCard(
          label: 'Bénéfice du mois',
          valeur: formatMontant(data.resume.benefice),
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
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String valeur;
  final IconData icone;
  final Color? couleur;

  const _StatCard({required this.label, required this.valeur, required this.icone, this.couleur});

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
            Text(valeur, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: couleur)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
