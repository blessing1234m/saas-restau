import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/providers/admin_etablissement_provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:frontend/screens/admin_commandes_screen.dart';
import 'package:frontend/screens/menu_management_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/qr_menu_screen.dart';
import 'package:frontend/screens/serveurs_management_screen.dart';
import 'package:frontend/widgets/web_page_frame.dart';
import 'package:frontend/widgets/image_picker_widgets.dart';
import 'package:provider/provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final adminProvider = context.read<AdminEtablissementProvider>();
    if (authProvider.token != null) {
      adminProvider.loadEtablissement(authProvider.token!);
    }
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
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
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
      body: WebPageFrame(
        maxWidth: 1200,
        child: Consumer2<AuthProvider, AdminEtablissementProvider>(
          builder: (context, authProvider, adminProvider, _) {
            if (adminProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
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

            if (adminProvider.etablissement == null) {
              return Center(
                child: Text(
                  'Aucune donnée disponible',
                  style: textTheme.bodyLarge,
                ),
              );
            }

            final nomEtablissement =
                adminProvider.etablissementName ?? 'Établissement';
            final villeEtablissement = adminProvider.etablissementVille ?? 'Ville';
            final nbrSousRestaurants = adminProvider.sousRestaurants.length;
            final nbrServeurs = adminProvider.serveurs.length;

            final headerCard = _buildHeaderCard(
              context,
              nomEtablissement,
              villeEtablissement,
            );

            final contactSection = _buildContactSection(
              context,
              adminProvider.etablissementTelephone,
              adminProvider.etablissementEmail,
            );

            final actionsSection = _buildActionsSection(
              context,
              colorScheme,
              textTheme,
            );

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: kIsWeb
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          headerCard,
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStatCard(
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
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildStatCard(
                                            context,
                                            Icon(
                                              Icons.people,
                                              size: 40,
                                              color: colorScheme.secondary,
                                            ),
                                            'Compte Tablette',
                                            '$nbrServeurs',
                                            colorScheme,
                                            textTheme,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    contactSection,
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 3,
                                child: actionsSection,
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          headerCard,
                          const SizedBox(height: 24),
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
                                'Compte Tablette',
                                '$nbrServeurs',
                                colorScheme,
                                textTheme,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          contactSection,
                          const SizedBox(height: 24),
                          actionsSection,
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    String nomEtablissement,
    String villeEtablissement,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer,
              colorScheme.primary.withValues(alpha: 0.3),
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
    );
  }

  Widget _buildContactSection(
    BuildContext context,
    String? telephone,
    String? email,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                if (telephone != null && telephone.isNotEmpty)
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
                            telephone,
                            style: textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (email != null && email.isNotEmpty)
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
                          email,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
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
          Icons.receipt_long,
          'Suivi des commandes',
          'Voir et mettre à jour les commandes en cours',
          colorScheme,
          textTheme,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminCommandesScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          context,
          Icons.person,
          'Gérer les tablettes de Présentation',
          'Ajouter et gérer les tablettes',
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
          Icons.palette,
          'Personnaliser le QR',
          'Définir bannière et logo du menu public',
          colorScheme,
          textTheme,
          onTap: () => _showQrBrandingDialog(context),
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          context,
          Icons.qr_code_2,
          'QR des menus',
          'Générer un QR code pour chaque sous-restaurant',
          colorScheme,
          textTheme,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QrMenuScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          context,
          Icons.security,
          'Profil',
          'Voir mon profil et changer mon mot de passe',
          colorScheme,
          textTheme,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            );
          },
        ),
      ],
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
    TextTheme textTheme, {
    VoidCallback? onTap,
  }) {
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

  Future<void> _showQrBrandingDialog(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final adminProvider = context.read<AdminEtablissementProvider>();
    if (authProvider.token == null) return;

    String? logoImage = adminProvider.etablissementLogo;
    String? banniereImage = adminProvider.etablissementBanniere;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Personnaliser le menu QR'),
        content: SizedBox(
          width: 540,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatefulBuilder(
                  builder: (context, setState) => SingleImagePickerWidget(
                    label: 'Logo',
                    initialImage: logoImage,
                    maxWidth: 320,
                    maxHeight: 320,
                    onImageSelected: (base64Image) {
                      setState(() {
                        logoImage = base64Image;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (context, setState) => SingleImagePickerWidget(
                    label: 'Bannière',
                    initialImage: banniereImage,
                    maxWidth: 1280,
                    maxHeight: 720,
                    onImageSelected: (base64Image) {
                      setState(() {
                        banniereImage = base64Image;
                      });
                    },
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
          FilledButton(
            onPressed: () async {
              final success = await adminProvider.updateEtablissement(
                token: authProvider.token!,
                logoAffichage: logoImage,
                banniereAffichage: banniereImage,
              );

              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Logo et bannière enregistrés'
                        : (adminProvider.errorMessage ?? 'Erreur de mise à jour'),
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Enregistrer'),
          ),
        ],
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

