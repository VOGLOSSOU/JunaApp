# Juna — Application Mobile

> Plateforme d'abonnement repas pour l'Afrique de l'Ouest

---

## À propos du projet

**Juna** est une application mobile qui connecte des travailleurs urbains avec des prestataires culinaires de confiance (restaurants, traiteurs, cuisiniers indépendants) en Afrique de l'Ouest.

L'idée est simple : au lieu de perdre du temps chaque jour à chercher quoi manger, l'utilisateur s'abonne à l'avance à un prestataire de son choix, choisit son mode de réception (livraison ou retrait), et paie via Mobile Money. Il reçoit un QR code qui sert de ticket pour valider sa commande chez le prestataire.

### Le problème résolu

En Afrique de l'Ouest, les travailleurs urbains perdent en moyenne 45 minutes par jour à trouver un repas de qualité. Les prestataires culinaires, eux, manquent de visibilité et de clientèle fidèle. Juna résout les deux problèmes en un seul produit.

### Marchés cibles

| Marché | Statut |
|--------|--------|
| Bénin (Cotonou) | Lancement initial |
| Togo | Extension prévue |
| Côte d'Ivoire | Extension prévue |
| Sénégal | Extension prévue |

---

## Stack technique

### Framework & Langage

| Élément | Choix | Raison |
|---------|-------|--------|
| Framework | **Flutter** (Dart) | Un seul codebase iOS + Android, performances natives, contrôle total du design |
| Langage | **Dart** | Typé, compilé nativement, parfaitement intégré à Flutter |

### Packages principaux

| Couche | Package | Rôle |
|--------|---------|------|
| State Management | `flutter_riverpod` + `riverpod_annotation` | Gestion d'état robuste, testable, scalable |
| Navigation | `go_router` | Routing déclaratif avec deep linking et guards d'authentification |
| HTTP Client | `dio` + `retrofit` | Appels API REST avec intercepteurs, gestion centralisée des erreurs |
| Auth Storage | `flutter_secure_storage` | Stockage sécurisé des tokens JWT |
| Cache local | `isar` | Base de données locale ultra-rapide pour le mode offline |
| Environnement | `flutter_dotenv` | Gestion des variables d'environnement (dev / prod) |
| Animations | `lottie` + Flutter natif | Animations fluides 60/120fps |
| Images réseau | `cached_network_image` | Chargement et mise en cache des images distantes |
| Formulaires | `reactive_forms` | Gestion propre des formulaires avec validation |
| Dates | `intl` | Formatage adapté au contexte africain (FCFA, fuseaux horaires) |
| Connectivité | `connectivity_plus` | Gestion du réseau lent / coupures (contexte africain) |
| Notifications | `firebase_messaging` | Push notifications |
| QR Code | `qr_flutter` + `mobile_scanner` | Génération et scan des QR codes de commande |
| Design System | `google_fonts` + Material 3 | Base personnalisée, typographie Plus Jakarta Sans |
| Skeleton loaders | `shimmer` | Placeholders animés pendant le chargement (jamais d'écran vide) |

---

## Architecture du code

Le projet suit le pattern **Feature-first + Clean Architecture légère**. Chaque fonctionnalité est un module autonome avec ses propres couches data / domain / presentation.

```
lib/
├── main.dart                        # Point d'entrée de l'app
│
├── app/
│   ├── router/                      # go_router — toutes les routes et guards
│   ├── shell/                       # Bottom navigation bar (MainShell)
│   ├── theme/                       # Design System complet
│   │   ├── app_colors.dart          # Palette officielle Juna
│   │   ├── app_typography.dart      # Styles de texte
│   │   ├── app_spacing.dart         # Espacements et border radius
│   │   └── app_theme.dart           # ThemeData Material 3
│   └── providers/                   # Providers Riverpod globaux
│
├── core/
│   ├── api/                         # Client Dio, intercepteurs, endpoints
│   ├── storage/                     # Secure storage, Isar cache
│   ├── errors/                      # AppException, gestion centralisée erreurs
│   ├── utils/
│   │   ├── enums.dart               # Tous les enums avec labels français
│   │   └── mock_data.dart           # Données simulées (phase design)
│   └── widgets/                     # Composants réutilisables du Design System
│       ├── juna_button.dart
│       ├── juna_badge.dart
│       ├── juna_rating.dart
│       ├── juna_skeleton.dart
│       └── juna_avatar.dart
│
└── features/
    ├── auth/                        # Authentification
    ├── home/                        # Page d'accueil
    ├── subscriptions/               # Catalogue et détail abonnements
    ├── explorer/                    # Recherche et filtres
    ├── orders/                      # Commandes et checkout
    ├── profile/                     # Profil et sous-pages
    ├── provider_space/              # Espace prestataire
    ├── notifications/               # Notifications push
    └── support/                     # Support et tickets
```

Chaque feature suit la même structure interne :
```
feature_name/
├── data/
│   ├── models/          # Modèles JSON (sérialisables)
│   ├── repositories/    # Implémentation des repos (appels API)
│   └── datasources/     # Sources de données (remote / local)
├── domain/
│   ├── entities/        # Entités métier (pures, pas de dépendance Flutter)
│   └── usecases/        # Cas d'usage (logique métier)
└── presentation/
    ├── screens/         # Écrans Flutter
    ├── controllers/     # StateNotifiers Riverpod
    └── widgets/         # Widgets spécifiques à cette feature
```

---

## Design System

### Identité visuelle

**Philosophie :** Vert foncé + Blanc comme couleurs dominantes. L'orange est utilisé de façon chirurgicale — uniquement pour les CTA principaux, les prix et les badges importants. C'est ce qui donne à Juna son identité forte et chaleureuse.

### Palette de couleurs

| Rôle | Couleur | Hex |
|------|---------|-----|
| Couleur principale | Vert foncé | `#1A5C2A` |
| Accent / CTA | Orange Juna | `#F4521E` |
| Fond général | Blanc cassé | `#F7F7F7` |
| Surface (cards) | Blanc | `#FFFFFF` |
| Texte principal | Presque noir | `#1A1A1A` |
| Texte secondaire | Gris moyen | `#6B6B6B` |

L'orange **ne doit jamais** être utilisé pour les fonds de sections, la navigation, les textes courants ou les icônes génériques.

### Typographie

Police : **Plus Jakarta Sans** (Google Fonts) — moderne, lisible, avec une touche africaine chaleureuse.

### Composants custom

| Composant | Fichier | Description |
|-----------|---------|-------------|
| `JunaButton` | `core/widgets/juna_button.dart` | Bouton en 5 variantes : primary (orange), secondary (vert), outline, ghost, danger |
| `JunaBadge` | `core/widgets/juna_badge.dart` | Badge catégorie, statut commande, promo |
| `JunaRating` | `core/widgets/juna_rating.dart` | Affichage étoiles + note + nombre d'avis |
| `JunaSkeleton` | `core/widgets/juna_skeleton.dart` | Skeleton loader avec shimmer effect |
| `JunaAvatar` | `core/widgets/juna_avatar.dart` | Photo de profil circulaire avec badge vérifié |

---

## Écrans et fonctionnalités

### Parcours USER

#### Navigation principale
4 onglets en bottom bar : **Accueil · Explorer · Mes Commandes · Profil**

#### Écrans implémentés

| Écran | Statut | Description |
|-------|--------|-------------|
| Splash Screen | ✅ Fait | Logo centré, fond vert foncé, animation fade + scale |
| Onboarding | ✅ Fait | 3 slides avec images food, PageView, bouton "Passer" |
| Connexion | ✅ Fait | Email + mot de passe, validation, bouton "S'inscrire" |
| Inscription | ✅ Fait | Prénom + nom + email + mdp, 3 champs max |
| Accueil | 🔄 En cours | Header dynamique, filtres chips, sections horizontales |
| Explorer | 🔄 En cours | Recherche, filtres, grille 2 colonnes, scroll infini |
| Détail Abonnement | 🔄 En cours | Image, infos, repas inclus, avis, bouton sticky "S'abonner" |
| Checkout — Livraison | 🔄 En cours | Choix livraison / retrait, sélection point |
| Checkout — Récapitulatif | 🔄 En cours | Résumé commande, détail prix, total orange |
| Checkout — Paiement | 🔄 En cours | Wave, MTN, Moov, Orange Money, Carte, Espèces |
| Checkout — Confirmation | 🔄 En cours | Animation succès Lottie + QR Code |
| Mes Commandes | 🔄 En cours | Onglets En cours / Historique, badges statut colorés |
| Détail Commande | 🔄 En cours | Infos commande + QR ticket |
| Profil | 🔄 En cours | Avatar, menu complet avec toutes les sous-pages |
| Paramètres compte | ⏳ Planifié | Modifier nom, photo, téléphone, mot de passe |
| Mes Favoris | ⏳ Planifié | Abonnements sauvegardés |
| Notifications | ⏳ Planifié | Activer/désactiver par type |
| Devenir Prestataire | ⏳ Planifié | Formulaire de candidature |
| Parrainer un ami | ⏳ Planifié | Code de parrainage + partage |
| Support | ⏳ Planifié | Ouvrir un ticket, voir les tickets existants |

#### Parcours PROVIDER (Espace Prestataire)

| Écran | Statut |
|-------|--------|
| Dashboard (commandes du jour, revenus) | ⏳ Planifié |
| Gestion des repas (CRUD) | ⏳ Planifié |
| Gestion des abonnements | ⏳ Planifié |
| Gestion des commandes | ⏳ Planifié |
| Scan QR Code client | ⏳ Planifié |

---

## Approche de développement — Phase actuelle

### Données simulées (mock)

L'application tourne actuellement sur des **données entièrement simulées**. Il n'y a aucun appel réseau réel — toutes les données (abonnements, prestataires, commandes, utilisateur) sont définies dans `lib/core/utils/mock_data.dart`.

Cette approche délibérée permet de :
1. **Valider les designs et l'expérience utilisateur** avant de brancher le backend
2. **Développer et tester l'interface** sans dépendance à l'environnement serveur
3. **Itérer rapidement** sur les écrans et les interactions

### Passage au backend réel

Une fois les designs validés, la connexion au backend se fera en remplaçant les repositories mock par des repositories qui appellent l'API réelle via Dio + Retrofit. L'architecture Clean Architecture garantit que **aucun écran (presentation layer) ne changera** lors de cette transition — seule la couche data sera mise à jour.

Le backend (Node.js + Express + Prisma + PostgreSQL) est développé en parallèle dans le repo `juna-backend`.

---

## Prérequis et installation

### Prérequis

- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0
- Android Studio ou VS Code avec l'extension Flutter

### Installation

```bash
# 1. Cloner le projet
git clone <url-du-repo> juna-App
cd juna-App

# 2. Installer les dépendances
flutter pub get

# 3. Générer les fichiers (freezed, json_serializable, riverpod)
dart run build_runner build --delete-conflicting-outputs

# 4. Copier le fichier d'environnement
cp .env.example .env

# 5. Lancer l'application
flutter run
```

### Lancer sur différentes cibles

```bash
# Navigateur Chrome (recommandé pour le développement rapide)
flutter run -d chrome

# Émulateur Android
flutter run -d emulator-5554

# Téléphone physique Android (USB)
flutter run -d <device-id>

# iOS Simulator (macOS requis)
flutter run -d iPhone
```

### Variables d'environnement

Créer un fichier `.env` à la racine (non versionné) :

```env
API_BASE_URL=http://localhost:3000/api
APP_ENV=development
```

---

## Structure des données

### Entités principales

| Entité | Fichier | Description |
|--------|---------|-------------|
| `UserEntity` | `features/auth/domain/entities/user_entity.dart` | Utilisateur (USER / PROVIDER / ADMIN) |
| `SubscriptionEntity` | `features/subscriptions/domain/entities/subscription_entity.dart` | Abonnement repas |
| `ProviderEntity` | `features/subscriptions/domain/entities/provider_entity.dart` | Prestataire culinaire |
| `MealEntity` | `features/subscriptions/domain/entities/meal_entity.dart` | Repas individuel |
| `OrderEntity` | `features/orders/domain/entities/order_entity.dart` | Commande / abonnement souscrit |

### Enums clés

Définis dans `lib/core/utils/enums.dart` avec leurs labels en français :

- `SubscriptionType` — Petit-déjeuner, Déjeuner, Dîner, Journée complète, etc.
- `SubscriptionDuration` — 1 jour, Semaine de travail, 1 mois, etc.
- `SubscriptionCategory` — Africain, Halal, Végétarien, Asiatique, etc.
- `OrderStatus` — En attente, Confirmée, En préparation, Prête, etc.
- `PaymentMethod` — Wave, MTN Mobile Money, Moov Money, Orange Money, Carte, Espèces

---

## Règles de développement

1. **Toujours utiliser le Design System** — jamais de couleur, taille ou police en dur dans les widgets
2. **Riverpod pour tout l'état** — pas de `setState` sauf pour l'UI locale simple (toggle, animation)
3. **Skeleton loaders partout** — jamais de spinner seul sur un écran vide
4. **Gestion offline** — les listes doivent fonctionner en cache si le réseau coupe
5. **Séparation stricte** data / domain / presentation — pas de logique dans les widgets
6. **Nommage cohérent** — `snake_case` pour les fichiers, `PascalCase` pour les classes, `camelCase` pour les variables
7. **Responsive** — tester sur petits écrans (4.7") et grands (6.7")
8. **Accessibilité** — zones de tap ≥ 48px, contrastes corrects

---

## Roadmap

### Phase 1 — Foundation (en cours)
- [x] Setup projet Flutter + tous les packages
- [x] Design System complet (couleurs, typo, espacements, thème Material 3)
- [x] Architecture feature-first + Clean Architecture
- [x] Données mock
- [x] Entités métier
- [x] Auth controller (Riverpod)
- [x] Router go_router avec guards
- [x] Bottom navigation shell
- [x] Composants UI réutilisables (JunaButton, JunaBadge, JunaRating, JunaSkeleton, JunaAvatar)
- [x] Splash Screen
- [x] Onboarding (3 slides)
- [x] Login / Register

### Phase 2 — Parcours principal USER
- [ ] Home Screen (header, filtres, sections horizontales, cards)
- [ ] Explorer Screen (recherche, grille, scroll infini)
- [ ] Détail Abonnement
- [ ] Checkout 4 étapes (livraison → récap → paiement → confirmation + QR)
- [ ] Mes Commandes + Détail commande + QR ticket
- [ ] Profil + toutes les sous-pages

### Phase 3 — Espace Prestataire
- [ ] Dashboard
- [ ] Gestion repas / abonnements
- [ ] Gestion commandes
- [ ] Scan QR

### Phase 4 — Connexion Backend
- [ ] Remplacer mock data par appels API Dio
- [ ] Authentification JWT réelle (flutter_secure_storage)
- [ ] Cache Isar pour mode offline
- [ ] Gestion des erreurs réseau
- [ ] Firebase Messaging (push notifications)

### Phase 5 — Polish & Production
- [ ] Animations Lottie finales
- [ ] Tests unitaires et d'intégration
- [ ] Optimisations performances
- [ ] Build Android APK / iOS
- [ ] Déploiement Play Store / App Store

---

## Contribution

Ce projet est développé en solo pour le moment. Les conventions de code sont appliquées via `flutter_lints`.

```bash
# Vérifier la qualité du code
flutter analyze

# Formatter le code
dart format lib/
```

---

*Document mis à jour au fur et à mesure de l'évolution du projet.*
