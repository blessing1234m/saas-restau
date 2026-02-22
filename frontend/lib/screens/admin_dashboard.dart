import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/admin_etablissement_provider.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/change_password_screen.dart';
import 'package:frontend/screens/menu_management_screen.dart';
import 'package:frontend/screens/serveurs_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final authProvider = context.read<AuthProvider>();
      final adminProvider = context.read<AdminEtablissementProvider>();
      if (authProvider.token != null) {
        adminProvider.loadEtablissement(authProvider.token!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord'),
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
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            tooltip: 'Mon profil',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, AdminEtablissementProvider>(
        builder: (context, authProvider, adminProvider, _) {
          if (adminProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (adminProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.error,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      adminProvider.errorMessage ?? 'Une erreur est survenue',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (authProvider.token != null) {
                        adminProvider.loadEtablissement(authProvider.token!);
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final etablissement = adminProvider.etablissement;
          if (etablissement == null) {
            return Center(
              child: Text(
                'Aucune donnée disponible',
                style: textTheme.bodyLarge,
              ),
            );
          }

          final nomEtablissement = adminProvider.etablissementName ?? 'Établissement';
          final villeEtablissement = adminProvider.etablissementVille ?? 'Ville';
          final nbrSousRestaurants = adminProvider.sousRestaurants.length;
          final nbrServeurs = adminProvider.serveurs.length;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card with établissement name
                  Card(
                    elevation: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primaryContainer,
                            colorScheme.primary.withOpacity(0.3),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Établissement',
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            nomEtablissement,
                            style: textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 20,
                                color: colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                villeEtablissement,
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Statistics grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildStatCard(
                        context,
                        Icon(
                          Icons.restaurant,
                          size: 40,
                          color: colorScheme.primary,
                        ),
                        'Sous-restaurants',
                        '$nbrSousRestaurants',
                        colorScheme,
                        textTheme,
                      ),
                      _buildStatCard(
                        context,
                        Icon(
                          Icons.people,
                          size: 40,
                          color: colorScheme.secondary,
                        ),
                        'Compte Serveurs',
                        '$nbrServeurs',
                        colorScheme,
                        textTheme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Contact information section
                  Text(
                    'Informations de contact',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (adminProvider.etablissementTelephone != null &&
                              adminProvider.etablissementTelephone!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    size: 20,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      adminProvider.etablissementTelephone ?? '',
                                      style: textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (adminProvider.etablissementEmail != null &&
                              adminProvider.etablissementEmail!.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.email,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    adminProvider.etablissementEmail ?? '',
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick actions section
                  Text(
                    'Actions rapides',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      _buildActionButton(
                        context,
                        Icons.restaurant_menu,
                        'Gérer le Menu',
                        'Sous-restaurants, Catégories, Plats',
                        colorScheme,
                        textTheme,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MenuManagementScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildActionButton(
                        context,
                        Icons.person,
                        'Gérer les serveurs',
                        'Ajouter et gérer les serveurs',
                        colorScheme,
                        textTheme,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ServeursManagementScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildActionButton(
                        context,
                        Icons.settings,
                        'Paramètres',
                        'Configurer votre établissement',
                        colorScheme,
                        textTheme,
                        onTap: () {
                          // TODO: Implement settings
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

  Widget _buildStatCard(
    BuildContext context,
    Widget icon,
    String label,
    String value,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 12),
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    ColorScheme colorScheme,
    TextTheme textTheme,
    {VoidCallback? onTap}
  ) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: colorScheme.primary,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminEtablissementProvider>().clear();
              context.read<AuthProvider>().logout();
            },
            child: Text(
              'Déconnecter',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
