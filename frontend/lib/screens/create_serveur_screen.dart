import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/serveur_provider.dart';
import 'package:frontend/providers/admin_etablissement_provider.dart';
import 'package:frontend/models/index.dart';

class CreateServeurScreen extends StatefulWidget {
  const CreateServeurScreen({super.key});

  @override
  State<CreateServeurScreen> createState() => _CreateServeurScreenState();
}

class _CreateServeurScreenState extends State<CreateServeurScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeAgentController = TextEditingController();
  final _motDePasseController = TextEditingController();
  final _confirmMotDePasseController = TextEditingController();
  String? _selectedSousRestaurantId;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _loadSousRestaurants();
  }

  Future<void> _loadSousRestaurants() async {
    try {
      final adminProvider = context.read<AdminEtablissementProvider>();
      final sousRest = adminProvider.sousRestaurants;
      
      if (mounted && sousRest.isNotEmpty) {
        setState(() {
          _selectedSousRestaurantId = sousRest[0].id;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des sous-restaurants: $e');
    }
  }

  @override
  void dispose() {
    _codeAgentController.dispose();
    _motDePasseController.dispose();
    _confirmMotDePasseController.dispose();
    super.dispose();
  }

  Future<void> _createServeur() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_motDePasseController.text != _confirmMotDePasseController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedSousRestaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un sous-restaurant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final serveurProvider = context.read<ServeurProvider>();

      // Create message with sous-restaurant ID
      await serveurProvider.createServeurWithSousRestaurant(
        codeAgent: _codeAgentController.text.trim(),
        motDePasse: _motDePasseController.text,
        sousRestaurantId: _selectedSousRestaurantId!,
        token: authProvider.token!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serveur créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un serveur'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.person_add,
                      size: 40,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Description
                Text(
                  'Informations du serveur',
                  style: textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Remplissez les informations ci-dessous pour créer un nouveau compte serveur',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 24),

                // Code Agent Field
                TextFormField(
                  controller: _codeAgentController,
                  decoration: InputDecoration(
                    labelText: 'Identifiant *',
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
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // Sous-restaurant Field
                Consumer<AdminEtablissementProvider>(
                  builder: (context, adminProvider, _) => DropdownButtonFormField<String>(
                    value: _selectedSousRestaurantId,
                    decoration: InputDecoration(
                      labelText: 'Sous-restaurant assigné',
                      hintText: 'Sélectionnez un sous-restaurant',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.restaurant_menu),
                    ),
                    items: adminProvider.sousRestaurants.map((sr) {
                      return DropdownMenuItem<String>(
                        value: sr.id,
                        child: Text(sr.nom),
                      );
                    }).toList(),
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() => _selectedSousRestaurantId = value);
                          },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner un sous-restaurant';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Mot de passe Field
                TextFormField(
                  controller: _motDePasseController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    hintText: 'Entrez le mot de passe',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                    ),
                  ),
                  obscureText: !_showPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le mot de passe est requis';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // Confirmer Mot de passe Field
                TextFormField(
                  controller: _confirmMotDePasseController,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    hintText: 'Confirmez le mot de passe',
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez confirmer le mot de passe';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _createServeur,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Créer le serveur'),
                  ),
                ),
                const SizedBox(height: 16),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.pop(context, false);
                          },
                    child: const Text('Annuler'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
