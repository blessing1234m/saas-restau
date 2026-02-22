# Guide d'Utilisation - Gestion des Mots de Passe (Frontend)

## 📋 Modèles Créés

### 1. `ChangePasswordRequest`
Utilisé quand l'utilisateur doit fournir l'ancien et le nouveau mot de passe.

```dart
class ChangePasswordRequest {
  final String ancienMotDePasse;
  final String nouveauMotDePasse;
  
  ChangePasswordRequest({
    required this.ancienMotDePasse,
    required this.nouveauMotDePasse,
  });
}
```

**Utilisé par:**
- SuperAdmin
- AdminEtablissement (pour son propre changement)
- Serveur

---

### 2. `ChangeUserPasswordRequest`
Utilisé par les AdminEtablissement pour changer le mot de passe d'un serveur.

```dart
class ChangeUserPasswordRequest {
  final String nouveauMotDePasse;
  
  ChangeUserPasswordRequest({
    required this.nouveauMotDePasse,
  });
}
```

**Utilisé par:**
- AdminEtablissement (pour changer MDP serveur)

---

### 3. `PasswordChangeResponse`
Réponse générique pour tous les changements de mot de passe.

```dart
class PasswordChangeResponse {
  final String message;
  final bool success;
}
```

**Réponse du serveur:**
```json
{
  "message": "Mot de passe changé avec succès",
  "success": true
}
```

---

## 🔌 Méthodes API Service

### Créées dans `ApiService`

#### 1. `changePasswordSuperAdmin`
```dart
static Future<PasswordChangeResponse> changePasswordSuperAdmin({
  required String ancienMotDePasse,
  required String nouveauMotDePasse,
  required String token,
}) async
```

**Appel:**
```dart
final response = await ApiService.changePasswordSuperAdmin(
  ancienMotDePasse: 'oldPass123',
  nouveauMotDePasse: 'newPass123',
  token: token,
);
```

---

#### 2. `changePasswordAdminEtablissement`
```dart
static Future<PasswordChangeResponse> changePasswordAdminEtablissement({
  required String ancienMotDePasse,
  required String nouveauMotDePasse,
  required String token,
}) async
```

**Appel:**
```dart
final response = await ApiService.changePasswordAdminEtablissement(
  ancienMotDePasse: 'oldPass123',
  nouveauMotDePasse: 'newPass123',
  token: token,
);
```

---

#### 3. `changeServerPassword`
```dart
static Future<PasswordChangeResponse> changeServerPassword({
  required String serveurId,
  required String nouveauMotDePasse,
  required String token,
}) async
```

**Appel:**
```dart
final response = await ApiService.changeServerPassword(
  serveurId: 'srv-123',
  nouveauMotDePasse: 'newPass123',
  token: token,
);
```

---

#### 4. `changePasswordServeur`
```dart
static Future<PasswordChangeResponse> changePasswordServeur({
  required String ancienMotDePasse,
  required String nouveauMotDePasse,
  required String token,
}) async
```

**Appel:**
```dart
final response = await ApiService.changePasswordServeur(
  ancienMotDePasse: 'oldPass123',
  nouveauMotDePasse: 'newPass123',
  token: token,
);
```

---

## 🎯 Méthodes Provider

### `AuthProvider`

#### 1. `changePassword()` - Pour changement propre MDP
```dart
Future<bool> changePassword({
  required String ancienMotDePasse,
  required String nouveauMotDePasse,
}) async
```

**Utilisation:**
```dart
final authProvider = Provider.of<AuthProvider>(context, listen: false);

bool success = await authProvider.changePassword(
  ancienMotDePasse: 'oldPassword',
  nouveauMotDePasse: 'newPassword',
);

if (success) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Mot de passe changé avec succès')),
  );
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(authProvider.errorMessage ?? 'Erreur')),
  );
}
```

**Détermination automatique du rôle:**
- Si `user.isSuperAdmin` → appelle `changePasswordSuperAdmin`
- Si `user.isAdminEtablissement` → appelle `changePasswordAdminEtablissement`
- Si `user.isServeur` → appelle `changePasswordServeur`

---

#### 2. `changeServerPassword()` - Pour AdminEtablissement
```dart
Future<bool> changeServerPassword({
  required String serveurId,
  required String nouveauMotDePasse,
}) async
```

**Utilisation:**
```dart
final authProvider = Provider.of<AuthProvider>(context, listen: false);

bool success = await authProvider.changeServerPassword(
  serveurId: 'srv-456',
  nouveauMotDePasse: 'newServerPassword',
);

if (success) {
  print('Mot de passe du serveur changé');
} else {
  print('Erreur: ${authProvider.errorMessage}');
}
```

**Restrictions:**
- ✅ Fonctionne uniquement pour AdminEtablissement
- ❌ Lève une exception si l'utilisateur n'est pas AdminEtablissement

---

## 📊 Gestion d'État

### États du Provider
```dart
bool isLoading       // En cours de traitement
String? errorMessage // Message d'erreur
bool isAuthenticated // Authentifié ou non
AuthUser? user       // Utilisateur courant
String? token        // JWT token
```

### Écoute des changements
```dart
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    if (authProvider.isLoading) {
      return CircularProgressIndicator();
    }
    
    if (authProvider.errorMessage != null) {
      return Text('Erreur: ${authProvider.errorMessage}');
    }
    
    return Text('Prêt');
  },
)
```

---

## 🛠️ Exemple Complet - Écran de Changement MDP

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _ancienMdp = '';
  late String _nouveauMdp = '';
  late String _confirmMdp = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Changer le mot de passe'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Ancien mot de passe
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Ancien mot de passe',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requis';
                      }
                      return null;
                    },
                    onChanged: (value) => _ancienMdp = value,
                  ),
                  SizedBox(height: 16),

                  // Nouveau mot de passe
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requis';
                      }
                      if (value.length < 6) {
                        return 'Minimum 6 caractères';
                      }
                      return null;
                    },
                    onChanged: (value) => _nouveauMdp = value,
                  ),
                  SizedBox(height: 16),

                  // Confirmer mot de passe
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requis';
                      }
                      if (value != _nouveauMdp) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                    onChanged: (value) => _confirmMdp = value,
                  ),
                  SizedBox(height: 24),

                  // Message d'erreur
                  if (authProvider.errorMessage != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      color: Colors.red.shade100,
                      child: Text(
                        authProvider.errorMessage!,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  SizedBox(height: 16),

                  // Bouton Changer
                  ElevatedButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              final success = await authProvider.changePassword(
                                ancienMotDePasse: _ancienMdp,
                                nouveauMotDePasse: _nouveauMdp,
                              );

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Mot de passe changé'),
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            }
                          },
                    child: authProvider.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text('Changer le mot de passe'),
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
```

---

## 🔐 Sécurité Frontend

### Bonnes Pratiques Implémentées

1. **Stockage Sécurisé**
   - Token stocké avec `SecureStorageService`
   - Pas de stockage en texte brut

2. **Validation DTO**
   - ✅ `toJson()` et `fromJson()` implémentés
   - ✅ Conversion automatique

3. **Gestion d'Erreurs**
   - Messages d'erreur spécifiques (ancien MDP incorrect, serveur non trouvé)
   - Nettoyage des erreurs

4. **Détermination de Rôle**
   - Utilise `user.isSuperAdmin`, `user.isAdminEtablissement`, `user.isServeur`
   - Appelle l'endpoint approprié automatiquement

---

## 📱 Intégration avec UI

### Recommandations pour les Screens

#### Pour SuperAdmin/AdminEtab/Serveur
Créer un écran de settings avec:
```
┌─────────────────────────────┐
│   Mon Compte                 │
├─────────────────────────────┤
│ Code Agent: SA001            │
│ Rôle: SuperAdmin             │
│                              │
│ [Changer le mot de passe]   │
│ [Déconnexion]               │
└─────────────────────────────┘
```

#### Pour AdminEtablissement
Ajouter dans la gestion des serveurs:
```
┌─────────────────────────────┐
│ Serveur: S001               │
│ Code: SERVEUR-001           │
│                              │
│ [Modifier]                   │
│ [Changer MDP]               │
│ [Désactiver]                │
└─────────────────────────────┘
```

---

## 🧪 Tests

### Scénarios de Test

#### Test 1: AdminEtab change son MDP
```dart
test('changePassword pour AdminEtablissement', () async {
  authProvider._user = AuthUser(
    utilisateurId: 'admin-1',
    codeAgent: 'A001',
    role: 'ADMIN_ETABLISSEMENT',
  );
  
  bool result = await authProvider.changePassword(
    ancienMotDePasse: 'oldPass',
    nouveauMotDePasse: 'newPass',
  );
  
  expect(result, true);
});
```

#### Test 2: AdminEtab change MDP serveur
```dart
test('changeServerPassword pour AdminEtablissement', () async {
  authProvider._user = AuthUser(
    utilisateurId: 'admin-1',
    codeAgent: 'A001',
    role: 'ADMIN_ETABLISSEMENT',
  );
  
  bool result = await authProvider.changeServerPassword(
    serveurId: 'srv-123',
    nouveauMotDePasse: 'newPass',
  );
  
  expect(result, true);
});
```

---

## 📚 Fichiers Créés/Modifiés

### Créés
- ✅ `lib/models/password_change.dart` - 3 classes (Request, ChangeUserRequest, Response)
- ✅ `lib/models/index.dart` - Export ajouté

### Modifiés
- ✅ `lib/services/api_service.dart` - 4 méthodes API
- ✅ `lib/providers/auth_provider.dart` - 2 méthodes provider

---

## ✅ Résumé

La gestion complète des mots de passe est implémentée avec:
- ✅ Modèles typés (Dart)
- ✅ Méthodes API avec gestion d'erreurs
- ✅ Provider pour la gestion d'état
- ✅ Sécurité (stockage sécurisé, validation)
- ✅ Détermination automatique de rôle
- ✅ Prêt pour l'intégration UI
