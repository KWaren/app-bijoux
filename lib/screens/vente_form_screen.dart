import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/db_helper.dart';
import '../models/arrivage.dart';
import '../models/dette.dart';
import '../models/vente.dart';
import '../models/vente_ligne.dart';
import '../state/app_state.dart';
import '../utils/formatters.dart';
import '../widgets/modele_photo.dart';

class VenteFormScreen extends StatefulWidget {
  final Vente? vente;

  const VenteFormScreen({super.key, this.vente});

  @override
  State<VenteFormScreen> createState() => _VenteFormScreenState();
}

/// État d'une ligne modèle/quantité/prix en cours de saisie dans le formulaire.
class _LigneVenteState {
  Arrivage? arrivage;
  final TextEditingController qteCtrl;
  final TextEditingController prixCtrl;

  _LigneVenteState({this.arrivage, String qte = '1', String prix = ''})
      : qteCtrl = TextEditingController(text: qte),
        prixCtrl = TextEditingController(text: prix);

  void dispose() {
    qteCtrl.dispose();
    prixCtrl.dispose();
  }
}

class _VenteFormScreenState extends State<VenteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montantPayeCtrl = TextEditingController();
  late final TextEditingController _noteCtrl;

  List<Arrivage> _stock = [];
  List<String> _clients = [];
  List<_LigneVenteState> _lignes = [];
  TextEditingController? _clientController;
  late DateTime _dateVente;
  bool _venteACredit = false;
  String _modePaiement = ModePaiement.especes;
  bool _chargement = true;
  bool _enregistrement = false;

  bool get _modeEdition => widget.vente != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vente;
    _noteCtrl = TextEditingController(text: v?.note ?? '');
    _dateVente = v != null ? DateTime.parse(v.dateVente) : DateTime.now();
    _modePaiement = v?.modePaiement ?? ModePaiement.especes;
    _charger();
  }

  String _formatNombre(double valeur) {
    if (valeur == valeur.roundToDouble()) return valeur.toStringAsFixed(0);
    return valeur.toStringAsFixed(2);
  }

  Future<void> _charger() async {
    final clients = await DbHelper.instance.getClientsDistincts();
    final stockDisponible = await DbHelper.instance.getArrivagesEnStock();
    final stockParId = {for (final a in stockDisponible) a.id!: a};

    List<_LigneVenteState> lignes;
    if (_modeEdition) {
      // Un modèle déjà vendu ici peut ne plus avoir de stock disponible ; on le
      // garde visible/sélectionnable dans le formulaire d'édition malgré tout.
      for (final l in widget.vente!.lignes) {
        if (!stockParId.containsKey(l.arrivageId)) {
          final a = await DbHelper.instance.getArrivageById(l.arrivageId);
          if (a != null) stockParId[a.id!] = a;
        }
      }
      lignes = widget.vente!.lignes
          .map((l) => _LigneVenteState(
                arrivage: stockParId[l.arrivageId],
                qte: l.qteVendue.toString(),
                prix: _formatNombre(l.prixLigne),
              ))
          .toList();
    } else {
      lignes = [_LigneVenteState()];
    }

    if (!mounted) return;
    setState(() {
      _stock = stockParId.values.toList()..sort((a, b) => a.modele.compareTo(b.modele));
      _clients = clients;
      _lignes = lignes;
      _chargement = false;
    });
  }

  @override
  void dispose() {
    for (final l in _lignes) {
      l.dispose();
    }
    _montantPayeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final choix = await showDatePicker(
      context: context,
      initialDate: _dateVente,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Date de la vente',
    );
    if (choix != null) setState(() => _dateVente = choix);
  }

  void _ajouterLigne() {
    setState(() => _lignes.add(_LigneVenteState()));
  }

  void _retirerLigne(int index) {
    setState(() {
      _lignes[index].dispose();
      _lignes.removeAt(index);
    });
  }

  double get _prixTotal {
    var total = 0.0;
    for (final l in _lignes) {
      total += double.tryParse(l.prixCtrl.text.replaceAll(',', '.')) ?? 0;
    }
    return total;
  }

  Future<void> _valider() async {
    if (!_formKey.currentState!.validate()) return;

    final lignesValides = _lignes.where((l) => l.arrivage != null).toList();
    if (lignesValides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choisis au moins un modèle.')));
      return;
    }

    final client = _clientController?.text.trim() ?? '';
    if (client.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indique le nom du client.')));
      return;
    }

    setState(() => _enregistrement = true);

    // Regroupe les quantités demandées par arrivage (au cas où deux lignes
    // portent sur le même modèle) avant de revérifier le stock disponible :
    // le snapshot chargé à l'ouverture du formulaire a pu devenir obsolète.
    final ancienneQteParArrivage = <int, int>{};
    if (_modeEdition) {
      for (final l in widget.vente!.lignes) {
        ancienneQteParArrivage[l.arrivageId] = (ancienneQteParArrivage[l.arrivageId] ?? 0) + l.qteVendue;
      }
    }
    final qteDemandeeParArrivage = <int, int>{};
    for (final l in lignesValides) {
      final id = l.arrivage!.id!;
      qteDemandeeParArrivage[id] = (qteDemandeeParArrivage[id] ?? 0) + int.parse(l.qteCtrl.text);
    }

    for (final entry in qteDemandeeParArrivage.entries) {
      final arrivageAJour = await DbHelper.instance.getArrivageById(entry.key);
      final ancienneQte = ancienneQteParArrivage[entry.key] ?? 0;
      final restantDisponible = arrivageAJour == null ? 0 : arrivageAJour.qteRestante + ancienneQte;
      if (arrivageAJour == null || entry.value > restantDisponible) {
        if (mounted) {
          setState(() => _enregistrement = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                arrivageAJour == null
                    ? 'Un modèle a été supprimé entre-temps.'
                    : 'Il ne reste que $restantDisponible pièce(s) pour "${arrivageAJour.modele}".',
              ),
            ),
          );
        }
        return;
      }
    }

    final dateIso =
        '${_dateVente.year.toString().padLeft(4, '0')}-${_dateVente.month.toString().padLeft(2, '0')}-${_dateVente.day.toString().padLeft(2, '0')}';
    final mois = dateIso.substring(0, 7);
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    final prixTotal = _prixTotal;

    final lignesAEnregistrer = lignesValides
        .map((l) => VenteLigne(
              arrivageId: l.arrivage!.id!,
              qteVendue: int.parse(l.qteCtrl.text),
              prixLigne: double.parse(l.prixCtrl.text.replaceAll(',', '.')),
            ))
        .toList();

    if (_modeEdition) {
      await DbHelper.instance.updateVente(
        Vente(
          id: widget.vente!.id,
          clientNom: client,
          dateVente: dateIso,
          prixVenteTotal: prixTotal,
          modePaiement: _modePaiement,
          note: note,
        ),
        lignesAEnregistrer,
      );
    } else {
      final venteId = await DbHelper.instance.insertVente(
        Vente(
          clientNom: client,
          dateVente: dateIso,
          prixVenteTotal: prixTotal,
          modePaiement: _modePaiement,
          note: note,
        ),
        lignesAEnregistrer,
      );

      if (_venteACredit) {
        final montantPaye = double.tryParse(_montantPayeCtrl.text.replaceAll(',', '.')) ?? 0;
        final resteAPayer = prixTotal - montantPaye;
        if (resteAPayer > 0) {
          final modeles = lignesValides.map((l) => l.arrivage!.modele).join(', ');
          await DbHelper.instance.insertDette(Dette(
            clientNom: client,
            venteId: venteId,
            montant: resteAPayer,
            description: 'Reste à payer — $modeles',
            dateDette: dateIso,
          ));
        }
      }
    }

    if (mounted) {
      // Comme pour le stock : sans ça, une vente enregistrée pour un mois différent
      // de celui affiché à l'écran devient invisible tant qu'on ne le sélectionne pas.
      final appState = context.read<AppState>();
      appState.ajouterMoisSiAbsent(mois);
      appState.signalerChangement();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final aucunStock = _stock.isEmpty && !_modeEdition;
    return Scaffold(
      appBar: AppBar(title: Text(_modeEdition ? 'Modifier la vente' : 'Nouvelle vente')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (aucunStock)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Aucun modèle en stock. Ajoute un arrivage avant de vendre.'),
              )
            else ...[
              for (var i = 0; i < _lignes.length; i++) ...[
                _LigneVenteWidget(
                  key: ObjectKey(_lignes[i]),
                  stock: _stock,
                  ligne: _lignes[i],
                  onModifie: () => setState(() {}),
                  onSupprimer: _lignes.length > 1 ? () => _retirerLigne(i) : null,
                ),
                const SizedBox(height: 8),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _ajouterLigne,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un modèle'),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total : ${formatMontant(_prixTotal)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: widget.vente?.clientNom ?? ''),
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                return _clients.where(
                  (c) => c.toLowerCase().contains(textEditingValue.text.toLowerCase()),
                );
              },
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                _clientController = controller;
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(labelText: 'Nom du client'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                );
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date de la vente'),
              subtitle: Text(formatDateAffichage(
                '${_dateVente.year.toString().padLeft(4, '0')}-${_dateVente.month.toString().padLeft(2, '0')}-${_dateVente.day.toString().padLeft(2, '0')}',
              )),
              trailing: const Icon(Icons.calendar_month),
              onTap: _choisirDate,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _modePaiement,
              decoration: const InputDecoration(labelText: 'Mode de paiement'),
              items: ModePaiement.libelles.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _modePaiement = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (optionnel)',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            if (_modeEdition)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  "Pour enregistrer un paiement sur la dette éventuellement liée à cette vente, "
                  "reviens à la liste des ventes et touche l'étiquette « À crédit ».",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              )
            else ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vente à crédit / paiement partiel'),
                value: _venteACredit,
                onChanged: (v) => setState(() => _venteACredit = v),
              ),
              if (_venteACredit)
                TextFormField(
                  controller: _montantPayeCtrl,
                  decoration: InputDecoration(labelText: 'Montant payé maintenant ($devise)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_enregistrement || aucunStock) ? null : _valider,
              child: Text(_enregistrement ? 'Enregistrement...' : 'Valider la vente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LigneVenteWidget extends StatelessWidget {
  final List<Arrivage> stock;
  final _LigneVenteState ligne;
  final VoidCallback onModifie;
  final VoidCallback? onSupprimer;

  const _LigneVenteWidget({
    super.key,
    required this.stock,
    required this.ligne,
    required this.onModifie,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _ChampModele(
                    stock: stock,
                    selectionne: ligne.arrivage,
                    onSelected: (a) {
                      ligne.arrivage = a;
                      onModifie();
                    },
                  ),
                ),
                if (onSupprimer != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onSupprimer,
                    tooltip: 'Retirer ce modèle',
                  ),
              ],
            ),
            if (ligne.arrivage != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Row(
                  children: [
                    ModelePhoto(photoPath: ligne.arrivage!.photoPath, taille: 36),
                    const SizedBox(width: 12),
                    Text('Restant : ${ligne.arrivage!.qteRestante}'),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: ligne.qteCtrl,
                    decoration: const InputDecoration(labelText: 'Quantité'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (ligne.arrivage == null) return null;
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Nombre invalide';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: ligne.prixCtrl,
                    decoration: InputDecoration(labelText: 'Prix ($devise)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => onModifie(),
                    validator: (v) {
                      if (ligne.arrivage == null) return null;
                      if (double.tryParse((v ?? '').replaceAll(',', '.')) == null) return 'Montant invalide';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChampModele extends StatelessWidget {
  final List<Arrivage> stock;
  final Arrivage? selectionne;
  final ValueChanged<Arrivage> onSelected;

  const _ChampModele({required this.stock, required this.selectionne, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Arrivage>(
      displayStringForOption: (a) => a.modele,
      initialValue: TextEditingValue(text: selectionne?.modele ?? ''),
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return stock;
        return stock.where((a) => a.modele.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(labelText: 'Modèle'),
          validator: (_) => selectionne == null ? 'Choisis un modèle' : null,
        );
      },
      optionsViewBuilder: (context, onSelectedOption, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 32,
              height: options.length > 4 ? 280 : null,
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: options.length <= 4,
                children: options
                    .map(
                      (a) => ListTile(
                        leading: ModelePhoto(photoPath: a.photoPath, taille: 36),
                        title: Text(a.modele),
                        subtitle: Text('Restant : ${a.qteRestante}'),
                        onTap: () => onSelectedOption(a),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
