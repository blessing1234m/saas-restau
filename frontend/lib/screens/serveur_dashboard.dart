import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/serveur_menu_provider.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'dart:convert';

class ServeurDashboard extends StatefulWidget {
  const ServeurDashboard({super.key});

  @override
  State<ServeurDashboard> createState() => _ServeurDashboardState();
}

class _ServeurDashboardState extends State<ServeurDashboard> {
  bool _isInitializing = true;
  String? _selectedCategorieId;
  Map<String, dynamic>? _selectedPlat;
  int _currentImageIndex = 0;

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
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
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
        if (_isInitializing ||
            (menuProvider.isLoading &&
                menuProvider.sousRestaurantActuel == null)) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
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
        if (menuProvider.sousRestaurantActuel == null &&
            menuProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  menuProvider.errorMessage ?? 'Erreur du chargement',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colorScheme.error),
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

        // Show categories grid or plats based on selection
        if (_selectedCategorieId == null) {
          return _buildCategoriesGrid(context, menuProvider, colorScheme);
        } else {
          return _buildPlatsView(context, menuProvider, colorScheme);
        }
      },
    );
  }

  Widget _buildCategoriesGrid(
    BuildContext context,
    ServeurMenuProvider menuProvider,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        // Header with restaurant name
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Menu',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                menuProvider.sousRestaurantActuel?['nom'] ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary.withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),
        // Categories grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: menuProvider.categories.length,
            itemBuilder: (context, index) {
              final categorie = menuProvider.categories[index];
              return _buildCategorieCard(
                context,
                categorie,
                colorScheme,
                () {
                  setState(() => _selectedCategorieId = _safeString(categorie['id']));
                  final idValue = categorie['id'];
                  final categorieId = idValue is String ? idValue : idValue.toString();
                  final sousRestId = menuProvider.sousRestaurantActuel?['id'];
                  final sousRestIdStr =
                      sousRestId is String ? sousRestId : sousRestId.toString();
                  
                  final authProvider = context.read<AuthProvider>();
                  menuProvider.selectCategorie(
                    categorie,
                    sousRestIdStr,
                    authProvider.token!,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategorieCard(
    BuildContext context,
    Map<String, dynamic> categorie,
    ColorScheme colorScheme,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: _buildCategoriImage(categorie, colorScheme),
              ),
            ),
            // Category name
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _safeString(categorie['nom']),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriImage(
    Map<String, dynamic> categorie,
    ColorScheme colorScheme,
  ) {
    final imageUrl = categorie['photoAffichage'];
    if (imageUrl is String && imageUrl.isNotEmpty) {
      // Check if it's a data URI
      if (imageUrl.startsWith('data:')) {
        return _buildMemoryImage(imageUrl, colorScheme);
      }
      // Otherwise use network image
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildCategoryPlaceholder(colorScheme);
        },
      );
    }
    return _buildCategoryPlaceholder(colorScheme);
  }

  Widget _buildMemoryImage(
    String dataUri,
    ColorScheme colorScheme, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    try {
      // Extract base64 data from data URI
      final parts = dataUri.split(',');
      if (parts.length == 2) {
        final base64String = parts[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return _buildCategoryPlaceholder(colorScheme);
          },
        );
      }
    } catch (e) {
      return _buildCategoryPlaceholder(colorScheme);
    }
    return _buildCategoryPlaceholder(colorScheme);
  }

  Widget _buildCategoryPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          size: 40,
          color: colorScheme.outline.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildPlatsView(
    BuildContext context,
    ServeurMenuProvider menuProvider,
    ColorScheme colorScheme,
  ) {
    // Show plat details if selected
    if (_selectedPlat != null) {
      return _buildPlatDetail(context, menuProvider, colorScheme);
    }

    final selectedCategorie = menuProvider.categorieSelectionnee;
    
    return Column(
      children: [
        // Header with back button and category name
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),

              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => _selectedCategorieId = null);
                },
                child: Icon(
                  Icons.arrow_back,
                  color: colorScheme.onPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _safeString(selectedCategorie?['nom'] ?? 'Menu'),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      menuProvider.sousRestaurantActuel?['nom'] ?? '',
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
        // Plats list
        Expanded(
          child: menuProvider.isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                )
              : menuProvider.plats.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun plat disponible',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: menuProvider.plats.length,
                      itemBuilder: (context, index) {
                        final plat = menuProvider.plats[index];
                        return _buildPlatCard(
                          context,
                          plat,
                          colorScheme,
                          () {
                            setState(() {
                              _selectedPlat = plat;
                              _currentImageIndex = 0;
                            });
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildPlatDetail(
    BuildContext context,
    ServeurMenuProvider menuProvider,
    ColorScheme colorScheme,
  ) {
    if (_selectedPlat == null) {
      return const SizedBox.shrink();
    }

    final plat = _selectedPlat!;
    final images = (plat['images'] is List) ? (plat['images'] as List) : [];
    final hasImages = images.isNotEmpty;

    return Column(
      children: [
        // Header with back button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPlat = null;
                    _currentImageIndex = 0;
                  });
                },
                child: Icon(
                  Icons.arrow_back,
                  color: colorScheme.onPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _safeString(plat['nom']),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image gallery
                if (hasImages)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildGalleryImage(images, colorScheme),
                      ),
                      const SizedBox(height: 12),
                      // Image navigation controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _currentImageIndex > 0
                                ? () {
                                    setState(
                                        () => _currentImageIndex--);
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex > 0
                                    ? colorScheme.primary
                                    : colorScheme.surfaceVariant,
                              ),
                              child: Icon(
                                Icons.chevron_left,
                                color: _currentImageIndex > 0
                                    ? colorScheme.onPrimary
                                    : colorScheme.outline,
                                size: 24,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${_currentImageIndex + 1}/${images.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          GestureDetector(
                            onTap:
                                _currentImageIndex < images.length - 1
                                    ? () {
                                        setState(
                                            () => _currentImageIndex++);
                                      }
                                    : null,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex < images.length - 1
                                    ? colorScheme.primary
                                    : colorScheme.surfaceVariant,
                              ),
                              child: Icon(
                                Icons.chevron_right,
                                color: _currentImageIndex < images.length - 1
                                    ? colorScheme.onPrimary
                                    : colorScheme.outline,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.restaurant,
                        size: 64,
                        color: colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                  ),
                // Plat details
                Text(
                  _safeString(plat['nom']),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                // Price
                Text(
                  '${plat['prix']} FCFA',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                // Description
                if (plat['description'] != null &&
                    _safeString(plat['description']).isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _safeString(plat['description']),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryImage(
    List<dynamic> images,
    ColorScheme colorScheme,
  ) {
    if (images.isEmpty || _currentImageIndex >= images.length) {
      return Container(
        width: double.infinity,
        height: 250,
        color: colorScheme.surfaceVariant,
        child: Icon(
          Icons.image_not_supported,
          size: 48,
          color: colorScheme.outline,
        ),
      );
    }

    final imageData = images[_currentImageIndex];
    if (imageData is Map<String, dynamic>) {
      final donnees = imageData['donnees'];
      if (donnees is String && donnees.isNotEmpty) {
        try {
          // Check if it's a data URI
          if (donnees.startsWith('data:')) {
            return _buildMemoryImage(
              donnees,
              colorScheme,
              width: double.infinity,
              height: 250,
            );
          }
          // Otherwise use network image
          return Image.network(
            donnees,
            width: double.infinity,
            height: 250,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImage(colorScheme);
            },
          );
        } catch (e) {
          return _buildPlaceholderImage(colorScheme);
        }
      }
    }
    return _buildPlaceholderImage(colorScheme);
  }
  Widget _buildPlatCard(
    BuildContext context,
    Map<String, dynamic> plat,
    ColorScheme colorScheme,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Plat image
            Expanded(
              flex: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: _buildPlatImage(plat, colorScheme),
              ),
            ),
            // Plat name
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _safeString(plat['nom']),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${plat['prix']} FCFA',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          // Check if it's a data URI
          if (donnees.startsWith('data:')) {
            return _buildMemoryImage(donnees, colorScheme);
          }
          // Otherwise use network image
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
      child: Icon(Icons.restaurant, size: 40, color: colorScheme.outline),
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
  }
}
