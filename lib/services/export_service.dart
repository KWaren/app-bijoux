import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/db_helper.dart';
import '../models/arrivage.dart';
import '../models/depense.dart';
import '../models/resume.dart';
import '../models/vente.dart';
import '../utils/date_ranges.dart';
import '../utils/formatters.dart';

class ExportService {
  final DbHelper _db = DbHelper.instance;

  Future<File> genererRapport(Periode periode) async {
    final resume = await _db.getResume(periode.debut, periode.fin);
    final ventes = await _db.getVentesByPeriode(periode.debut, periode.fin);
    final depenses = await _db.getDepensesByPeriode(periode.debut, periode.fin);
    final arrivages = await _db.getArrivagesByPeriode(periode.debut, periode.fin);

    final excelFile = Excel.createExcel();
    final premierNom = excelFile.sheets.keys.first;
    excelFile.rename(premierNom, 'Résumé');

    _remplirResume(excelFile['Résumé'], periode, resume);
    _remplirVentes(excelFile['Ventes'], ventes);
    _remplirArrivages(excelFile['Arrivages'], arrivages);
    _remplirDepenses(excelFile['Dépenses'], depenses);

    final bytes = excelFile.save();
    final dir = await _dossierExports();
    final fileName = 'rapport_${_slug(periode.libelle)}_${_horodatage()}.xlsx';
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(bytes!, flush: true);
    return file;
  }

  Future<void> genererEtPartager(Periode periode) async {
    final file = await genererRapport(periode);
    await Share.shareXFiles([XFile(file.path)], text: 'Rapport ${periode.libelle}');
  }

  void _entete(Sheet sheet, List<String> colonnes) {
    sheet.appendRow(colonnes.map((c) => TextCellValue(c)).toList());
    final style = CellStyle(bold: true);
    for (var i = 0; i < colonnes.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = style;
    }
  }

  void _remplirResume(Sheet sheet, Periode periode, ResumePeriode resume) {
    _entete(sheet, ['Indicateur', 'Valeur']);
    sheet.appendRow([TextCellValue('Période'), TextCellValue(periode.libelle)]);
    sheet.appendRow([TextCellValue('Nombre de ventes'), IntCellValue(resume.nbVentes)]);
    sheet.appendRow([TextCellValue('Coût des marchandises vendues'), DoubleCellValue(resume.coutMarchandisesVendues)]);
    sheet.appendRow([TextCellValue('Total des ventes'), DoubleCellValue(resume.totalVentes)]);
    sheet.appendRow([TextCellValue('Dépenses'), DoubleCellValue(resume.totalDepenses)]);
    sheet.appendRow([TextCellValue('Pertes (casse)'), DoubleCellValue(resume.totalPertes)]);
    sheet.appendRow([TextCellValue('Dépenses & pertes'), DoubleCellValue(resume.depensesEtPertes)]);
    sheet.appendRow([TextCellValue('Bénéfice'), DoubleCellValue(resume.benefice)]);
    sheet.appendRow([TextCellValue('Nouvelles dettes'), DoubleCellValue(resume.dettesCreees)]);
  }

  void _remplirVentes(Sheet sheet, List<Vente> ventes) {
    _entete(sheet, ['Date', 'Modèle', 'Client', 'Quantité', 'Prix de vente total']);
    for (final v in ventes) {
      sheet.appendRow([
        TextCellValue(formatDateAffichage(v.dateVente)),
        TextCellValue(v.modeleNom ?? ''),
        TextCellValue(v.clientNom),
        IntCellValue(v.qteVendue),
        DoubleCellValue(v.prixVenteTotal),
      ]);
    }
  }

  void _remplirArrivages(Sheet sheet, List<Arrivage> arrivages) {
    _entete(sheet, [
      'Date',
      'Modèle',
      'Quantité',
      'Prix unitaire achat',
      'Prix total achat',
      'Frais liés',
      'Qté endommagée',
      'Bijoux restants',
    ]);
    for (final a in arrivages) {
      sheet.appendRow([
        TextCellValue(formatDateAffichage(a.dateAjout)),
        TextCellValue(a.modele),
        IntCellValue(a.quantite),
        DoubleCellValue(a.prixAchatUnitaire),
        DoubleCellValue(a.prixAchatTotal),
        DoubleCellValue(a.depensesLiees),
        IntCellValue(a.qteEndommage),
        IntCellValue(a.bijouxRestant),
      ]);
    }
  }

  void _remplirDepenses(Sheet sheet, List<Depense> depenses) {
    _entete(sheet, ['Date', 'Désignation', 'Coût', 'Modèle lié']);
    for (final d in depenses) {
      sheet.appendRow([
        TextCellValue(formatDateAffichage(d.dateDepense)),
        TextCellValue(d.designation),
        DoubleCellValue(d.cout),
        TextCellValue(d.modeleNom ?? ''),
      ]);
    }
  }

  Future<Directory> _dossierExports() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, 'exports'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _slug(String texte) => texte
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  String _horodatage() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
        '_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }
}
