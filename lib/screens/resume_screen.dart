import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/db_helper.dart';
import '../models/dette.dart';
import '../models/resume.dart';
import '../services/export_service.dart';
import '../state/app_state.dart';
import '../utils/date_ranges.dart';
import '../utils/formatters.dart';
import '../widgets/month_selector.dart';
import 'depenses_screen.dart';

enum _TypePeriode { jour, semaine, mois }

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  _TypePeriode _type = _TypePeriode.mois;
  DateTime _dateReference = DateTime.now();
  Future<ResumePeriode>? _futureResume;
  Future<List<Dette>>? _futureDettes;
  Periode? _periodeActuelle;
  bool _export = false;
  String? _moisVu;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mois = context.watch<AppState>().moisSelectionne;
    final doitRecharger = _futureResume == null || (_type == _TypePeriode.mois && mois != _moisVu);
    _moisVu = mois;
    if (doitRecharger) _recharger();
  }

  Periode _calculerPeriode() {
    switch (_type) {
      case _TypePeriode.jour:
        return rangeJour(_dateReference);
      case _TypePeriode.semaine:
        return rangeSemaine(_dateReference);
      case _TypePeriode.mois:
        return rangeMois(context.read<AppState>().moisSelectionne);
    }
  }

  void _recharger() {
    final periode = _calculerPeriode();
    setState(() {
      _periodeActuelle = periode;
      _futureResume = DbHelper.instance.getResume(periode.debut, periode.fin);
      _futureDettes = DbHelper.instance.getDettesEnCours();
    });
  }

  void _naviguer(int sens) {
    setState(() {
      _dateReference = _type == _TypePeriode.semaine
          ? _dateReference.add(Duration(days: 7 * sens))
          : _dateReference.add(Duration(days: sens));
    });
    _recharger();
  }

  Future<void> _exporter() async {
    if (_periodeActuelle == null) return;
    setState(() => _export = true);
    try {
      await ExportService().genererEtPartager(_periodeActuelle!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de l'export : $e")));
      }
    } finally {
      if (mounted) setState(() => _export = false);
    }
  }

  Future<void> _ajouterDette() async {
    final clientCtrl = TextEditingController();
    final montantCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    final ajoute = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une dette'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: clientCtrl,
              decoration: const InputDecoration(labelText: 'Nom du client'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: montantCtrl,
              decoration: InputDecoration(labelText: 'Montant ($devise)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionCtrl,
              decoration: const InputDecoration(labelText: 'Description (optionnel)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ajouter')),
        ],
      ),
    );
    if (ajoute != true) return;
    final client = clientCtrl.text.trim();
    final montant = double.tryParse(montantCtrl.text.replaceAll(',', '.'));
    if (client.isEmpty || montant == null) return;
    await DbHelper.instance.insertDette(Dette(
      clientNom: client,
      montant: montant,
      description: descriptionCtrl.text.trim().isEmpty ? null : descriptionCtrl.text.trim(),
      dateDette: dateDuJourIso(),
    ));
    _recharger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résumé'),
        actions: [
          IconButton(
            tooltip: 'Autres dépenses',
            icon: const Icon(Icons.receipt_long),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const DepensesScreen()));
              _recharger();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _recharger(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<_TypePeriode>(
              segments: const [
                ButtonSegment(value: _TypePeriode.jour, label: Text('Jour')),
                ButtonSegment(value: _TypePeriode.semaine, label: Text('Semaine')),
                ButtonSegment(value: _TypePeriode.mois, label: Text('Mois')),
              ],
              selected: {_type},
              onSelectionChanged: (s) {
                setState(() => _type = s.first);
                _recharger();
              },
            ),
            const SizedBox(height: 16),
            if (_type == _TypePeriode.mois)
              const MonthSelector()
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _naviguer(-1)),
                  Text(
                    _periodeActuelle?.libelle ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _naviguer(1)),
                ],
              ),
            const SizedBox(height: 16),
            FutureBuilder<ResumePeriode>(
              future: _futureResume,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _ResumeDetail(resume: snapshot.data!);
              },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _export ? null : _exporter,
              icon: const Icon(Icons.file_download_outlined),
              label: Text(_export ? 'Génération...' : 'Exporter en Excel'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Dettes en cours', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: _ajouterDette,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Dette>>(
              future: _futureDettes,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final dettes = snapshot.data!;
                if (dettes.isEmpty) {
                  return const Text('Aucune dette en cours.');
                }
                return Column(
                  children: dettes
                      .map((d) => Card(
                            child: ListTile(
                              title: Text(d.clientNom),
                              subtitle: Text(
                                '${d.description ?? ''}\n${formatDateAffichage(d.dateDette)}',
                              ),
                              isThreeLine: true,
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(formatMontant(d.montant), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  TextButton(
                                    onPressed: () async {
                                      await DbHelper.instance.updateDetteStatut(d.id!, 'payee');
                                      _recharger();
                                    },
                                    child: const Text('Marquer payée'),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeDetail extends StatelessWidget {
  final ResumePeriode resume;
  const _ResumeDetail({required this.resume});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Ligne(label: 'Nombre de ventes', valeur: '${resume.nbVentes}'),
            _Ligne(label: "Total prix d'achat", valeur: formatMontant(resume.totalAchat)),
            _Ligne(label: 'Total des ventes', valeur: formatMontant(resume.totalVentes)),
            _Ligne(label: 'Dépenses', valeur: formatMontant(resume.totalDepenses)),
            _Ligne(label: 'Pertes (casse)', valeur: formatMontant(resume.totalPertes)),
            const Divider(),
            _Ligne(
              label: 'Bénéfice',
              valeur: resume.margeEnPourcent != null
                  ? '${formatMontant(resume.benefice)} (${resume.margeEnPourcent!.toStringAsFixed(1)} %)'
                  : formatMontant(resume.benefice),
              gras: true,
              couleur: resume.benefice >= 0 ? Colors.green.shade700 : Colors.red.shade700,
            ),
            if (resume.dettesCreees > 0)
              _Ligne(label: 'Nouvelles dettes sur la période', valeur: formatMontant(resume.dettesCreees)),
          ],
        ),
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  final String label;
  final String valeur;
  final bool gras;
  final Color? couleur;

  const _Ligne({required this.label, required this.valeur, this.gras = false, this.couleur});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: gras ? FontWeight.bold : FontWeight.normal,
      fontSize: gras ? 17 : 14,
      color: couleur,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(valeur, style: style),
        ],
      ),
    );
  }
}
