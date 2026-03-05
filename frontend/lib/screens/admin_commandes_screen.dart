import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/admin_etablissement_provider.dart';
import 'package:frontend/providers/commandes_provider.dart';
import 'package:frontend/widgets/web_page_frame.dart';

class AdminCommandesScreen extends StatefulWidget {
  const AdminCommandesScreen({super.key});

  @override
  State<AdminCommandesScreen> createState() => _AdminCommandesScreenState();
}

class _AdminCommandesScreenState extends State<AdminCommandesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final auth = context.read<AuthProvider>();
      final admin = context.read<AdminEtablissementProvider>();
      final commandes = context.read<CommandesProvider>();
      if (auth.token == null) return;
      if (admin.sousRestaurants.isEmpty) {
        await admin.loadEtablissement(auth.token!);
      }
      await commandes.loadCommandes(auth.token!);
    });
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'EN_ATTENTE':
        return 'En attente';
      case 'EN_PREPARATION':
        return 'En preparation';
      case 'SERVIE':
        return 'Servie';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'EN_ATTENTE':
        return Colors.orange;
      case 'EN_PREPARATION':
        return Colors.blue;
      case 'SERVIE':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes'),
      ),
      body: WebPageFrame(
        maxWidth: 1200,
        child: Consumer3<AuthProvider, AdminEtablissementProvider, CommandesProvider>(
          builder: (context, auth, admin, commandesProvider, _) {
            final token = auth.token;
            final sousRestaurants = admin.sousRestaurants;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 700;
                      if (isMobile) {
                        return Column(
                          children: [
                            DropdownButtonFormField<String?>(
                              initialValue: commandesProvider.selectedSousRestaurantId,
                              decoration: const InputDecoration(
                                labelText: 'Sous-restaurant',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Tous'),
                                ),
                                ...sousRestaurants.map(
                                  (sr) => DropdownMenuItem<String?>(
                                    value: sr.id,
                                    child: Text(sr.nom),
                                  ),
                                ),
                              ],
                              onChanged: (value) async {
                                commandesProvider.setSousRestaurantFilter(value);
                                if (token != null) {
                                  await commandesProvider.loadCommandes(token);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: commandesProvider.selectedStatut,
                              decoration: const InputDecoration(
                                labelText: 'Statut',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'TOUS', child: Text('Tous')),
                                DropdownMenuItem(
                                  value: 'EN_ATTENTE',
                                  child: Text('En attente'),
                                ),
                                DropdownMenuItem(
                                  value: 'EN_PREPARATION',
                                  child: Text('En preparation'),
                                ),
                                DropdownMenuItem(value: 'SERVIE', child: Text('Servie')),
                              ],
                              onChanged: (value) async {
                                if (value == null) return;
                                commandesProvider.setStatutFilter(value);
                                if (token != null) {
                                  await commandesProvider.loadCommandes(token);
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                onPressed: token == null
                                    ? null
                                    : () => commandesProvider.loadCommandes(token),
                                icon: const Icon(Icons.refresh),
                                tooltip: 'Rafraichir',
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              initialValue: commandesProvider.selectedSousRestaurantId,
                              decoration: const InputDecoration(
                                labelText: 'Sous-restaurant',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Tous'),
                                ),
                                ...sousRestaurants.map(
                                  (sr) => DropdownMenuItem<String?>(
                                    value: sr.id,
                                    child: Text(sr.nom),
                                  ),
                                ),
                              ],
                              onChanged: (value) async {
                                commandesProvider.setSousRestaurantFilter(value);
                                if (token != null) {
                                  await commandesProvider.loadCommandes(token);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: commandesProvider.selectedStatut,
                              decoration: const InputDecoration(
                                labelText: 'Statut',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'TOUS', child: Text('Tous')),
                                DropdownMenuItem(
                                  value: 'EN_ATTENTE',
                                  child: Text('En attente'),
                                ),
                                DropdownMenuItem(
                                  value: 'EN_PREPARATION',
                                  child: Text('En preparation'),
                                ),
                                DropdownMenuItem(value: 'SERVIE', child: Text('Servie')),
                              ],
                              onChanged: (value) async {
                                if (value == null) return;
                                commandesProvider.setStatutFilter(value);
                                if (token != null) {
                                  await commandesProvider.loadCommandes(token);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: token == null
                                ? null
                                : () => commandesProvider.loadCommandes(token),
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Rafraichir',
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _buildContent(context, token, commandesProvider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    String? token,
    CommandesProvider provider,
  ) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(provider.errorMessage!),
        ),
      );
    }

    if (provider.commandes.isEmpty) {
      return const Center(
        child: Text('Aucune commande'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (token != null) {
          await provider.loadCommandes(token);
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.commandes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final cmd = provider.commandes[index];
          final status = (cmd['statut'] ?? '').toString();
          final table = cmd['table'] as Map<String, dynamic>?;
          final sousRestaurant = cmd['sousRestaurant'] as Map<String, dynamic>?;
          final items = (cmd['items'] as List<dynamic>? ?? []);
          final total = cmd['totalCommande'];
          final createdAtRaw = (cmd['createdAt'] ?? '').toString();

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Table ${table?['numero'] ?? '-'}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          _statusLabel(status),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: _statusColor(status),
                      ),
                      const Spacer(),
                      Text('${total ?? 0} FCFA'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Sous-restaurant: ${sousRestaurant?['nom'] ?? '-'}'),
                  const SizedBox(height: 4),
                  Text(
                    'Heure: ${createdAtRaw.length >= 16 ? createdAtRaw.substring(0, 16).replaceAll('T', ' ') : createdAtRaw}',
                  ),
                  const SizedBox(height: 10),
                  ...items.map((item) {
                    final plat = item['plat'] as Map<String, dynamic>?;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '- ${item['quantite']} x ${plat?['nom'] ?? 'Plat'}',
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (status == 'EN_ATTENTE')
                        FilledButton(
                          onPressed: token == null
                              ? null
                              : () async {
                                  final ok = await provider.updateCommandeStatut(
                                    token: token,
                                    commandeId: cmd['id'].toString(),
                                    statut: 'EN_PREPARATION',
                                  );
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ok
                                            ? 'Commande en preparation'
                                            : (provider.errorMessage ?? 'Erreur'),
                                      ),
                                      backgroundColor: ok ? Colors.green : Colors.red,
                                    ),
                                  );
                                },
                          child: const Text('Passer en preparation'),
                        ),
                      if (status == 'EN_PREPARATION')
                        FilledButton(
                          onPressed: token == null
                              ? null
                              : () async {
                                  final ok = await provider.updateCommandeStatut(
                                    token: token,
                                    commandeId: cmd['id'].toString(),
                                    statut: 'SERVIE',
                                  );
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ok
                                            ? 'Commande marquee servie'
                                            : (provider.errorMessage ?? 'Erreur'),
                                      ),
                                      backgroundColor: ok ? Colors.green : Colors.red,
                                    ),
                                  );
                                },
                          child: const Text('Marquer servie'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
