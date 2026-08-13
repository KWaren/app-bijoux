import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'database/backup_service.dart';
import 'screens/home_screen.dart';
import 'screens/resume_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/vente_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBijoux());
}

class AppBijoux extends StatelessWidget {
  const AppBijoux({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..chargerMoisDisponibles(),
      child: MaterialApp(
        title: 'App Bijoux',
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
