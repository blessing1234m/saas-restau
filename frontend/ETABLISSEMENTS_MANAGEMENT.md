# 📋 Interface de Gestion des Établissements

## 🎯 Vue d'ensemble

L'interface **EtablissementsManagementScreen** offre une gestion complète des établissements (CRUD) pour le SuperAdmin. Elle est entièrement conforme au schéma Prisma et intégrée avec le backend NestJS.

## 🏗️ Architecture

```
etablissements_management_screen.dart
├── EtablissementsManagementScreen (StatefulWidget)
│   ├── Barre de recherche + filtrage
│   ├── Bouton "Créer"
│   ├── List des établissements (ExpansionTile)
│   │   ├── Actions (Modifier, Activer/Désactiver, Supprimer)
│   │   └── Détails développables
│   └── Dialogs (création, modification, suppression)
└── Intégration SuperAdminProvider + ApiService
```

## 📱 Fonctionnalités

### 1. **Affichage des Établissements**
- ✅ Liste avec détails développables (ExpansionTile)
- ✅ Icône avec code couleur (Actif/Inactif)
- ✅ Informations clés visibles: Nom, Ville, État
- ✅ Détails complets au développement: Téléphone, Email, Date de création

### 2. **Recherche et Filtrage**
- ✅ Barre de recherche en temps réel
- ✅ Recherche par: Nom, Ville, Email
- ✅ Filtres par état: Tous, Actifs, Inactifs
- ✅ Chips de filtrage intuitifs

### 3. **Création (CREATE)**
```dart
Dialog avec formulaire:
├── Nom * (requis)
├── Ville * (requis)
├── Téléphone (optionnel)
├── Email (optionnel)
└── Actions: Annuler, Créer
```
- ✅ Validation côté client (champs requis)
- ✅ Validation email
- ✅ Message de succès/erreur

### 4. **Modification (UPDATE)**
- ✅ Formulaire identique à la création
- ✅ Tous les champs pré-remplis
- ✅ Validation complète
- ✅ Feedback utilisateur

### 5. **Activation/Désactivation**
- ✅ Toggle d'état d'un clic
- ✅ Changement de couleur immédiat
- ✅ Bouton contextuel (Activer/Désactiver selon l'état)

### 6. **Suppression (DELETE)**
- ✅ Dialog de confirmation
- ✅ Message d'avertissement clair
- ✅ Suppression irréversible mentionnée

### 7. **Interactions UX**
- ✅ Pull-to-refresh
- ✅ Loading indicators
- ✅ SnackBar feedback
- ✅ Material Design 3 complète

## 📊 Schéma Prisma Supporté

```prisma
model Etablissement {
  id            String    @id @default(cuid())
  nom           String    ✅
  ville         String    ✅
  telephone     String?   ✅
  email         String?   ✅
  estActif      Boolean   @default(true)  ✅
  createdAt     DateTime  @default(now())  ✅
  updatedAt     DateTime  @updatedAt       ✅
}
```

**Tous les champs sont supportés!**

## 🔌 Intégration API

### Endpoints utilisés

```
POST   /api/super-admin/etablissements           → Créer
GET    /api/super-admin/etablissements           → Lister
GET    /api/super-admin/etablissements/{id}      → Détail
PUT    /api/super-admin/etablissements/{id}      → Modifier
PATCH  /api/super-admin/changer-etat-etablissements/{id}  → Activer/Désactiver
DELETE /api/super-admin/etablissements/{id}      → Supprimer
```

**Token JWT requis** pour tous les appels Auth Guard + Role Guard (SUPER_ADMIN)

## 🎨 Design Tokens (Material 3)

- **Couleurs**:
  - Actif: ✅ Green + Primary
  - Inactif: ⚠️ Orange + Error
  - Actions: Primary, Secondary, Error

- **Typographie**:
  - Titre: TitleMedium Bold
  - Subtitle: BodyMedium
  - Labels: LabelSmall

- **Composants**:
  - Cards avec elevation
  - ExpansionTile pour détails
  - FilterChips pour filtres
  - TextFormField + validation

## 🚀 Utilisation

### Depuis le Dashboard

```dart
// Dans SuperAdminDashboard
const EtablissementsManagementScreen()  // Intégré directement dans Tab 1
```

### Workflow Complet

```
1. Utilisateur lance l'app
   ↓
2. Login SuperAdmin
   ↓
3. Accès Dashboard
   ↓
4. Clique sur Tab "Établissements"
   ↓
5. Voir liste avec stats
   ↓
6. Actions possibles:
   - Rechercher/Filtrer
   - Créer nouveau
   - Modifier existant
   - Activer/Désactiver
   - Supprimer
```

## 📝 Modèle de Données

### Etablissement (Dart Model)

```dart
class Etablissement {
  final String id;
  final String nom;
  final String ville;
  final String? telephone;
  final String? email;
  final bool estActif;
  final DateTime createdAt;
  
  // JSON serialization automatique
  factory Etablissement.fromJson(Map<String, dynamic> json)
  Map<String, dynamic> toJson()
}
```

## 🔐 Sécurité

- ✅ JWT Token requis
- ✅ Role Guard (SUPER_ADMIN uniquement)
- ✅ Pas de stockage de données sensibles
- ✅ Validation côté client ET serveur
- ✅ Confirmation avant suppression

## 🧪 Test de Chaque Action

### 1. Créer
```
1. Cliquer "Nouvel Établissement"
2. Remplir: nom="Restaurant ABC", ville="Paris"
3. Cliquer "Créer"
4. Vérifier la liste mise à jour
```

### 2. Rechercher
```
1. Taper "Paris" dans la recherche
2. Vérifier filtrage en temps réel
```

### 3. Filtrer
```
1. Cliquer sur "Actifs"
2. Vérifier que seuls les actifs apparaissent
```

### 4. Modifier
```
1. Développer une carte
2. Cliquer "Modifier"
3. Changer un champ
4. Cliquer "Modifier"
```

### 5. Activer/Désactiver
```
1. Cliquer l'icône bascule
2. Vérifier la couleur change
3. Vérifier la liste mise à jour
```

### 6. Supprimer
```
1. Cliquer "Supprimer"
2. Confirmer dans dialog
3. Vérifier disparition de la liste
```

## 🔄 État (State Management)

### SuperAdminProvider gère

```dart
- _etablissements: List<Etablissement>
- _isLoading: bool
- _errorMessage: String?

Méthodes:
- loadEtablissements(token)
- createEtablissement(token, nom, ville, tel, email)
- updateEtablissement(id, token, nom, ville, tel, email)
- toggleEtablissementState(id, token)
- deleteEtablissement(id, token)
```

Les mises à jour s'appliquent **instantanément** via `notifyListeners()` (Consumer)

## 📱 Responsive Design

- ✅ Mobile: Optimisé pour small screens
- ✅ Tablet: Utilise l'espace horizontal
- ✅ Desktop: Cards et list adaptés

## 🚧 Améliorations Possibles

1. **Pagination** pour grandes listes
2. **Utilisation** statistiques par établissement
3. **Bulk Actions** (sélection multiple)
4. **Export CSV** des données
5. **Graphiques** d'activité
6. **Historique** des modifications

## 📚 Fichiers Impliqués

```
lib/
├── screens/etablissements_management_screen.dart  ← Écran principal
├── providers/super_admin_provider.dart             ← Logique état
├── services/api_service.dart                       ← API calls
├── models/etablissement.dart                       ← Modèle de données
└── screens/super_admin_dashboard.dart              ← Intégration
```

## 🎊 Statut

✅ **Complètement fonctionnelle**
- Création ✅
- Lecture ✅
- Mise à jour ✅
- Suppression ✅
- Recherche/Filtrage ✅
- Validation ✅
- Error handling ✅
- Material Design 3 ✅

**Prête pour la production!**

---

**Dernière mise à jour**: 18 Février 2026
**Version**: 1.0.0
**Statut**: STABLE
