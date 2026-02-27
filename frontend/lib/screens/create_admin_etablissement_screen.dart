import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/super_admin_provider.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:frontend/models/admin_etablissement.dart';

class CreateAdminEtablissementScreen extends StatefulWidget {
  final AdminEtablissement? adminToEdit;

  const CreateAdminEtablissementScreen({
    super.key,
    this.adminToEdit,
  });

  @override
  State<CreateAdminEtablissementScreen> createState() =>
      _CreateAdminEtablissementScreenState();
}

class _CreateAdminEtablissementScreenState
    extends State<CreateAdminEtablissementScreen> {
  late TextEditingController _codeAgentController;
  late TextEditingController _motDePasseController;
  String? _selectedEtablissementId;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codeAgentController =
        TextEditingController(text: widget.adminToEdit?.codeAgent ?? '');
    _motDePasseController = TextEditingController();
    _selectedEtablissementId = widget.adminToEdit?.etablissementId;
  }

  @override
  void dispose() {
    _codeAgentController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.adminToEdit == null
              ? 'Nouvel Admin Établissement'
              : 'Modifier Admin Établissement',
        ),
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
      body: Consumer2<AuthProvider, SuperAdminProvider>(
        builder: (context, authProvider, superAdminProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Code Agent
                  TextFormField(
                    controller: _codeAgentController,
                    decoration: InputDecoration(
                      labelText: 'Identifiant *',
                      prefixIcon: const Icon(Icons.badge),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty
                            ? 'Le code agent est requis'
                            : null,
                  ),
                  const SizedBox(height: 16),
                  // Mot de passe
                  TextFormField(
                    controller: _motDePasseController,
                    decoration: InputDecoration(
                      labelText: widget.adminToEdit == null
                          ? 'Mot de passe *'
                          : 'Nouveau mot de passe (optionnel)',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (widget.adminToEdit == null) {
                        // Création : mot de passe requis
                        if (value == null || value.isEmpty) {
                          return 'Le mot de passe est requis';
                        }
                        if (value.length < 6) {
                          return 'Minimum 6 caractères';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Établissement
                  DropdownButtonFormField<String>(
                    value: _selectedEtablissementId,
                    items: superAdminProvider.etablissements
                        .map((e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.nom),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedEtablissementId = val),
                    decoration: InputDecoration(
                      labelText: 'Établissement *',
                      prefixIcon: const Icon(Icons.apartment),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty
                            ? 'Veuillez sélectionner un établissement'
                            : null,
                  ),
                  const SizedBox(height: 32),
                  // Boutons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _handleSubmit,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            widget.adminToEdit == null ? 'Créer' : 'Modifier',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Message d'erreur
                  if (superAdminProvider.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: colorScheme.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              superAdminProvider.errorMessage!,
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final superAdminProvider = context.read<SuperAdminProvider>();

    setState(() => _isLoading = true);

    String? error;
    if (widget.adminToEdit == null) {
      // Création
      error = await superAdminProvider.createAdminEtablissement(
        codeAgent: _codeAgentController.text.trim(),
        motDePasse: _motDePasseController.text.trim(),
        etablissementId: _selectedEtablissementId!,
        token: authProvider.token!,
      );
    } else {
      // Modification
      error = await superAdminProvider.updateAdminEtablissement(
        id: widget.adminToEdit!.id,
        codeAgent: _codeAgentController.text.trim(),
        motDePasse: _motDePasseController.text.isNotEmpty
            ? _motDePasseController.text.trim()
            : null,
        etablissementId: _selectedEtablissementId!,
        token: authProvider.token!,
      );
    }

    if (!mounted) return;

    if (error == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.adminToEdit == null
                  ? 'Admin créé avec succès'
                  : 'Admin modifié avec succès',
            ),
          ),
        );
      }
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isLoading = false);
    }
  }
}
