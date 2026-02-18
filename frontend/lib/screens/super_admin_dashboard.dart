import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/super_admin_provider.dart';
import 'package:frontend/screens/etablissements_management_screen.dart';
import 'package:frontend/screens/admin_etablissement_management_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load data
    Future.microtask(() {
      final authProvider = context.read<AuthProvider>();
      final superAdminProvider = context.read<SuperAdminProvider>();

      if (authProvider.token != null) {
        superAdminProvider.loadEtablissements(authProvider.token!);
        superAdminProvider.loadAdmins(authProvider.token!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.apartment),
              text: 'Établissements',
            ),
            Tab(
              icon: Icon(Icons.admin_panel_settings),
              text: 'Admins',
            ),
          ],
        ),
      ),
      body: Consumer2<AuthProvider, SuperAdminProvider>(
        builder: (context, authProvider, superAdminProvider, _) {
          return TabBarView(
            controller: _tabController,
            children: const [
              EtablissementsManagementScreen(),
              AdminEtablissementManagementScreen(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdminsTab(
    BuildContext context,
    SuperAdminProvider superAdminProvider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (superAdminProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (superAdminProvider.admins.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'Aucun admin d\'établissement',
            style: textTheme.bodyLarge,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: superAdminProvider.admins.length,
      itemBuilder: (context, index) {
        final admin = superAdminProvider.admins[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Card(
            child: ListTile(
              leading: Icon(
                Icons.admin_panel_settings,
                color: admin.estActif
                    ? colorScheme.primary
                    : colorScheme.outline,
              ),
              title: Text(admin.codeAgent),
              subtitle: Text(
                '${admin.etablissementNom} • ${admin.estActif ? 'Actif' : 'Inactif'}',
              ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Text(
                      admin.estActif
                          ? 'Désactiver'
                          : 'Activer',
                    ),
                    onTap: () async {
                      final authProvider = context.read<AuthProvider>();
                      await superAdminProvider.toggleAdminState(
                        admin.id,
                        authProvider.token!,
                      );
                    },
                  ),
                  PopupMenuItem(
                    child: const Text('Supprimer'),
                    onTap: () => _showDeleteAdminConfirm(
                      context,
                      admin.codeAgent,
                      () async {
                        final authProvider = context.read<AuthProvider>();
                        await superAdminProvider.deleteAdmin(
                          admin.id,
                          authProvider.token!,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteAdminConfirm(
    BuildContext context,
    String name,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              onConfirm();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Admin supprimé'),
                  ),
                );
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(context);
            },
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }
}
