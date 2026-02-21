import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/serveur_menu_provider.dart';
import 'package:frontend/providers/theme_provider.dart';

class ServeurDashboard extends StatefulWidget {
  const ServeurDashboard({super.key});

  @override
  State<ServeurDashboard> createState() => _ServeurDashboardState();
}

class _ServeurDashboardState extends State<ServeurDashboard> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeMenu();
  }

  Future<void> _initializeMenu() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final menuProvider = context.read<ServeurMenuProvider>();
      
      if (authProvider.token != null) {
        await menuProvider.initializeServerMenu(authProvider.token!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu de Service'),
        elevation: 0,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return _buildMenuInterface(context, authProvider, colorScheme);
        },
      ),
    );
  }

  Widget _buildMenuInterface(
    BuildContext context,
    AuthProvider authProvider,
    ColorScheme colorScheme,
  ) {
    return Consumer<ServeurMenuProvider>(
      builder: (context, menuProvider, _) {
        // Show loading while initializing or loading menu
        if (_isInitializing || (menuProvider.isLoading && menuProvider.sousRestaurantActuel == null)) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chargement du menu...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        // Show error if no sous-restaurant assigned or error occurred
        if (menuProvider.sousRestaurantActuel == null && menuProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  menuProvider.errorMessage ?? 'Erreur du chargement',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: _initializeMenu,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        // Show menu interface once loaded
        return Row(
          children: [
            // Sidebar with categories
            Container(
              width: 180,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                border: Border(
                  right: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                ),
              ),
              child: _buildCategoriesSidebar(context, authProvider, colorScheme),
            ),
            // Main content with plats
            Expanded(
              child: _buildPlatsContent(context, authProvider, colorScheme),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoriesSidebar(
    BuildContext context,
    AuthProvider authProvider,
    ColorScheme colorScheme,
  ) {
    return Consumer<ServeurMenuProvider>(
      builder: (context, menuProvider, _) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                border: Border(
                  bottom: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menuProvider.sousRestaurantActuel?['nom'] ?? 'Menu',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      final authProvider = context.read<AuthProvider>();
                      if (authProvider.token != null && menuProvider.sousRestaurantActuel != null) {
                        final idValue = menuProvider.sousRestaurantActuel!['id'];
                        final idStr = idValue is String ? idValue : idValue.toString();
                        menuProvider.loadMenu(
                          idStr,
                          authProvider.token!,
                        );
                      }
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.refresh,
                          size: 16,
                          color: colorScheme.onPrimary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rafraîchir le menu',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onPrimary.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Categories list
            Expanded(
              child: menuProvider.categories.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune catégorie',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: menuProvider.categories.length,
                      itemBuilder: (context, index) {
                        final categorie = menuProvider.categories[index];
                        final selectedId = menuProvider.categorieSelectionnee?['id'];
                        final currentId = categorie['id'];
                        final isSelected = selectedId != null && selectedId.toString() == currentId.toString();

                        return _buildCategorieItem(
                          context,
                          categorie,
                          isSelected,
                          authProvider,
                          colorScheme,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategorieItem(
    BuildContext context,
    Map<String, dynamic> categorie,
    bool isSelected,
    AuthProvider authProvider,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () async {
        final menuProvider = context.read<ServeurMenuProvider>();
        final idValue = menuProvider.sousRestaurantActuel?['id'];
        final sousRestId = idValue is String ? idValue : (idValue?.toString() ?? '');
        await menuProvider.selectCategorie(
          categorie,
          sousRestId,
          authProvider.token!,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category image if available
            if (categorie['photoAffichage'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  _safeString(categorie['photoAffichage']),
                  height: 40,
                  width: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 40,
                      width: 100,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        color: colorScheme.outline,
                        size: 16,
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Text(
              _safeString(categorie['nom']),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatsContent(
    BuildContext context,
    AuthProvider authProvider,
    ColorScheme colorScheme,
  ) {
    return Consumer<ServeurMenuProvider>(
      builder: (context, menuProvider, _) {
        if (menuProvider.sousRestaurantActuel == null) {
          return Center(
            child: Text(
              'Sélectionnez un sous-restaurant',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.outline,
                  ),
            ),
          );
        }

        if (menuProvider.categorieSelectionnee == null) {
          return Center(
            child: Text(
              'Aucune catégorie sélectionnée',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.outline,
                  ),
            ),
          );
        }

        if (menuProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (menuProvider.plats.isEmpty) {
          return Center(
            child: Text(
              'Aucun plat dans cette catégorie',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.outline,
                  ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: menuProvider.plats.length,
          itemBuilder: (context, index) {
            final plat = menuProvider.plats[index];
            return _buildPlatCard(context, plat, colorScheme);
          },
        );
      },
    );
  }

  Widget _buildPlatCard(
    BuildContext context,
    Map<String, dynamic> plat,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plat image
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: _buildPlatImage(plat, colorScheme),
            ),
          ),
          // Plat details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _safeString(plat['nom']),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (plat['description'] != null && _safeString(plat['description']).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _safeString(plat['description']),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.outline,
                                  fontSize: 10,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Flexible(
                        child: Text(
                          '${plat['prix']} €',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                        ),
                      ),
                      // Icon(
                      //   Icons.add_circle,
                      //   color: colorScheme.primary,
                      //   size: 16,
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatImage(Map<String, dynamic> plat, ColorScheme colorScheme) {
    final images = plat['images'];
    if (images is List && images.isNotEmpty) {
      final imageData = images[0];
      if (imageData is Map<String, dynamic>) {
        final donnees = imageData['donnees'];
        if (donnees is String && donnees.isNotEmpty) {
          return Image.network(
            donnees,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImage(colorScheme);
            },
          );
        }
      }
    }
    return _buildPlaceholderImage(colorScheme);
  }

  Widget _buildPlaceholderImage(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceVariant,
      child: Icon(
        Icons.restaurant,
        size: 40,
        color: colorScheme.outline,
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

  // Helper function to safely convert dynamic values to String
  String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }}