import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/dette.dart';
import '../models/vente.dart';
import '../utils/formatters.dart';
import '../widgets/modele_photo.dart';

class ClientDetailScreen extends StatefulWidget {
  final String clientNom;
  const ClientDetailScreen({super.key, required this.clientNom});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  late Future<List<Vente>> _futureVentes;
  late Future<List<Dette>> _futureDettes;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  void _charger() {
    _futureVentes = DbHelper.instance.getVentesByClient(widget.clientNom);
    _futureDettes = DbHelper.instance.getDettesByClient(widget.clientNom);
  }

  void _recharger() => setState(_charger);

  Future<void> _ajouterDette() async {
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
    final montant = double.tryParse(montantCtrl.text.replaceAll(',', '.'));
    if (montant == null) return;
    await DbHelper.instance.insertDette(Dette(
      clientNom: widget.clientNom,
      montant: montant,
      description: descriptionCtrl.text.trim().isEmpty ? null : descriptionCtrl.text.trim(),
      dateDette: dateDuJourIso(),
    ));
    _recharger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.clientNom)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Dettes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FutureBuilder<List<Dette>>(
            future: _futureDettes,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final dettes = snapshot.data!;
              if (dettes.isEmpty) return const Text('Aucune dette.');
              return Column(
                children: dettes
                    .map(
                      (d) => Card(
                        color: d.estPayee ? Colors.green.shade50 : null,
                        child: ListTile(
                          title: Text(formatMontant(d.montant)),
                          subtitle: Text(
                            '${d.description ?? ''}\n${formatDateAffichage(d.dateDette)} · ${d.estPayee ? 'Payée' : 'En cours'}',
                          ),
                          isThreeLine: true,
                          trailing: d.estPayee
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : TextButton(
                                  onPressed: () async {
                                    await DbHelper.instance.updateDetteStatut(d.id!, 'payee');
                                    _recharger();
                                  },
                                  child: const Text('Marquer payée'),
                                ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Historique des achats', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FutureBuilder<List<Vente>>(
            future: _futureVentes,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final ventes = snapshot.data!;
              if (ventes.isEmpty) return const Text('Aucun achat.');
              return Column(
                children: ventes
                    .map(
                      (v) => Card(
                        child: ListTile(
                          leading: ModelePhoto(photoPath: v.photoPath, taille: 44),
                          title: Text(v.modeleNom ?? ''),
                          subtitle: Text('${formatDateAffichage(v.dateVente)} · Qté ${v.qteVendue}'),
                          trailing: Text(
                            formatMontant(v.prixVenteTotal),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une dette'),
        onPressed: _ajouterDette,
      ),
    );
  }
}
