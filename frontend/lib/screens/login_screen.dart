import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _codeAgentController;
  late TextEditingController _motDePasseController;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _codeAgentController = TextEditingController();
    _motDePasseController = TextEditingController();
  }

  @override
  void dispose() {
    _codeAgentController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext context, AuthProvider authProvider) async {
    if (_formKey.currentState!.validate()) {
      final success = await authProvider.login(
        _codeAgentController.text,
        _motDePasseController.text,
      );

      if (success && mounted) {
        // The app will automatically switch to HomeScreen due to Consumer
        // in main.dart listening to authProvider changes.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isWeb = kIsWeb;
    final screenHeight = MediaQuery.of(context).size.height;

    Widget buildContent(AuthProvider authProvider) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.02),
            Center(
              child: Image.asset(
                Theme.of(context).brightness == Brightness.dark
                    ? 'assets/logo_bleu_blanc.png'
                    : 'assets/logo_bleu_noir.png',
                height: isWeb ? 140 : 120,
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Center(
              child: Text(
                'Connexion',
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Connectez-vous à votre compte',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.05),
            if (authProvider.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.error,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        authProvider.errorMessage!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      onPressed: authProvider.clearError,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            if (authProvider.errorMessage != null) const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _codeAgentController,
                    enabled: !authProvider.isLoading,
                    decoration: InputDecoration(
                      labelText: 'Identifiant',
                      hintText: 'Entrez votre code agent',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le code agent est requis';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _motDePasseController,
                    enabled: !authProvider.isLoading,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      hintText: 'Entrez votre mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le mot de passe est requis';
                      }
                      if (value.length < 6) {
                        return 'Le mot de passe doit contenir au moins 6 caractères';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      _handleLogin(context, authProvider);
                    },
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () => _handleLogin(context, authProvider),
                      child: authProvider.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Text(
                              'Se connecter',
                              style: textTheme.labelLarge,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Bienvenue sur MENO, votre assistant de gestion de menu',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final content = buildContent(authProvider);
          return SingleChildScrollView(
            child: isWeb
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: content,
                    ),
                  )
                : content,
          );
        },
      ),
    );
  }
}
