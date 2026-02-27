import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:frontend/screens/super_admin_dashboard.dart';
import 'package:frontend/screens/admin_dashboard.dart';
import 'package:frontend/screens/serveur_dashboard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;

        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Text('Utilisateur non connecté'),
            ),
          );
        }

        // Route to appropriate dashboard based on role
        if (user.isSuperAdmin) {
          return const SuperAdminDashboard();
        }

        if (user.isAdminEtablissement) {
          return const AdminDashboard();
        }

        if (user.isServeur) {
          return const ServeurDashboard();
        }

        // Default home screen for other roles
        return const _DefaultHomeScreen();
      },
    );
  }
}

class _DefaultHomeScreen extends StatelessWidget {
  const _DefaultHomeScreen();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MENO'),
        elevation: 0,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
                tooltip: themeProvider.isDarkMode ? 'Mode clair' : 'Mode sombre',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          if (user == null) {
            return Center(
              child: Text(
                'Utilisateur non connecté',
                style: textTheme.bodyLarge,
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenue',
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.codeAgent,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Chip(
                            label: Text(_getRoleLabel(user.role)),
                            backgroundColor: _getRoleColor(user.role, colorScheme),
                            labelStyle: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'ID: ${user.utilisateurId}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Quick Actions
                  Text(
                    'Actions rapides',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildActionCard(
                        context,
                        icon: Icons.restaurant_menu,
                        label: 'Commandes',
                        onTap: () {
                          // TODO: Navigate to orders
                        },
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.settings,
                        label: 'Paramètres',
                        onTap: () {
                          // TODO: Navigate to settings
                        },
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

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return 'Super Administrateur';
      case 'ADMIN_ETABLISSEMENT':
        return 'Admin Établissement';
      case 'SERVEUR':
        return 'Serveur';
      default:
        return role;
    }
  }

  Color _getRoleColor(String role, ColorScheme colorScheme) {
    switch (role) {
      case 'SUPER_ADMIN':
        return colorScheme.error;
      case 'ADMIN_ETABLISSEMENT':
        return colorScheme.primary;
      case 'SERVEUR':
        return colorScheme.tertiary;
      default:
        return colorScheme.primary;
    }
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
