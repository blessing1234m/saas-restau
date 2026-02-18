import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/super_admin_provider.dart';
import 'package:frontend/models/admin_etablissement.dart';
import 'package:frontend/models/etablissement.dart';
import 'package:frontend/screens/create_admin_etablissement_screen.dart';

class AdminEtablissementManagementScreen extends StatefulWidget {
  const AdminEtablissementManagementScreen({super.key});

  @override
  State<AdminEtablissementManagementScreen> createState() => _AdminEtablissementManagementScreenState();
}

class _AdminEtablissementManagementScreenState extends State<AdminEtablissementManagementScreen> {
  String _search = '';
  String _filterState = 'all'; // all, actif, inactif

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final authProvider = context.read<AuthProvider>();
      final superAdminProvider = context.read<SuperAdminProvider>();
      if (authProvider.token != null) {
        superAdminProvider.loadAdmins(authProvider.token!);
        superAdminProvider.loadEtablissements(authProvider.token!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Admins Établissement'),
        elevation: 0,
      ),
      body: Consumer2<AuthProvider, SuperAdminProvider>(
        builder: (context, authProvider, superAdminProvider, _) {
          final admins = _getFilteredAdmins(superAdminProvider.admins);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher un admin (code agent, établissement)...',
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
                          builder: (context) => const CreateAdminEtablissementScreen(),
                        ),
                      );
                      if (result == true && mounted) {
                        // Actualiser la liste
                        final superAdminProvider = context.read<SuperAdminProvider>();
                        final authProvider = context.read<AuthProvider>();
                        await Future.delayed(const Duration(milliseconds: 500));
                        if (mounted) {
                          superAdminProvider.loadAdmins(authProvider.token!);
                        }
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvel Admin'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (superAdminProvider.isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (admins.isEmpty)
                Expanded(
                  child: Center(
                    child: Text('Aucun admin trouvé', style: textTheme.bodyLarge?.copyWith(color: colorScheme.outline)),
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await superAdminProvider.loadAdmins(authProvider.token!);
                    },
                    child: ListView.builder(
                      itemCount: admins.length,
                      itemBuilder: (context, index) {
                        final admin = admins[index];
                        return _buildAdminCard(context, admin, authProvider, superAdminProvider, colorScheme, textTheme);
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<AdminEtablissement> _getFilteredAdmins(List<AdminEtablissement> admins) {
    var filtered = admins;
    if (_filterState == 'actif') {
      filtered = filtered.where((a) => a.estActif).toList();
    } else if (_filterState == 'inactif') {
      filtered = filtered.where((a) => !a.estActif).toList();
    }
    if (_search.isNotEmpty) {
      final query = _search.toLowerCase();
      filtered = filtered.where((a) =>
        a.codeAgent.toLowerCase().contains(query) ||
        a.etablissementNom.toLowerCase().contains(query)
      ).toList();
    }
    return filtered;
  }

  Widget _buildAdminCard(
    BuildContext context,
    AdminEtablissement admin,
    AuthProvider authProvider,
    SuperAdminProvider superAdminProvider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        child: ListTile(
          leading: Icon(Icons.person, color: admin.estActif ? colorScheme.primary : colorScheme.error),
          title: Text(admin.codeAgent, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Text('Établissement : ${admin.etablissementNom}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                color: colorScheme.primary,
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CreateAdminEtablissementScreen(
                        adminToEdit: admin,
                      ),
                    ),
                  );
                  if (result == true && mounted) {
                    final superAdminProvider = context.read<SuperAdminProvider>();
                    final authProvider = context.read<AuthProvider>();
                    await Future.delayed(const Duration(milliseconds: 500));
                    if (mounted) {
                      superAdminProvider.loadAdmins(authProvider.token!);
                    }
                  }
                },
              ),
              IconButton(
                icon: Icon(admin.estActif ? Icons.block : Icons.check_circle),
                color: admin.estActif ? Colors.orange : Colors.red,
                onPressed: () async {
                  await superAdminProvider.toggleAdminState(admin.id, authProvider.token!);
                  if (mounted && superAdminProvider.errorMessage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(admin.estActif ? 'Admin désactivé' : 'Admin activé')),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                color: colorScheme.error,
                onPressed: () => _showDeleteConfirmDialog(context, admin, authProvider, superAdminProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    AdminEtablissement admin,
    AuthProvider authProvider,
    SuperAdminProvider superAdminProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer l\'admin ${admin.codeAgent} ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              await superAdminProvider.deleteAdmin(admin.id, authProvider.token!);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Admin supprimé avec succès')),
                );
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
