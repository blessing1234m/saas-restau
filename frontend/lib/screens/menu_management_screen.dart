import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/admin_etablissement_provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/menu_management_provider.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:frontend/models/index.dart';
import 'package:frontend/widgets/image_picker_widgets.dart';
import 'package:frontend/widgets/web_page_frame.dart';
import 'package:frontend/utils/image_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

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
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
                tooltip: themeProvider.isDarkMode
                    ? 'Mode clair'
                    : 'Mode sombre',
              );
            },
          ),
        ],
      ),
      body: WebPageFrame(
        maxWidth: 1400,
        child: Consumer2<AuthProvider, MenuManagementProvider>(
          builder: (context, authProvider, menuProvider, _) {
          final isSimpleCategory =
              context.watch<AdminEtablissementProvider>().etablissementCategorie ==
              'SIMPLE';

          if (isSimpleCategory &&
              _currentStep == 0 &&
              menuProvider.sousRestaurants.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _currentStep = 1);
              }
            });
          }

          final mainContent = menuProvider.isLoading
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
                );

          if (kIsWeb) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 290,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Etapes',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (!isSimpleCategory)
                              _buildWebStepTile(
                                label: 'Restaurants',
                                step: 0,
                                colorScheme: colorScheme,
                                textTheme: textTheme,
                              ),
                            _buildWebStepTile(
                              label: 'Categories',
                              step: 1,
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                            ),
                            _buildWebStepTile(
                              label: 'Plats',
                              step: 2,
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _canGoPrevious(isSimpleCategory)
                                        ? () => setState(() => _currentStep--)
                                        : null,
                                    icon: const Icon(Icons.arrow_back),
                                    label: const Text('Precedent',style: TextStyle(fontSize: 8),),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _canGoNext(menuProvider)
                                        ? () => setState(() => _currentStep++)
                                        : null,
                                    icon: const Icon(Icons.arrow_forward),
                                    label: const Text('Suivant',style: TextStyle(fontSize: 9),),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                    child: Card(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: mainContent,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              // Step indicator
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (!isSimpleCategory) ...[
                        _buildStepIndicator(
                          'Restaurants',
                          0,
                          colorScheme,
                          textTheme,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(
                            Icons.arrow_forward,
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                      _buildStepIndicator(
                        'Catégories',
                        1,
                        colorScheme,
                        textTheme,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(
                          Icons.arrow_forward,
                          color: colorScheme.outline,
                        ),
                      ),
                      _buildStepIndicator('Plats', 2, colorScheme, textTheme),
                    ],
                  ),
                ),
              ),
              Divider(color: colorScheme.outlineVariant),
              Expanded(child: mainContent),
            ],
          );
          },
        ),
      ),
      bottomNavigationBar: kIsWeb
          ? null
          : Consumer<MenuManagementProvider>(
        builder: (context, menuProvider, _) {
          final isSimpleCategory =
              context.watch<AdminEtablissementProvider>().etablissementCategorie ==
              'SIMPLE';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _canGoPrevious(isSimpleCategory)
                      ? () => setState(() => _currentStep--)
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Précédent'),
                ),
                ElevatedButton.icon(
                  onPressed: _canGoNext(menuProvider)
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

  bool _canGoPrevious(bool isSimpleCategory) {
    return isSimpleCategory ? _currentStep > 1 : _currentStep > 0;
  }

  bool _canGoNext(MenuManagementProvider menuProvider) {
    return _currentStep < 2 &&
        ((_currentStep == 0 && menuProvider.sousRestaurants.isNotEmpty) ||
            (_currentStep == 1 && menuProvider.selectedCategories.isNotEmpty));
  }

  bool _canJumpToStep(int step) {
    return (_currentStep == 0 && step <= 0) ||
        (_currentStep >= 1 && step == 1) ||
        (_currentStep >= 2 && step == 2);
  }

  Widget _buildWebStepTile({
    required String label,
    required int step,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final isActive = _currentStep == step;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: isActive ? colorScheme.primaryContainer : colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (_canJumpToStep(step)) {
              setState(() => _currentStep = step);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isActive
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  child: Text(
                    '${step + 1}',
                    style: textTheme.labelSmall?.copyWith(
                      color: isActive
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
        if (_canJumpToStep(step)) {
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
            color: isActive
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
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
    final etablissementCategorie = context
        .watch<AdminEtablissementProvider>()
        .etablissementCategorie;
    final isSimpleCategory = etablissementCategorie == 'SIMPLE';

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
                  onPressed: isSimpleCategory
                      ? null
                      : () => _showAddSousRestaurantDialog(
                          context,
                          authProvider,
                          menuProvider,
                        ),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                  style: isSimpleCategory
                      ? ElevatedButton.styleFrom(
                          foregroundColor: colorScheme.onSurface,
                          backgroundColor: colorScheme.surfaceVariant,
                        )
                      : null,
                ),
              ],
            ),
            if (isSimpleCategory)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'L\'Etablissement de catégorie SIMPLE ne peut pas avoir de sous-restaurants',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
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
                    await menuProvider.deleteSousRestaurant(
                      sr.id,
                      authProvider.token!,
                    );
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
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
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
        elevation: isSelected ? 3 : 1,
        color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Icon(
            Icons.category,
            color: isSelected ? colorScheme.primary : colorScheme.outline,
          ),
          title: Text(
            cat.nom,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isSelected ? colorScheme.primary : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: (cat.description != null && cat.description!.trim().isNotEmpty)
              ? Text(
                  cat.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: SizedBox(
            width: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _showDetailsCategorieDialog(context, cat),
                  icon: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: colorScheme.secondary,
                  ),
                  tooltip: 'Détails',
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(32, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                  icon: Icon(Icons.edit, size: 18, color: colorScheme.primary),
                  tooltip: 'Modifier',
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(32, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                  icon: Icon(Icons.delete, size: 18, color: Colors.red[400]),
                  tooltip: 'Supprimer',
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(32, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
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

    // Trouvez la catÃ©gorie sÃ©lectionnÃ©e ou retournez null si vide
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
    // Obtenir la premiÃ¨re image si disponible
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
      return Icon(Icons.restaurant_menu, color: colorScheme.primary);
    }

    return Card(
      child: InkWell(
        onTap: () => _showPlatDetailsDialog(context, plat),
        child: ListTile(
          leading: buildLeading(),
          title: Text(
            plat.nom,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
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

  // Formate le prix sans zÃ©ros inutiles
  String _formatPrice(double prix) {
    if (prix == prix.toInt()) {
      return prix.toInt().toString();
    }
    return prix
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  // ========== DIALOGS ==========

  void _showPlatDetailsDialog(BuildContext context, Plat plat) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final description = (plat.description ?? '').trim();
    final hasDescription = description.isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plat.nom,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          '${_formatPrice(plat.prix)} FCFA',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        backgroundColor: colorScheme.primaryContainer,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 2.2,
                      child: ColoredBox(
                        color: colorScheme.surfaceContainerHighest,
                        child: (plat.images != null && plat.images!.isNotEmpty)
                            ? _buildPlatImage(plat.images!.first, fit: BoxFit.cover)
                            : Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 42,
                                  color: colorScheme.outline,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Description',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      hasDescription ? description : 'Pas de description',
                      style: textTheme.bodyMedium?.copyWith(
                        color: hasDescription
                            ? colorScheme.onSurface
                            : colorScheme.outline,
                      ),
                    ),
                  ),
                  if (plat.images != null && plat.images!.length > 1) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Photos (${plat.images!.length})',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 74,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: plat.images!.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 74,
                              child: ColoredBox(
                                color: colorScheme.surfaceContainerHighest,
                                child: _buildPlatImage(plat.images![index]),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Fermer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlatImage(dynamic image, {BoxFit fit = BoxFit.cover}) {
    if (image is Map && image['donnees'] != null) {
      try {
        return Image.memory(
          base64Decode(image['donnees']),
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image),
          ),
        );
      } catch (_) {
        return const Center(child: Icon(Icons.broken_image));
      }
    }
    return const Center(child: Icon(Icons.image_not_supported_outlined));
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
    final descriptionController = TextEditingController(
      text: sr.description ?? '',
    );

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
    final descriptionController = TextEditingController(
      text: cat.description ?? '',
    );
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (selectedImages.isNotEmpty)
                    SizedBox(
                      height: 120,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(selectedImages.length, (
                            index,
                          ) {
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
                                          selectedImages[index].startsWith(
                                                'data:',
                                              )
                                              ? selectedImages[index]
                                                    .split(',')
                                                    .last
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
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
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
                    imagesBase64: selectedImages.isNotEmpty
                        ? selectedImages
                        : null,
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
    final descriptionController = TextEditingController(
      text: plat.description ?? '',
    );
    final prixController = TextEditingController(text: plat.prix.toString());
    // Seulement les NOUVELLES images (base64)
    List<String> newImages = [];
    // Toutes les images existantes originales
    List<dynamic> originalImages = List.from(plat.images ?? []);
    // IDs des images existantes Ã  supprimer
    Set<String> imagesToRemove = {};

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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Afficher les images existantes avec option de suppression
                  if (originalImages.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Images actuelles (cliquez X pour supprimer):',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(originalImages.length, (
                                index,
                              ) {
                                final imageId =
                                    originalImages[index]['id'] as String?;
                                final isMarkedForRemoval =
                                    imageId != null &&
                                    imagesToRemove.contains(imageId);

                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Opacity(
                                          opacity: isMarkedForRemoval
                                              ? 0.5
                                              : 1.0,
                                          child: Container(
                                            width: 120,
                                            height: 120,
                                            color: Colors.grey[200],
                                            child:
                                                (originalImages[index] is Map &&
                                                    originalImages[index]['donnees'] !=
                                                        null)
                                                ? Image.memory(
                                                    base64Decode(
                                                      originalImages[index]['donnees'],
                                                    ),
                                                    fit: BoxFit.cover,
                                                  )
                                                : const Icon(
                                                    Icons.image,
                                                    color: Colors.grey,
                                                  ),
                                          ),
                                        ),
                                      ),
                                      if (isMarkedForRemoval)
                                        Positioned.fill(
                                          child: Container(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                                size: 40,
                                              ),
                                            ),
                                          ),
                                        ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: isMarkedForRemoval
                                                ? Colors.green[400]
                                                : Colors.red[400],
                                            shape: BoxShape.circle,
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              if (imageId != null) {
                                                setState(() {
                                                  if (imagesToRemove.contains(
                                                    imageId,
                                                  )) {
                                                    imagesToRemove.remove(
                                                      imageId,
                                                    );
                                                  } else {
                                                    imagesToRemove.add(imageId);
                                                  }
                                                });
                                              }
                                            },
                                            child: Icon(
                                              isMarkedForRemoval
                                                  ? Icons.check
                                                  : Icons.close,
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
                    ),
                  // Afficher les NOUVELLES images
                  if (newImages.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nouvelles images:',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(newImages.length, (
                                index,
                              ) {
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
                                              newImages[index].startsWith(
                                                    'data:',
                                                  )
                                                  ? newImages[index]
                                                        .split(',')
                                                        .last
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
                  else if (originalImages.isEmpty)
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ajouter de nouvelles images:',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              (originalImages.length -
                                      imagesToRemove.length +
                                      newImages.length >=
                                  3)
                              ? null
                              : () async {
                                  final base64 =
                                      await ImageHandler.pickImageAsBase64(
                                        source: ImageSource.gallery,
                                      );
                                  if (base64 != null &&
                                      (newImages.length +
                                              originalImages.length -
                                              imagesToRemove.length) <
                                          3) {
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
                          onPressed:
                              (originalImages.length -
                                      imagesToRemove.length +
                                      newImages.length >=
                                  3)
                              ? null
                              : () async {
                                  final base64 =
                                      await ImageHandler.pickImageAsBase64(
                                        source: ImageSource.camera,
                                      );
                                  if (base64 != null &&
                                      (newImages.length +
                                              originalImages.length -
                                              imagesToRemove.length) <
                                          3) {
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
                    '${newImages.length + originalImages.length - imagesToRemove.length}/3 photos',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
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
                    removeImageIds: imagesToRemove.isNotEmpty
                        ? imagesToRemove.toList()
                        : null,
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showDetailsCategorieDialog(BuildContext context, Categorie categorie) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final description = (categorie.description ?? '').trim();
    final hasDescription = description.isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        categorie.nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        'Categorie',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      backgroundColor: colorScheme.primaryContainer,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 2.2,
                    child: ColoredBox(
                      color: colorScheme.surfaceContainerHighest,
                      child: categorie.photoAffichage != null
                          ? _buildCategoryImage(
                              categorie.photoAffichage!,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 42,
                                color: colorScheme.outline,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Description',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    hasDescription ? description : 'Pas de description',
                    style: textTheme.bodyMedium?.copyWith(
                      color: hasDescription
                          ? colorScheme.onSurface
                          : colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Fermer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryImage(
    String base64String, {
    BoxFit fit = BoxFit.cover,
  }) {
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
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(Icons.broken_image, size: 32, color: Colors.red[400]),
            );
          },
        );
      }
    } catch (e) {
      print('Erreur décodage image catégorie: $e');
    }

    return Center(
      child: Icon(Icons.image_not_supported, size: 32, color: Colors.grey[500]),
    );
  }
}






