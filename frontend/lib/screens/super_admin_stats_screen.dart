import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/super_admin_provider.dart';
import 'package:frontend/providers/theme_provider.dart';

class SuperAdminStatsScreen extends StatefulWidget {
  const SuperAdminStatsScreen({super.key});

  @override
  State<SuperAdminStatsScreen> createState() => _SuperAdminStatsScreenState();
}

class _SuperAdminStatsScreenState extends State<SuperAdminStatsScreen> {
  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques Générales'),
        elevation: 0,
      ),
      body: Consumer2<AuthProvider, SuperAdminProvider>(
        builder: (context, authProvider, superAdminProvider, _) {
          final totalEtablissements = superAdminProvider.totalEtablissements;
          final actifEtablissements = superAdminProvider.actifEtablissements;
          final inactifEtablissements = superAdminProvider.inactifEtablissements;

          final totalAdmins = superAdminProvider.admins.length;
          final actifAdmins =
              superAdminProvider.admins.where((a) => a.estActif).length;
          final inactifAdmins =
              superAdminProvider.admins.where((a) => !a.estActif).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ========== ÉTABLISSEMENTS ==========
                Text(
                  'Établissements',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                // Stats cards pour établissements
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        title: 'Total',
                        value: totalEtablissements.toString(),
                        icon: Icons.apartment,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        title: 'Actifs',
                        value: actifEtablissements.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        title: 'Inactifs',
                        value: inactifEtablissements.toString(),
                        icon: Icons.cancel,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Graphique de progression pour établissements
                _buildProgressSection(
                  context: context,
                  title: 'Distribution des établissements',
                  total: totalEtablissements,
                  actif: actifEtablissements,
                  inactif: inactifEtablissements,
                ),
                const SizedBox(height: 32),

                // ========== ADMINS ÉTABLISSEMENTS ==========
                Text(
                  'Admins Établissements',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                // Stats cards pour admins
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        title: 'Total',
                        value: totalAdmins.toString(),
                        icon: Icons.person,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        title: 'Actifs',
                        value: actifAdmins.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        title: 'Inactifs',
                        value: inactifAdmins.toString(),
                        icon: Icons.cancel,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Graphique de progression pour admins
                _buildProgressSection(
                  context: context,
                  title: 'Distribution des admins',
                  total: totalAdmins,
                  actif: actifAdmins,
                  inactif: inactifAdmins,
                ),
                const SizedBox(height: 32),

                // ========== INFOS SUPPLÉMENTAIRES ==========
                _buildInfoCard(
                  context: context,
                  title: 'Moyenne d\'admins par établissement',
                  value: totalEtablissements > 0
                      ? (totalAdmins / totalEtablissements).toStringAsFixed(2)
                      : '0',
                  icon: Icons.analytics,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  context: context,
                  title: 'Taux d\'activité établissements',
                  value: totalEtablissements > 0
                      ? '${((actifEtablissements / totalEtablissements) * 100).toStringAsFixed(1)}%'
                      : '0%',
                  icon: Icons.percent,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  context: context,
                  title: 'Taux d\'activité admins',
                  value: totalAdmins > 0
                      ? '${((actifAdmins / totalAdmins) * 100).toStringAsFixed(1)}%'
                      : '0%',
                  icon: Icons.percent,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection({
    required BuildContext context,
    required String title,
    required int total,
    required int actif,
    required int inactif,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final actifPercent = total > 0 ? (actif / total) : 0.0;
    final inactifPercent = total > 0 ? (inactif / total) : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Barre de progression
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Expanded(
                    flex: (actif * 100).toInt().clamp(0, 100),
                    child: Container(
                      height: 30,
                      color: Colors.green,
                      alignment: Alignment.center,
                      child: actif > 0
                          ? Text(
                              '${(actifPercent * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Expanded(
                    flex: (inactif * 100).toInt().clamp(0, 100),
                    child: Container(
                      height: 30,
                      color: Colors.orange,
                      alignment: Alignment.center,
                      child: inactif > 0
                          ? Text(
                              '${(inactifPercent * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Légende
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLegendItem('Actifs', Colors.green, actif),
                _buildLegendItem('Inactifs', Colors.orange, inactif),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text('$label: $count'),
      ],
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
