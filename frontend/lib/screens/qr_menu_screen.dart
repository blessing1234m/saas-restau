import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:frontend/constants/app_constants.dart';
import 'package:frontend/providers/admin_etablissement_provider.dart';
import 'package:frontend/providers/auth_provider.dart';

class QrMenuScreen extends StatefulWidget {
  const QrMenuScreen({super.key});

  @override
  State<QrMenuScreen> createState() => _QrMenuScreenState();
}

class _QrMenuScreenState extends State<QrMenuScreen> {
  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final adminProvider = context.read<AdminEtablissementProvider>();
    if (authProvider.token != null && adminProvider.sousRestaurants.isEmpty) {
      adminProvider.loadEtablissement(authProvider.token!);
    }
  }

  String _buildMenuUrl(String sousRestaurantId) {
    final base = AppConstants.apiBaseUrl.endsWith('/')
        ? AppConstants.apiBaseUrl.substring(0, AppConstants.apiBaseUrl.length - 1)
        : AppConstants.apiBaseUrl;
    return '$base${AppConstants.publicMenuEndpoint}/$sousRestaurantId/menu';
  }

  Future<void> _copyUrl(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien du menu copie')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR des menus'),
      ),
      body: Consumer<AdminEtablissementProvider>(
        builder: (context, adminProvider, _) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adminProvider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  adminProvider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            );
          }

          final sousRestaurants = adminProvider.sousRestaurants;
          if (sousRestaurants.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Aucun sous-restaurant. Creez-en un pour generer un QR menu.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sousRestaurants.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final sr = sousRestaurants[index];
              final menuUrl = _buildMenuUrl(sr.id);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sr.nom,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(8),
                          child: QrImageView(
                            data: menuUrl,
                            version: QrVersions.auto,
                            size: 210,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        menuUrl,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _copyUrl(menuUrl),
                            icon: const Icon(Icons.copy),
                            label: const Text('Copier le lien'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
