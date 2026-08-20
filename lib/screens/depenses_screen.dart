import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/db_helper.dart';
import '../models/arrivage.dart';
import '../models/depense.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/month_selector.dart';

class DepensesScreen extends StatefulWidget {
  const DepensesScreen({super.key});

  @override
  State<DepensesScreen> createState() => _DepensesScreenState();
}

class _DepensesScreenState extends State<DepensesScreen> {
  Future<List<Depense>>? _futureDepenses;
  String? _moisCharge;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mois = context.watch<AppState>().moisSelectionne;
    if (mois != _moisCharge) {
      _moisCharge = mois;
      _recharger();
    }
  }

  void _recharger() {
    setState(() {
      _futureDepenses = DbHelper.instance.getDepensesByMois(_moisCharge!);
    });
  }

  Future<void> _ajouterDepense() async {
    final designationCtrl = TextEditingController();
    final coutCtrl = TextEditingController();
    DateTime dateDepense = DateTime.now();
    Arrivage? arrivageLie;

    final arrivages = await DbHelper.instance.getTousLesArrivages();

    final ajoute = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle dépense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: designationCtrl,
                  decoration: const InputDecoration(labelText: 'Désignation (ex : Sachets, Transport...)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: coutCtrl,
                  decoration: InputDecoration(labelText: 'Coût ($devise)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(formatDateAffichage(
                    '${dateDepense.year.toString().padLeft(4, '0')}-${dateDepense.month.toString().padLeft(2, '0')}-${dateDepense.day.toString().padLeft(2, '0')}',
                  )),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final choix = await showDatePicker(
                      context: context,
                      initialDate: dateDepense,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (choix != null) setDialogState(() => dateDepense = choix);
                  },
                ),
                if (arrivages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Autocomplete<Arrivage>(
                    displayStringForOption: (a) => a.modele,
                    optionsBuilder: (v) {
                      if (v.text.isEmpty) return arrivages;
                      return arrivages.where((a) => a.modele.toLowerCase().contains(v.text.toLowerCase()));
                    },
                    onSelected: (a) => setDialogState(() => arrivageLie = a),
                    fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Lié à un modèle (optionnel)',
                          helperText: 'Ex : frais de transport ou de douane pour ce lot',
                          suffixIcon: arrivageLie != null
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    controller.clear();
                                    setDialogState(() => arrivageLie = null);
                                  },
                                )
                              : null,
                        ),
                        onChanged: (t) {
                          if (t.isEmpty && arrivageLie != null) setDialogState(() => arrivageLie = null);
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ajouter')),
          ],
        ),
      ),
    );

    if (ajoute != true) return;
    final cout = double.tryParse(coutCtrl.text.replaceAll(',', '.'));
    if (designationCtrl.text.trim().isEmpty || cout == null) return;

    final mois =
        '${dateDepense.year.toString().padLeft(4, '0')}-${dateDepense.month.toString().padLeft(2, '0')}';
    final dateIso = '$mois-${dateDepense.day.toString().padLeft(2, '0')}';

    await DbHelper.instance.insertDepense(Depense(
      mois: mois,
      dateDepense: dateIso,
      designation: designationCtrl.text.trim(),
      cout: cout,
      arrivageId: arrivageLie?.id,
    ));
    if (mounted) {
      final appState = context.read<AppState>();
      appState.ajouterMoisSiAbsent(mois);
      appState.signalerChangement();
      _recharger();
    }
  }

  Future<void> _supprimer(Depense d) async {
    if (d.id == null) return;
    await DbHelper.instance.deleteDepense(d.id!);
    if (mounted) context.read<AppState>().signalerChangement();
    _recharger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Autres dépenses')),
      body: Column(
        children: [
          const Padding(padding: EdgeInsets.all(16), child: MonthSelector()),
          Expanded(
            child: FutureBuilder<List<Depense>>(
              future: _futureDepenses,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final depenses = snapshot.data!;
                if (depenses.isEmpty) {
                  return const Center(
                    child: Padding(padding: EdgeInsets.all(24), child: Text('Aucune dépense ce mois-ci.')),
                  );
                }
                final total = depenses.fold<double>(0, (s, d) => s + d.cout);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text('Total : ${formatMontant(total)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 90),
                        itemCount: depenses.length,
                        itemBuilder: (context, index) {
                          final d = depenses[index];
                          return Card(
                            child: ListTile(
                              title: Text(d.designation),
                              subtitle: Text(
                                d.modeleNom != null
                                    ? '${formatDateAffichage(d.dateDepense)} · Lié à ${d.modeleNom}'
                                    : formatDateAffichage(d.dateDepense),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    formatMontant(d.cout),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.rougeAlerte),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    onPressed: () => _supprimer(d),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        onPressed: _ajouterDepense,
      ),
    );
  }
}
