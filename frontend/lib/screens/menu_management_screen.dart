import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/menu_management_provider.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:frontend/models/index.dart';
import 'package:frontend/widgets/image_picker_widgets.dart';
import 'package:frontend/utils/image_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  int _currentStep = 0; // 0: Sous-restaurants, 1: Categories, 2: Plats

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final authProvider = context.read<AuthProvider>();
      final menuProvider = context.read<MenuManagementProvider>();
      if (authProvider.token != null) {
        menuProvider.loadSousRestaurants(authProvider.token!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion du Menu'),
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
        ],
      ),
      body: Consumer2<AuthProvider, MenuManagementProvider>(
        builder: (context, authProvider, menuProvider, _) {
          return Column(
            children: [
              // Step indicator
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStepIndicator(
                        'Restaurants',
                        0,
                        colorScheme,
                        textTheme,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.arrow_forward, color: colorScheme.outline),
                      ),
                      _buildStepIndicator(
                        'Catégories',
                        1,
                        colorScheme,
                        textTheme,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.arrow_forward, color: colorScheme.outline),
                      ),
                      _buildStepIndicator(
                        'Plats',
                        2,
                        colorScheme,
                        textTheme,
                      ),
                    ],
                  ),
                ),
              ),
              Divider(color: colorScheme.outlineVariant),
              // Main content
              Expanded(
                child: menuProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : IndexedStack(
                        index: _currentStep,
                        children: [
                          _buildSousRestaurantsView(
                            context,
                            authProvider,
                            menuProvider,
                            colorScheme,
                            textTheme,
                          ),
                          _buildCategoriesView(
                            context,
                            authProvider,
                            menuProvider,
                            colorScheme,
                            textTheme,
                          ),
                          _buildPlatsView(
                            context,
                            authProvider,
                            menuProvider,
                            colorScheme,
                            textTheme,
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<MenuManagementProvider>(
        builder: (context, menuProvider, _) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentStep > 0
                      ? () => setState(() => _currentStep--)
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Précédent'),
                ),
                ElevatedButton.icon(
                  onPressed: _currentStep < 2 &&
                          ((_currentStep == 0 && menuProvider.sousRestaurants.isNotEmpty) ||
                              (_currentStep == 1 && menuProvider.selectedCategories.isNotEmpty))
                      ? () => setState(() => _currentStep++)
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Suivant'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator(
    String label,
    int step,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isActive = _currentStep == step;
    return GestureDetector(
      onTap: () {
        if ((_currentStep == 0 && step <= 0) ||
            (_currentStep >= 1 && step == 1) ||
            (_currentStep >= 2 && step == 2)) {
          setState(() => _currentStep = step);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ========== SOUS-RESTAURANTS VIEW ==========

  Widget _buildSousRestaurantsView(
    BuildContext context,
    AuthProvider authProvider,
    MenuManagementProvider menuProvider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final sousRestaurants = menuProvider.sousRestaurants;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sous-Restaurants',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddSousRestaurantDialog(
                    context,
                    authProvider,
                    menuProvider,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (sousRestaurants.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.restaurant,
                      size: 64,
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun sous-restaurant',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sousRestaurants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final sr = sousRestaurants[index];
                  return _buildSousRestaurantCard(
                    context,
                    sr,
                    authProvider,
                    menuProvider,
                    colorScheme,
                    textTheme,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSousRestaurantCard(
    BuildContext context,
    SousRestaurant sr,
    AuthProvider authProvider,
    MenuManagementProvider menuProvider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isSelected = menuProvider.selectedSousRestaurantId == sr.id;

    return Card(
      color: isSelected ? colorScheme.primaryContainer : null,
      child: ListTile(
        leading: Icon(
          Icons.restaurant,
          color: isSelected ? colorScheme.primary : colorScheme.outline,
        ),
        title: Text(
          sr.nom,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: sr.description != null ? Text(sr.description!) : null,
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Modifier'),
              onTap: () => _showEditSousRestaurantDialog(
                context,
                sr,
                authProvider,
                menuProvider,
              ),
            ),
            PopupMenuItem(
              child: const Text('Supprimer'),
              onTap: () => _showDeleteConfirmDialog(
                context,
                'Supprimer ${sr.nom}?',
                () async {
                  if (authProvider.token != null) {
                    await menuProvider.deleteSousRestaurant(sr.id, authProvider.token!);
                  }
                },
              ),
            ),
          ],
        ),
        onTap: () {
          menuProvider.selectSousRestaurant(sr.id);
          Future.microtask(() {
            if (authProvider.token != null) {
              menuProvider.loadCategories(sr.id, authProvider.token!);
            }
          });
        },
      ),
    );
  }

  // ========== CATEGORIES VIEW ==========

  Widget _buildCategoriesView(
    BuildContext context,
    AuthProvider authProvider,
    MenuManagementProvider menuProvider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final selectedSR = menuProvider.selectedSousRestaurant;
    final categories = menuProvider.selectedCategories;

    if (selectedSR == null) {
      return Center(
        child: Text(
          'Veuillez sélectionner un sous-restaurant',
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
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sous-Restaurant Sélectionné',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedSR.nom,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Catégories de Plats',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddCategorieDialog(
                    context,
                    selectedSR.id,
                    authProvider,
                    menuProvider,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (categories.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.category,
                      size: 64,
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune catégorie',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return _buildCategorieCard(
                    context,
                    selectedSR.id,
                    cat,
                    authProvider,
                    menuProvider,
                    colorScheme,
                    textTheme,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorieCard(
    BuildContext context,
    String sousRestaurantId,
    Categorie cat,
    AuthProvider authProvider,
    MenuManagementProvider menuProvider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isSelected = menuProvider.selectedCategorieId == cat.id;

    return GestureDetector(
      onTap: () {
        menuProvider.selectCategorie(cat.id);
        menuProvider.loadPlats(sousRestaurantId, cat.id, authProvider.token!);
      },
      child: Card(
        elevation: isSelected ? 12 : 4,
        color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Photo area avec background gradient
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                color: isSelected 
                    ? colorScheme.primary.withOpacity(0.2) 
                    : colorScheme.primary.withOpacity(0.1),
              ),
              child: cat.photoAffichage != null
                  ? Center(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: _buildCategoryImage(cat.photoAffichage!),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 48,
                            color: colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pas de photo',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            // Contenu (nom + description + actions)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom
                    Text(
                      cat.nom,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isSelected ? colorScheme.primary: null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Boutons
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: () => _showDetailsCategorieDialog(
                            context,
                            cat,
                          ),
                          icon: Icon(Icons.info_outline, color: colorScheme.secondary),
                          tooltip: 'Détails',
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.secondary.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showEditCategorieDialog(
                            context,
                            sousRestaurantId,
                            cat,
                            authProvider,
                            menuProvider,
                          ),
                          icon: Icon(Icons.edit, color: colorScheme.primary),
                          tooltip: 'Modifier',
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.primary.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showDeleteConfirmDialog(
                            context,
                            'Supprimer ${cat.nom}?',
                            () async {
                              if (authProvider.token != null) {
                                await menuProvider.deleteCategorie(
                                  sousRestaurantId,
                                  cat.id,
                                  authProvider.token!,
                                );
                              }
                            },
                          ),
                          icon: Icon(Icons.delete, color: Colors.red[400]),
                          tooltip: 'Supprimer',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red[400]?.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
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

  // ========== PLATS VIEW ==========

  Widget _buildPlatsView(
    BuildContext context,
    AuthProvider authProvider,
    MenuManagementProvider menuProvider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final selectedSR = menuProvider.selectedSousRestaurant;
    final categories = menuProvider.selectedCategories;
    
    // Trouvez la catégorie sélectionnée ou retournez null si vide
    Categorie? selectedCat;
    if (categories.isNotEmpty && menuProvider.selectedCategorieId != null) {
      try {
        selectedCat = categories.firstWhere(
          (c) => c.id == menuProvider.selectedCategorieId,
        );
      } catch (e) {
        selectedCat = categories.isNotEmpty ? categories.first : null;
      }
    }
    
    final plats = menuProvider.selectedPlats;

    if (selectedSR == null || selectedCat == null) {
      return Center(
        child: Text(
          'Veuillez sélectionner une catégorie',
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
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedSR.nom,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedCat.nom,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Plats',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddPlatDialog(
                    context,
                    selectedSR.id,
                    selectedCat!.id,
                    authProvider,
                    menuProvider,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (plats.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun plat',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: plats.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final plat = plats[index];
                  return _buildPlatCard(
                    context,
                    selectedSR.id,
                    selectedCat!.id,
                    plat,
                    authProvider,
                    menuProvider,
                    colorScheme,
                    textTheme,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatCard(
    BuildContext context,
    String sousRestaurantId,
    String categorieId,
    Plat plat,
    AuthProvider authProvider,
    MenuManagementProvider menuProvider,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // Obtenir la première image si disponible
    Widget buildLeading() {
      if (plat.images != null && plat.images!.isNotEmpty) {
        final firstImage = plat.images![0];
        if (firstImage is Map && firstImage['donnees'] != null) {
          try {
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 64,
                height: 64,
                color: Colors.grey[200],
                child: Image.memory(
                  base64Decode(firstImage['donnees']),
                  fit: BoxFit.cover,
                ),
              ),
            );
          } catch (e) {
            print('Erreur affichage image: $e');
          }
        }
      }
      return Icon(
        Icons.restaurant_menu,
        color: colorScheme.primary,
      );
    }

    return Card(
      child: InkWell(
        onTap: () => _showPlatDetailsDialog(context, plat, colorScheme, textTheme),
        child: ListTile(
          leading: buildLeading(),
          title: Text(
            plat.nom,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plat.description != null && plat.description!.isNotEmpty)
                Text(plat.description!),
              const SizedBox(height: 4),
              Text(
                '${_formatPrice(plat.prix)} FCFA',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Modifier'),
                onTap: () => _showEditPlatDialog(
                  context,
                  sousRestaurantId,
                  categorieId,
                  plat,
                  authProvider,
                  menuProvider,
                ),
              ),
              PopupMenuItem(
                child: const Text('Supprimer'),
                onTap: () => _showDeleteConfirmDialog(
                  context,
                  'Supprimer ${plat.nom}?',
                  () async {
                    if (authProvider.token != null) {
                      await menuProvider.deletePlat(
                        sousRestaurantId,
                        categorieId,
                        plat.id,
                        authProvider.token!,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Formate le prix sans zéros inutiles
  String _formatPrice(double prix) {
    if (prix == prix.toInt()) {
      return prix.toInt().toString();
    }
    return prix.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  // ========== DIALOGS ==========

  void _showPlatDetailsDialog(
    BuildContext context,
    Plat plat,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(plat.nom),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Afficher la première image en grand
                if (plat.images != null && plat.images!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Builder(
                      builder: (context) {
                        final firstImage = plat.images![0];
                        if (firstImage is Map && firstImage['donnees'] != null) {
                          try {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(firstImage['donnees']),
                                fit: BoxFit.cover,
                                height: 250,
                                width: double.infinity,
                              ),
                            );
                          } catch (e) {
                            return Container(
                              height: 250,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.broken_image),
                              ),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                // Prix
                Text(
                  '${_formatPrice(plat.prix)} FCFA',
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                if (plat.description != null && plat.description!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        plat.description!,
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                // Toutes les images
                if (plat.images != null && plat.images!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Photos (${plat.images!.length})',
                        style: textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(
                              plat.images!.length,
                              (index) {
                                final image = plat.images![index];
                                if (image is Map && image['donnees'] != null) {
                                  try {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.memory(
                                          base64Decode(image['donnees']),
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image),
                                    );
                                  }
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showAddSousRestaurantDialog(
    BuildContext context,
    AuthProvider authProvider,
    MenuManagementProvider menuProvider,
  ) {
    final nomController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter un Sous-Restaurant'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nom = nomController.text.trim();
              final description = descriptionController.text.trim();

              if (nom.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer un nom')),
                );
                return;
              }

              if (authProvider.token != null) {
                final success = await menuProvider.createSousRestaurant(
                  nom: nom,
                  description: description.isEmpty ? null : description,
                  token: authProvider.token!,
                );

                if (success) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sous-restaurant créé'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(menuProvider.errorMessage ?? 'Erreur'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showEditSousRestaurantDialog(
    BuildContext context,
    SousRestaurant sr,
    AuthProvider authProvider,
    MenuManagementProvider menuProvider,
  ) {
    final nomController = TextEditingController(text: sr.nom);
    final descriptionController = TextEditingController(text: sr.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier le Sous-Restaurant'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nom = nomController.text.trim();
              final description = descriptionController.text.trim();

              if (nom.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer un nom')),
                );
                return;
              }

              if (authProvider.token != null) {
                final success = await menuProvider.updateSousRestaurant(
                  sousRestaurantId: sr.id,
                  nom: nom,
                  description: description.isEmpty ? null : description,
                  token: authProvider.token!,
                );

                if (success) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sous-restaurant modifié'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(menuProvider.errorMessage ?? 'Erreur'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _showAddCategorieDialog(
    BuildContext context,
    String sousRestaurantId,
    AuthProvider authProvider,
    MenuManagementProvider menuProvider,
  ) {
    final nomController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedPhoto;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter une Catégorie'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: InputDecoration(
                  labelText: 'Nom de la catégorie',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) {
                  return SingleImagePickerWidget(
                    label: 'Photo de la catégorie (optionnel)',
                    initialImage: selectedPhoto,
                    onImageSelected: (base64Image) {
                      setState(() {
                        selectedPhoto = base64Image;
                      });
                    },
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nom = nomController.text.trim();
              final description = descriptionController.text.trim();

              if (nom.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer un nom')),
                );
                return;
              }

              if (authProvider.token != null) {
                final success = await menuProvider.createCategorie(
                  sousRestaurantId: sousRestaurantId,
                  nom: nom,
                  description: description.isEmpty ? null : description,
                  photoBase64: selectedPhoto,
                  token: authProvider.token!,
                );

                if (success) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Catégorie créée'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(menuProvider.errorMessage ?? 'Erreur'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showEditCategorieDialog(
    BuildContext context,
    String sousRestaurantId,
    Categorie cat,
    AuthProvider authProvider,
    MenuManagementProvider menuProvider,
  ) {
    final nomController = TextEditingController(text: cat.nom);
    final descriptionController = TextEditingController(text: cat.description ?? '');
    String? selectedPhoto = cat.photoAffichage;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier la Catégorie'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: InputDecoration(
                  labelText: 'Nom de la catégorie',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) {
                  return SingleImagePickerWidget(
                    label: 'Photo de la catégorie',
                    initialImage: selectedPhoto,
                    onImageSelected: (base64Image) {
                      setState(() {
                        selectedPhoto = base64Image;
                      });
                    },
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nom = nomController.text.trim();
              final description = descriptionController.text.trim();

              if (nom.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer un nom')),
                );
                return;
              }

              if (authProvider.token != null) {
                final success = await menuProvider.updateCategorie(
                  sousRestaurantId: sousRestaurantId,
                  categorieId: cat.id,
                  nom: nom,
                  description: description.isEmpty ? null : description,
                  photoBase64: selectedPhoto,
                  token: authProvider.token!,
                );

                if (success) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Catégorie modifiée'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(menuProvider.errorMessage ?? 'Erreur'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _showAddPlatDialog(
    BuildContext context,
    String sousRestaurantId,
    String categorieId,
    AuthProvider authProvider,
    MenuManagementProvider menuProvider,
  ) {
    final nomController = TextEditingController();
    final descriptionController = TextEditingController();
    final prixController = TextEditingController();
    List<String> selectedImages = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ajouter un Plat'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextField(
                controller: nomController,
                decoration: InputDecoration(
                  labelText: 'Nom du plat',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: prixController,
                decoration: InputDecoration(
                  labelText: 'Prix (FCFA)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              if (selectedImages.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(selectedImages.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  color: Colors.grey[200],
                                  child: Image.memory(
                                    base64Decode(
                                      selectedImages[index].startsWith('data:')
                                          ? selectedImages[index].split(',').last
                                          : selectedImages[index],
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.red[400],
                                    shape: BoxShape.circle,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedImages.removeAt(index);
                                      });
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                    color: Colors.grey[50],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final base64 = await ImageHandler.pickImageAsBase64(
                          source: ImageSource.gallery,
                        );
                        if (base64 != null) {
                          setState(() {
                            if (selectedImages.length < 3) {
                              selectedImages.add(base64);
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Galerie'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final base64 = await ImageHandler.pickImageAsBase64(
                          source: ImageSource.camera,
                        );
                        if (base64 != null) {
                          setState(() {
                            if (selectedImages.length < 3) {
                              selectedImages.add(base64);
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Caméra'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${selectedImages.length}/3 photos',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nom = nomController.text.trim();
              final description = descriptionController.text.trim();
              final prixStr = prixController.text.trim();

              if (nom.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer un nom')),
                );
                return;
              }

              if (prixStr.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer un prix')),
                );
                return;
              }

              final prix = double.tryParse(prixStr);
              if (prix == null || prix <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Prix invalide')),
                );
                return;
              }

              if (authProvider.token != null) {
                final success = await menuProvider.createPlat(
                  sousRestaurantId: sousRestaurantId,
                  categorieId: categorieId,
                  nom: nom,
                  description: description.isEmpty ? null : description,
                  prix: prix,
                  imagesBase64: selectedImages.isNotEmpty ? selectedImages : null,
                  token: authProvider.token!,
                );

                if (success) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Plat créé'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(menuProvider.errorMessage ?? 'Erreur'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    ),
  );
  }

  void _showEditPlatDialog(
    BuildContext context,
    String sousRestaurantId,
    String categorieId,
    Plat plat,
    AuthProvider authProvider,
    MenuManagementProvider menuProvider,
  ) {
    final nomController = TextEditingController(text: plat.nom);
    final descriptionController = TextEditingController(text: plat.description ?? '');
    final prixController = TextEditingController(text: plat.prix.toString());
    // IMPORTANT: Seulement les NOUVELLES images (base64), pas les existantes
    List<String> newImages = [];
    // Garder les images existantes séparément
    List<dynamic> existingImages = List.from(plat.images ?? []);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifier le Plat'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextField(
                controller: nomController,
                decoration: InputDecoration(
                  labelText: 'Nom du plat',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: prixController,
                decoration: InputDecoration(
                  labelText: 'Prix (FCFA)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              // Afficher les images existantes
              if (existingImages.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Images existantes:', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(existingImages.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: (existingImages[index] is String && (existingImages[index] as String).startsWith('data:'))
                                      ? Image.memory(
                                          base64Decode(
                                            (existingImages[index] as String).split(',').last,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(Icons.image, color: Colors.grey),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              // Afficher les NOUVELLES images
              if (newImages.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nouvelles images:', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(newImages.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      color: Colors.grey[200],
                                      child: Image.memory(
                                        base64Decode(
                                          newImages[index].startsWith('data:')
                                              ? newImages[index].split(',').last
                                              : newImages[index],
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.red[400],
                                        shape: BoxShape.circle,
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            newImages.removeAt(index);
                                          });
                                        },
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                )
              else if (existingImages.isEmpty)
                Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                    color: Colors.grey[50],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (existingImages.length + newImages.length >= 3) ? null : () async {
                        final base64 = await ImageHandler.pickImageAsBase64(
                          source: ImageSource.gallery,
                        );
                        if (base64 != null && (newImages.length + existingImages.length) < 3) {
                          setState(() {
                            newImages.add(base64);
                          });
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Galerie'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (existingImages.length + newImages.length >= 3) ? null : () async {
                        final base64 = await ImageHandler.pickImageAsBase64(
                          source: ImageSource.camera,
                        );
                        if (base64 != null && (newImages.length + existingImages.length) < 3) {
                          setState(() {
                            newImages.add(base64);
                          });
                        }
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Caméra'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${existingImages.length + newImages.length}/3 photos',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nom = nomController.text.trim();
              final description = descriptionController.text.trim();
              final prixStr = prixController.text.trim();

              if (nom.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer un nom')),
                );
                return;
              }

              if (prixStr.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer un prix')),
                );
                return;
              }

              final prix = double.tryParse(prixStr);
              if (prix == null || prix <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Prix invalide')),
                );
                return;
              }

              if (authProvider.token != null) {
                final success = await menuProvider.updatePlat(
                  sousRestaurantId: sousRestaurantId,
                  categorieId: categorieId,
                  platId: plat.id,
                  nom: nom,
                  description: description.isEmpty ? null : description,
                  prix: prix,
                  imagesBase64: newImages.isNotEmpty ? newImages : null,
                  token: authProvider.token!,
                );

                if (success) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Plat modifié'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(menuProvider.errorMessage ?? 'Erreur'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    ),
  );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showDetailsCategorieDialog(
    BuildContext context,
    Categorie categorie,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(categorie.nom),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (categorie.photoAffichage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildCategoryImage(categorie.photoAffichage!),
                  ),
                ),
              if (categorie.description != null && categorie.description!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(categorie.description!),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryImage(String base64String) {
    try {
      Uint8List? imageBytes;
      
      // Extraire le base64 du format data URI
      if (base64String.startsWith('data:')) {
        final parts = base64String.split(',');
        if (parts.length == 2) {
          imageBytes = base64Decode(parts[1]);
        }
      } else {
        imageBytes = base64Decode(base64String);
      }

      if (imageBytes != null) {
        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.broken_image,
                size: 32,
                color: Colors.red[400],
              ),
            );
          },
        );
      }
    } catch (e) {
      print('Erreur décodage image catégorie: $e');
    }

    return Center(
      child: Icon(
        Icons.image_not_supported,
        size: 32,
        color: Colors.grey[500],
      ),
    );
  }
}
