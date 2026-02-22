import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/serveur_provider.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:frontend/models/serveur.dart';
import 'package:frontend/screens/create_serveur_screen.dart';
import 'package:frontend/screens/edit_serveur_screen.dart';

class ServeursManagementScreen extends StatefulWidget {
  const ServeursManagementScreen({super.key});

  @override
  State<ServeursManagementScreen> createState() => _ServeursManagementScreenState();
}

class _ServeursManagementScreenState extends State<ServeursManagementScreen> {
  String _search = '';
  String _filterState = 'all'; // all, actif, inactif

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final authProvider = context.read<AuthProvider>();
      final serveurProvider = context.read<ServeurProvider>();
      if (authProvider.token != null) {
        serveurProvider.loadServeurs(authProvider.token!);
      }
    });
  }

  List<Serveur> _getFilteredServeurs(List<Serveur> serveurs) {
    List<Serveur> filtered = serveurs;

    // Filter by search
    if (_search.isNotEmpty) {
      filtered = filtered
          .where((s) =>
              s.codeAgent.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }

    // Filter by state
    if (_filterState == 'actif') {
      filtered = filtered.where((s) => s.estActif).toList();
    } else if (_filterState == 'inactif') {
      filtered = filtered.where((s) => !s.estActif).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Serveurs'),
        elevation: 0,
      ),
      body: Consumer2<AuthProvider, ServeurProvider>(
        builder: (context, authProvider, serveurProvider, _) {
          final serveurs = _getFilteredServeurs(serveurProvider.serveurs);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher un serveur (code agent)...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() => _search = '');
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) => setState(() => _search = value),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Tous'),
                          selected: _filterState == 'all',
                          onSelected: (selected) => setState(() => _filterState = 'all'),
                        ),
                        FilterChip(
                          label: const Text('Actifs'),
                          selected: _filterState == 'actif',
                          onSelected: (selected) => setState(() => _filterState = 'actif'),
                        ),
                        FilterChip(
                          label: const Text('Inactifs'),
                          selected: _filterState == 'inactif',
                          onSelected: (selected) => setState(() => _filterState = 'inactif'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CreateServeurScreen(),
                        ),
                      );

                      if (result == true && mounted) {
                        serveurProvider.loadServeurs(authProvider.token!);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un serveur'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (serveurProvider.isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (serveurProvider.errorMessage != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Erreur',
                          style: textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(serveurProvider.errorMessage ?? ''),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            serveurProvider.clearError();
                            serveurProvider.loadServeurs(authProvider.token!);
                          },
                          child: const Text('Réessayer'),
                        )
                      ],
                    ),
                  ),
                )
              else if (serveurs.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun serveur trouvé',
                          style: textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _search.isNotEmpty
                              ? 'Essayez une autre recherche'
                              : 'Créez votre premier serveur',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: serveurs.length,
                    itemBuilder: (context, index) {
                      final serveur = serveurs[index];
                      return _buildServeurCard(context, serveur, authProvider, serveurProvider);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildServeurCard(
    BuildContext context,
    Serveur serveur,
    AuthProvider authProvider,
    ServeurProvider serveurProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: serveur.estActif ? colorScheme.primary : colorScheme.outline,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.person,
            color: colorScheme.onPrimary,
          ),
        ),
        title: Text(serveur.codeAgent),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: serveur.estActif
                    ? colorScheme.primaryContainer
                    : colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                serveur.estActif ? 'Actif' : 'Inactif',
                style: textTheme.labelSmall?.copyWith(
                  color: serveur.estActif
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditServeurScreen(serveur: serveur),
                  ),
                );

                if (result == true && mounted) {
                  serveurProvider.loadServeurs(authProvider.token!);
                }
              },
              child: const Text('Modifier'),
            ),
            PopupMenuItem(
              onTap: () async {
                try {
                  await serveurProvider.toggleServeurState(
                    serveur.id,
                    authProvider.token!,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          serveur.estActif
                              ? 'Serveur désactivé'
                              : 'Serveur activé',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: ${e.toString()}'),
                        backgroundColor: colorScheme.error,
                      ),
                    );
                  }
                }
              },
              child: Text(
                serveur.estActif ? 'Désactiver' : 'Activer',
              ),
            ),
            PopupMenuItem(
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmer la suppression'),
                    content: Text(
                      'Êtes-vous sûr de vouloir supprimer le serveur "${serveur.codeAgent}" ?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && mounted) {
                  try {
                    await serveurProvider.deleteServeur(
                      serveur.id,
                      authProvider.token!,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Serveur supprimé'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: ${e.toString()}'),
                          backgroundColor: colorScheme.error,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Supprimer'),
            ),
          ],
        ),
      ),
    );
  }
}
