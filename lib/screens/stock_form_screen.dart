import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/db_helper.dart';
import '../models/arrivage.dart';
import '../utils/formatters.dart';
import '../widgets/modele_photo.dart';

class StockFormScreen extends StatefulWidget {
  final String mois;
  final Arrivage? arrivage;

  const StockFormScreen({super.key, required this.mois, this.arrivage});

  @override
  State<StockFormScreen> createState() => _StockFormScreenState();
}

class _StockFormScreenState extends State<StockFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _modeleCtrl;
  late TextEditingController _quantiteCtrl;
  late TextEditingController _prixAchatTotalCtrl;
  late TextEditingController _qteEndommageCtrl;
  late TextEditingController _prixVenteMaxCtrl;
  late TextEditingController _prixVenteLastCtrl;
  late TextEditingController _prixVenteMinCtrl;
  late DateTime _dateAjout;
  String? _photoPath;
  bool _enregistrement = false;

  bool get _modeEdition => widget.arrivage != null;

  @override
  void initState() {
    super.initState();
    final a = widget.arrivage;
    _modeleCtrl = TextEditingController(text: a?.modele ?? '');
    _quantiteCtrl = TextEditingController(text: a != null ? a.quantite.toString() : '');
    _prixAchatTotalCtrl = TextEditingController(text: a != null ? _formatNombre(a.prixAchatTotal) : '');
    _qteEndommageCtrl = TextEditingController(text: a != null ? a.qteEndommage.toString() : '0');
    _prixVenteMaxCtrl = TextEditingController(text: a?.prixVenteMax != null ? _formatNombre(a!.prixVenteMax!) : '');
    _prixVenteLastCtrl = TextEditingController(text: a?.prixVenteLast != null ? _formatNombre(a!.prixVenteLast!) : '');
    _prixVenteMinCtrl = TextEditingController(text: a?.prixVenteMin != null ? _formatNombre(a!.prixVenteMin!) : '');
    _dateAjout = a != null ? DateTime.parse(a.dateAjout) : _premierJourUtileDuMois(widget.mois);
    _photoPath = a?.photoPath;
    _quantiteCtrl.addListener(_recalculer);
    _prixAchatTotalCtrl.addListener(_recalculer);
    _qteEndommageCtrl.addListener(_recalculer);
    _prixVenteMinCtrl.addListener(_recalculer);
  }

  /// Affiche un nombre sans décimales inutiles (ex: 15000 plutôt que 15000.0).
  String _formatNombre(double valeur) {
    if (valeur == valeur.roundToDouble()) return valeur.toStringAsFixed(0);
    return valeur.toStringAsFixed(2);
  }

  double? get _prixUnitaireCalcule {
    final quantite = int.tryParse(_quantiteCtrl.text);
    final total = double.tryParse(_prixAchatTotalCtrl.text.replaceAll(',', '.'));
    if (quantite == null || quantite <= 0 || total == null) return null;
    return total / quantite;
  }

  /// Frais déjà rattachés à cet arrivage (transport, douane...) en mode édition.
  /// Nul à la création : on ne peut lier une dépense qu'à un arrivage déjà enregistré.
  double get _depensesLieesExistantes => widget.arrivage?.depensesLiees ?? 0;

  /// Bénéfice minimum garanti sur le stock restant si tout est vendu au prix de
  /// vente minimum saisi, frais annexes déjà rattachés inclus. Recalculé en
  /// direct pendant la saisie du formulaire (même logique que
  /// `Arrivage.beneficeEstime`, avant enregistrement).
  double? get _beneficeEstimeCalcule {
    final quantite = int.tryParse(_quantiteCtrl.text);
    final prixAchatTotal = double.tryParse(_prixAchatTotalCtrl.text.replaceAll(',', '.'));
    final prixVenteMin = double.tryParse(_prixVenteMinCtrl.text.replaceAll(',', '.'));
    if (quantite == null || quantite <= 0 || prixAchatTotal == null || prixVenteMin == null) return null;
    final qteEndommage = int.tryParse(_qteEndommageCtrl.text) ?? 0;
    final qteVendue = widget.arrivage?.qteVendue ?? 0;
    final restant = quantite - qteEndommage - qteVendue;
    if (restant <= 0) return null;
    final coutUnitaire = (prixAchatTotal + _depensesLieesExistantes) / quantite;
    return restant * (prixVenteMin - coutUnitaire);
  }

  void _recalculer() => setState(() {});

  /// Les prix de vente max/dernier/min sont optionnels : un champ vide est
  /// valide, mais un texte non vide doit être un nombre (sinon `double.parse`
  /// plante à l'enregistrement).
  String? _validateurMontantOptionnel(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.')) == null ? 'Montant invalide' : null;
  }

  DateTime _premierJourUtileDuMois(String moisYYYYMM) {
    final parts = moisYYYYMM.split('-');
    final annee = int.parse(parts[0]);
    final mois = int.parse(parts[1]);
    final maintenant = DateTime.now();
    if (annee == maintenant.year && mois == maintenant.month) return maintenant;
    return DateTime(annee, mois, 1);
  }

  @override
  void dispose() {
    _modeleCtrl.dispose();
    _quantiteCtrl.dispose();
    _prixAchatTotalCtrl.dispose();
    _qteEndommageCtrl.dispose();
    _prixVenteMaxCtrl.dispose();
    _prixVenteLastCtrl.dispose();
    _prixVenteMinCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 1000);
    if (xfile == null) return;
    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(docsDir.path, 'photos'));
    if (!await photosDir.exists()) await photosDir.create(recursive: true);
    final fileName = 'modele_${DateTime.now().millisecondsSinceEpoch}${p.extension(xfile.path)}';
    final dest = p.join(photosDir.path, fileName);
    await File(xfile.path).copy(dest);
    if (mounted) setState(() => _photoPath = dest);
  }

  Future<void> _choisirDate() async {
    final choix = await showDatePicker(
      context: context,
      initialDate: _dateAjout,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: "Date d'arrivage",
    );
    if (choix != null) setState(() => _dateAjout = choix);
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enregistrement = true);
    final mois = '${_dateAjout.year.toString().padLeft(4, '0')}-${_dateAjout.month.toString().padLeft(2, '0')}';
    final dateIso = '$mois-${_dateAjout.day.toString().padLeft(2, '0')}';
    final quantite = int.parse(_quantiteCtrl.text);
    final prixAchatTotal = double.parse(_prixAchatTotalCtrl.text.replaceAll(',', '.'));
    final arrivage = Arrivage(
      id: widget.arrivage?.id,
      mois: mois,
      modele: _modeleCtrl.text.trim(),
      quantite: quantite,
      prixAchatUnitaire: prixAchatTotal / quantite,
      qteEndommage: int.tryParse(_qteEndommageCtrl.text) ?? 0,
      prixVenteMax: _prixVenteMaxCtrl.text.trim().isEmpty
          ? null
          : double.parse(_prixVenteMaxCtrl.text.replaceAll(',', '.')),
      prixVenteLast: _prixVenteLastCtrl.text.trim().isEmpty
          ? null
          : double.parse(_prixVenteLastCtrl.text.replaceAll(',', '.')),
      prixVenteMin: _prixVenteMinCtrl.text.trim().isEmpty
          ? null
          : double.parse(_prixVenteMinCtrl.text.replaceAll(',', '.')),
      photoPath: _photoPath,
      dateAjout: dateIso,
    );
    if (_modeEdition) {
      await DbHelper.instance.updateArrivage(arrivage);
    } else {
      await DbHelper.instance.insertArrivage(arrivage);
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _supprimer() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce modèle ?'),
        content: const Text(
          'Les ventes déjà enregistrées pour ce modèle seront aussi supprimées. Cette action est irréversible.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirme == true && widget.arrivage?.id != null) {
      await DbHelper.instance.deleteArrivage(widget.arrivage!.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_modeEdition ? 'Modifier le modèle' : 'Nouveau modèle'),
        actions: [
          if (_modeEdition) IconButton(icon: const Icon(Icons.delete_outline), onPressed: _supprimer),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _choisirPhoto,
                child: Stack(
                  children: [
                    ModelePhoto(photoPath: _photoPath, taille: 120),
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(radius: 16, child: Icon(Icons.camera_alt, size: 16)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _modeleCtrl,
              decoration: const InputDecoration(labelText: 'Nom du modèle'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Date d'arrivage"),
              subtitle: Text(formatDateAffichage(
                '${_dateAjout.year.toString().padLeft(4, '0')}-${_dateAjout.month.toString().padLeft(2, '0')}-${_dateAjout.day.toString().padLeft(2, '0')}',
              )),
              trailing: const Icon(Icons.calendar_month),
              onTap: _choisirDate,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantiteCtrl,
              decoration: const InputDecoration(labelText: 'Quantité achetée'),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Nombre invalide';
                final dejaEcoule = (widget.arrivage?.qteVendue ?? 0) + (int.tryParse(_qteEndommageCtrl.text) ?? 0);
                if (n < dejaEcoule) return 'Doit être ≥ $dejaEcoule (déjà vendu/endommagé)';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _prixAchatTotalCtrl,
              decoration: InputDecoration(labelText: "Prix total payé pour le lot — prix de gros ($devise)"),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  (double.tryParse((v ?? '').replaceAll(',', '.')) == null) ? 'Montant invalide' : null,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _prixUnitaireCalcule != null
                    ? 'Prix unitaire (détail) calculé : ${formatMontant(_prixUnitaireCalcule!)} / pièce'
                    : 'Prix unitaire (détail) calculé : —',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _qteEndommageCtrl,
              decoration: const InputDecoration(labelText: 'Quantité endommagée'),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0) return 'Nombre invalide';
                final quantite = int.tryParse(_quantiteCtrl.text) ?? 0;
                final qteVendue = widget.arrivage?.qteVendue ?? 0;
                if (n + qteVendue > quantite) return 'Trop élevé : max ${quantite - qteVendue}';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _prixVenteMinCtrl,
              decoration: InputDecoration(
                labelText: 'Prix de vente minimum ($devise) — optionnel',
                helperText: 'Sert à estimer le bénéfice minimum garanti sur ce modèle',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _validateurMontantOptionnel,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _beneficeEstimeCalcule != null
                    ? 'Bénéfice min. garanti estimé sur le stock restant : ${formatMontant(_beneficeEstimeCalcule!)}'
                        '${_depensesLieesExistantes > 0 ? ' (frais liés de ${formatMontant(_depensesLieesExistantes)} déduits)' : ''}'
                    : 'Bénéfice min. garanti estimé : — (quantité, prix d\'achat et prix de vente minimum requis)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _prixVenteMaxCtrl,
              decoration: InputDecoration(labelText: 'Prix de vente max ($devise) — optionnel'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _validateurMontantOptionnel,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _prixVenteLastCtrl,
              decoration: InputDecoration(labelText: 'Dernier prix vendu ($devise) — optionnel'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _validateurMontantOptionnel,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _enregistrement ? null : _enregistrer,
              child: Text(_enregistrement ? 'Enregistrement...' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
