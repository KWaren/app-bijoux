import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Journal d'erreurs persistant, consultable depuis l'app.
///
/// Certaines erreurs (mise en page, peinture) ne passent pas par
/// [ErrorWidget.builder] et restent invisibles en release sans console
/// branchée — on les logge donc ici pour pouvoir les lire depuis le
/// téléphone (voir bouton de l'écran d'accueil).
class ErrorLog {
  ErrorLog._();

  static const int _tailleMaxOctets = 200 * 1024;

  static Future<File> _fichier() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(join(dir.path, 'erreurs.log'));
  }

  static Future<void> enregistrer(String message) async {
    try {
      final f = await _fichier();
      final horodatage = DateTime.now().toIso8601String();
      await f.writeAsString('[$horodatage]\n$message\n\n', mode: FileMode.append, flush: true);
      if (await f.length() > _tailleMaxOctets) {
        final contenu = await f.readAsString();
        await f.writeAsString(contenu.substring(contenu.length - _tailleMaxOctets ~/ 2));
      }
    } catch (_) {
      // Le journal lui-même ne doit jamais faire planter l'app.
    }
  }

  static Future<String> lire() async {
    try {
      final f = await _fichier();
      if (!await f.exists()) return 'Aucune erreur enregistrée.';
      final contenu = await f.readAsString();
      return contenu.trim().isEmpty ? 'Aucune erreur enregistrée.' : contenu;
    } catch (e) {
      return 'Impossible de lire le journal : $e';
    }
  }

  static Future<void> effacer() async {
    try {
      final f = await _fichier();
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
