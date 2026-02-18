# Configuration de l'API Backend

Cette application Flutter se connecte à un backend NestJS. Voici comment configurer la connexion.

## Configuration Locale (Development)

Pour le développement local, modifier le fichier `lib/constants/app_constants.dart`:

```dart
// Pour Windows/Mac/Linux avec localhost
static const String apiBaseUrl = 'http://localhost:3000/api';

// Ou si vous êtes sur Android/iOS pointant vers votre machine
// Récupérez l'adresse IP de votre machine avec: ipconfig (Windows) ou ifconfig (Mac/Linux)
static const String apiBaseUrl = 'http://192.168.x.x:3000/api';
```

## Configuration pour Émulateurs/Appareils

### Android
- Les émulateurs Android ont accès à localhost via `10.0.2.2`
- Plus simple: utiliser l'adresse IP réelle de votre machine

### iOS
- Utiliser l'adresse IP réelle de votre machine
- Vérifier que le firewall autorise les connexions entrantes sur le port 3000

### Appareil Physique
- S'assurer que l'appareil et la machine sont sur le même réseau
- Utiliser l'adresse IP de la machine (192.168.x.x ou similaire)

## Vérifier la Connectivité

```bash
# Vérifier que le backend écoute sur le port 3000
curl http://localhost:3000/health

# Depuis un autre appareil
curl http://192.168.x.x:3000/health
```

## Variables d'Environnement (Future)

Pour un système plus robuste avec multiples environnements, vous pouvez:

1. Utiliser `.env` avec le package `flutter_dotenv`:
```yaml
flutter_dotenv: ^5.0.0
```

2. Créer des fichiers de configuration:
```
lib/
├── config/
│   ├── dev.dart
│   ├── prod.dart
│   └── config.dart
```

3. Charger selon la plateforme/build:
```dart
void main() async {
  const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
  await AppConfig.loadEnvironment(environment);
  runApp(const MyApp());
}
```

## Test de Connexion

Après configuration, lancez l'app en mode debug:
```bash
flutter run -v
```

Vérifiez les logs pour les erreurs de connexion API. L'app devrait:
1. Afficher LoginScreen
2. Accepter un login valide du backend
3. Afficher HomeScreen après authentification réussie
