import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'database/backup_service.dart';
import 'screens/home_screen.dart';
import 'screens/resume_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/vente_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'utils/error_log.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Par défaut, une erreur de construction de widget est invisible en release
  // (case grise vide) : on force l'affichage du message pour pouvoir
  // diagnostiquer un écran qui resterait vide sans ça.
  ErrorWidget.builder = (details) => Container(
        color: Colors.red.shade50,
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        child: Text(
          '${details.exception}',
          style: TextStyle(color: Colors.red.shade900, fontSize: 12),
        ),
      );
  // Les erreurs de mise en page/peinture (contrairement à celles de
  // construction) ne passent pas par ErrorWidget.builder et restent
  // totalement invisibles en release sans console — on les consigne donc
  // dans un journal lisible depuis l'app (voir bouton sur l'écran d'accueil).
  final gestionnaireOrigine = FlutterError.onError;
  FlutterError.onError = (details) {
    ErrorLog.enregistrer('${details.exceptionAsString()}\n${details.stack}');
    gestionnaireOrigine?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorLog.enregistrer('$error\n$stack');
    return true;
  };
  runApp(const StockFlowApp());
}

class StockFlowApp extends StatelessWidget {
  const StockFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..chargerMoisDisponibles(),
      child: MaterialApp(
        title: 'Stock Flow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const RootShell(),
      ),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _ecrans = [
    HomeScreen(),
    StockScreen(),
    VenteScreen(),
    ResumeScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Sauvegarde automatique en tâche de fond, sans bloquer le démarrage.
    BackupService.instance.backupAutomatiqueSiNecessaire();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _ecrans),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_shopping_cart_outlined),
            selectedIcon: Icon(Icons.add_shopping_cart),
            label: 'Vente',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Résumé',
          ),
        ],
      ),
    );
  }
}
