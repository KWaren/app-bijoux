import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/arrivage.dart';
import '../models/dette.dart';
import '../models/vente.dart';
import '../utils/formatters.dart';
import '../widgets/modele_photo.dart';

class VenteFormScreen extends StatefulWidget {
  const VenteFormScreen({super.key});

  @override
  State<VenteFormScreen> createState() => _VenteFormScreenState();
}

class _VenteFormScreenState extends State<VenteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qteCtrl = TextEditingController(text: '1');
  final _prixVenteCtrl = TextEditingController();
  final _montantPayeCtrl = TextEditingController();

  List<Arrivage> _stock = [];
  List<String> _clients = [];
  Arrivage? _arrivageSelectionne;
  TextEditingController? _clientController;
  DateTime _dateVente = DateTime.now();
  bool _venteACredit = false;
  bool _chargement = true;
  bool _enregistrement = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final stock = await DbHelper.instance.getArrivagesEnStock();
    final clients = await DbHelper.instance.getClientsDistincts();
    setState(() {
      _stock = stock;
      _clients = clients;
      _chargement = false;
    });
  }

  @override
  void dispose() {
    _qteCtrl.dispose();
    _prixVenteCtrl.dispose();
    _montantPayeCtrl.dispose();
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

  Future<void> _valider() async {
    if (_arrivageSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choisis un modèle.')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final qte = int.parse(_qteCtrl.text);

    final client = _clientController?.text.trim() ?? '';
    if (client.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indique le nom du client.')));
      return;
    }

    setState(() => _enregistrement = true);

    // Revérifie le stock disponible juste avant d'enregistrer : le snapshot chargé à
    // l'ouverture du formulaire a pu devenir obsolète (autre vente entre-temps).
    final arrivageAJour = await DbHelper.instance.getArrivageById(_arrivageSelectionne!.id!);
    if (arrivageAJour == null || qte > arrivageAJour.bijouxRestant) {
      if (mounted) {
        setState(() => _enregistrement = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              arrivageAJour == null
                  ? 'Ce modèle a été supprimé entre-temps.'
                  : 'Il ne reste que ${arrivageAJour.bijouxRestant} pièce(s) pour ce modèle.',
            ),
          ),
        );
      }
      return;
    }

    final prixTotal = double.parse(_prixVenteCtrl.text.replaceAll(',', '.'));
    final dateIso =
        '${_dateVente.year.toString().padLeft(4, '0')}-${_dateVente.month.toString().padLeft(2, '0')}-${_dateVente.day.toString().padLeft(2, '0')}';

    final venteId = await DbHelper.instance.insertVente(Vente(
      arrivageId: _arrivageSelectionne!.id!,
      clientNom: client,
      dateVente: dateIso,
      qteVendue: qte,
      prixVenteTotal: prixTotal,
    ));

    // Met à jour le "dernier prix vendu" du modèle (prix unitaire moyen de cette vente),
    // sans toucher au reste de la fiche.
    await DbHelper.instance.updateArrivagePrixVenteLast(_arrivageSelectionne!.id!, prixTotal / qte);

    if (_venteACredit) {
      final montantPaye = double.tryParse(_montantPayeCtrl.text.replaceAll(',', '.')) ?? 0;
      final resteAPayer = prixTotal - montantPaye;
      if (resteAPayer > 0) {
        await DbHelper.instance.insertDette(Dette(
          clientNom: client,
          venteId: venteId,
          montant: resteAPayer,
          description: 'Reste à payer — ${_arrivageSelectionne!.modele}',
          dateDette: dateIso,
        ));
      }
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle vente')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_stock.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Aucun modèle en stock. Ajoute un arrivage avant de vendre.'),
              )
            else
              _ChampModele(
                stock: _stock,
                selectionne: _arrivageSelectionne,
                onSelected: (a) => setState(() => _arrivageSelectionne = a),
              ),
            const SizedBox(height: 12),
            if (_arrivageSelectionne != null)
              Row(
                children: [
                  ModelePhoto(photoPath: _arrivageSelectionne!.photoPath, taille: 44),
                  const SizedBox(width: 12),
                  Text('Restant : ${_arrivageSelectionne!.bijouxRestant}'),
                ],
              ),
            const SizedBox(height: 16),
            Autocomplete<String>(
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
            TextFormField(
              controller: _prixVenteCtrl,
              decoration: InputDecoration(labelText: 'Prix de vente total ($devise)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  (double.tryParse((v ?? '').replaceAll(',', '.')) == null) ? 'Montant invalide' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _qteCtrl,
              decoration: const InputDecoration(labelText: 'Quantité vendue'),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Nombre invalide';
                return null;
              },
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_enregistrement || _stock.isEmpty) ? null : _valider,
              child: Text(_enregistrement ? 'Enregistrement...' : 'Valider la vente'),
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
                        subtitle: Text('Restant : ${a.bijouxRestant}'),
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
