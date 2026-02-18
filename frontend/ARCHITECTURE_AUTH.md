# Restaurant SaaS - Frontend Flutter

Implémentation du frontend Flutter pour le système de management de restaurant avec authentification JWT.

## 🏗️ Architecture

### Hiérarchie des Dossiers

```
lib/
├── main.dart                 # Point d'entrée (Material Design 3 + Provider)
├── constants/
│   └── app_constants.dart    # Constantes globales (URLs, clés stockage)
├── models/
│   ├── auth_user.dart        # Modèle utilisateur authentifié
│   ├── login_response.dart   # Réponse du serveur lors du login
│   └── index.dart            # Exports des modèles
├── services/
│   ├── api_service.dart      # Requêtes HTTP (login, endpoints protégés)
│   ├── secure_storage_service.dart # Stockage sécurisé du token JWT
│   └── index.dart            # Exports des services
├── providers/
│   └── auth_provider.dart    # État d'authentification (Provider pattern)
├── screens/
│   ├── login_screen.dart     # Écran de connexion (Material 3)
│   └── home_screen.dart      # Écran d'accueil principal
└── utils/
    └── router.dart           # Configuration des routes (si nécessaire)
```

## 🔐 Flux d'Authentification

### 1. **Initialisation au Démarrage**
- `AuthProvider._initializeAuth()` lit le token stocké en mémoire sécurisée
- Si un token existe, l'utilisateur est automatiquement connecté
- Sinon, l'écran de login s'affiche

### 2. **Processus de Login**
```
User -> LoginScreen -> AuthProvider.login() 
    -> ApiService.login(codeAgent, motDePasse)
    -> Backend valide les identifiants
    -> Response: { accessToken, utilisateurId, codeAgent, role }
    -> SecureStorageService stocke le token
    -> Consumer reconstruit l'app -> HomeScreen s'affiche
```

### 3. **Requêtes Authentifiées**
- Header: `Authorization: Bearer {token}`
- `ApiService.getWithAuth()` et `ApiService.postWithAuth()`

### 4. **Logout**
- Supprime le token du stockage sécurisé
- `AuthProvider.isAuthenticated` devient `false`
- Affiche automatiquement le LoginScreen

## 📦 Dépendances Principales

```yaml
provider: ^6.0.0               # Gestion d'état
http: ^1.1.0                   # Requêtes HTTP
flutter_secure_storage: ^9.0.0 # Stockage sécurisé du token
intl: ^0.19.0                  # Localisation (optionnel)
```

## 🚀 Installation et Lancement

### 1. Installer les dépendances
```bash
cd frontend
flutter pub get
```

### 2. **Configuration de l'URL API**
Modifier dans `lib/constants/app_constants.dart`:
```dart
static const String apiBaseUrl = 'http://YOUR_BACKEND_IP:3000/api';
```

### 3. Lancer l'application
```bash
flutter run
```

## 🧪 Test du Système d'Authentification

### Avec des données de test du backend

1. **Backend doit être lancé**: `npm run start` (depuis le dossier Backend)
2. **S'assurer qu'une migration a été faite**: Les tables d'utilisateurs doivent exister
3. **Créer un utilisateur de test** via la seed du backend ou via une requête POST:

```bash
# Exemple avec curl (adapter l'IP)
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "codeAgent": "AGENT001",
    "motDePasse": "password123"
  }'
```

### Cas de Test

#### ✅ Login Réussi
- Code Agent: `AGENT001`
- Mot de passe: `password123`
- Résultat: Accès au HomeScreen

#### ❌ Erreurs
- Code Agent invalide → Message d'erreur affiché
- Mot de passe incorrect → Message d'erreur affiché
- Serveur injoignable → Message d'erreur réseau

## 🎨 Système de Thème (Material Design 3)

- **Thème clair** et **sombre** automatiques basés sur les paramètres système
- La couleur de base (seedColor) est `Colors.blue`
- Tous les composants utilisent les tokens Material 3 (colorScheme, textTheme)

## 🔒 Sécurité

- ✅ Token JWT stocké dans `flutter_secure_storage` (chiffrée)
- ✅ Mot de passe validé côté serveur avec bcrypt
- ✅ Tokens avec expiration 24h
- ✅ Pas de stockage en clair des données sensibles

## 📋 Fonctionnalités Implémentées

### Login Screen
- ✅ Validation du formulaire
- ✅ Affichage/masquage du mot de passe
- ✅ Gestion des erreurs
- ✅ Indicateur de chargement
- ✅ Design Material 3

### Home Screen
- ✅ Affichage des informations utilisateur
- ✅ Affichage du rôle avec couleur
- ✅ Bouton déconnexion
- ✅ Actions futures structurées

### State Management
- ✅ Authentification persistante
- ✅ Gestion d'erreurs
- ✅ Chargement asynchrone

## 🚧 Prochaines Étapes

1. **Implémenter les écrans métier** (Commandes, Tables, etc.)
2. **Ajouter les guards de rôles** au niveau des routes
3. **Implémenter un système de refresh token**
4. **Ajouter les appels API authentifiés** pour les données métier
5. **Implémenter les notifications push**
6. **Tests unitaires et d'intégration**

## 💡 Notes de Développement

- Utiliser `Consumer<AuthProvider>` pour accéder aux données d'authentification
- Les routes changent automatiquement grâce aux Consumer dans main.dart
- Ne pas stocker le token en tant que texte clair (déjà géré par SecureStorageService)
- Toujours utiliser `ApiService.getWithAuth()` pour les requêtes protégées

## 📞 Support & Contact

Pour des questions sur l'architecture d'authentification ou le développement Flutter, consulter:
- Documentation backend: Backend/FONCTIONNALITES_APPLICATION.txt
- Architecture NestJS: Backend/src/auth/
