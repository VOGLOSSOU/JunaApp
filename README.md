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
| State Management | `flutter_riverpod` | Gestion d'état robuste et testable |
| Navigation | `go_router` | Routing déclaratif avec deep linking |
| HTTP Client | `dio` + `retrofit` | Appels API REST avec intercepteurs |
| Auth Storage | `flutter_secure_storage` | Stockage sécurisé des tokens JWT |
| Cache local | `isar` | Base de données locale pour le mode offline |
| Environnement | `flutter_dotenv` | Variables d'environnement dev / prod |
| Animations | `lottie` | Animations fluides 60/120fps |
| Images réseau | `cached_network_image` | Chargement et cache des images |
| Formulaires | `reactive_forms` | Gestion des formulaires et validations |
| Dates | `intl` | Formatage adapté au contexte africain |
| Connectivité | `connectivity_plus` | Détection réseau lent / coupures |
| Notifications | `firebase_messaging` | Push notifications |
| QR Code | `qr_flutter` + `mobile_scanner` | Génération et scan des QR codes |
| Typographie | `google_fonts` | Police Plus Jakarta Sans |
| Skeleton loaders | `shimmer` | Placeholders animés pendant le chargement |

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
│   ├── storage/       # Secure storage, cache Isar
│   ├── errors/        # Gestion centralisée des erreurs
│   ├── utils/         # Helpers, enums, formatters
│   └── widgets/       # Composants réutilisables du Design System
└── features/
    ├── auth/
    ├── home/
    ├── subscriptions/
    ├── explorer/
    ├── orders/
    ├── profile/
    ├── provider_space/
    ├── notifications/
    └── support/
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

`JunaButton` · `JunaCard` · `JunaInput` · `JunaAvatar` · `JunaBadge` · `JunaRating` · `JunaSkeleton` · `JunaBottomSheet` · `JunaSnackbar`

---

## Fonctionnalités principales

### Parcours utilisateur (USER)

- **Exploration libre** — l'app est entièrement explorable sans compte. L'authentification n'est déclenchée que lors de la souscription.
- **Catalogue d'abonnements** — filtres par catégorie (Africain, Halal, Végétarien…), type de repas, durée. Recherche texte libre.
- **Détail abonnement** — description, liste des repas inclus, zones de livraison, avis clients, note.
- **Flow de commande en 4 étapes** — choix du mode de réception → récapitulatif → paiement → confirmation avec QR code.
- **QR Code** — ticket unique par commande, accessible dans l'app, non téléchargeable.
- **Mes commandes** — suivi en temps réel avec badges de statut colorés, historique complet.
- **Profil** — paramètres, favoris, parrainage, devenir prestataire.

### Parcours prestataire (PROVIDER)

- **Dashboard** — commandes du jour, revenus, alertes.
- **Gestion des menus** — créer, modifier et supprimer des repas.
- **Gestion des abonnements** — créer des formules, définir les zones et horaires.
- **Traitement des commandes** — confirmer, préparer, marquer comme prête, livrer.
- **Scan QR** — valider les commandes des clients en scannant leur QR code.

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

# Générer les fichiers (freezed, json_serializable, riverpod)
dart run build_runner build --delete-conflicting-outputs

# Configurer l'environnement
cp .env.example .env

# Lancer
flutter run
```

### Variables d'environnement (`.env`)

```env
API_BASE_URL=https://api.juna.app/api
APP_ENV=production
```

---

## Liens

- Backend API : [`juna-backend`](../juna-backend)
- Documentation API : [`api-documentation.md`](../api-documentation.md)
- Architecture système : [`ARCHITECTURE.md`](../ARCHITECTURE.md)
- Guideline mobile : [`MOBILE_GUIDELINE.md`](./MOBILE_GUIDELINE.md)
