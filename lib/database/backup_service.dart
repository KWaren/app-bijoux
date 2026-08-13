import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import 'db_helper.dart';

/// Sauvegarde locale automatique de la base de données.
///
/// L'appli étant mono-utilisateur et hors-ligne sur un seul téléphone,
/// la perte/casse du téléphone = perte de tout l'historique si rien n'est
/// copié ailleurs que le fichier sqlite d'origine. On garde donc une copie
/// horodatée à chaque lancement (une par jour) dans un dossier "backups",
/// et l'utilisatrice peut en plus exporter/partager une sauvegarde à la main
/// (WhatsApp, Drive, mail...) pour avoir une copie hors du téléphone.
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const int maxBackupsConserves = 15;

  Future<Directory> _backupsDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(join(docsDir.path, 'backups'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> _dbPath() async {
    final dbDir = await getDatabasesPath();
    return join(dbDir, DbHelper.dbFileName);
  }

  /// À appeler au démarrage de l'appli : ne fait rien si une sauvegarde
  /// existe déjà pour aujourd'hui.
  Future<void> backupAutomatiqueSiNecessaire() async {
    final dbFile = File(await _dbPath());
    if (!await dbFile.exists()) return;

    final backupsDir = await _backupsDir();
    final todayFile = File(join(backupsDir.path, 'auto_${_dateStr(DateTime.now())}.db'));
    if (await todayFile.exists()) return;

    await dbFile.copy(todayFile.path);
    await _nettoyerAnciennesSauvegardes(backupsDir);
  }

  Future<File> creerSauvegardeManuelle() async {
    final dbFile = File(await _dbPath());
    final backupsDir = await _backupsDir();
    final fileName = 'sauvegarde_app_bijoux_${_dateTimeStr(DateTime.now())}.db';
    final dest = File(join(backupsDir.path, fileName));
    await dbFile.copy(dest.path);
    return dest;
  }

  Future<void> partagerSauvegarde() async {
    final file = await creerSauvegardeManuelle();
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Sauvegarde App Bijoux du ${_dateStr(DateTime.now())}',
    );
  }

  Future<DateTime?> derniereSauvegarde() async {
    final dir = await _backupsDir();
    final files = (await dir.list().toList()).whereType<File>().toList();
    if (files.isEmpty) return null;
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files.first.statSync().modified;
  }

  Future<void> _nettoyerAnciennesSauvegardes(Directory dir) async {
    final files = (await dir.list().toList())
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .toList();
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    if (files.length > maxBackupsConserves) {
      for (final f in files.skip(maxBackupsConserves)) {
        await f.delete();
      }
    }
  }

  String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _dateTimeStr(DateTime d) =>
      '${_dateStr(d)}_${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
}
