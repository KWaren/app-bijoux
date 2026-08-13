import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/arrivage.dart';
import '../models/depense.dart';
import '../models/dette.dart';
import '../models/resume.dart';
import '../models/vente.dart';

class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  static const String dbFileName = 'app_bijoux.db';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbFileName);
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE arrivages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mois TEXT NOT NULL,
            modele TEXT NOT NULL,
            quantite INTEGER NOT NULL,
            prix_achat_unitaire REAL NOT NULL,
            qte_endommage INTEGER NOT NULL DEFAULT 0,
            prix_vente_max REAL,
            prix_vente_last REAL,
            photo_path TEXT,
            date_ajout TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE ventes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            arrivage_id INTEGER NOT NULL,
            client_nom TEXT NOT NULL,
            date_vente TEXT NOT NULL,
            qte_vendue INTEGER NOT NULL,
            prix_vente_total REAL NOT NULL,
            FOREIGN KEY (arrivage_id) REFERENCES arrivages(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE depenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mois TEXT NOT NULL,
            date_depense TEXT NOT NULL,
            designation TEXT NOT NULL,
            cout REAL NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE dettes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client_nom TEXT NOT NULL,
            vente_id INTEGER,
            montant REAL NOT NULL,
            description TEXT,
            date_dette TEXT NOT NULL,
            statut TEXT NOT NULL DEFAULT 'en_cours',
            FOREIGN KEY (vente_id) REFERENCES ventes(id)
          )
        ''');
        await db.execute('CREATE INDEX idx_ventes_arrivage ON ventes(arrivage_id)');
        await db.execute('CREATE INDEX idx_ventes_date ON ventes(date_vente)');
        await db.execute('CREATE INDEX idx_arrivages_mois ON arrivages(mois)');
        await db.execute('CREATE INDEX idx_depenses_mois ON depenses(mois)');
      },
    );
  }

  // ---------------------------------------------------------------------
  // Arrivages
  // ---------------------------------------------------------------------

  Future<int> insertArrivage(Arrivage a) async {
    final db = await database;
    return db.insert('arrivages', a.toMap());
  }

  Future<int> updateArrivage(Arrivage a) async {
    final db = await database;
    return db.update('arrivages', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  Future<void> deleteArrivage(int id) async {
    final db = await database;
    await db.delete('ventes', where: 'arrivage_id = ?', whereArgs: [id]);
    await db.delete('arrivages', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Arrivage>> getArrivagesByMois(String mois) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT a.*, COALESCE(SUM(v.qte_vendue), 0) as qte_vendue
      FROM arrivages a
      LEFT JOIN ventes v ON v.arrivage_id = a.id
      WHERE a.mois = ?
      GROUP BY a.id
      ORDER BY a.date_ajout DESC, a.id DESC
    ''', [mois]);
    return rows.map(Arrivage.fromMap).toList();
  }

  /// Modèles ayant encore du stock disponible, toutes périodes confondues
  /// (utilisé pour le formulaire de vente).
  Future<List<Arrivage>> getArrivagesEnStock() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT a.*, COALESCE(SUM(v.qte_vendue), 0) as qte_vendue
      FROM arrivages a
      LEFT JOIN ventes v ON v.arrivage_id = a.id
      GROUP BY a.id
      HAVING (a.quantite - a.qte_endommage - COALESCE(SUM(v.qte_vendue), 0)) > 0
      ORDER BY a.modele ASC
    ''');
    return rows.map(Arrivage.fromMap).toList();
  }

  Future<Arrivage?> getArrivageById(int id) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT a.*, COALESCE(SUM(v.qte_vendue), 0) as qte_vendue
      FROM arrivages a
      LEFT JOIN ventes v ON v.arrivage_id = a.id
      WHERE a.id = ?
      GROUP BY a.id
    ''', [id]);
    if (rows.isEmpty) return null;
    return Arrivage.fromMap(rows.first);
  }

  /// Arrivages dont la date d'ajout tombe dans la période donnée
  /// (utilisé pour les exports jour/semaine/mois).
  Future<List<Arrivage>> getArrivagesByPeriode(DateTime debut, DateTime fin) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT a.*, COALESCE(SUM(v.qte_vendue), 0) as qte_vendue
      FROM arrivages a
      LEFT JOIN ventes v ON v.arrivage_id = a.id
      WHERE a.date_ajout BETWEEN ? AND ?
      GROUP BY a.id
      ORDER BY a.date_ajout DESC, a.id DESC
    ''', [_fmt(debut), _fmt(fin)]);
    return rows.map(Arrivage.fromMap).toList();
  }

  Future<List<String>> getMoisDisponibles() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT mois FROM (
        SELECT mois FROM arrivages
        UNION
        SELECT substr(date_vente, 1, 7) as mois FROM ventes
        UNION
        SELECT mois FROM depenses
      )
      ORDER BY mois DESC
    ''');
    return rows.map((r) => r['mois'] as String).toList();
  }

  // ---------------------------------------------------------------------
  // Ventes
  // ---------------------------------------------------------------------

  Future<int> insertVente(Vente v) async {
    final db = await database;
    return db.insert('ventes', v.toMap());
  }

  Future<void> deleteVente(int id) async {
    final db = await database;
    await db.delete('dettes', where: 'vente_id = ?', whereArgs: [id]);
    await db.delete('ventes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Vente>> getVentesByPeriode(DateTime debut, DateTime fin) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT v.*, a.modele as modele, a.photo_path as photo_path
      FROM ventes v
      JOIN arrivages a ON a.id = v.arrivage_id
      WHERE v.date_vente BETWEEN ? AND ?
      ORDER BY v.date_vente DESC, v.id DESC
    ''', [_fmt(debut), _fmt(fin)]);
    return rows.map(Vente.fromMap).toList();
  }

  Future<List<Vente>> getVentesRecentes({int limit = 20}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT v.*, a.modele as modele, a.photo_path as photo_path
      FROM ventes v
      JOIN arrivages a ON a.id = v.arrivage_id
      ORDER BY v.date_vente DESC, v.id DESC
      LIMIT ?
    ''', [limit]);
    return rows.map(Vente.fromMap).toList();
  }

  Future<List<Vente>> getVentesByClient(String client) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT v.*, a.modele as modele, a.photo_path as photo_path
      FROM ventes v
      JOIN arrivages a ON a.id = v.arrivage_id
      WHERE v.client_nom = ?
      ORDER BY v.date_vente DESC, v.id DESC
    ''', [client]);
    return rows.map(Vente.fromMap).toList();
  }

  // ---------------------------------------------------------------------
  // Dépenses
  // ---------------------------------------------------------------------

  Future<int> insertDepense(Depense d) async {
    final db = await database;
    return db.insert('depenses', d.toMap());
  }

  Future<void> deleteDepense(int id) async {
    final db = await database;
    await db.delete('depenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Depense>> getDepensesByMois(String mois) async {
    final db = await database;
    final rows = await db.query('depenses', where: 'mois = ?', whereArgs: [mois], orderBy: 'date_depense DESC, id DESC');
    return rows.map(Depense.fromMap).toList();
  }

  Future<List<Depense>> getDepensesByPeriode(DateTime debut, DateTime fin) async {
    final db = await database;
    final rows = await db.query(
      'depenses',
      where: 'date_depense BETWEEN ? AND ?',
      whereArgs: [_fmt(debut), _fmt(fin)],
      orderBy: 'date_depense DESC, id DESC',
    );
    return rows.map(Depense.fromMap).toList();
  }

  // ---------------------------------------------------------------------
  // Dettes
  // ---------------------------------------------------------------------

  Future<int> insertDette(Dette d) async {
    final db = await database;
    return db.insert('dettes', d.toMap());
  }

  Future<void> updateDetteStatut(int id, String statut) async {
    final db = await database;
    await db.update('dettes', {'statut': statut}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteDette(int id) async {
    final db = await database;
    await db.delete('dettes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Dette>> getDettesByClient(String client) async {
    final db = await database;
    final rows = await db.query('dettes', where: 'client_nom = ?', whereArgs: [client], orderBy: 'date_dette DESC');
    return rows.map(Dette.fromMap).toList();
  }

  Future<List<Dette>> getDettesEnCours() async {
    final db = await database;
    final rows = await db.query('dettes', where: "statut = 'en_cours'", orderBy: 'date_dette DESC');
    return rows.map(Dette.fromMap).toList();
  }

  Future<double> getTotalDettesEnCours() async {
    final db = await database;
    final result = await db.rawQuery("SELECT COALESCE(SUM(montant), 0) as total FROM dettes WHERE statut = 'en_cours'");
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getDettesCreeesEntre(DateTime debut, DateTime fin) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(montant), 0) as total FROM dettes WHERE date_dette BETWEEN ? AND ?',
      [_fmt(debut), _fmt(fin)],
    );
    return (result.first['total'] as num).toDouble();
  }

  // ---------------------------------------------------------------------
  // Clients
  // ---------------------------------------------------------------------

  Future<List<String>> getClientsDistincts() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT DISTINCT client_nom FROM ventes ORDER BY client_nom ASC');
    return rows.map((r) => r['client_nom'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getClientsResume() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        v.client_nom as client_nom,
        COUNT(*) as nb_ventes,
        SUM(v.prix_vente_total) as total_achats,
        MAX(v.date_vente) as dernier_achat,
        COALESCE((
          SELECT SUM(d.montant) FROM dettes d
          WHERE d.client_nom = v.client_nom AND d.statut = 'en_cours'
        ), 0) as dettes_en_cours
      FROM ventes v
      GROUP BY v.client_nom
      ORDER BY total_achats DESC
    ''');
    return rows;
  }

  // ---------------------------------------------------------------------
  // Résumé
  // ---------------------------------------------------------------------

  Future<ResumePeriode> getResume(DateTime debut, DateTime fin) async {
    final db = await database;
    final debutStr = _fmt(debut);
    final finStr = _fmt(fin);

    final achatRows = await db.rawQuery(
      'SELECT COALESCE(SUM(quantite * prix_achat_unitaire), 0) as total FROM arrivages WHERE date_ajout BETWEEN ? AND ?',
      [debutStr, finStr],
    );
    final pertesRows = await db.rawQuery(
      'SELECT COALESCE(SUM(qte_endommage * prix_achat_unitaire), 0) as total FROM arrivages WHERE date_ajout BETWEEN ? AND ?',
      [debutStr, finStr],
    );
    final ventesRows = await db.rawQuery(
      'SELECT COALESCE(SUM(prix_vente_total), 0) as total, COUNT(*) as nb FROM ventes WHERE date_vente BETWEEN ? AND ?',
      [debutStr, finStr],
    );
    final depensesRows = await db.rawQuery(
      'SELECT COALESCE(SUM(cout), 0) as total FROM depenses WHERE date_depense BETWEEN ? AND ?',
      [debutStr, finStr],
    );
    final dettesCreees = await getDettesCreeesEntre(debut, fin);

    return ResumePeriode(
      debut: debut,
      fin: fin,
      totalAchat: (achatRows.first['total'] as num).toDouble(),
      totalVentes: (ventesRows.first['total'] as num).toDouble(),
      totalDepenses: (depensesRows.first['total'] as num).toDouble(),
      totalPertes: (pertesRows.first['total'] as num).toDouble(),
      nbVentes: (ventesRows.first['nb'] as num).toInt(),
      dettesCreees: dettesCreees,
    );
  }

  String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
