import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/super_admin_provider.dart';
import 'package:frontend/models/etablissement.dart';
import 'package:frontend/screens/create_etablissement_screen.dart';
import 'package:frontend/widgets/web_page_frame.dart';

class EtablissementsManagementScreen extends StatefulWidget {
  const EtablissementsManagementScreen({super.key});

  @override
  State<EtablissementsManagementScreen> createState() =>
      _EtablissementsManagementScreenState();
}

class _EtablissementsManagementScreenState
    extends State<EtablissementsManagementScreen> {
  late TextEditingController _searchController;
  String _filterState = 'all'; // all, actif, inactif

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Load données
    Future.microtask(() {
      final authProvider = context.read<AuthProvider>();
      final superAdminProvider = context.read<SuperAdminProvider>();
      if (authProvider.token != null) {
        superAdminProvider.loadEtablissements(authProvider.token!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Établissements'),
        elevation: 0,
      ),
      body: WebPageFrame(
        maxWidth: 1200,
        child: Consumer2<AuthProvider, SuperAdminProvider>(
          builder: (context, authProvider, superAdminProvider, _) {
          // Filtrer les établissements
          final filteredEtablissements = _getFilteredEtablissements(
            superAdminProvider.etablissements,
          );

          return Column(
            children: [
              // Search and filter bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search field
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un établissement...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    // Filter chips
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Tous'),
                          selected: _filterState == 'all',
                          onSelected: (selected) {
                            setState(() {
                              _filterState = 'all';
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Actifs'),
                          selected: _filterState == 'actif',
                          onSelected: (selected) {
                            setState(() {
                              _filterState = 'actif';
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Inactifs'),
                          selected: _filterState == 'inactif',
                          onSelected: (selected) {
                            setState(() {
                              _filterState = 'inactif';
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Créer button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const CreateEtablissementScreen(),
                        ),
                      );
                      if (result == true && mounted) {
                        // Actualiser la liste
                        final superAdminProvider = context
                            .read<SuperAdminProvider>();
                        final authProvider = context.read<AuthProvider>();
                        await Future.delayed(const Duration(milliseconds: 500));
                        if (mounted) {
                          superAdminProvider.loadEtablissements(
                            authProvider.token!,
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvel Établissement'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // List
              if (superAdminProvider.isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filteredEtablissements.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'Aucun établissement trouvé',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await superAdminProvider.loadEtablissements(
                        authProvider.token!,
                      );
                    },
                    child: ListView.builder(
                      itemCount: filteredEtablissements.length,
                      itemBuilder: (context, index) {
                        final etab = filteredEtablissements[index];
                        return _buildEtablissementCard(
                          context,
                          etab,
                          authProvider,
                          superAdminProvider,
                          colorScheme,
                          textTheme,
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
          },
        ),
      ),
    );
  }

  List<Etablissement> _getFilteredEtablissements(
    List<Etablissement> etablissements,
  ) {
    var filtered = etablissements;

    // Filter by state
    if (_filterState == 'actif') {
      filtered = filtered.where((e) => e.estActif).toList();
    } else if (_filterState == 'inactif') {
      filtered = filtered.where((e) => !e.estActif).toList();
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where(
            (e) =>
                e.nom.toLowerCase().contains(query) ||
                e.ville.toLowerCase().contains(query) ||
                (e.email?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }

    return filtered;
  }

  Widget _buildEtablissementCard(
    BuildContext context,
    Etablissement etab,
    AuthProvider authProvider,
    SuperAdminProvider superAdminProvider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: etab.estActif
                  ? colorScheme.primaryContainer
                  : colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.apartment,
              color: etab.estActif ? colorScheme.primary : colorScheme.error,
            ),
          ),
          title: Text(
            etab.nom,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Row(
            children: [
              Icon(Icons.location_on, size: 16, color: colorScheme.outline),
              const SizedBox(width: 4),
              Text(etab.ville),
              const SizedBox(width: 12),
              Text(etab.categorie),
              const SizedBox(width: 12),
              Chip(
                label: Text(
                  etab.estActif ? 'Actif' : 'Inactif',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
                backgroundColor: etab.estActif ? Colors.green : Colors.red,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    context,
                    'Téléphone',
                    etab.telephone ?? 'Non renseigné',
                    Icons.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    'Email',
                    etab.email ?? 'Non renseigné',
                    Icons.email,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    'Catégorie',
                    etab.categorie,
                    Icons.category,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    'Créé le',
                    _formatDate(etab.createdAt),
                    Icons.calendar_today,
                  ),
                  const SizedBox(height: 16),
                  Divider(color: colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        context,
                        icon: Icons.edit,
                        label: 'Modifier',
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CreateEtablissementScreen(
                                etablissementToEdit: etab,
                              ),
                            ),
                          );
                          if (result == true && mounted) {
                            final superAdminProvider = context
                                .read<SuperAdminProvider>();
                            final authProvider = context.read<AuthProvider>();
                            await Future.delayed(
                              const Duration(milliseconds: 500),
                            );
                            if (mounted) {
                              superAdminProvider.loadEtablissements(
                                authProvider.token!,
                              );
                            }
                          }
                        },
                        color: colorScheme.primary,
                      ),
                      _buildActionButton(
                        context,
                        icon: etab.estActif ? Icons.block : Icons.check_circle,
                        label: etab.estActif ? 'Désactiver' : 'Activer',
                        onPressed: () async {
                          await superAdminProvider.toggleEtablissementState(
                            etab.id,
                            authProvider.token!,
                          );
                          if (mounted &&
                              superAdminProvider.errorMessage == null) {
                            // ✅ Message adapté selon l'état
                            String message = etab.estActif
                                ? 'Établissement désactivé (admins aussi désactivés)'
                                : 'Établissement activé';

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        color: etab.estActif ? Colors.red : Colors.green,
                      ),
                      _buildActionButton(
                        context,
                        icon: Icons.delete,
                        label: 'Supprimer',
                        onPressed: () => _showDeleteConfirmDialog(
                          context,
                          etab,
                          authProvider,
                          superAdminProvider,
                        ),
                        color: colorScheme.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: color),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    Etablissement etab,
    AuthProvider authProvider,
    SuperAdminProvider superAdminProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${etab.nom}"?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final success = await superAdminProvider.deleteEtablissement(
                etab.id,
                authProvider.token!,
              );

              if (success && mounted) {
                // Utiliser microtask pour éviter "setState during build"
                Future.microtask(() {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Établissement supprimé avec succès'),
                    ),
                  );
                });
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
