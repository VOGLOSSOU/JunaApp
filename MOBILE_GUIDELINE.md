# JUNA — Mobile App Guideline

> Document de référence pour le développement de l'application mobile Juna.
> À fournir en contexte au début de chaque session de développement.

---

## 1. Description du projet

**Juna** est une plateforme d'abonnement repas destinée au marché ouest-africain (Bénin et pays voisins).
Elle met en relation des utilisateurs avec des prestataires culinaires (restaurants, traiteurs, cuisiniers indépendants) qui proposent des formules d'abonnement repas : petit-déjeuner, déjeuner, dîner, journée complète, semaine de travail, etc.

### Problème résolu

En Afrique de l'Ouest, les travailleurs urbains perdent beaucoup de temps et d'argent à trouver un repas de qualité chaque jour. Juna leur permet de s'abonner à l'avance à un prestataire de confiance, de planifier leurs repas sur la semaine ou le mois, et de payer facilement via Mobile Money.

### Proposition de valeur

- **Pour l'utilisateur** : manger bien, sans stress, à prix maîtrisé, avec retrait sur place ou livraison.
- **Pour le prestataire** : avoir une clientèle fidèle, des revenus prévisibles, et une visibilité digitale.

### Marchés cibles

- Bénin (lancement), puis extension progressive vers le Togo, la Côte d'Ivoire, le Sénégal.
- Cible principale : travailleurs urbains, étudiants, entreprises (repas d'équipe).

---

## 2. Rôles dans l'app mobile

L'application mobile est destinée uniquement à deux types d'utilisateurs :

| Rôle | Description |
|------|-------------|
| `USER` | Utilisateur final — cherche, s'abonne, commande, reçoit, évalue |
| `PROVIDER` | Prestataire culinaire — crée ses menus, gère ses abonnements et commandes |

---

## 3. Stack technique mobile

### Framework principal

| Choix | Technologie | Raison |
|-------|------------|--------|
| Framework | **Flutter** (Dart) | Contrôle pixel-perfect, performances natives, design bluffant |
| Langage | **Dart** | Typé, simple, compilé nativement |
| Cible | iOS + Android (+ Web si besoin) | Un seul codebase |

### Stack complète

| Couche | Package | Rôle |
|--------|---------|------|
| State Management | `riverpod` + `flutter_riverpod` | Gestion d'état robuste, scalable, testable |
| Navigation | `go_router` | Routing déclaratif, deep linking, typé |
| HTTP Client | `dio` + `retrofit` | Appels API REST, intercepteurs, gestion erreurs |
| Auth Storage | `flutter_secure_storage` | Stockage sécurisé des tokens JWT |
| Cache / Local DB | `isar` | Base locale rapide pour offline et cache |
| Variables d'env | `flutter_dotenv` | Gestion des environnements dev/prod |
| Animations | Flutter natif + `lottie` | Animations fluides 60/120fps |
| Images réseau | `cached_network_image` | Chargement et cache d'images distantes |
| Design System | Material 3 (custom theme) | Base solide, entièrement personnalisable |
| Formulaires | `reactive_forms` | Gestion propre des formulaires et validations |
| Gestion dates | `intl` | Formatage dates/heures en contexte africain |
| Connectivity | `connectivity_plus` | Détecter l'état réseau (important en Afrique) |
| Notifications | `firebase_messaging` | Push notifications |
| QR Code | `qr_flutter` + `mobile_scanner` | Affichage et scan des QR codes commandes |
| Maps (futur) | `flutter_map` + OpenStreetMap | Géolocalisation sans coût Google Maps |

### Architecture du code

Pattern recommandé : **Feature-first + Clean Architecture légère**

```
lib/
├── main.dart
├── app/
│   ├── router/           # Go Router — toutes les routes
│   ├── theme/            # Design system, couleurs, typographie
│   └── providers/        # Providers globaux Riverpod
├── core/
│   ├── api/              # Client Dio, intercepteurs, endpoints
│   ├── storage/          # Secure storage, cache local
│   ├── errors/           # Gestion des erreurs (AppException, etc.)
│   ├── utils/            # Helpers, formatters, extensions
│   └── widgets/          # Widgets réutilisables (boutons, cards, inputs...)
└── features/
    ├── auth/
    │   ├── data/         # Repository, datasource, modèles API
    │   ├── domain/       # Entités, use cases
    │   └── presentation/ # Screens, controllers (Riverpod), widgets
    ├── home/
    ├── subscriptions/
    ├── orders/
    ├── profile/
    ├── provider_space/   # Espace prestataire
    ├── reviews/
    ├── notifications/
    └── support/
```

---

## 4. Identité visuelle et Design System

### Couleurs officielles

Extraites directement des logos officiels de Juna.

**Philosophie :** Vert foncé + Blanc comme couleurs dominantes. Orange utilisé en accent rare et chirurgical — bouton principal, prix, badge important, notation. Ça donne une identité forte, cohérente et élégante.

```dart
class AppColors {
  // === COULEURS PRINCIPALES ===
  static const Color primary       = Color(0xFF1A5C2A); // Vert foncé — couleur dominante
  static const Color primaryLight  = Color(0xFF2E7D40); // Vert moyen — hover, états actifs
  static const Color primaryDark   = Color(0xFF0F3D1A); // Vert très foncé — headers, AppBar
  static const Color primarySurface= Color(0xFFEEF5F0); // Vert très très clair — fonds de cards

  // === ACCENT (orange — utilisation rare et ciblée) ===
  // Utiliser uniquement pour : bouton CTA principal, prix, badge promo, étoiles de notation
  static const Color accent        = Color(0xFFF4521E); // Orange vif Juna

  // === FOND & SURFACES ===
  static const Color white         = Color(0xFFFFFFFF);
  static const Color background    = Color(0xFFF7F7F7); // Fond général — blanc légèrement grisé
  static const Color surface       = Color(0xFFFFFFFF); // Cards, modals
  static const Color surfaceGrey   = Color(0xFFF0F0F0); // Inputs, zones inactives

  // === TEXTES ===
  static const Color textPrimary   = Color(0xFF1A1A1A); // Texte principal — presque noir
  static const Color textSecondary = Color(0xFF6B6B6B); // Texte secondaire — gris moyen
  static const Color textLight     = Color(0xFFAAAAAA); // Texte désactivé, placeholder
  static const Color textOnPrimary = Color(0xFFFFFFFF); // Texte sur fond vert

  // === ÉTATS SYSTÈME ===
  static const Color success       = Color(0xFF2E7D32); // Succès (peut réutiliser le vert primary)
  static const Color error         = Color(0xFFD32F2F); // Erreur
  static const Color warning       = Color(0xFFF9A825); // Warning
  static const Color info          = Color(0xFF0277BD); // Info

  // === BORDURES & SÉPARATEURS ===
  static const Color border        = Color(0xFFE0E0E0);
  static const Color divider       = Color(0xFFF0F0F0);
}
```

**Quand utiliser l'orange `accent` :**
- Bouton principal (CTA) — "S'abonner", "Commander", "Payer"
- Prix et montants
- Badge "Nouveau", "Promo", "Populaire"
- Étoiles de notation
- Icônes du logo Juna

**Ne jamais utiliser l'orange pour :**
- Les fonds de sections
- La navigation (bottom bar, AppBar)
- Les textes courants
- Les icônes génériques

### Typographie

```dart
// Police recommandée : "Plus Jakarta Sans" (Google Fonts) — moderne, lisible, africaine
// Fallback : "Poppins"

class AppTypography {
  static const String fontFamily = 'PlusJakartaSans';

  static const TextStyle displayLarge  = TextStyle(fontSize: 32, fontWeight: FontWeight.w700);
  static const TextStyle displayMedium = TextStyle(fontSize: 28, fontWeight: FontWeight.w700);
  static const TextStyle headlineLarge = TextStyle(fontSize: 24, fontWeight: FontWeight.w600);
  static const TextStyle headlineMedium= TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
  static const TextStyle titleLarge    = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
  static const TextStyle titleMedium   = TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
  static const TextStyle bodyLarge     = TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
  static const TextStyle bodyMedium    = TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
  static const TextStyle bodySmall     = TextStyle(fontSize: 12, fontWeight: FontWeight.w400);
  static const TextStyle labelLarge    = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
  static const TextStyle labelSmall    = TextStyle(fontSize: 11, fontWeight: FontWeight.w500);
}
```

### Spacing & Border Radius

```dart
class AppSpacing {
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 24.0;
  static const double xxl  = 32.0;
  static const double xxxl = 48.0;
}

class AppRadius {
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 24.0;
  static const double full = 999.0; // Pill shape
}
```

### Principes de design

- Design **moderne, chaud, africain** — pas froid/corporate
- UI **épurée** avec beaucoup d'espace blanc et des accents orange/vert
- Beaucoup d'**images food de qualité** — la nourriture doit faire saliver
- **Animations subtiles** sur les transitions, les loadings, les interactions
- Prise en compte du **réseau lent** — skeleton loaders partout, jamais de spinner seul
- **Accessibilité** : textes lisibles, contrastes corrects, zones de tap ≥ 48px

### Composants personnalisés à créer

- `JunaButton` — bouton principal (primary/secondary/outline/ghost)
- `JunaCard` — carte abonnement, carte repas, carte commande
- `JunaInput` — champ de saisie avec style cohérent
- `JunaAvatar` — photo de profil / logo prestataire
- `JunaBadge` — tags (Halal, Végétarien, Africain, etc.)
- `JunaRating` — affichage étoiles
- `JunaSkeleton` — loading placeholder
- `JunaBottomSheet` — modal bottom sheet stylisé
- `JunaSnackbar` — notifications toast

---

## 5. Parcours utilisateur (USER)

---

### 5.1 Flux de démarrage

```
Lancement app
      │
      ▼
 Splash Screen
 (logo Juna centré, fond vert foncé, animation douce)
      │
      ▼
 Première ouverture ?
   ├── OUI → Onboarding (3 slides) → Page d'accueil
   └── NON → Page d'accueil directement
      │
      ▼
 Page d'accueil (accessible SANS authentification)
      │
      ▼
 L'user veut s'abonner ?
   ├── Authentifié → Flow commande
   └── Non authentifié → Redirection vers Login
```

**Règle fondamentale :** l'app est entièrement explorable sans compte. L'authentification n'est déclenchée que lorsque l'utilisateur tente de souscrire un abonnement.

---

### 5.2 Onboarding

- 3 slides maximum, sobres et rapides
- Chaque slide : une grande illustration food, un titre fort, une courte phrase
- Bouton "Passer" visible dès le premier slide
- Indicateur de progression (3 points en bas)
- Dernier slide : bouton "Commencer" → redirige vers l'accueil

---

### 5.3 Authentification

Déclenchée uniquement quand l'user veut s'abonner.

**Page de connexion / inscription :**
```
┌─────────────────────────────┐
│   Logo Juna (petit, en haut)│
│                             │
│  [ Continuer avec Google ]  │  ← bouton blanc, icône Google, bordure légère
│                             │
│  ───────── ou ─────────     │
│                             │
│  [ Champ Email           ]  │
│  [ Champ Mot de passe    ]  │
│                             │
│  [ Se connecter ]           │  ← bouton vert foncé
│                             │
│  Pas de compte ? S'inscrire │
└─────────────────────────────┘
```

- Inscription : email + mot de passe + nom (3 champs max)
- Pas de vérification bloquante au démarrage — l'user arrive directement dans l'app après auth

---

### 5.4 Navigation principale (Bottom Bar)

Présente sur toutes les pages principales. 4 onglets :

```
┌────────┬────────┬────────┬────────┐
│  🏠    │  🔍   │  📦   │  👤   │
│ Accueil│Explorer│  Mes   │ Profil │
│        │        │Commandes│       │
└────────┴────────┴────────┴────────┘
```

| Onglet | Icône | Contenu |
|--------|-------|---------|
| **Accueil** | Maison | Page principale avec abonnements mis en avant |
| **Explorer** | Loupe | Recherche libre + filtres avancés |
| **Mes commandes** | Boîte | Historique et suivi des commandes actives |
| **Profil** | Personne | Compte, préférences, notifications, support |

- Icône active : vert foncé + petit label visible
- Icône inactive : gris clair, label masqué
- Badge rouge sur "Mes commandes" si commande en cours

---

### 5.5 Page d'accueil — Structure détaillée

C'est l'écran le plus important de l'app. Il doit être beau, fluide, et donner envie.

#### HEADER (fixe en haut)

```
┌─────────────────────────────────────┐
│ 👋 Bonjour, Marcus          🔔 (3) │
│ 📍 Cotonou, Bénin  ▾               │
└─────────────────────────────────────┘
```

- **Salutation dynamique :**
  - Matin (5h–12h) : "Bonjour"
  - Après-midi (12h–18h) : "Bon après-midi"
  - Soir (18h–23h) : "Bonsoir"
  - + prénom de l'user si connecté, sinon juste la salutation
  - Emoji main qui salue 👋 (fixe, pas animé)

- **Localisation :**
  - Détectée automatiquement via GPS → affiche la ville
  - Icône 📍 + nom de la ville + flèche ▾ cliquable
  - Si cliqué → Bottom sheet avec liste de villes disponibles pour changer manuellement
  - La ville sélectionnée filtre automatiquement tous les abonnements affichés

- **Icône notifications :**
  - Coin haut droit
  - Badge orange avec le nombre si notifications non lues
  - Si cliqué → page notifications

---

#### FILTRES (juste sous le header)

**Problème :** 3 dimensions de filtres (type, durée, catégorie) = beaucoup d'options. Il ne faut pas noyer l'écran.

**Solution proposée — système à 2 niveaux :**

**Niveau 1 — Chips de catégorie scrollables horizontalement (toujours visibles)**

Une seule ligne de chips horizontale scrollable, avec les catégories les plus parlantes visuellement :

```
[ Tous ] [ 🌍 Africain ] [ 🥗 Végétarien ] [ ☪️ Halal ] [ 🌏 Asiatique ] [ 🌿 Vegan ] ...
```

- Chip actif : fond vert foncé + texte blanc
- Chip inactif : fond gris clair + texte gris foncé
- "Tous" sélectionné par défaut

**Niveau 2 — Bouton "Filtres" avec badge**

À droite de la ligne de chips, un petit bouton icône :

```
[ 🌍 Africain ] [ ☪️ Halal ] ...  ⚙️ Filtres (2)
```

- Le chiffre entre parenthèses indique combien de filtres sont actifs
- Si cliqué → **Bottom sheet de filtres** avec :
  - **Type de repas** (chips horizontales) : Petit-déj, Déjeuner, Dîner, Journée complète, etc.
  - **Durée** (chips horizontales) : 1 jour, 3 jours, Semaine, Semaine travail, Mois, etc.
  - Bouton "Réinitialiser" (gauche) + bouton "Appliquer" orange (droite)

**Mapping des labels affichés (plus lisibles que les enums bruts) :**

| Enum | Label affiché |
|------|--------------|
| BREAKFAST | Petit-déjeuner |
| LUNCH | Déjeuner |
| DINNER | Dîner |
| SNACK | Snack |
| BREAKFAST_LUNCH | Petit-déj + Déjeuner |
| LUNCH_DINNER | Déjeuner + Dîner |
| FULL_DAY | Journée complète |
| CUSTOM | Personnalisé |
| DAY | 1 jour |
| THREE_DAYS | 3 jours |
| WEEK | 1 semaine |
| TWO_WEEKS | 2 semaines |
| MONTH | 1 mois |
| WORK_WEEK | Semaine de travail (5j) |
| WORK_WEEK_2 | 2 semaines de travail (10j) |
| WORK_MONTH | Mois de travail (20j) |
| WEEKEND | Week-end (2j) |

---

#### BODY — Les abonnements

Le corps de la page est un scroll vertical fluide avec plusieurs sections :

**Principe important :** chaque section affiche seulement 4 à 6 abonnements maximum, avec un lien **"Explorer →"** en fin de section qui redirige vers la page Explorer avec le filtre correspondant pré-appliqué.

**Section 1 — Populaires près de toi**
- Scroll horizontal de cards larges (type "featured")
- Card grande : image food, titre, prestataire, prix, note
- Animation d'entrée douce (fade + slide up) au chargement
- Lien "Explorer →" → page Explorer sans filtre particulier

**Section 2 — Cuisine Africaine**
- Scroll horizontal de cards compactes
- Lien "Explorer →" → page Explorer avec filtre `category=AFRICAN` pré-appliqué

**Section 3 — Formules semaine de travail**
- Scroll horizontal de cards compactes
- Lien "Explorer →" → page Explorer avec filtre `duration=WORK_WEEK` pré-appliqué

**Section 4 — Découvrir les prestataires**
- Scroll horizontal de cards prestataires (avatar, nom, note, badge certifié)

> Les sections affichées peuvent évoluer selon la localisation et les données disponibles.

**Skeleton loaders** : présents sur toutes les sections pendant le chargement. Jamais d'écran vide.

---

#### CARTE D'ABONNEMENT — Design masterclass

Chaque card doit être soignée, appétissante, avec des animations douces.

**Card grande (featured) :**
```
┌─────────────────────────────────┐
│  [  IMAGE FOOD haute qualité  ] │  ← 60% de la hauteur de la card
│  ● Certifié    ★ 4.8  (120)    │  ← badge vert + étoiles oranges
├─────────────────────────────────┤
│  Abonnement Repas Africain      │  ← titre, bold
│  par Chez Mariam                │  ← nom prestataire, gris
│                                 │
│  🕐 Semaine de travail          │  ← durée
│  🍽️ Déjeuner                    │  ← type
│                                 │
│  25 000 FCFA          [Voir] →  │  ← prix orange + bouton
└─────────────────────────────────┘
```

**Animations :**
- Entrée : fade-in + légère translation Y (↑) au scroll
- Au tap : légère réduction de scale (0.97) puis retour — effet "press"
- Image : léger zoom au hover/focus (scale 1.03, durée 300ms)
- Skeleton shimmer effect pendant le chargement

**Badge prestataire certifié :**
- Petit badge bleu avec coche ✓ à côté du nom du prestataire (comme Twitter/Instagram)
- Tooltip au long-press : "Prestataire vérifié par Juna"

---

### 5.6 Page Détail Abonnement

Accessible en cliquant sur une card d'abonnement.

```
┌─────────────────────────────────┐
│  ← (retour)          ♡ (save)  │
│  [   IMAGE FOOD large         ] │
│  ─────────────────────────────  │
│  Abonnement Repas Africain      │
│  ★ 4.8 (120 avis)              │
│                                 │
│  👨‍🍳 Chez Mariam  ✓ Certifié   │
│                                 │
│  📋 Description                 │
│  🍽️ Repas inclus (liste)        │
│  🕐 Durées disponibles          │
│  📍 Zones de livraison          │
│  📦 Retrait possible            │
│                                 │
│  ─── Avis clients ───           │
│  [cards d'avis]                 │
│                                 │
│  ──────────────────────────     │
│  25 000 FCFA  [S'abonner →]    │  ← bouton orange fixe en bas
└─────────────────────────────────┘
```

- Bouton "S'abonner" fixe en bas (sticky), couleur orange
- Déclenchement de l'auth si non connecté au clic sur ce bouton

---

### 5.7 Flow de commande — Étape par étape

Déclenché au clic sur "S'abonner" depuis la page détail abonnement.

```
Clic "S'abonner"
      │
      ▼
 Authentifié ?
  ├── NON → Page Auth → retour sur l'abonnement après connexion
  └── OUI → Étape 1 : Choix de livraison
               │
               ▼
          Étape 2 : Récapitulatif commande
               │
               ▼
          Étape 3 : Paiement
               │
               ▼
          Étape 4 : Confirmation + QR Code
```

---

#### Étape 1 — Choix du mode de réception

```
┌─────────────────────────────────┐
│  ←  Comment recevoir votre      │
│     commande ?                  │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 🛵  Livraison à domicile │   │  ← card sélectionnable
│  │ Choisir un point de      │   │
│  │ livraison                │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 🏠  Retrait sur place   │   │  ← card sélectionnable
│  │ Venir chercher chez      │   │
│  │ le prestataire           │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

**Si Livraison sélectionnée :**
- Une liste de points/zones de livraison disponibles s'affiche (définis par le prestataire)
- L'user sélectionne son point — liste scrollable avec nom + éventuellement distance
- Il peut aussi saisir une adresse libre si le prestataire l'autorise

**Si Retrait sélectionné :**
- Les points de retrait du prestataire s'affichent (adresse + horaires si disponibles)
- L'user sélectionne le point de retrait

Bouton "Continuer" en bas (vert foncé) → activé seulement quand un choix est fait.

---

#### Étape 2 — Récapitulatif de la commande

L'user voit tout avant de payer. Pas de surprise.

```
┌─────────────────────────────────┐
│  ←  Récapitulatif               │
│                                 │
│  📦 Abonnement Repas Africain   │
│  par Chez Mariam  ✓             │
│                                 │
│  🍽️  Déjeuner · Semaine travail │
│  📍  Livraison — Quartier Zongo │
│  📅  Début : dès demain         │
│                                 │
│  ─────── Détail du prix ─────── │
│  Abonnement          24 000 F   │
│  Frais de livraison   1 000 F   │
│  ─────────────────────────────  │
│  Total               25 000 F   │  ← montant en orange
│                                 │
│       [ Choisir le paiement ]   │  ← bouton orange
└─────────────────────────────────┘
```

- Tous les détails de l'abonnement choisi
- Mode de réception + lieu sélectionné
- Détail du prix clair et lisible
- Total en orange (c'est le CTA visuel)

---

#### Étape 3 — Paiement

```
┌─────────────────────────────────┐
│  ←  Moyen de paiement           │
│                                 │
│  ○  📱 Wave                     │
│  ○  📱 MTN Mobile Money         │
│  ○  📱 Moov Money               │
│  ○  📱 Orange Money             │
│  ○  💳 Carte bancaire           │
│  ○  💵 Espèces (à la livraison) │
│                                 │
│  [champ numéro selon méthode]   │
│                                 │
│  ─────────────────────────────  │
│  Total à payer    25 000 FCFA   │
│                                 │
│       [ Confirmer et payer ]    │  ← bouton orange
└─────────────────────────────────┘
```

- Liste de méthodes radio-button (une seule sélectionnable)
- Selon méthode choisie, un champ contextuel apparaît (ex: numéro de téléphone pour Mobile Money)
- Pour "Espèces" : pas de champ, juste une note "Paiement à la livraison"
- Bouton "Confirmer et payer" — orange — déclenche le paiement

---

#### Étape 4 — Confirmation + QR Code

Après paiement réussi. C'est l'écran de célébration.

```
┌─────────────────────────────────┐
│                                 │
│       ✅  Commande confirmée !  │  ← animation Lottie success
│                                 │
│   Abonnement Repas Africain     │
│   Chez Mariam · Déjeuner        │
│   Semaine de travail            │
│                                 │
│  ┌─────────────────────────┐   │
│  │                         │   │
│  │      [QR CODE]          │   │  ← QR code unique de la commande
│  │                         │   │
│  └─────────────────────────┘   │
│                                 │
│  Présentez ce QR code au        │
│  prestataire pour validation    │
│                                 │
│  [ Voir mes commandes ]         │  ← bouton vert foncé
│  [ Retour à l'accueil  ]        │  ← bouton outline
└─────────────────────────────────┘
```

- Animation Lottie de succès (confettis ou checkmark animé — sobre, pas criard)
- QR code unique généré pour cette commande
- Après 2-3 secondes ou au clic sur "Voir mes commandes" → redirection automatique vers la page "Mes commandes"
- **Le QR code n'est pas téléchargeable** — accessible uniquement dans l'app (sécurité + rétention)

---

### 5.8 Page "Mes Commandes"

Accessible via l'onglet 3 de la bottom bar. Affiche toutes les commandes de l'user.

#### Liste des commandes

```
┌─────────────────────────────────┐
│  Mes commandes                  │
│                                 │
│  [ En cours ]  [ Historique ]   │  ← 2 onglets
│                                 │
│  ┌─────────────────────────┐   │
│  │ Abonnement Repas Africain│   │
│  │ Chez Mariam  ✓          │   │
│  │ Déjeuner · Semaine trav. │   │
│  │ 📍 Livraison — Zongo    │   │
│  │                         │   │
│  │ ● EN COURS    25 000 F  │   │  ← badge statut coloré
│  │              [Voir →]   │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │  ...autre commande...   │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

**Badge statut et couleurs :**

| Statut | Couleur badge |
|--------|--------------|
| EN ATTENTE | Gris |
| CONFIRMÉE | Bleu |
| EN PRÉPARATION | Orange |
| PRÊTE | Vert clair |
| EN LIVRAISON | Orange |
| LIVRÉE | Vert foncé |
| COMPLÉTÉE | Vert foncé |
| ANNULÉE | Rouge |

---

#### Détail d'une commande + Ticket QR

Accessible au clic sur une commande de la liste.

```
┌─────────────────────────────────┐
│  ←  Commande #JUN-00123         │
│                                 │
│  ● CONFIRMÉE                    │  ← badge statut
│                                 │
│  📦 Abonnement Repas Africain   │
│  par Chez Mariam  ✓             │
│  🍽️  Déjeuner · Semaine travail │
│  📍  Livraison — Quartier Zongo │
│  📅  Passée le 23 mars 2026     │
│                                 │
│  ─────── Montant payé ──────── │
│  Total             25 000 FCFA  │
│  Payé via          Wave         │
│                                 │
│  ══════════════════════════════ │
│  🎫  Votre ticket               │
│                                 │
│  ┌─────────────────────────┐   │
│  │                         │   │
│  │       [QR CODE]         │   │  ← QR code, non téléchargeable
│  │                         │   │
│  └─────────────────────────┘   │
│                                 │
│  Présentez ce code au           │
│  prestataire pour validation    │
│                                 │
│  ─────────────────────────────  │
│  [ Laisser un avis ]            │  ← visible si commande complétée
└─────────────────────────────────┘
```

**Règles importantes :**
- QR Code uniquement visible dans l'app — pas de bouton télécharger, pas de partage (v1)
- Bouton "Laisser un avis" apparaît uniquement quand la commande est au statut COMPLÉTÉE
- Bouton "Annuler" visible uniquement si statut = EN ATTENTE ou CONFIRMÉE

---

### 5.8b Page Explorer

Accessible via le 2ème onglet de la bottom bar, ou via un lien "Explorer →" depuis l'accueil (avec filtre pré-appliqué).

C'est le catalogue complet de tous les abonnements disponibles, avec tous les filtres accessibles.

#### Structure

```
┌─────────────────────────────────┐
│  🔍  Rechercher un abonnement   │  ← barre de recherche texte libre en haut
│                                 │
│  [ 🌍 Africain ][ ☪️ Halal ]...  ⚙️ Filtres (2) │  ← même système que l'accueil
│                                 │
│  245 abonnements trouvés        │  ← compteur dynamique
│  Trier par : [ Pertinence ▾ ]  │  ← selector de tri
│                                 │
│  ┌──────────┐  ┌──────────┐    │
│  │  card    │  │  card    │    │  ← grille 2 colonnes
│  └──────────┘  └──────────┘    │
│  ┌──────────┐  ┌──────────┐    │
│  │  card    │  │  card    │    │
│  └──────────┘  └──────────┘    │
│       ... (scroll infini)       │
└─────────────────────────────────┘
```

**Différences avec l'accueil :**
- Barre de recherche texte libre visible en permanence
- Grille 2 colonnes au lieu du scroll horizontal — on veut voir un maximum d'abonnements
- Compteur de résultats dynamique qui se met à jour à chaque filtre
- Options de tri : Pertinence / Prix croissant / Prix décroissant / Mieux notés / Les plus récents
- Scroll infini (pagination automatique) — pas de bouton "charger plus"

**Si arrivée depuis un lien "Explorer →" de l'accueil :**
- Le filtre correspondant est pré-appliqué automatiquement
- Le badge "Filtres (1)" reflète ce filtre actif
- L'user peut le retirer ou en ajouter d'autres

**Si aucun résultat :**
- Illustration sobre + message "Aucun abonnement trouvé dans cette zone"
- Bouton "Réinitialiser les filtres"

---

### 5.9 Page Profil

Accessible via le 4ème onglet de la bottom bar.

```
┌─────────────────────────────────┐
│                                 │
│         [  PHOTO  ]             │  ← avatar circulaire, initiales si pas de photo
│        Marcus Dupont            │  ← nom complet
│      marcus@email.com           │  ← email, gris clair
│                                 │
│  ─────────────────────────────  │
│                                 │
│  ⚙️   Paramètres du compte    › │
│  🔔   Notifications            › │
│  ❤️   Mes favoris              › │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  🍽️   Devenir prestataire      › │  ← CTA important, légèrement mis en avant
│  💡   Proposer un abonnement   › │
│  🎁   Parrainer un ami         › │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  💬   Contacter le support     › │
│  🚩   Signaler un problème     › │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  [ Se déconnecter ]             │  ← bouton outline rouge discret
│                                 │
└─────────────────────────────────┘
```

**Règles :**
- Photo de profil : circulaire, cliquable pour modifier
- Si pas de photo → initiales du nom sur fond vert foncé
- "Devenir prestataire" : légèrement mis en avant (fond vert très clair, texte vert foncé) — c'est un CTA stratégique pour Juna
- "Se déconnecter" : bouton discret, outline rouge, tout en bas — pas de confirmation requise

---

**Sous-pages accessibles depuis le profil :**

- **Paramètres du compte** → modifier nom, prénom, téléphone, photo, mot de passe
- **Notifications** → activer/désactiver les types de notifications
- **Mes favoris** → abonnements sauvegardés (icône ♡ depuis la page détail)
- **Devenir prestataire** → formulaire de candidature prestataire
- **Proposer un abonnement** → formulaire de proposition personnalisée (CustomProposal)
- **Parrainer un ami** → code de parrainage à partager
- **Contacter le support** → ouvrir un ticket ou voir les tickets existants
- **Signaler un problème** → formulaire rapide (catégorie + description)

---

## 6. Parcours prestataire (PROVIDER)

> *À compléter*

**Onboarding prestataire**
- Candidature (formulaire + documents)
- Attente validation

**Tableau de bord**
- Commandes du jour
- Revenus / statistiques
- Alertes

**Gestion**
- Mes repas (créer, modifier, supprimer)
- Mes abonnements (créer, modifier, activer/désactiver)
- Gestion commandes (confirmer, marquer prêt, livrer)
- Scan QR Code client

---

## 7. Règles de développement

1. **Toujours utiliser le Design System** — jamais de couleur, taille ou police en dur dans les widgets
2. **Riverpod pour tout l'état** — pas de `setState` sauf pour l'UI locale simple
3. **Gestion offline** — les listes doivent fonctionner en cache si le réseau coupe
4. **Skeleton loaders** — jamais de spinner seul sur un écran vide
5. **Gestion des erreurs explicite** — toujours afficher un message clair à l'utilisateur
6. **Responsive** — tester sur petits écrans (4.7") et grands écrans (6.7")
7. **Séparation stricte** data / domain / presentation — pas de logique dans les widgets
8. **Nommage cohérent** — snake_case pour les fichiers, PascalCase pour les classes, camelCase pour les variables

---

*Ce document est vivant — il sera mis à jour au fur et à mesure que la navigation et les règles métier sont affinées.*
