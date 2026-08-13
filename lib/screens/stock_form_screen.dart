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
  late TextEditingController _prixAchatCtrl;
  late TextEditingController _qteEndommageCtrl;
  late TextEditingController _prixVenteMaxCtrl;
  late TextEditingController _prixVenteLastCtrl;
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
    _prixAchatCtrl = TextEditingController(text: a != null ? a.prixAchatUnitaire.toString() : '');
    _qteEndommageCtrl = TextEditingController(text: a != null ? a.qteEndommage.toString() : '0');
    _prixVenteMaxCtrl = TextEditingController(text: a?.prixVenteMax?.toString() ?? '');
    _prixVenteLastCtrl = TextEditingController(text: a?.prixVenteLast?.toString() ?? '');
    _dateAjout = a != null ? DateTime.parse(a.dateAjout) : _premierJourUtileDuMois(widget.mois);
    _photoPath = a?.photoPath;
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
    _prixAchatCtrl.dispose();
    _qteEndommageCtrl.dispose();
    _prixVenteMaxCtrl.dispose();
    _prixVenteLastCtrl.dispose();
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
    final arrivage = Arrivage(
      id: widget.arrivage?.id,
      mois: mois,
      modele: _modeleCtrl.text.trim(),
      quantite: int.parse(_quantiteCtrl.text),
      prixAchatUnitaire: double.parse(_prixAchatCtrl.text.replaceAll(',', '.')),
      qteEndommage: int.tryParse(_qteEndommageCtrl.text) ?? 0,
      prixVenteMax: _prixVenteMaxCtrl.text.trim().isEmpty
          ? null
          : double.parse(_prixVenteMaxCtrl.text.replaceAll(',', '.')),
      prixVenteLast: _prixVenteLastCtrl.text.trim().isEmpty
          ? null
          : double.parse(_prixVenteLastCtrl.text.replaceAll(',', '.')),
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
              validator: (v) => (int.tryParse(v ?? '') == null) ? 'Nombre invalide' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _prixAchatCtrl,
              decoration: InputDecoration(labelText: "Prix unitaire d'achat ($devise)"),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  (double.tryParse((v ?? '').replaceAll(',', '.')) == null) ? 'Montant invalide' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _qteEndommageCtrl,
              decoration: const InputDecoration(labelText: 'Quantité endommagée'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _prixVenteMaxCtrl,
              decoration: InputDecoration(labelText: 'Prix de vente max ($devise) — optionnel'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _prixVenteLastCtrl,
              decoration: InputDecoration(labelText: 'Dernier prix vendu ($devise) — optionnel'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
