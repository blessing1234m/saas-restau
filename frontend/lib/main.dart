import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/super_admin_provider.dart';
import 'package:frontend/providers/admin_etablissement_provider.dart';
import 'package:frontend/providers/menu_management_provider.dart';
import 'package:frontend/providers/serveur_provider.dart';
import 'package:frontend/providers/serveur_menu_provider.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/themes/app_themes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SuperAdminProvider()),
        ChangeNotifierProvider(create: (_) => AdminEtablissementProvider()),
        ChangeNotifierProvider(create: (_) => MenuManagementProvider()),
        ChangeNotifierProvider(create: (_) => ServeurProvider()),
        ChangeNotifierProvider(create: (_) => ServeurMenuProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Restaurant Manager',
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeProvider.themeMode,
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.isAuthenticated) {
                  return const HomeScreen();
                } else {
                  return const LoginScreen();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
