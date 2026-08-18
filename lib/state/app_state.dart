import 'package:flutter/foundation.dart';

import '../database/db_helper.dart';
import '../utils/date_ranges.dart';

class AppState extends ChangeNotifier {
  String _moisSelectionne = moisActuel();
  bool _prixAchatVisible = false;
  List<String> _moisDisponibles = [];

  /// Incrémenté à chaque changement de données (vente, dette, stock, dépense...)
  /// pour que les écrans gardés en mémoire par l'`IndexedStack` de la navigation
  /// (voir `RootShell`) sachent qu'ils doivent recharger au prochain passage,
  /// même sans changement de mois sélectionné.
  int _dataVersion = 0;

  String get moisSelectionne => _moisSelectionne;
  bool get prixAchatVisible => _prixAchatVisible;
  List<String> get moisDisponibles => _moisDisponibles;
  int get dataVersion => _dataVersion;

  void signalerChangement() {
    _dataVersion++;
    notifyListeners();
  }

  Future<void> chargerMoisDisponibles() async {
    final mois = await DbHelper.instance.getMoisDisponibles();
    if (!mois.contains(_moisSelectionne)) {
      mois.insert(0, _moisSelectionne);
    }
    _moisDisponibles = mois;
    notifyListeners();
  }

  void changerMois(String mois) {
    _moisSelectionne = mois;
    notifyListeners();
  }

  void ajouterMoisSiAbsent(String mois) {
    if (!_moisDisponibles.contains(mois)) {
      _moisDisponibles = [mois, ..._moisDisponibles];
      notifyListeners();
    }
  }

  void toggleVisibilitePrixAchat() {
    _prixAchatVisible = !_prixAchatVisible;
    notifyListeners();
  }

  /// Remasque le prix d'achat par sécurité (ex: en quittant l'écran Stock),
  /// pour ne jamais le laisser affiché par erreur au prochain passage devant une cliente.
  void masquerPrixAchat() {
    if (_prixAchatVisible) {
      _prixAchatVisible = false;
      notifyListeners();
    }
  }
}
