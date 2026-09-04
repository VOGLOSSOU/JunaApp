# Juna — Application Mobile

> Plateforme d'abonnement repas pour l'Afrique de l'Ouest

---

## À propos

**Juna** est une application mobile qui connecte des travailleurs urbains avec des prestataires culinaires de confiance — restaurants, traiteurs, cuisiniers indépendants — en Afrique de l'Ouest.

L'utilisateur s'abonne à l'avance à un prestataire de son choix, choisit son mode de réception (livraison ou retrait sur place), et paie via Mobile Money ou carte. Un QR code unique est généré pour chaque commande et sert de ticket de validation chez le prestataire.

### Le problème résolu

En Afrique de l'Ouest, les travailleurs urbains perdent chaque jour un temps précieux à trouver un repas de qualité. Les prestataires culinaires, eux, manquent de visibilité et de clientèle fidèle. Juna résout les deux problèmes en un seul produit.

### Proposition de valeur

- **Pour l'utilisateur** — manger bien, sans stress, à prix maîtrisé, avec livraison ou retrait sur place.
- **Pour le prestataire** — clientèle fidèle, revenus prévisibles, visibilité digitale.

### Marchés cibles

Bénin (lancement), puis extension progressive vers le Togo, la Côte d'Ivoire et le Sénégal.

---

## Rôles dans l'application

| Rôle | Description |
|------|-------------|
| `USER` | Utilisateur final — explore, s'abonne, commande, reçoit, évalue |
| `PROVIDER` | Prestataire culinaire — gère ses menus, abonnements et commandes |
| `ADMIN` | Équipe Juna — gère la plateforme, valide les prestataires |

---

## Stack technique

### Framework

| Élément | Choix |
|---------|-------|
| Framework | **Flutter** (Dart) |
| Cible | iOS + Android (un seul codebase) |

### Packages

| Couche | Package | Rôle |
|--------|---------|------|
| State Management | `flutter_riverpod` | Gestion d'état (FutureProvider.family + keepAlive pour le détail, StateNotifierProvider pour les listes/flux complexes) |
| Navigation | `go_router` | Routing déclaratif, deep linking via `app_links` |
| HTTP Client | `dio` | Appels API REST — intercepteurs maison pour l'auth et le mapping d'erreurs (pas de code-gen type Retrofit) |
| Auth Storage | `flutter_secure_storage` | Stockage sécurisé des tokens JWT (fallback `shared_preferences` sur web uniquement) |
| Cache local | `shared_preferences` (via `CacheService` maison) | Cache JSON timestampé avec expiration par `maxAge` — pas de base de données locale (pas d'Isar/Hive/sqflite) |
| Environnement | `flutter_dotenv` | Charge `.env`, mais `API_BASE_URL` n'y est actuellement pas branché — l'URL de l'API est en dur dans `core/api/api_endpoints.dart` |
| Animations | `lottie` | Animations (splash, écrans vides) |
| Images réseau | `cached_network_image` | Chargement et cache disque des images |
| Formulaires | `TextFormField` + `Form` (Flutter natif) | Pas de lib de formulaires tierce (pas de `reactive_forms`) |
| Dates / nombres | `intl` | Formatage des prix (FCFA) — les dates utilisent des helpers maison (`formatDate`), pas `DateFormat` à cause du risque de crash sans init locale |
| Connectivité | `connectivity_plus` | Présent en dépendance mais **non utilisé** dans le code actuellement |
| Notifications | — | Centre de notifications in-app (liste via API), pas de push OS — pas de `firebase_messaging` |
| QR Code | `qr_flutter` | Génération du QR ticket côté client uniquement — pas de scan (pas de `mobile_scanner`), c'est un choix produit assumé |
| Typographie | `google_fonts` | Police Plus Jakarta Sans |
| Skeleton loaders | `shimmer` | Placeholders animés pendant le chargement |
| Liens externes | `url_launcher` | Ouverture de liens `tel:`, `wa.me/`, CGU |
| Photo de profil | `image_picker` | Sélection depuis la galerie (utilise le Photo Picker natif Android 13+, aucune permission à déclarer) |

---

## Architecture

Le projet suit le pattern **Feature-first + Clean Architecture légère**.

```
lib/
├── main.dart
├── app/
│   ├── router/        # Routes et guards d'authentification (go_router)
│   ├── shell/         # Bottom navigation bar
│   ├── theme/         # Design System — couleurs, typographie, espacements
│   └── providers/     # Providers Riverpod globaux
├── core/
│   ├── api/           # Client Dio, intercepteurs, endpoints
│   ├── storage/       # Secure storage, cache local (SharedPreferences + TTL)
│   ├── errors/        # Gestion centralisée des erreurs
│   ├── utils/         # Helpers, enums, formatters
│   └── widgets/       # Composants réutilisables du Design System
└── features/
    ├── auth/
    ├── home/
    ├── subscriptions/
    ├── explorer/
    ├── meals/
    ├── orders/
    ├── checkout/
    ├── profile/
    ├── provider_space/    # Profil public d'un prestataire, vu par un USER
    ├── proposals/         # Abonnements sur mesure composés par l'utilisateur
    ├── notifications/
    └── support/           # Dossier réservé, non implémenté
```

Chaque feature est structurée en trois couches indépendantes :

```
feature/
├── data/         # Repositories, datasources, modèles JSON
├── domain/       # Entités métier, use cases
└── presentation/ # Screens, controllers Riverpod, widgets
```

---

## Design System

### Identité visuelle

**Vert foncé + Blanc** comme couleurs dominantes. L'orange est utilisé de façon chirurgicale — uniquement sur les boutons CTA principaux, les prix et les badges importants.

### Palette

| Rôle | Hex |
|------|-----|
| Couleur principale (vert foncé) | `#1A5C2A` |
| Accent / CTA (orange Juna) | `#F4521E` |
| Fond général | `#F7F7F7` |
| Surface (cards, modals) | `#FFFFFF` |
| Texte principal | `#1A1A1A` |
| Texte secondaire | `#6B6B6B` |

### Typographie

Police principale : **Plus Jakarta Sans** (Google Fonts).

### Composants UI

`JunaButton` · `JunaAvatar` · `JunaBadge` · `JunaRating` · `JunaSkeleton`

Le reste des cartes/inputs de l'app (ex: cartes abonnement, cartes commande) est construit par écran avec `Container` + `BoxDecoration`, pas via des composants partagés dédiés — il n'y a pas encore de `JunaCard`/`JunaInput`/`JunaBottomSheet`/`JunaSnackbar`.

---

## Fonctionnalités principales

### Parcours utilisateur (USER)

- **Exploration libre** — l'app est entièrement explorable sans compte. L'authentification n'est déclenchée que lors de la souscription.
- **Catalogue d'abonnements** — filtres par catégorie (Africain, Halal, Végétarien…), type de repas, durée. Recherche texte libre.
- **Détail abonnement** — description, liste des repas inclus, zones de livraison, avis clients, note.
- **Flow de commande en 4 étapes** — choix du mode de réception → récapitulatif → paiement → confirmation avec QR code.
- **QR Code** — ticket unique par commande, accessible dans l'app, non téléchargeable.
- **Mes commandes** — suivi en temps réel avec badges de statut colorés, historique complet.
- **Propositions personnalisées** — composer un abonnement sur mesure à partir du catalogue d'un prestataire et lui envoyer, avec suivi du statut (en attente / approuvée / rejetée).
- **Profil** — paramètres, favoris, devenir prestataire.

### Côté prestataire, dans cette app mobile

Ce repo (`juna-App`) est **l'app consommateur uniquement**. Un utilisateur `USER` peut consulter le profil public d'un prestataire (menu, note, adresse, zones de livraison) et lui envoyer une proposition d'abonnement — mais il n'y a **aucune interface de gestion prestataire** ici (pas de dashboard, pas de gestion de menu/commandes, pas de scan QR). Ce volet — décrit historiquement ci-dessous — est géré ailleurs (dashboard web / backend), pas dans ce codebase :

- Dashboard (commandes du jour, revenus, alertes)
- Gestion des menus et des formules d'abonnement
- Traitement des commandes (confirmer, préparer, marquer prête, livrer)
- Validation des commandes par scan QR

### Méthodes de paiement

Wave · MTN Mobile Money · Moov Money · Orange Money · Carte bancaire · Espèces à la livraison

---

## Installation

### Prérequis

- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0

### Démarrage

```bash
# Cloner le projet
git clone <url-du-repo> juna-App
cd juna-App

# Installer les dépendances
flutter pub get

# Configurer l'environnement
cp .env.example .env

# Lancer
flutter run
```

Pas d'étape de génération de code (`build_runner`) — le projet n'utilise ni `freezed`, ni `json_serializable`, ni `riverpod_generator` : le parsing JSON → entités est écrit à la main dans chaque repository.

### Variables d'environnement (`.env`)

```env
API_BASE_URL=https://juna-app.up.railway.app/api/v1
APP_ENV=production
```

⚠️ `API_BASE_URL` est chargé au démarrage mais **n'est pas branché** à l'URL réellement utilisée par l'app — celle-ci est en dur dans `lib/core/api/api_endpoints.dart`. Modifier `.env` n'a donc aucun effet sur l'API ciblée tant que ce n'est pas corrigé.

