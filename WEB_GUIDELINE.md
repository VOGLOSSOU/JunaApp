# JUNA — Web Platform Guideline

> Ce document est la référence complète pour le développement de la version web de JUNA.
> Il décrit dans l'ordre de priorité tout ce qui doit être construit, les specs UI/UX,
> l'identité visuelle, les endpoints API à consommer, et les règles de développement.

---

## Table des matières

1. [Vue d'ensemble & Architecture](#1-vue-densemble--architecture)
2. [Identité visuelle](#2-identité-visuelle)
3. [Stack technique recommandée](#3-stack-technique-recommandée)
4. [Structure des routes web](#4-structure-des-routes-web)
5. [PRIORITÉ 1 — Parcours consommateur](#5-priorité-1--parcours-consommateur)
6. [PRIORITÉ 2 — Parcours provider complet](#6-priorité-2--parcours-provider-complet)
7. [PRIORITÉ 3 — Checkout & Paiement](#7-priorité-3--checkout--paiement)
8. [PRIORITÉ 4 — Avis, notifications & reste](#8-priorité-4--avis-notifications--reste)
9. [API Reference](#9-api-reference)
10. [Composants réutilisables](#10-composants-réutilisables)
11. [Règles générales de développement](#11-règles-générales-de-développement)

---

## 1. Vue d'ensemble & Architecture

### Rôle de la version web

La version web JUNA joue **trois rôles simultanés** :

1. **Interface consommateur** — Pour les utilisateurs iOS (pas d'app Apple au lancement),
   les utilisateurs sans smartphone Android, ou ceux qui préfèrent le web.
   Le parcours est identique à l'app mobile : découverte → détail → commande → paiement.

2. **Plateforme de paiement** — L'app mobile Android redirige vers le web au moment
   du paiement. Le web gère le checkout complet, puis redirige l'utilisateur
   vers l'app via deep link (`juna://orders/:id`).

3. **Dashboard provider** — Les prestataires gèrent tout leur activité ici :
   inscription, création d'abonnements, gestion des commandes, statistiques.

### Flux entre mobile et web

```
App Android
    │
    ▼
[Page détail abonnement]
    │
    │  Clic "S'abonner"
    ▼
[Web — /checkout?subscriptionId=xxx&userId=xxx&token=xxx]
    │
    │  Paiement validé
    ▼
[Web — /checkout/confirmation]
    │
    │  Deep link
    ▼
App Android — [Mes commandes]
```

### Ce que la version web couvre

- Tout le parcours consommateur (identique au mobile)
- Le checkout complet avec paiement
- Le dashboard provider (gestion totale)
- Le formulaire "Devenir prestataire"
- La page publique de profil provider

---

## 2. Identité visuelle

> L'identité visuelle est **strictement identique** à l'app mobile.
> Même couleurs, même typographie, même logique d'espacement.
> Seule adaptation : le layout s'ouvre pour profiter de l'espace desktop (sidebar, grilles plus larges).

### 2.1 Palette de couleurs

```css
/* === COULEURS PRINCIPALES === */
--color-primary:         #1A5C2A;   /* Vert principal — boutons, liens actifs, accents */
--color-primary-light:   #2E7D40;   /* Vert hover */
--color-primary-dark:    #0F3D1A;   /* Vert pressé / focus */
--color-primary-surface: #EEF5F0;   /* Fond vert très léger — badges, highlights */

/* === ACCENT (usage rare et ciblé) === */
--color-accent:          #F4521E;   /* Orange — CTA secondaires, alertes positives */

/* === FONDS & SURFACES === */
--color-white:           #FFFFFF;
--color-background:      #F7F7F7;   /* Fond global des pages */
--color-surface:         #FFFFFF;   /* Cartes, modals, panels */
--color-surface-grey:    #F0F0F0;   /* Surfaces secondaires */

/* === TEXTES === */
--color-text-primary:    #1A1A1A;   /* Titres, labels importants */
--color-text-secondary:  #6B6B6B;   /* Descriptions, métadonnées */
--color-text-light:      #AAAAAA;   /* Placeholders, icônes désactivées */
--color-text-on-primary: #FFFFFF;   /* Texte sur fond vert */

/* === ÉTATS SYSTÈME === */
--color-success:         #2E7D32;
--color-error:           #D32F2F;
--color-warning:         #F9A825;
--color-info:            #0277BD;

/* === BORDURES & SÉPARATEURS === */
--color-border:          #E0E0E0;
--color-divider:         #F0F0F0;

/* === STATUTS COMMANDES === */
--color-status-pending:    #9E9E9E;
--color-status-confirmed:  #1565C0;
--color-status-preparing:  #F57C00;
--color-status-ready:      #388E3C;
--color-status-delivering: #F57C00;
--color-status-delivered:  #1A5C2A;
--color-status-completed:  #1A5C2A;
--color-status-cancelled:  #D32F2F;
```

### 2.2 Typographie

**Police principale :** `Plus Jakarta Sans` (Google Fonts)

```css
/* Import */
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap');

body {
  font-family: 'Plus Jakarta Sans', sans-serif;
}

/* Échelle typographique — équivalents web des styles Flutter */
.text-display-large  { font-size: 32px; font-weight: 700; color: #1A1A1A; }
.text-display-medium { font-size: 28px; font-weight: 700; color: #1A1A1A; }
.text-headline-large { font-size: 24px; font-weight: 600; color: #1A1A1A; }
.text-headline-medium{ font-size: 20px; font-weight: 600; color: #1A1A1A; }
.text-title-large    { font-size: 18px; font-weight: 600; color: #1A1A1A; }
.text-title-medium   { font-size: 16px; font-weight: 500; color: #1A1A1A; }
.text-body-large     { font-size: 16px; font-weight: 400; color: #1A1A1A; }
.text-body-medium    { font-size: 14px; font-weight: 400; color: #1A1A1A; }
.text-body-small     { font-size: 12px; font-weight: 400; color: #6B6B6B; }
.text-label-large    { font-size: 14px; font-weight: 600; color: #1A1A1A; }
.text-label-small    { font-size: 11px; font-weight: 500; color: #6B6B6B; }
```

### 2.3 Espacements

```css
/* Système d'espacement — identique à l'app */
--spacing-xs:   4px;
--spacing-sm:   8px;
--spacing-md:   12px;
--spacing-lg:   16px;
--spacing-xl:   24px;
--spacing-xxl:  32px;
--spacing-xxxl: 48px;

/* Rayons de bordure */
--radius-sm:   8px;
--radius-md:   12px;
--radius-lg:   16px;
--radius-xl:   24px;
--radius-full: 9999px;
```

### 2.4 Ombres

```css
--shadow-sm: 0 1px 3px rgba(0,0,0,0.08);
--shadow-md: 0 4px 12px rgba(0,0,0,0.10);
--shadow-lg: 0 8px 24px rgba(0,0,0,0.12);
```

### 2.5 Adaptation au web (desktop-first)

L'app mobile est mobile-first. Le web est **desktop-first avec responsive** :

| Breakpoint | Taille | Layout |
|------------|--------|--------|
| Mobile     | < 768px | 1 colonne, navbar bottom |
| Tablet     | 768px–1024px | 2 colonnes, sidebar collapsée |
| Desktop    | > 1024px | Sidebar fixe, contenu centré max 1280px |

```css
--max-content-width: 1280px;
--sidebar-width: 260px;
--navbar-height: 64px;
```

### 2.6 Tailwind config (si Next.js + Tailwind)

```js
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        primary:        '#1A5C2A',
        'primary-light':'#2E7D40',
        'primary-dark': '#0F3D1A',
        'primary-surface': '#EEF5F0',
        accent:         '#F4521E',
        background:     '#F7F7F7',
        surface:        '#FFFFFF',
        'text-primary': '#1A1A1A',
        'text-secondary':'#6B6B6B',
        'text-light':   '#AAAAAA',
        border:         '#E0E0E0',
        success:        '#2E7D32',
        error:          '#D32F2F',
        warning:        '#F9A825',
      },
      fontFamily: {
        sans: ['Plus Jakarta Sans', 'sans-serif'],
      },
      borderRadius: {
        sm:   '8px',
        md:   '12px',
        lg:   '16px',
        xl:   '24px',
        full: '9999px',
      },
      spacing: {
        xs: '4px', sm: '8px', md: '12px',
        lg: '16px', xl: '24px', xxl: '32px', xxxl: '48px',
      },
    },
  },
}
```

---

## 3. Stack technique recommandée

### Framework

**Next.js 14+ (App Router)**
- SSR pour le SEO des pages publiques (home, abonnements, détail)
- Client components pour les pages interactives (explorer, dashboard)
- API Routes si besoin de proxy

### UI & Styling

**Tailwind CSS** — pour coller fidèlement aux tokens de l'app mobile

### État global

**Zustand** ou **TanStack Query** (React Query)
- TanStack Query pour le fetching/caching des données API
- Zustand pour l'état global (auth, ville sélectionnée, panier/commande en cours)

### HTTP Client

**Axios** avec intercepteurs pour :
- Injecter le `Authorization: Bearer` token
- Auto-refresh du token expiré (identique à l'app)
- Gestion centralisée des erreurs

### Auth

**Cookies httpOnly** pour stocker les tokens (plus sécurisé que localStorage)
- `accessToken` → cookie httpOnly, SameSite=Strict, 15min
- `refreshToken` → cookie httpOnly, SameSite=Strict, 7 jours

### Autres

- `react-hot-toast` — notifications système
- `react-hook-form` + `zod` — formulaires et validation
- `framer-motion` — animations douces
- `qrcode.react` — affichage QR code commandes
- `date-fns` — manipulation dates
- `recharts` — graphiques dashboard provider

---

## 4. Structure des routes web

```
/                          → Page d'accueil (feed public)
/explorer                  → Explorer avec filtres
/subscriptions/:id         → Détail abonnement
/providers/:id             → Profil public provider

/auth/login                → Connexion
/auth/register             → Inscription
/auth/provider/register    → Inscription prestataire (depuis paramètres avancés)

/checkout                  → Checkout (depuis mobile ou web)
/checkout/confirmation     → Confirmation + QR code + deep link

/profile                   → Mon profil (auth requis)
/profile/orders            → Mes commandes
/profile/orders/:id        → Détail commande + QR
/profile/settings          → Paramètres compte
/profile/notifications     → Mes notifications
/profile/favorites         → Mes favoris

/dashboard                 → Dashboard provider (auth provider requis)
/dashboard/subscriptions   → Mes abonnements
/dashboard/subscriptions/new       → Créer abonnement
/dashboard/subscriptions/:id/edit  → Modifier abonnement
/dashboard/orders          → Commandes reçues
/dashboard/orders/:id      → Détail commande reçue
/dashboard/meals           → Mes plats
/dashboard/meals/new       → Créer un plat
/dashboard/profile         → Mon profil provider
/dashboard/stats           → Statistiques & revenus
/dashboard/settings        → Paramètres provider
```

---

## 5. PRIORITÉ 1 — Parcours consommateur

> Reproduire fidèlement tout ce qui a été fait dans l'app mobile.
> Même logique, même état, même API. Adaptation visuelle desktop uniquement.

---

### 5.1 Navbar

**Position :** fixe en haut, hauteur 64px, fond blanc, ombre légère

**Contenu (non connecté) :**
- Logo JUNA à gauche
- Liens : Accueil | Explorer
- Boutons : Se connecter | S'inscrire

**Contenu (connecté) :**
- Logo JUNA à gauche
- Liens : Accueil | Explorer | Mes commandes
- Sélecteur de ville (dropdown avec pays → ville)
- Avatar utilisateur (dropdown : Profil | Paramètres | Déconnexion)
- Badge notifications

**Comportement :**
- Sur mobile web (< 768px) : navbar en bas (tabs), identique à l'app
- Sélecteur de ville obligatoire au premier accès (modal, identique au GeoModal de l'app)

---

### 5.2 Page d'accueil `/`

**Comportement général :**
- Si ville non sélectionnée → modal GeoModal bloquant (sélection pays puis ville)
- Si ville sélectionnée → `GET /home?cityId=xxx&limit=10`
- Si filtres actifs → basculer sur `GET /subscriptions` (Explorer)

**Layout desktop :**
- Navbar en haut
- Hero section : titre + barre de recherche rapide + sélecteur de ville
- Section "Populaires" : scroll horizontal (même qu'app) OU grille 4 colonnes
- Section "Récents" : scroll horizontal ou grille 4 colonnes
- Section "Nos prestataires" : grille de cards providers
- Footer

**Section Populaires :**
- Titre "Les plus populaires à [Ville]"
- Grille de `SubscriptionCard` (voir composant)
- Si vide : message "Aucun abonnement populaire pour l'instant"

**Section Récents :**
- Titre "Nouveautés"
- Même structure que Populaires

**Section Prestataires :**
- Titre "Nos prestataires"
- Cards horizontales avec logo, nom, ville, rating, nb abonnements
- Clic → `/providers/:id`
- Masqué si aucun abonnement disponible

**États :**
- Chargement → skeleton (même logique que l'app)
- Erreur réseau → icône wifi_off + bouton Réessayer
- Pas d'abonnements → illustration + message encourageant

**API :**
```
GET /home?cityId={uuid}&limit=10
```

---

### 5.3 Page Explorer `/explorer`

**Layout desktop :**
- Sidebar gauche fixe (260px) : tous les filtres
- Contenu principal : grille 3-4 colonnes selon breakpoint
- Barre de recherche + tri en haut du contenu

**Sidebar filtres :**
- Catégorie (checkbox ou chips) : Africain, Végétarien, Halal, Asiatique, Vegan, Européen, Fast-food, Healthy
- Type de repas : Petit-déjeuner, Déjeuner, Dîner, Snack, Journée complète...
- Durée : 1 jour, 3 jours, Semaine de travail, 2 semaines, 1 mois...
- Zone de retrait (landmark) : dropdown des landmarks de la ville
- Bouton "Réinitialiser les filtres"

**Barre de recherche :**
- Debounce 350ms → `GET /subscriptions?search=xxx`
- Affichage nb résultats

**Tri :**
- Dropdown : Populaires | Plus récents | Prix croissant | Prix décroissant | Mieux notés
- Valeurs API : `popular` | `recent` | `price_asc` | `price_desc` | `rating`

**Grille abonnements :**
- Infinite scroll (IntersectionObserver en bas)
- 4 colonnes desktop, 2 tablette, 1 mobile
- Chaque changement de filtre ou tri → rechargement depuis page=1

**État "pas de ville" :**
- Illustration + "Choisissez votre ville pour voir les abonnements"
- Bouton "Choisir ma ville"

**États vides :**
- Aucun résultat → "Aucun abonnement trouvé à [Ville]" + bouton reset filtres si actifs

**API :**
```
GET /subscriptions?cityId={uuid}&sort=popular&page=1&limit=20&category=AFRICAN&type=LUNCH...
```

---

### 5.4 Page Détail abonnement `/subscriptions/:id`

**Layout desktop :**
- Colonne gauche (60%) : carousel images, description, plats, avis
- Colonne droite (40%) : sticky — prix, bouton S'abonner, infos provider, zones

**Colonne gauche :**

*Carousel images :*
- Galerie avec miniatures en bas (desktop)
- Indicateurs dots sur mobile
- Fallback image si tableau vide

*Infos principales :*
- Titre, badge disponibilité (Disponible / Indisponible)
- Chips : type de repas | durée | catégorie | nb repas
- Description complète
- Note globale (étoiles) + nb avis

*Section Plats inclus :*
- Titre "Repas inclus"
- Liste horizontale scrollable : image + nom + description
- Si vide : "Contactez le prestataire pour la liste des plats"

*Section Avis :*
- Note globale en grand
- Liste des avis paginée (infinite scroll ou bouton "Voir plus")
- Chaque avis : avatar/initiales, nom, note étoiles, date relative, commentaire
- Si aucun avis : "Aucun avis pour le moment — soyez le premier !"

**Colonne droite (sticky) :**

*Card prix :*
- Prix en grand + devise (XOF)
- Durée (ex: "Semaine de travail")
- Bouton "S'abonner" → checkout
- Si `isAvailable: false` → bouton désactivé + message

*Card provider :*
- Logo + nom + badge vérifié
- Rating + nb avis
- Description courte
- Bouton "Voir le profil" → `/providers/:id`

*Infos livraison :*
- Zones de livraison (liste)
- Points de retrait (liste)

**API :**
```
GET /subscriptions/:id
GET /reviews/subscription/:id?page=1&limit=10
```

---

### 5.5 Page Profil provider public `/providers/:id`

**Layout :**
- Header : logo, nom, badge vérifié, rating, nb avis, nb abonnements, ville
- Section abonnements du provider : grille
- Section avis : liste

**API :**
> À confirmer avec le backend — endpoint provider public à prévoir si absent

---

### 5.6 Pages auth `/auth/login` et `/auth/register`

**Login :**
- Champ email
- Champ mot de passe (masqué/démasqué)
- Bouton Se connecter
- Lien "Mot de passe oublié ?"
- Lien "Pas encore de compte ? S'inscrire"
- Gestion erreur `INVALID_CREDENTIALS`

**Register :**
- Champ nom complet
- Champ email
- Champ téléphone
- Champ mot de passe
- Bouton S'inscrire
- Lien "Déjà un compte ? Se connecter"
- Validation temps réel (zod)
- Après inscription → modal GeoModal pour sélectionner la ville

**API :**
```
POST /auth/login    { email, password }
POST /auth/register { name, email, phone, password }
```

---

### 5.7 Page Profil utilisateur `/profile`

**Layout :**
- Sidebar gauche : liens de navigation profil
- Contenu principal

**Sidebar navigation profil :**
- Mon profil
- Mes commandes
- Mes favoris
- Paramètres
- Notifications
- Déconnexion

**Page Mon profil :**
- Avatar (avec upload)
- Nom, email, téléphone
- Ville actuelle
- Bouton modifier → formulaire inline ou modal
- API : `GET /users/me`, `PUT /users/me`

**Page Mes commandes `/profile/orders` :**
- Liste paginée des commandes
- Chaque commande : nom abonnement, prestataire, date, statut, prix
- Statuts avec couleurs correspondantes
- Infinite scroll
- API : `GET /orders/me?page=1&limit=20`

**Page Détail commande `/profile/orders/:id` :**
- Infos commande complètes
- QR code (si statut le permet)
- Bouton Annuler (si statut le permet)
- Timeline du statut
- API : `GET /orders/:id`

**Page Paramètres `/profile/settings` :**
- Modifier nom, téléphone, adresse
- Changer de ville
- Préférences alimentaires
- Préférences notifications (email, push, SMS)
- API : `PUT /users/me`, `PUT /users/me/location`, `PUT /users/me/preferences`

**Page Notifications `/profile/notifications` :**
- Liste chronologique
- Non lues en haut, badge count
- Clic → marquer comme lu + redirection
- Bouton "Tout marquer lu"
- API : `GET /notifications`, `PUT /notifications/:id/read`, `PUT /notifications/read-all`

---

## 6. PRIORITÉ 2 — Parcours provider complet

> C'est la partie la plus importante et la plus différente du mobile.
> Le dashboard provider est une interface riche de type back-office.

---

### 6.1 Inscription provider `/auth/provider/register`

**Accès :** depuis `/profile/settings` → section "Paramètres avancés" → "Devenir prestataire"

**Formulaire en plusieurs étapes (stepper) :**

*Étape 1 — Informations établissement :*
- Nom de l'établissement (requis)
- Description de l'activité (requis, textarea)
- Téléphone professionnel (requis)
- Adresse professionnelle (requis)
- Ville d'opération (requis — dropdown avec sélection pays → ville)

*Étape 2 — Visuels :*
- Logo (upload image, requis — `POST /upload/providers`)
- Document justificatif (optionnel — `POST /upload/documents`)

*Étape 3 — Récapitulatif :*
- Affichage de toutes les infos
- Bouton "Envoyer ma demande"

*Étape 4 — Confirmation :*
- Icône succès
- Message : "Votre demande est en cours d'examen. Notre équipe vous contactera sous 48h."

**API :**
```
POST /auth/provider/register
{
  "businessName": "Chez Mariam",
  "description": "...",
  "phone": "+22961111111",
  "address": "...",
  "cityId": "uuid",
  "logoUrl": "https://...",
  "documentUrl": "https://..." (optionnel)
}
```

---

### 6.2 Dashboard provider `/dashboard`

**Accès :** utilisateur avec `role: PROVIDER` et statut `APPROVED`

**Layout dashboard :**
- Sidebar gauche fixe (260px) avec navigation
- Topbar : nom provider, badge vérifié, avatar, déconnexion
- Zone contenu principale

**Sidebar navigation dashboard :**
- Tableau de bord (home)
- Mes abonnements
- Commandes reçues
- Mes plats
- Mon profil provider
- Statistiques
- Paramètres
- Retour à l'accueil Juna

---

### 6.3 Page Tableau de bord `/dashboard`

**Widgets KPI (4 cartes en ligne) :**
- Revenus du mois (XOF)
- Commandes du mois
- Abonnements actifs
- Note moyenne

**Graphique revenus :**
- Courbe sur les 6 derniers mois
- `recharts` LineChart

**Commandes récentes :**
- Tableau des 5 dernières commandes
- Colonnes : client, abonnement, date, statut, montant
- Lien "Voir toutes les commandes"

**Abonnements populaires :**
- Top 3 abonnements par nb commandes
- Progression visuelle (barre)

---

### 6.4 Mes abonnements `/dashboard/subscriptions`

**Liste des abonnements du provider :**
- Tableau ou grille cards
- Colonnes/infos : image, nom, prix, type, durée, nb commandes, statut (actif/inactif)
- Toggle activer/désactiver
- Boutons : Modifier | Supprimer
- Bouton "+ Créer un abonnement" (prominent)

**Filtres :**
- Statut : Tous | Actifs | Inactifs
- Type : Déjeuner | Dîner | etc.

---

### 6.5 Créer/modifier abonnement `/dashboard/subscriptions/new` et `/:id/edit`

**Formulaire complet en sections :**

*Informations de base :*
- Nom de l'abonnement (requis)
- Description (requis, textarea riche)
- Prix (requis, number)
- Devise (XOF par défaut)

*Classification :*
- Type de repas (select) : BREAKFAST | LUNCH | DINNER | SNACK | FULL_DAY | etc.
- Catégorie (select) : AFRICAN | VEGETARIAN | HALAL | ASIAN | VEGAN | EUROPEAN | FAST_FOOD | HEALTHY
- Durée (select) : DAY | THREE_DAYS | WORK_WEEK | WEEK | TWO_WEEKS | WORK_WEEK_2 | WORK_MONTH | MONTH | WEEKEND

*Images :*
- Upload multiple (max 5 images)
- Drag & drop
- Réordonnage des images
- API : `POST /upload/subscriptions` pour chaque image

*Plats inclus :*
- Liste dynamique de plats
- Chaque plat : nom + description + image optionnelle
- Bouton "+ Ajouter un plat"
- Réordonnage drag & drop

*Livraison :*
- Zones de livraison (tags input : taper une zone + Entrée)
- Points de retrait (sélection parmi les landmarks de la ville)

*Publication :*
- Toggle "Actif / Inactif"
- Bouton "Enregistrer"
- Bouton "Annuler"

---

### 6.6 Commandes reçues `/dashboard/orders`

**Tableau des commandes :**
- Colonnes : #ID, client, abonnement, date, mode livraison, statut, montant, actions
- Filtres : statut | période | abonnement
- Pagination ou infinite scroll

**Gestion du statut :**
- Chaque commande peut avancer dans le workflow :
  `PENDING → CONFIRMED → PREPARING → READY → DELIVERING → DELIVERED → COMPLETED`
- Boutons d'action contextuels selon le statut actuel
- Tooltip sur chaque statut

**Couleurs statuts :**
```
PENDING:    #9E9E9E  (gris)
CONFIRMED:  #1565C0  (bleu)
PREPARING:  #F57C00  (orange)
READY:      #388E3C  (vert clair)
DELIVERING: #F57C00  (orange)
DELIVERED:  #1A5C2A  (vert primary)
COMPLETED:  #1A5C2A  (vert primary)
CANCELLED:  #D32F2F  (rouge)
```

---

### 6.7 Détail commande provider `/dashboard/orders/:id`

**Infos complètes :**
- Identité client (nom, téléphone)
- Abonnement commandé
- Mode de livraison + adresse ou point de retrait
- Notes client
- Date et heure
- Montant + méthode de paiement

**Timeline statut :**
- Affichage visuel de l'avancement
- Bouton pour passer au statut suivant

**QR code :**
- Affiché pour que le provider puisse valider la remise physique

---

### 6.8 Mes plats `/dashboard/meals`

**Liste des plats :**
- Grille ou tableau
- Image, nom, description, abonnements associés
- Boutons : Modifier | Supprimer

**Créer/modifier un plat `/dashboard/meals/new` :**
- Nom du plat (requis)
- Description (requis)
- Photo (upload — `POST /upload/meals`)
- Abonnements auxquels rattacher ce plat (multi-select)

---

### 6.9 Profil provider `/dashboard/profile`

**Infos modifiables :**
- Logo (upload)
- Nom établissement
- Description
- Téléphone
- Adresse
- Ville

**API :**
```
GET /auth/provider/me
PUT /auth/provider/me
POST /upload/providers  (pour le logo)
```

---

### 6.10 Statistiques `/dashboard/stats`

**KPIs sur période sélectionnable (7j, 30j, 3 mois, 1 an) :**
- Revenus totaux
- Nb commandes
- Nb clients uniques
- Taux de satisfaction (rating moyen)

**Graphiques :**
- Revenus par période (LineChart)
- Répartition des commandes par abonnement (PieChart)
- Évolution du rating dans le temps

**Tableau top abonnements :**
- Classement par revenus générés

---

### 6.11 Paramètres provider `/dashboard/settings`

- Préférences notifications
- Zones de livraison globales
- Jours et horaires de service (si supporté par l'API)
- Désactiver temporairement tous les abonnements

---

## 7. PRIORITÉ 3 — Checkout & Paiement

> Le checkout est accessible depuis le web (mobile redirige ici) et depuis le web directement.
> C'est l'étape la plus critique — elle génère le revenu.

---

### 7.1 Flow checkout complet

```
[Détail abonnement] → Clic "S'abonner"
    │
    ├── Non connecté → /auth/login?redirect=/checkout?subscriptionId=xxx
    │
    └── Connecté → /checkout?subscriptionId=xxx
                        │
                        ▼
              [Étape 1 — Livraison]
                        │
                        ▼
              [Étape 2 — Paiement]
                        │
                        ▼
              [Étape 3 — Récapitulatif]
                        │
                        ▼
              [Étape 4 — Confirmation + QR]
                        │
                        ├── Depuis mobile → deep link juna://orders/:id
                        └── Depuis web → redirection /profile/orders/:id
```

---

### 7.2 Stepper visuel

- 4 étapes affichées en haut
- Étape active en vert primary
- Navigation Précédent/Suivant
- Impossible de sauter une étape

---

### 7.3 Étape 1 — Livraison `/checkout`

**Récapitulatif abonnement :**
- Image, nom, provider, prix, durée

**Choix mode de livraison :**
- Livraison à domicile (si disponible selon `deliveryZones`)
  - Champ adresse complète (requis)
  - Champ notes (optionnel)
- Retrait sur place (si disponible selon `pickupPoints`)
  - Sélection du point de retrait (dropdown)

**Validation :**
- Au moins un mode disponible affiché
- Adresse requise si livraison

---

### 7.4 Étape 2 — Paiement `/checkout/payment`

**Méthodes disponibles :**

| Méthode | Valeur API | Label |
|---------|-----------|-------|
| Wave | `MOBILE_MONEY_WAVE` | Wave |
| MTN Mobile Money | `MOBILE_MONEY_MTN` | MTN Mobile Money |
| Moov Money | `MOBILE_MONEY_MOOV` | Moov Money |
| Orange Money | `MOBILE_MONEY_ORANGE` | Orange Money |
| Carte bancaire | `CARD` | Carte bancaire |
| Espèces | `CASH` | À la livraison |

**UI :**
- Radio buttons visuels avec logo de chaque opérateur
- Pour Mobile Money : champ numéro de téléphone
- Pour Carte : champs numéro, expiry, CVV
- Pour Cash : message "Paiement à la réception"

---

### 7.5 Étape 3 — Récapitulatif `/checkout/recap`

**Affichage complet :**
- Abonnement : nom, image, provider, durée
- Livraison : mode + adresse ou point de retrait + notes
- Paiement : méthode choisie
- Montant total en grand

**Bouton "Confirmer et payer" :**
- Lance `POST /orders`
- État loading pendant la requête
- Gestion erreur (toast)

**API :**
```
POST /orders
{
  "subscriptionId": "uuid",
  "deliveryMethod": "DELIVERY" | "PICKUP",
  "deliveryAddress": "...",      // si DELIVERY
  "landmarkId": "uuid",          // si PICKUP
  "notes": "...",                // optionnel
  "paymentMethod": "MOBILE_MONEY_WAVE" | ...
}
```

---

### 7.6 Étape 4 — Confirmation `/checkout/confirmation`

**Contenu :**
- Icône succès (cercle vert + checkmark)
- Titre "Commande confirmée !"
- Numéro de commande
- QR code (généré depuis l'ID commande)
- Résumé rapide
- Bouton "Voir mes commandes" → `/profile/orders`
- Si depuis mobile → bouton "Retourner dans l'app" → deep link `juna://orders/:id`

**Deep link Android :**
```
juna://orders/{orderId}
```
Ce lien doit être configuré dans l'app Android (`android/app/src/main/AndroidManifest.xml`).

---

## 8. PRIORITÉ 4 — Avis, notifications & reste

### 8.1 Laisser un avis

**Déclencheur :** depuis `/profile/orders/:id` si commande `COMPLETED`

**Modal ou page `/reviews/new?orderId=xxx` :**
- Note étoiles (1 à 5, required)
- Commentaire (textarea, optionnel)
- Bouton "Publier mon avis"

**API :**
```
POST /reviews
{
  "orderId": "uuid",
  "rating": 5,
  "comment": "Excellente cuisine !"
}
```

### 8.2 Page Mes favoris `/profile/favorites`

- Grille des abonnements mis en favoris
- Bouton retirer des favoris
- Note : les favoris sont gérés localement (localStorage) si pas d'endpoint dédié,
  ou via un endpoint `POST /favorites` si disponible

### 8.3 Page Résultats de recherche

- Accessible depuis la barre de recherche du header
- Même layout que l'Explorer mais sans sidebar
- Résultats filtrés par `?search=`

### 8.4 Pages statiques

- `/about` — À propos de JUNA
- `/contact` — Contact
- `/legal` — Mentions légales
- `/privacy` — Politique de confidentialité
- `/terms` — CGU

### 8.5 Page 404

- Illustration + "Page introuvable"
- Bouton "Retour à l'accueil"

---

## 9. API Reference

### Base URL

```
Production : https://juna-app.up.railway.app/api/v1
Local :      http://localhost:5000/api/v1
```

### Headers requis

```
Authorization: Bearer {accessToken}   // pour les routes auth
Content-Type: application/json        // pour les POST/PUT
```

### Format de réponse standard

```json
{
  "success": true | false,
  "message": "...",
  "data": { ... },
  "error": { "code": "ERROR_CODE" }
}
```

### Tokens

- `accessToken` → 15 minutes
- `refreshToken` → 7 jours
- Refresh : `POST /auth/refresh`

### Tous les endpoints

| Méthode | Route | Auth | Description |
|---------|-------|------|-------------|
| GET | `/countries` | public | Lister les pays |
| GET | `/countries/:code/cities` | public | Villes d'un pays |
| GET | `/cities/:cityId/landmarks` | public | Landmarks d'une ville |
| POST | `/auth/register` | public | Inscription utilisateur |
| POST | `/auth/login` | public | Connexion |
| POST | `/auth/refresh` | public | Refresh token |
| GET | `/auth/me` | auth | Infos utilisateur |
| PUT | `/auth/me` | auth | Modifier profil |
| GET | `/users/me` | auth | Profil complet |
| PUT | `/users/me` | auth | Modifier profil |
| PUT | `/users/me/location` | auth | Changer de ville |
| PUT | `/users/me/preferences` | auth | Préférences |
| GET | `/home` | public | Feed d'accueil |
| GET | `/subscriptions` | public | Liste abonnements |
| GET | `/subscriptions/:id` | public | Détail abonnement |
| POST | `/orders` | auth | Créer commande |
| GET | `/orders/me` | auth | Mes commandes |
| GET | `/orders/:id` | auth | Détail commande |
| PUT | `/orders/:id/cancel` | auth | Annuler commande |
| POST | `/reviews` | auth | Créer avis |
| GET | `/reviews/subscription/:id` | public | Avis abonnement |
| GET | `/notifications` | auth | Mes notifications |
| PUT | `/notifications/:id/read` | auth | Marquer lu |
| PUT | `/notifications/read-all` | auth | Tout marquer lu |
| POST | `/upload/:folder` | auth | Upload image |
| POST | `/auth/provider/register` | public | Inscription provider |
| GET | `/auth/provider/me` | auth | Profil provider |
| PUT | `/auth/provider/me` | auth | Modifier profil provider |

### Upload — dossiers acceptés

| Dossier | Usage |
|---------|-------|
| `avatars` | Photo profil utilisateur |
| `providers` | Logo provider |
| `meals` | Photo d'un plat |
| `subscriptions` | Image abonnement |
| `documents` | Justificatifs provider |

Champ : `image` (multipart/form-data) — Types : JPG, PNG, WEBP — Max : 5 Mo

### Codes d'erreur

| Code | Description | Action UI |
|------|-------------|-----------|
| `INVALID_CREDENTIALS` | Email/mdp incorrect | Message rouge formulaire |
| `USER_NOT_FOUND` | Utilisateur inexistant | Rediriger inscription |
| `TOKEN_EXPIRED` | Token expiré | Auto-refresh ou re-login |
| `INSUFFICIENT_PERMISSIONS` | Droits insuffisants | Toast erreur |
| `RESOURCE_NOT_FOUND` | Ressource inexistante | Page 404 |
| `VALIDATION_ERROR` | Données invalides | Messages sous les champs |
| `RATE_LIMIT_EXCEEDED` | Trop de requêtes | "Réessayez dans 15 minutes" |

### Valeurs des enums

**SubscriptionType :**
`BREAKFAST` | `LUNCH` | `DINNER` | `SNACK` | `BREAKFAST_LUNCH` | `LUNCH_DINNER` | `FULL_DAY` | `CUSTOM`

**SubscriptionDuration :**
`DAY` | `THREE_DAYS` | `WORK_WEEK` | `WEEK` | `TWO_WEEKS` | `WORK_WEEK_2` | `WORK_MONTH` | `MONTH` | `WEEKEND`

**SubscriptionCategory :**
`AFRICAN` | `VEGETARIAN` | `HALAL` | `ASIAN` | `VEGAN` | `EUROPEAN` | `FAST_FOOD` | `HEALTHY`

**OrderStatus :**
`PENDING` | `CONFIRMED` | `PREPARING` | `READY` | `DELIVERING` | `DELIVERED` | `COMPLETED` | `CANCELLED`

**PaymentMethod :**
`MOBILE_MONEY_WAVE` | `MOBILE_MONEY_MTN` | `MOBILE_MONEY_MOOV` | `MOBILE_MONEY_ORANGE` | `CARD` | `CASH`

**DeliveryMethod :**
`DELIVERY` | `PICKUP`

**Sort (GET /subscriptions) :**
`popular` | `recent` | `rating` | `price_asc` | `price_desc`

---

## 10. Composants réutilisables

Ces composants doivent être créés une fois et réutilisés partout.
Ils sont l'équivalent web des widgets Flutter de l'app mobile.

### SubscriptionCard

**Props :** `{ id, name, imageUrl, price, currency, type, duration, category, rating, reviewCount, provider, isAvailable }`

**Variantes :**
- `compact` — pour les grilles (image + infos essentielles)
- `featured` — plus grande, pour les sections "Populaires"
- `horizontal` — pour les listes

**Comportement :**
- Clic → navigation vers `/subscriptions/:id`
- Badge "Indisponible" si `!isAvailable`
- Rating affiché avec étoile

### ProviderCard

**Props :** `{ id, name, logoUrl, isVerified, city, rating, subscriptionCount }`

**Comportement :**
- Clic → `/providers/:id`
- Badge vérifié si `isVerified`

### JunaButton

**Variantes :** `primary` | `secondary` | `outline` | `ghost` | `danger`

**States :** normal | hover | loading | disabled

**Tailles :** `sm` | `md` | `lg`

```jsx
<JunaButton variant="primary" size="lg" loading={isSubmitting}>
  S'abonner
</JunaButton>
```

### JunaInput

- Label flottant
- Icône optionnelle
- État erreur avec message
- Compteur caractères optionnel

### StarRating

**Props :** `{ value, max=5, readOnly, onChange }`

- Mode lecture : étoiles colorées
- Mode saisie : étoiles cliquables avec hover

### StatusBadge

**Props :** `{ status: OrderStatus }`

- Couleur de fond et texte selon le statut
- Utilise les couleurs définies en section 2.1

### Skeleton

- `SkeletonCard` — pour les grilles abonnements
- `SkeletonText` — pour les lignes de texte
- `SkeletonAvatar` — pour les avatars/logos

### Toast

- Succès (vert), Erreur (rouge), Warning (orange), Info (bleu)
- Position : top-right desktop, top mobile
- Auto-dismiss 4 secondes

### GeoModal

- Sélection pays (liste avec drapeau)
- Sélection ville (filtrable)
- Obligatoire au premier accès
- Stockage : `localStorage` + state global Zustand

### QRCode

**Props :** `{ value: string, size?: number }`

- Utilise `qrcode.react`
- Fond blanc, code noir
- Téléchargeable (bouton "Enregistrer")

---

## 11. Règles générales de développement

### Structure des dossiers (Next.js App Router)

```
/app
  /(public)
    /page.tsx              → Home
    /explorer/page.tsx
    /subscriptions/[id]/page.tsx
    /providers/[id]/page.tsx
  /(auth)
    /auth/login/page.tsx
    /auth/register/page.tsx
    /auth/provider/register/page.tsx
  /(user)
    /profile/page.tsx
    /profile/orders/page.tsx
    /profile/orders/[id]/page.tsx
    /profile/settings/page.tsx
    /profile/notifications/page.tsx
  /(checkout)
    /checkout/page.tsx
    /checkout/payment/page.tsx
    /checkout/recap/page.tsx
    /checkout/confirmation/page.tsx
  /(dashboard)
    /dashboard/page.tsx
    /dashboard/subscriptions/page.tsx
    /dashboard/subscriptions/new/page.tsx
    /dashboard/subscriptions/[id]/edit/page.tsx
    /dashboard/orders/page.tsx
    /dashboard/orders/[id]/page.tsx
    /dashboard/meals/page.tsx
    /dashboard/profile/page.tsx
    /dashboard/stats/page.tsx
    /dashboard/settings/page.tsx
/components
  /ui         → Composants de base (Button, Input, Badge...)
  /layout     → Navbar, Sidebar, Footer
  /cards      → SubscriptionCard, ProviderCard
  /forms      → Formulaires réutilisables
  /modals     → GeoModal, ConfirmModal
  /skeletons  → Skeletons de chargement
/lib
  /api        → Fonctions fetch (subscriptions, orders, etc.)
  /auth       → Gestion tokens, helpers auth
  /store      → Zustand stores
  /hooks      → React hooks personnalisés
  /utils      → Fonctions utilitaires (formatPrice, timeAgo...)
/types        → TypeScript types/interfaces
```

### Conventions

- Tous les montants en XOF : formatés avec séparateur milliers (`25 000 XOF`)
- Dates : format français (`15 avril 2026`, ou `Il y a 2 jours` pour les récentes)
- Images manquantes : toujours un fallback (placeholder gris avec icône)
- Textes en français uniquement
- Pas de données mockées — tout vient de l'API
- Skeleton loading sur chaque requête (pas de spinner vide)

### Sécurité

- Tokens en cookies httpOnly uniquement (pas localStorage)
- Toutes les routes `/dashboard/*` vérifiées côté serveur (middleware Next.js)
- Toutes les routes `/profile/*` redirigent vers `/auth/login` si non connecté
- Inputs validés côté client (zod) ET côté serveur (API)
- Images uploadées uniquement via `POST /upload/:folder` — jamais en base64

### Performance

- Images en `next/image` avec lazy loading
- `loading="lazy"` sur les images hors viewport
- Infinite scroll via IntersectionObserver (pas de bouton "Charger plus")
- Données publiques (home, subscriptions) en SSR pour le SEO
- Données privées (profil, commandes) en client-side fetching

### Responsive

- Mobile first pour les pages consommateur
- Desktop first pour le dashboard provider
- Tester systématiquement sur 375px (iPhone SE), 768px (iPad), 1280px (desktop)

---

*Document rédigé pour le projet JUNA — Version web.*
*À mettre à jour au fur et à mesure des décisions techniques et des retours backend.*
