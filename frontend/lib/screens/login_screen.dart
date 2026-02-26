import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _codeAgentController;
  late TextEditingController _motDePasseController;
  bool _obscurePassword = true;
  bool _rememberMe = false;
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
        // in main.dart listening to authProvider changes
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                  // Header
                  Text(
                    'Connexion',
                    style: textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connectez-vous à votre compte',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  // Error message
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
                  if (authProvider.errorMessage != null)
                    const SizedBox(height: 16),
                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Code Agent Field
                        TextFormField(
                          controller: _codeAgentController,
                          enabled: !authProvider.isLoading,
                          decoration: InputDecoration(
                            labelText: 'Code Agent',
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
                        // Password Field
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
                        // Remember me & Forgot password
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   children: [
                        //     Row(
                        //       children: [
                        //         Checkbox(
                        //           value: _rememberMe,
                        //           onChanged: (value) {
                        //             setState(() {
                        //               _rememberMe = value ?? false;
                        //             });
                        //           },
                        //         ),
                        //         Text(
                        //           'Se souvenir de moi',
                        //           style: textTheme.bodySmall,
                        //         ),
                        //       ],
                        //     ),
                        //     TextButton(
                        //       onPressed: () {
                        //         // TODO: Implement forgot password
                        //       },
                        //       child: Text(
                        //         'Mot de passe oublié?',
                        //         style: textTheme.bodySmall?.copyWith(
                        //           color: colorScheme.primary,
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        const SizedBox(height: 24),
                        // Login Button
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
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
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
                  // Footer
                  Center(
                    child: Text(
                      'Bienvenue Sur Tabloo',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                        fontWeight: FontWeight.bold
                      ),
                      
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
}
