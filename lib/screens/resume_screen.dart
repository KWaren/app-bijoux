import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/backup_service.dart';
import '../database/db_helper.dart';
import '../models/dette.dart';
import '../models/resume.dart';
import '../services/export_service.dart';
import '../state/app_state.dart';
import '../utils/date_ranges.dart';
import '../utils/formatters.dart';
import '../widgets/erreur_chargement.dart';
import '../widgets/month_selector.dart';

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
  bool _sauvegarde = false;
  bool _restauration = false;
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

  Future<void> _sauvegarder() async {
    setState(() => _sauvegarde = true);
    try {
      await BackupService.instance.partagerSauvegarde();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la sauvegarde : $e')));
      }
    } finally {
      if (mounted) setState(() => _sauvegarde = false);
    }
  }

  Future<void> _restaurer() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restaurer une sauvegarde ?'),
        content: const Text(
          "Toutes les données actuelles de l'appli (stock, ventes, dépenses, dettes) seront "
          'définitivement remplacées par le contenu du fichier de sauvegarde choisi. '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continuer')),
        ],
      ),
    );
    if (confirme != true) return;

    final resultat = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
    final chemin = resultat?.files.single.path;
    if (chemin == null) return;

    setState(() => _restauration = true);
    try {
      await BackupService.instance.restaurerDepuisFichier(chemin);
      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Sauvegarde restaurée'),
            content: const Text(
              "Ferme complètement l'application (pas juste revenir en arrière) puis rouvre-la "
              'pour voir les données restaurées.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la restauration : $e')));
      }
    } finally {
      if (mounted) setState(() => _restauration = false);
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
      appBar: AppBar(title: const Text('Résumé')),
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
                if (snapshot.hasError) {
                  return ErreurChargement(erreur: snapshot.error, onReessayer: _recharger);
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return FutureBuilder<List<Dette>>(
                  future: _futureDettes,
                  builder: (context, detteSnapshot) {
                    return _ResumeDetail(
                      resume: snapshot.data!,
                      dettesEnCours: detteSnapshot.data ?? const [],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _export ? null : _exporter,
              icon: const Icon(Icons.file_download_outlined),
              label: Text(_export ? 'Génération...' : 'Exporter en Excel'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _sauvegarde ? null : _sauvegarder,
              icon: const Icon(Icons.backup_outlined),
              label: Text(_sauvegarde ? 'Préparation...' : 'Partager une sauvegarde complète'),
            ),
            const SizedBox(height: 4),
            Text(
              'À faire régulièrement (WhatsApp, Drive, mail...) : la sauvegarde automatique quotidienne '
              "reste sur le téléphone et disparaît si l'appli est désinstallée.",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _restauration ? null : _restaurer,
              icon: const Icon(Icons.restore_outlined),
              label: Text(_restauration ? 'Restauration...' : 'Restaurer une sauvegarde'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
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
  final List<Dette> dettesEnCours;
  const _ResumeDetail({required this.resume, this.dettesEnCours = const []});

  void _afficherDetailDettes(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Dettes en cours'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: dettesEnCours
                .map((d) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(d.clientNom),
                      subtitle: d.description != null ? Text(d.description!) : null,
                      trailing: Text(formatMontant(d.montant), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalDettesEnCours = dettesEnCours.fold<double>(0, (s, d) => s + d.montant);
    final noms = dettesEnCours.map((d) => d.clientNom).toSet().join(', ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Ligne(label: 'Nombre de ventes', valeur: '${resume.nbVentes}'),
            _Ligne(label: 'Coût des marchandises vendues', valeur: formatMontant(resume.coutMarchandisesVendues)),
            _Ligne(label: 'Total des ventes', valeur: formatMontant(resume.totalVentes)),
            _Ligne(label: 'Total prix d\'achat', valeur: formatMontant(resume.totalAchats)),
            _Ligne(label: 'Nombre de marchandises achetées', valeur: '${resume.nbMarchandisesAchetees}'),
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
            if (dettesEnCours.isNotEmpty)
              InkWell(
                onTap: () => _afficherDetailDettes(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Dettes en cours : ${formatMontant(totalDettesEnCours)}\n$noms',
                          style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: Colors.orange.shade900),
                    ],
                  ),
                ),
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
