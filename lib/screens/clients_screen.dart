import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../utils/formatters.dart';
import 'client_detail_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  late Future<List<Map<String, dynamic>>> _futureClients;

  @override
  void initState() {
    super.initState();
    _futureClients = DbHelper.instance.getClientsResume();
  }

  void _recharger() {
    setState(() {
      _futureClients = DbHelper.instance.getClientsResume();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureClients,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final clients = snapshot.data!;
          if (clients.isEmpty) {
            return const Center(
              child: Padding(padding: EdgeInsets.all(24), child: Text('Aucun client enregistré pour l\'instant.')),
            );
          }
          return ListView.builder(
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final c = clients[index];
              final nom = c['client_nom'] as String;
              final dettes = (c['dettes_en_cours'] as num).toDouble();
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(nom.isNotEmpty ? nom[0].toUpperCase() : '?')),
                  title: Text(nom),
                  subtitle: Text(
                    '${c['nb_ventes']} achat(s) · Dernier : ${formatDateAffichage(c['dernier_achat'] as String)}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatMontant(c['total_achats'] as num), style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (dettes > 0)
                        Text('Doit ${formatMontant(dettes)}', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ClientDetailScreen(clientNom: nom)),
                    );
                    _recharger();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
