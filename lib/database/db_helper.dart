import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/arrivage.dart';
import '../models/depense.dart';
import '../models/dette.dart';
import '../models/modele_vendu.dart';
import '../models/resume.dart';
import '../models/vente.dart';
import '../models/vente_ligne.dart';
import '../utils/date_ranges.dart';

class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  static const String dbFileName = 'app_bijoux.db';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  /// Ferme la connexion active (nécessaire avant de remplacer le fichier de
  /// base de données par une sauvegarde restaurée) ; rouverte automatiquement
  /// au prochain accès à [database].
  Future<void> fermer() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbFileName);
    return openDatabase(
      path,
      version: 6,
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
            prix_vente_min REAL,
            photo_path TEXT,
            date_ajout TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE ventes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client_nom TEXT NOT NULL,
            date_vente TEXT NOT NULL,
            prix_vente_total REAL NOT NULL,
            mode_paiement TEXT,
            note TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE ventes_lignes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vente_id INTEGER NOT NULL,
            arrivage_id INTEGER NOT NULL,
            qte_vendue INTEGER NOT NULL,
            prix_ligne REAL NOT NULL,
            FOREIGN KEY (vente_id) REFERENCES ventes(id),
            FOREIGN KEY (arrivage_id) REFERENCES arrivages(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE depenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mois TEXT NOT NULL,
            date_depense TEXT NOT NULL,
            designation TEXT NOT NULL,
            cout REAL NOT NULL,
            arrivage_id INTEGER REFERENCES arrivages(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE dettes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client_nom TEXT NOT NULL,
            vente_id INTEGER,
            montant REAL NOT NULL,
            montant_paye REAL NOT NULL DEFAULT 0,
            description TEXT,
            date_dette TEXT NOT NULL,
            statut TEXT NOT NULL DEFAULT 'en_cours',
            FOREIGN KEY (vente_id) REFERENCES ventes(id)
          )
        ''');
        await db.execute('CREATE INDEX idx_ventes_lignes_vente ON ventes_lignes(vente_id)');
        await db.execute('CREATE INDEX idx_ventes_lignes_arrivage ON ventes_lignes(arrivage_id)');
        await db.execute('CREATE INDEX idx_ventes_date ON ventes(date_vente)');
        await db.execute('CREATE INDEX idx_arrivages_mois ON arrivages(mois)');
        await db.execute('CREATE INDEX idx_depenses_mois ON depenses(mois)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE arrivages ADD COLUMN prix_vente_min REAL');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE depenses ADD COLUMN arrivage_id INTEGER REFERENCES arrivages(id)');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE ventes ADD COLUMN mode_paiement TEXT');
          await db.execute('ALTER TABLE ventes ADD COLUMN note TEXT');
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE dettes ADD COLUMN montant_paye REAL NOT NULL DEFAULT 0');
        }
        if (oldVersion < 6) {
          // Passage d'une vente "1 modèle" (arrivage_id/qte_vendue sur `ventes`) à une
          // vente "en-tête + lignes" (une vente peut désormais porter plusieurs modèles).
          // Chaque vente existante devient un en-tête + exactement 1 ligne : aucune donnée perdue.
          await db.execute('''
            CREATE TABLE ventes_lignes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              vente_id INTEGER NOT NULL,
              arrivage_id INTEGER NOT NULL,
              qte_vendue INTEGER NOT NULL,
              prix_ligne REAL NOT NULL,
              FOREIGN KEY (vente_id) REFERENCES ventes(id),
              FOREIGN KEY (arrivage_id) REFERENCES arrivages(id)
            )
          ''');
          await db.execute('''
            INSERT INTO ventes_lignes (vente_id, arrivage_id, qte_vendue, prix_ligne)
            SELECT id, arrivage_id, qte_vendue, prix_vente_total FROM ventes
          ''');
          // SQLite (embarqué dans sqflite) ne supporte pas toujours DROP COLUMN de façon
          // fiable : on reconstruit `ventes` sans arrivage_id/qte_vendue plutôt que d'altérer.
          await db.execute('ALTER TABLE ventes RENAME TO ventes_old');
          await db.execute('''
            CREATE TABLE ventes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              client_nom TEXT NOT NULL,
              date_vente TEXT NOT NULL,
              prix_vente_total REAL NOT NULL,
              mode_paiement TEXT,
              note TEXT
            )
          ''');
          await db.execute('''
            INSERT INTO ventes (id, client_nom, date_vente, prix_vente_total, mode_paiement, note)
            SELECT id, client_nom, date_vente, prix_vente_total, mode_paiement, note FROM ventes_old
          ''');
          await db.execute('DROP TABLE ventes_old');
          await db.execute('CREATE INDEX idx_ventes_lignes_vente ON ventes_lignes(vente_id)');
          await db.execute('CREATE INDEX idx_ventes_lignes_arrivage ON ventes_lignes(arrivage_id)');
          await db.execute('CREATE INDEX idx_ventes_date ON ventes(date_vente)');
        }
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

  /// Supprime un arrivage. Les lignes de vente qui le référencent sont retirées ;
  /// si une vente se retrouve sans aucune ligne restante (elle ne portait que sur
  /// cet arrivage), son en-tête et sa dette éventuelle sont supprimés avec elle.
  /// Une vente multi-modèles qui a aussi d'autres lignes survit, allégée de celle-ci.
  Future<void> deleteArrivage(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      final venteIdsRows = await txn.rawQuery(
        'SELECT DISTINCT vente_id FROM ventes_lignes WHERE arrivage_id = ?',
        [id],
      );
      await txn.delete('ventes_lignes', where: 'arrivage_id = ?', whereArgs: [id]);
      for (final row in venteIdsRows) {
        final venteId = row['vente_id'] as int;
        final restantes = Sqflite.firstIntValue(
          await txn.rawQuery('SELECT COUNT(*) FROM ventes_lignes WHERE vente_id = ?', [venteId]),
        );
        if (restantes == 0) {
          await txn.delete('dettes', where: 'vente_id = ?', whereArgs: [venteId]);
          await txn.delete('ventes', where: 'id = ?', whereArgs: [venteId]);
        }
      }
      // Les dépenses liées restent (l'argent a bien été dépensé), seul le lien est retiré.
      await txn.update('depenses', {'arrivage_id': null}, where: 'arrivage_id = ?', whereArgs: [id]);
      await txn.delete('arrivages', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Sous-requêtes (plutôt que LEFT JOIN + GROUP BY) pour agréger séparément
  /// ventes et dépenses sans effet de fan-out entre les deux jointures.
  static const String _selectArrivageAvecAgregats = '''
    SELECT a.*,
      COALESCE((SELECT SUM(vl.qte_vendue) FROM ventes_lignes vl WHERE vl.arrivage_id = a.id), 0) as qte_vendue,
      COALESCE((SELECT SUM(d.cout) FROM depenses d WHERE d.arrivage_id = a.id), 0) as depenses_liees
    FROM arrivages a
  ''';

  Future<List<Arrivage>> getArrivagesByMois(String mois) async {
    final db = await database;
    final rows = await db.rawQuery('''
      $_selectArrivageAvecAgregats
      WHERE a.mois = ?
      ORDER BY a.date_ajout DESC, a.id DESC
    ''', [mois]);
    return rows.map(Arrivage.fromMap).toList();
  }

  /// Modèles ayant encore du stock disponible, toutes périodes confondues
  /// (utilisé pour le formulaire de vente).
  Future<List<Arrivage>> getArrivagesEnStock() async {
    final db = await database;
    final rows = await db.rawQuery('''
      $_selectArrivageAvecAgregats
      WHERE (a.quantite - a.qte_endommage -
        COALESCE((SELECT SUM(vl.qte_vendue) FROM ventes_lignes vl WHERE vl.arrivage_id = a.id), 0)) > 0
      ORDER BY a.modele ASC
    ''');
    return rows.map(Arrivage.fromMap).toList();
  }

  Future<Arrivage?> getArrivageById(int id) async {
    final db = await database;
    final rows = await db.rawQuery('''
      $_selectArrivageAvecAgregats
      WHERE a.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    return Arrivage.fromMap(rows.first);
  }

  /// Arrivages dont la date d'ajout tombe dans la période donnée
  /// (utilisé pour les exports jour/semaine/mois).
  Future<List<Arrivage>> getArrivagesByPeriode(DateTime debut, DateTime fin) async {
    final db = await database;
    final rows = await db.rawQuery('''
      $_selectArrivageAvecAgregats
      WHERE a.date_ajout BETWEEN ? AND ?
      ORDER BY a.date_ajout DESC, a.id DESC
    ''', [_fmt(debut), _fmt(fin)]);
    return rows.map(Arrivage.fromMap).toList();
  }

  /// Tous les arrivages, du plus récent au plus ancien (utilisé pour choisir
  /// un modèle auquel rattacher une dépense).
  Future<List<Arrivage>> getTousLesArrivages() async {
    final db = await database;
    final rows = await db.rawQuery('''
      $_selectArrivageAvecAgregats
      ORDER BY a.date_ajout DESC, a.id DESC
    ''');
    return rows.map(Arrivage.fromMap).toList();
  }

  /// Nom + photo du dernier arrivage enregistré pour chaque modèle déjà connu
  /// (tous mois confondus), pour proposer une suggestion à la création d'un
  /// nouvel arrivage du même modèle sans ressaisir nom/photo.
  Future<List<({String modele, String? photoPath})>> getModelesConnus() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT a1.modele as modele, a1.photo_path as photo_path
      FROM arrivages a1
      WHERE a1.id = (SELECT MAX(a2.id) FROM arrivages a2 WHERE a2.modele = a1.modele)
      ORDER BY a1.modele ASC
    ''');
    return rows.map((r) => (modele: r['modele'] as String, photoPath: r['photo_path'] as String?)).toList();
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

  Future<int> insertVente(Vente v, List<VenteLigne> lignes) async {
    final db = await database;
    return db.transaction((txn) async {
      final venteId = await txn.insert('ventes', v.toMap());
      for (final ligne in lignes) {
        await txn.insert('ventes_lignes', ligne.copyWith(venteId: venteId).toMap());
      }
      return venteId;
    });
  }

  Future<void> updateVente(Vente v, List<VenteLigne> lignes) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('ventes', v.toMap(), where: 'id = ?', whereArgs: [v.id]);
      await txn.delete('ventes_lignes', where: 'vente_id = ?', whereArgs: [v.id]);
      for (final ligne in lignes) {
        await txn.insert('ventes_lignes', ligne.copyWith(venteId: v.id).toMap());
      }
    });
  }

  Future<void> deleteVente(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('ventes_lignes', where: 'vente_id = ?', whereArgs: [id]);
      await txn.delete('dettes', where: 'vente_id = ?', whereArgs: [id]);
      await txn.delete('ventes', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Sous-requête pour indiquer, sans recharger tous les objets `Dette`, le
  /// reste à payer encore en cours pour chaque vente (`null`/0 si soldée ou
  /// vente comptant).
  static const String _selectVenteAvecReste = '''
    SELECT v.*,
      (SELECT SUM(d.montant - d.montant_paye) FROM dettes d WHERE d.vente_id = v.id AND d.statut = 'en_cours') as reste_a_payer,
      (SELECT d.id FROM dettes d WHERE d.vente_id = v.id AND d.statut = 'en_cours' LIMIT 1) as dette_id
    FROM ventes v
  ''';

  /// Récupère les lignes (avec modèle/photo joints) des ventes données, groupées par vente.
  Future<Map<int, List<VenteLigne>>> _lignesParVente(List<int> venteIds) async {
    if (venteIds.isEmpty) return {};
    final db = await database;
    final placeholders = List.filled(venteIds.length, '?').join(',');
    final rows = await db.rawQuery('''
      SELECT vl.*, a.modele as modele, a.photo_path as photo_path
      FROM ventes_lignes vl
      JOIN arrivages a ON a.id = vl.arrivage_id
      WHERE vl.vente_id IN ($placeholders)
      ORDER BY vl.id ASC
    ''', venteIds);
    final resultat = <int, List<VenteLigne>>{};
    for (final row in rows) {
      final ligne = VenteLigne.fromMap(row);
      resultat.putIfAbsent(ligne.venteId!, () => []).add(ligne);
    }
    return resultat;
  }

  Future<List<Vente>> getVentesByPeriode(DateTime debut, DateTime fin) async {
    final db = await database;
    final rows = await db.rawQuery('''
      $_selectVenteAvecReste
      WHERE v.date_vente BETWEEN ? AND ?
      ORDER BY v.date_vente DESC, v.id DESC
    ''', [_fmt(debut), _fmt(fin)]);
    final lignesParVente = await _lignesParVente(rows.map((r) => r['id'] as int).toList());
    return rows.map((r) => Vente.fromMap(r, lignes: lignesParVente[r['id']] ?? [])).toList();
  }

  Future<List<Vente>> getVentesRecentes({int limit = 20}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT v.*
      FROM ventes v
      ORDER BY v.date_vente DESC, v.id DESC
      LIMIT ?
    ''', [limit]);
    final lignesParVente = await _lignesParVente(rows.map((r) => r['id'] as int).toList());
    return rows.map((r) => Vente.fromMap(r, lignes: lignesParVente[r['id']] ?? [])).toList();
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
    final rows = await db.rawQuery('''
      SELECT d.*, a.modele as modele
      FROM depenses d
      LEFT JOIN arrivages a ON a.id = d.arrivage_id
      WHERE d.mois = ?
      ORDER BY d.date_depense DESC, d.id DESC
    ''', [mois]);
    return rows.map(Depense.fromMap).toList();
  }

  Future<List<Depense>> getDepensesByPeriode(DateTime debut, DateTime fin) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT d.*, a.modele as modele
      FROM depenses d
      LEFT JOIN arrivages a ON a.id = d.arrivage_id
      WHERE d.date_depense BETWEEN ? AND ?
      ORDER BY d.date_depense DESC, d.id DESC
    ''', [_fmt(debut), _fmt(fin)]);
    return rows.map(Depense.fromMap).toList();
  }

  // ---------------------------------------------------------------------
  // Dettes
  // ---------------------------------------------------------------------

  Future<int> insertDette(Dette d) async {
    final db = await database;
    return db.insert('dettes', d.toMap());
  }

  /// Enregistre un paiement (partiel ou total) sur une dette : le montant se
  /// cumule à ce qui a déjà été payé, et la dette passe automatiquement à
  /// "payée" une fois le solde épuisé.
  Future<void> payerDette(int id, double montantPaye) async {
    final db = await database;
    final rows = await db.query('dettes', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return;
    final dette = Dette.fromMap(rows.first);
    final nouveauMontantPaye = dette.montantPaye + montantPaye;
    final solde = dette.montant - nouveauMontantPaye;
    await db.update(
      'dettes',
      {
        'montant_paye': nouveauMontantPaye,
        'statut': solde <= 0 ? 'payee' : 'en_cours',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDette(int id) async {
    final db = await database;
    await db.delete('dettes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Dette>> getDettesEnCours() async {
    final db = await database;
    final rows = await db.query('dettes', where: "statut = 'en_cours'", orderBy: 'date_dette DESC');
    return rows.map(Dette.fromMap).toList();
  }

  Future<double> getTotalDettesEnCours() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(montant - montant_paye), 0) as total FROM dettes WHERE statut = 'en_cours'",
    );
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
  // Clients (autocomplétion à la saisie uniquement — pas de suivi par client)
  // ---------------------------------------------------------------------

  Future<List<String>> getClientsDistincts() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT DISTINCT client_nom FROM ventes ORDER BY client_nom ASC');
    return rows.map((r) => r['client_nom'] as String).toList();
  }

  // ---------------------------------------------------------------------
  // Résumé
  // ---------------------------------------------------------------------

  Future<ResumePeriode> getResume(DateTime debut, DateTime fin) async {
    final db = await database;
    final debutStr = _fmt(debut);
    final finStr = _fmt(fin);

    // Coût des marchandises VENDUES sur la période (pas de tout ce qui a été
    // acheté sur la période) : chaque vente est valorisée au coût unitaire de
    // son lot d'origine (prix d'achat + frais liés répartis sur la quantité
    // du lot). Sans ça, un gros réassort fait paraître le mois très déficitaire
    // même si le stock n'est pas encore vendu, et l'inverse le mois suivant.
    final achatRows = await db.rawQuery('''
      SELECT COALESCE(SUM(
        vl.qte_vendue * (
          (a.quantite * a.prix_achat_unitaire +
            COALESCE((SELECT SUM(d.cout) FROM depenses d WHERE d.arrivage_id = a.id), 0)
          ) / a.quantite
        )
      ), 0) as total
      FROM ventes_lignes vl
      JOIN arrivages a ON a.id = vl.arrivage_id
      JOIN ventes v ON v.id = vl.vente_id
      WHERE v.date_vente BETWEEN ? AND ?
    ''', [debutStr, finStr]);
    final pertesRows = await db.rawQuery(
      'SELECT COALESCE(SUM(qte_endommage * prix_achat_unitaire), 0) as total FROM arrivages WHERE date_ajout BETWEEN ? AND ?',
      [debutStr, finStr],
    );
    final ventesRows = await db.rawQuery(
      'SELECT COALESCE(SUM(prix_vente_total), 0) as total, COUNT(*) as nb FROM ventes WHERE date_vente BETWEEN ? AND ?',
      [debutStr, finStr],
    );
    // Les dépenses rattachées à un arrivage (arrivage_id non nul) sont déjà
    // comptées dans le coût des marchandises vendues ci-dessus (au fil des
    // ventes de ce lot) : on ne garde ici que les dépenses générales, pour
    // ne pas les compter deux fois dans le bénéfice.
    final depensesRows = await db.rawQuery(
      'SELECT COALESCE(SUM(cout), 0) as total FROM depenses WHERE date_depense BETWEEN ? AND ? AND arrivage_id IS NULL',
      [debutStr, finStr],
    );
    final dettesCreees = await getDettesCreeesEntre(debut, fin);

    // Total des arrivages REÇUS sur la période (prix de gros payé), vendus ou
    // non — distinct du coût des marchandises vendues calculé plus haut.
    final achatsPeriodeRows = await db.rawQuery('''
      SELECT COALESCE(SUM(quantite * prix_achat_unitaire), 0) as total, COALESCE(SUM(quantite), 0) as nb
      FROM arrivages
      WHERE date_ajout BETWEEN ? AND ?
    ''', [debutStr, finStr]);

    return ResumePeriode(
      debut: debut,
      fin: fin,
      coutMarchandisesVendues: (achatRows.first['total'] as num).toDouble(),
      totalVentes: (ventesRows.first['total'] as num).toDouble(),
      totalDepenses: (depensesRows.first['total'] as num).toDouble(),
      totalPertes: (pertesRows.first['total'] as num).toDouble(),
      nbVentes: (ventesRows.first['nb'] as num).toInt(),
      dettesCreees: dettesCreees,
      totalAchats: (achatsPeriodeRows.first['total'] as num).toDouble(),
      nbMarchandisesAchetees: (achatsPeriodeRows.first['nb'] as num).toInt(),
    );
  }

  /// Modèles les plus vendus sur la période, classés par quantité vendue.
  Future<List<ModeleVendu>> getTopModeles(DateTime debut, DateTime fin, {int limit = 5}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT a.modele as modele, SUM(vl.qte_vendue) as qte, SUM(vl.prix_ligne) as ca
      FROM ventes_lignes vl
      JOIN arrivages a ON a.id = vl.arrivage_id
      JOIN ventes v ON v.id = vl.vente_id
      WHERE v.date_vente BETWEEN ? AND ?
      GROUP BY a.modele
      ORDER BY qte DESC
      LIMIT ?
    ''', [_fmt(debut), _fmt(fin), limit]);
    return rows.map(ModeleVendu.fromMap).toList();
  }

  /// Résumés des [nombreMois] derniers mois, du plus ancien au plus récent,
  /// [moisFin] inclus (format 'YYYY-MM'). Utilisé pour le graphique d'évolution.
  Future<List<ResumePeriode>> getResumeDerniersMois(String moisFin, int nombreMois) async {
    final parts = moisFin.split('-');
    final anneeFin = int.parse(parts[0]);
    final moisFinNum = int.parse(parts[1]);
    final resumes = <ResumePeriode>[];
    for (var i = nombreMois - 1; i >= 0; i--) {
      final date = DateTime(anneeFin, moisFinNum - i, 1);
      final mois = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
      final periode = rangeMois(mois);
      resumes.add(await getResume(periode.debut, periode.fin));
    }
    return resumes;
  }

  String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
