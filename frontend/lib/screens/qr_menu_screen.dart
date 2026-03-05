import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:frontend/constants/app_constants.dart';
import 'package:frontend/providers/admin_etablissement_provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/api_service.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:frontend/widgets/web_page_frame.dart';

class QrMenuScreen extends StatefulWidget {
  const QrMenuScreen({super.key});

  @override
  State<QrMenuScreen> createState() => _QrMenuScreenState();
}

class _QrMenuScreenState extends State<QrMenuScreen> {
  final Map<String, GlobalKey> _qrKeys = {};
  final Set<String> _regeneratingTableIds = {};
  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final adminProvider = context.read<AdminEtablissementProvider>();
    if (authProvider.token != null && adminProvider.sousRestaurants.isEmpty) {
      adminProvider.loadEtablissement(authProvider.token!);
    }
  }

  String _buildMenuUrl(String sousRestaurantId, {String? tableId, String? tableToken}) {
    final base = AppConstants.apiBaseUrl.endsWith('/')
        ? AppConstants.apiBaseUrl.substring(0, AppConstants.apiBaseUrl.length - 1)
        : AppConstants.apiBaseUrl;
    final params = <String>[];
    if (tableId != null && tableId.isNotEmpty) params.add('table=$tableId');
    if (tableToken != null && tableToken.isNotEmpty) params.add('t=$tableToken');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    return '$base${AppConstants.publicMenuEndpoint}/$sousRestaurantId/menu$query';
  }

  Future<void> _copyUrl(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien du menu copie')),
    );
  }

  Future<void> _downloadQrCode(String qrKeyId, String sousRestaurantName) async {
    try {
      // Request permissions
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission de stockage refusee')),
          );
          return;
        }
      }

      // Capture the QR code image
      final key = _qrKeys[qrKeyId];
      if (key == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: impossible de capturer le code QR')),
        );
        return;
      }

      final RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: impossible de convertir l\'image')),
        );
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Get the downloads directory
      late final String filepath;
      if (Platform.isAndroid) {
        final downloadsDir = await getExternalStorageDirectory();
        if (downloadsDir == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur: impossible d\'acceder au dossier de telechargement')),
          );
          return;
        }
        filepath =
            '${downloadsDir.path}/QR_Menu_${sousRestaurantName}_${DateTime.now().millisecondsSinceEpoch}.png';
      } else if (Platform.isIOS) {
        final appDocDir = await getApplicationDocumentsDirectory();
        filepath =
            '${appDocDir.path}/QR_Menu_${sousRestaurantName}_${DateTime.now().millisecondsSinceEpoch}.png';
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur: impossible d\'acceder au dossier de telechargement')),
          );
          return;
        }
        filepath =
            '${downloadsDir.path}/QR_Menu_${sousRestaurantName}_${DateTime.now().millisecondsSinceEpoch}.png';
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plateforme non suportee')),
        );
        return;
      }

      // Save the file
      final file = File(filepath);
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Code QR telecharge: ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du telechargement: $e')),
      );
    }
  }

  Future<void> _regenererTokenTable({
    required String sousRestaurantId,
    required String tableId,
  }) async {
    final authProvider = context.read<AuthProvider>();
    final adminProvider = context.read<AdminEtablissementProvider>();
    final token = authProvider.token;

    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session invalide')),
      );
      return;
    }

    setState(() => _regeneratingTableIds.add(tableId));
    try {
      await ApiService.regenererTokenTableQr(
        sousRestaurantId: sousRestaurantId,
        tableId: tableId,
        token: token,
      );
      await adminProvider.loadEtablissement(token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token QR regenere avec succes')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur regeneration token: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _regeneratingTableIds.remove(tableId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR des menus'),
      ),
      body: WebPageFrame(
        maxWidth: 1100,
        child: Consumer<AdminEtablissementProvider>(
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

          final qrEntries = <Map<String, String>>[];
          for (final sr in sousRestaurants) {
            final tables = sr.tables ?? [];
            if (tables.isEmpty) {
              qrEntries.add({
                'key': '${sr.id}-menu',
                'label': sr.nom,
                'srId': sr.id,
                'tableId': '',
              });
            } else {
              for (final t in tables) {
                final tableId = (t['id'] ?? '').toString();
                final tableNumber = (t['numero'] ?? '').toString();
                final tableToken = (t['tokenPublic'] ?? '').toString();
                qrEntries.add({
                  'key': '${sr.id}-$tableId',
                  'label': '${sr.nom} - Table $tableNumber',
                  'srId': sr.id,
                  'tableId': tableId,
                  'tableToken': tableToken,
                });
              }
            }
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: qrEntries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = qrEntries[index];
              final srId = entry['srId']!;
              final tableId = entry['tableId'] ?? '';
              final tableToken = entry['tableToken'];
              final hasTable = tableId.isNotEmpty;
              final isRegenerating = hasTable && _regeneratingTableIds.contains(tableId);
              final qrKeyId = entry['key']!;
              final displayName = entry['label']!;
              final menuUrl = _buildMenuUrl(
                srId,
                tableId: tableId,
                tableToken: tableToken,
              );
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: RepaintBoundary(
                          key: _qrKeys.putIfAbsent(
                            qrKeyId,
                            () => GlobalKey(),
                          ),
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
                          OutlinedButton.icon(
                            onPressed: () =>
                                _downloadQrCode(qrKeyId, displayName),
                            icon: const Icon(Icons.download),
                            label: const Text('Telecharger'),
                          ),
                          if (hasTable)
                            OutlinedButton.icon(
                              onPressed: isRegenerating
                                  ? null
                                  : () => _regenererTokenTable(
                                        sousRestaurantId: srId,
                                        tableId: tableId,
                                      ),
                              icon: isRegenerating
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.refresh),
                              label: Text(isRegenerating ? 'Regeneration...' : 'Regenerer QR'),
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
      ),
    );
  }
}
