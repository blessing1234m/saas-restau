import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/serveur_provider.dart';
import 'package:frontend/providers/admin_etablissement_provider.dart';
import 'package:frontend/models/index.dart';
import 'package:frontend/widgets/web_page_frame.dart';

class EditServeurScreen extends StatefulWidget {
  final Serveur serveur;

  const EditServeurScreen({
    super.key,
    required this.serveur,
  });

  @override
  State<EditServeurScreen> createState() => _EditServeurScreenState();
}

class _EditServeurScreenState extends State<EditServeurScreen> {
  late String _selectedSousRestaurantId;
  late TextEditingController _codeAgentController;
  late TextEditingController _ancienMotDePasseController;
  late TextEditingController _nouveauMotDePasseController;
  late TextEditingController _confirmMotDePasseController;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _showAncienPassword = false;
  bool _showNouveauPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _selectedSousRestaurantId = widget.serveur.sousRestaurantId ?? '';
    _codeAgentController = TextEditingController(text: widget.serveur.codeAgent);
    _ancienMotDePasseController = TextEditingController();
    _nouveauMotDePasseController = TextEditingController();
    _confirmMotDePasseController = TextEditingController();
  }

  @override
  void dispose() {
    _codeAgentController.dispose();
    _ancienMotDePasseController.dispose();
    _nouveauMotDePasseController.dispose();
    _confirmMotDePasseController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSousRestaurantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un sous-restaurant'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    // Validation: if password is entered, must fill all password fields
    if (_nouveauMotDePasseController.text.isNotEmpty) {
      if (_ancienMotDePasseController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez entrer l\'ancien mot de passe'),
            backgroundColor: Colors.amber,
          ),
        );
        return;
      }
      if (_confirmMotDePasseController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez confirmer le nouveau mot de passe'),
            backgroundColor: Colors.amber,
          ),
        );
        return;
      }
      if (_nouveauMotDePasseController.text != _confirmMotDePasseController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Les nouveaux mots de passe ne correspondent pas'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final serveurProvider = context.read<ServeurProvider>();

      await serveurProvider.updateServeurComplet(
        serveurId: widget.serveur.id,
        token: authProvider.token!,
        codeAgent: _codeAgentController.text.trim(),
        sousRestaurantId: _selectedSousRestaurantId,
        ancienMotDePasse: _ancienMotDePasseController.text.isNotEmpty ? _ancienMotDePasseController.text : null,
        nouveauMotDePasse: _nouveauMotDePasseController.text.isNotEmpty ? _nouveauMotDePasseController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serveur modifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le serveur'),
        elevation: 0,
      ),
      body: WebPageFrame(
        maxWidth: 900,
        child: Consumer2<AdminEtablissementProvider, ServeurProvider>(
          builder: (context, adminProvider, serveurProvider, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card
                  Card(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primaryContainer,
                            colorScheme.primary.withOpacity(0.3),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.orange[400],
                            ),
                            child: Center(
                              child: Text(
                                widget.serveur.codeAgent[0].toUpperCase(),
                                style: textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.serveur.codeAgent,
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Section
                  Text(
                    'Informations du serveur',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Code Agent Field
                  TextFormField(
                    controller: _codeAgentController,
                    decoration: InputDecoration(
                      labelText: 'Code Agent',
                      hintText: 'Ex: SERVEUR001',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.badge),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le code agent est requis';
                      }
                      if (value.length < 3) {
                        return 'Le code agent doit contenir au moins 3 caractères';
                      }
                      return null;
                    },
                    enabled: !_isSubmitting,
                  ),
                  const SizedBox(height: 16),

                  // Sous-restaurant Field
                  Text(
                    'Assignation',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            'Sous-restaurant assigné',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedSousRestaurantId.isEmpty
                                ? null
                                : _selectedSousRestaurantId,
                            hint: Text(
                              'Sélectionner un sous-restaurant',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                            items: adminProvider.sousRestaurants
                                .map((sr) => DropdownMenuItem<String>(
                                      value: sr.id,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Text(
                                          sr.nom,
                                          style: textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ))
                                .toList(),
                            onChanged: _isSubmitting ? null : (value) {
                              if (value != null) {
                                setState(() => _selectedSousRestaurantId = value);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Password Change Section
                  Text(
                    'Changer le mot de passe (optionnel)',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Laissez ces champs vides pour garder le mot de passe actuel',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Ancien Mot de passe
                  TextFormField(
                    controller: _ancienMotDePasseController,
                    decoration: InputDecoration(
                      labelText: 'Ancien mot de passe',
                      hintText: 'Entrez l\'ancien mot de passe',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showAncienPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _showAncienPassword = !_showAncienPassword);
                        },
                      ),
                    ),
                    obscureText: !_showAncienPassword,
                    enabled: !_isSubmitting,
                  ),
                  const SizedBox(height: 16),

                  // Nouveau Mot de passe
                  TextFormField(
                    controller: _nouveauMotDePasseController,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      hintText: 'Entrez le nouveau mot de passe',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showNouveauPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _showNouveauPassword = !_showNouveauPassword);
                        },
                      ),
                    ),
                    obscureText: !_showNouveauPassword,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (value.length < 6) {
                          return 'Le mot de passe doit contenir au moins 6 caractères';
                        }
                      }
                      return null;
                    },
                    enabled: !_isSubmitting,
                  ),
                  const SizedBox(height: 16),

                  // Confirmer Mot de passe
                  TextFormField(
                    controller: _confirmMotDePasseController,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le nouveau mot de passe',
                      hintText: 'Confirmez le nouveau mot de passe',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _showConfirmPassword = !_showConfirmPassword);
                        },
                      ),
                    ),
                    obscureText: !_showConfirmPassword,
                    enabled: !_isSubmitting,
                  ),
                  const SizedBox(height: 32),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submitForm,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Enregistrer les modifications'),
                        ),
                      ),
                    ],
                  ),
                ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
