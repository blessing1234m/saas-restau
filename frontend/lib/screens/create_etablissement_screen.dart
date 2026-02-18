import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/super_admin_provider.dart';
import 'package:frontend/models/etablissement.dart';

class CreateEtablissementScreen extends StatefulWidget {
  final Etablissement? etablissementToEdit;

  const CreateEtablissementScreen({
    super.key,
    this.etablissementToEdit,
  });

  @override
  State<CreateEtablissementScreen> createState() => _CreateEtablissementScreenState();
}

class _CreateEtablissementScreenState extends State<CreateEtablissementScreen> {
  late TextEditingController _nomController;
  late TextEditingController _villeController;
  late TextEditingController _telephoneController;
  late TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.etablissementToEdit?.nom ?? '');
    _villeController = TextEditingController(text: widget.etablissementToEdit?.ville ?? '');
    _telephoneController = TextEditingController(text: widget.etablissementToEdit?.telephone ?? '');
    _emailController = TextEditingController(text: widget.etablissementToEdit?.email ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _villeController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.etablissementToEdit == null
              ? 'Nouvel Établissement'
              : 'Modifier l\'Établissement',
        ),
        elevation: 0,
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
                  // Nom
                  TextFormField(
                    controller: _nomController,
                    decoration: InputDecoration(
                      labelText: 'Nom de l\'établissement *',
                      prefixIcon: const Icon(Icons.apartment),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Le nom est requis' : null,
                  ),
                  const SizedBox(height: 16),
                  // Ville
                  TextFormField(
                    controller: _villeController,
                    decoration: InputDecoration(
                      labelText: 'Ville *',
                      prefixIcon: const Icon(Icons.location_city),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'La ville est requise' : null,
                  ),
                  const SizedBox(height: 16),
                  // Téléphone
                  TextFormField(
                    controller: _telephoneController,
                    decoration: InputDecoration(
                      labelText: 'Téléphone (optionnel)',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email (optionnel)',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
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
                            widget.etablissementToEdit == null ? 'Créer' : 'Modifier',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Message d'erreur si applicable
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

    final success = widget.etablissementToEdit == null
        ? await superAdminProvider.createEtablissement(
            authProvider.token!,
            _nomController.text,
            _villeController.text,
            _telephoneController.text.isEmpty ? null : _telephoneController.text,
            _emailController.text.isEmpty ? null : _emailController.text,
          )
        : await superAdminProvider.updateEtablissement(
            widget.etablissementToEdit!.id,
            authProvider.token!,
            _nomController.text,
            _villeController.text,
            _telephoneController.text.isEmpty ? null : _telephoneController.text,
            _emailController.text.isEmpty ? null : _emailController.text,
          );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.etablissementToEdit == null
                ? 'Établissement créé avec succès'
                : 'Établissement modifié avec succès',
          ),
        ),
      );
      // Recharge en arrière-plan et revient
      context
          .read<SuperAdminProvider>()
          .loadEtablissements(context.read<AuthProvider>().token!);
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isLoading = false);
    }
  }
}
