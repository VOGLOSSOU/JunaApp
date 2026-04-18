# Documentation API JUNA — App Mobile

> Documentation des endpoints API utilisés par l'application mobile JUNA.
> Extrait et adapté de `api-documentation.md` pour les besoins spécifiques du développement mobile.

---

## Base URL

**Production :**
```
https://juna-app.up.railway.app/api/v1
```

**Local (développement) :**
```
http://localhost:5000/api/v1
```

---

## Conventions générales

- Tous les endpoints retournent un JSON avec la structure suivante :
```json
{
  "success": true | false,
  "message": "Message lisible" | ["Message 1", "Message 2"],  // string ou array pour erreurs validation
  "data": { ... }        // présent si succès
  "error": { "code": "ERROR_CODE" }  // présent si erreur
}
```

- Les endpoints protégés nécessitent un header `Authorization: Bearer {accessToken}`
- Les tokens expirent : `accessToken` → 15 minutes, `refreshToken` → 7 jours
- Rate limit : 5 requêtes / 15 minutes sur les endpoints auth

---

## Endpoints utilisés par l'app mobile

### Routes disponibles maintenant

| Méthode | Route | Auth | Description | Utilisation Mobile |
|---------|-------|------|-------------|-------------------|
| `GET` | `/countries` | public | Lister les pays | Sélection pays au démarrage |
| `GET` | `/countries/:code/cities` | public | Villes d'un pays | Liste villes après pays |
| `GET` | `/cities/:cityId/landmarks` | public | Landmarks d'une ville | Filtres géographiques |
| `POST` | `/auth/register` | public | Inscription user | Formulaire inscription |
| `POST` | `/auth/login` | public | Connexion user | Formulaire login |
| `POST` | `/auth/refresh` | public | Rafraîchir token | Auto-refresh JWT |
| `GET` | `/auth/me` | auth | Infos utilisateur | Profil, vérification auth |
| `PUT` | `/auth/me` | auth | Mettre à jour profil | Modification profil |
| `GET` | `/home` | public | Feed page d'accueil | Sections popular/recent/providers |
| `GET` | `/subscriptions` | public | Lister abonnements | Page Explorer (avec filtres) |
| `GET` | `/subscriptions/:id` | public | Détail abonnement | Page détail abonnement |
| `POST` | `/orders` | auth | Créer commande | Flow de commande |
| `GET` | `/orders/me` | auth | Mes commandes | Page "Mes commandes" |
| `GET` | `/orders/:id` | auth | Détail commande | Détail commande + QR |
| `PUT` | `/orders/:id/cancel` | auth | Annuler commande | Bouton annuler |
| `POST` | `/reviews` | auth | Créer avis | Laisser avis commande |
| `GET` | `/reviews/subscription/:id` | public | Avis abonnement | Page détail abonnement |
| `POST` | `/upload/:folder` | auth | Upload image | Photo de profil, logo, repas |
| `GET` | `/notifications` | auth | Mes notifications | Page notifications |
| `PUT` | `/notifications/:id/read` | auth | Marquer lu | Action notification |
| `PUT` | `/notifications/read-all` | auth | Tout marquer lu | Bouton "Tout lire" |
| `GET` | `/users/me` | auth | Mon profil complet | Affichage profil |
| `PUT` | `/users/me` | auth | Update profil | Modification nom/téléphone |
| `PUT` | `/users/me/location` | auth | Choisir ville | Paramètres géographiques |
| `PUT` | `/users/me/preferences` | auth | Gérer préférences | Paramètres utilisateur |
| `POST` | `/auth/provider/register` | public | Inscription provider | Formulaire prestataire |
| `GET` | `/auth/provider/me` | auth | Infos prestataire | Profil provider |
| `PUT` | `/auth/provider/me` | auth | Update profil provider | Modification profil |

---

## PARTIE 0 — GÉOGRAPHIE (Mobile Priority)

Les pays, villes et landmarks sont utilisés pour la sélection géographique obligatoire au démarrage.

### GET /countries — Lister les pays disponibles

**Accès :** public

**Utilisation mobile :** Modal de sélection pays au premier lancement

**Réponse 200 ✅ :**
```json
{
  "success": true,
  "message": "Liste des pays",
  "data": [
    {
      "id": "8b60ac9a-c04b-45d6-acea-ad5cf1a340f6",
      "code": "BJ",
      "translations": { "en": "Benin", "fr": "Bénin" },
      "isActive": true,
      "createdAt": "2026-04-08T16:34:35.035Z"
    }
  ]
}
```

### GET /countries/:code/cities — Villes d'un pays

**Accès :** public

**Paramètre :** `code` = code ISO du pays (ex: `BJ`)

**Utilisation mobile :** Liste des villes après sélection pays

**Réponse 200 ✅ :**
```json
{
  "success": true,
  "message": "Villes du pays",
  "data": [
    {
      "id": "101a6a8c-ad3b-4071-b399-ba5cd5afed0c",
      "name": "Cotonou",
      "countryId": "8b60ac9a-c04b-45d6-acea-ad5cf1a340f6",
      "isActive": true,
      "createdAt": "2026-04-08T16:37:58.275Z"
    }
  ]
}
```

### GET /cities/:cityId/landmarks — Landmarks d'une ville

**Accès :** public

**Paramètre :** `cityId` = ID de la ville

**Utilisation mobile :** Filtres par zone de référence dans l'app

**Réponse 200 ✅ :**
```json
{
  "success": true,
  "message": "Landmarks de la ville",
  "data": [
    {
      "id": " landmark-uuid",
      "name": "Étoile Rouge",
      "cityId": "city-uuid",
      "isActive": true,
      "createdAt": "2026-04-08T16:40:12.123Z"
    }
  ]
}
```

---

## PARTIE 1 — PROFIL UTILISATEUR (Mobile Core)

Endpoints pour gérer le profil utilisateur mobile.

### GET /users/me — Obtenir mon profil

**Accès :** auth

**Utilisation mobile :** Affichage profil, vérification données

**Réponse 200 ✅ :**
```json
{
  "success": true,
  "message": "Profil récupéré",
  "data": {
    "id": "<uuid>",
    "email": "user@example.com",
    "name": "Jean Dupont",
    "phone": "+22961111111",
    "role": "USER",
    "isVerified": false,
    "isActive": true,
    "profile": {
      "avatar": null,
      "address": "Quartier Cadjehoun",
      "city": {
        "id": "<uuid>",
        "name": "Cotonou",
        "country": { "code": "BJ", "translations": { "fr": "Bénin" } }
      },
      "preferences": {
        "dietaryRestrictions": ["végétarien"],
        "favoriteCategories": ["africain"],
        "notifications": {
          "email": true,
          "push": true,
          "sms": false
        }
      }
    }
  }
}
```

### PUT /users/me — Mettre à jour le profil

**Accès :** auth

**Body :** (tous les champs optionnels)
```json
{
  "name": "Jean Dupont Jr",           // Modifier nom
  "phone": "+22962222222",            // Modifier téléphone
  "address": "Nouvelle adresse",      // Modifier adresse
  "avatarUrl": "https://res.cloudinary.com/...",  // URL après POST /upload/avatars
  "cityId": "uuid-ville",             // Changer de ville
  "avatarUrl": "https://..."          // Photo de profil
}
```

**Utilisation mobile :** Formulaire modification profil + upload avatar

### PUT /users/me/location — Choisir pays + ville

**Accès :** auth

**Body :**
```json
{
  "cityId": "101a6a8c-ad3b-4071-b399-ba5cd5afed0c"
}
```

**Utilisation mobile :** Modal choix géographique dans les paramètres

**Note :** Liste des pays depuis `GET /countries`, villes depuis `GET /countries/:code/cities`

### PUT /users/me/preferences — Gérer les préférences

**Accès :** auth

**Body :**
```json
{
  "dietaryRestrictions": ["végétarien", "halal"],
  "favoriteCategories": ["africain", "fusion"],
  "notifications": {
    "email": true,
    "push": false,
    "sms": true
  }
}
```

**Utilisation mobile :** Paramètres utilisateur, filtres intelligents

**Note :** La photo de profil se met à jour via `PUT /users/me` avec le champ `avatarUrl` (après upload via `POST /upload/avatars`)

---

## PARTIE 2 — AUTHENTIFICATION (Mobile Critical)

Endpoints essentiels pour l'authentification mobile.

### POST /auth/register — Inscription utilisateur

**Accès :** public

**Body :**
```json
{
  "email": "user@example.com",
  "password": "Password123",
  "name": "Jean Dupont",
  "phone": "+22961111111"
}
```

**Utilisation mobile :** Formulaire d'inscription simple (4 champs)

**Réponse 201 ✅ :**
```json
{
  "success": true,
  "message": "Utilisateur créé avec succès",
  "data": {
    "user": {
      "id": "user-uuid",
      "email": "user@example.com",
      "name": "Jean Dupont",
      "phone": "+22961111111",
      "role": "USER",
      "isVerified": false,
      "isActive": true
    },
    "tokens": {
      "accessToken": "eyJhbGciOiJIUzI1NiIs...",
      "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
      "expiresIn": 900
    }
  }
}
```

### POST /auth/login — Connexion utilisateur

**Accès :** public

**Body :**
```json
{
  "email": "user@example.com",
  "password": "Password123"
}
```

**Utilisation mobile :** Formulaire de connexion

### POST /auth/refresh — Rafraîchir token

**Accès :** public

**Utilisation mobile :** Auto-refresh des tokens expirés

### GET /auth/me — Informations utilisateur

**Accès :** auth

**Utilisation mobile :** Vérification auth, données profil

### PUT /auth/me — Mettre à jour profil

**Accès :** auth

**Utilisation mobile :** Modification profil user

---

## PARTIE 3 — HOME FEED (Mobile Discovery)

### GET /home — Feed page d'accueil

**Accès :** public

**Query params :**
| Param | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `cityId` | UUID | ✅ | ID de la ville sélectionnée par l'utilisateur |
| `limit` | number | ❌ | Nb d'items par section (défaut : 10, max : 50) |

**Utilisation mobile :** Hydrate la page d'accueil en une seule requête (sections popular, recent, providers). Quand l'utilisateur applique un filtre (category, type, etc.), basculer sur `GET /subscriptions`.

**Réponse 200 ✅ :**
```json
{
  "success": true,
  "message": "Feed de la page d'accueil",
  "data": {
    "popular": [
      {
        "id": "sub-uuid",
        "name": "Abonnement Repas Africain",
        "description": "...",
        "price": 25000,
        "currency": "XOF",
        "category": "AFRICAN",
        "type": "LUNCH",
        "duration": "WORK_WEEK",
        "images": ["https://res.cloudinary.com/..."],
        "rating": 4.8,
        "reviewCount": 120,
        "isActive": true,
        "provider": {
          "id": "prov-uuid",
          "name": "Chez Mariam",
          "logo": "https://...",
          "isVerified": true
        }
      }
    ],
    "recent": [
      // même structure que popular
    ],
    "providers": [
      {
        "id": "prov-uuid",
        "name": "Chez Mariam",
        "logo": "https://...",
        "isVerified": true,
        "city": "Cotonou",
        "subscriptionCount": 3,
        "rating": 4.6
      }
    ]
  }
}
```

**Réponse 400 ❌ — cityId manquant ou invalide :**
```json
{
  "success": false,
  "message": ["cityId doit être un UUID valide"],
  "error": { "code": "INVALID_INPUT" }
}
```

**Réponse 404 ❌ — ville introuvable :**
```json
{
  "success": false,
  "message": "Ville introuvable",
  "error": { "code": "RESOURCE_NOT_FOUND" }
}
```

> **Note — score `popular`** : `(rating × 0.3) + (log(reviewCount+1) × 0.2) + (log(orderCount+1) × 0.4) + (isVerified ? 0.1 : 0)` — permet de lisser les volumes élevés pour ne pas écraser les nouveaux prestataires.

> **Note — `providers`** : uniquement les prestataires avec au moins un point de retrait physique dans la ville (via `ProviderLandmark`), status `APPROVED`.

---

## PARTIE 4 — ABONNEMENTS (Mobile Explorer)

Endpoints centraux pour la découverte et gestion des abonnements.

### GET /subscriptions — Lister les abonnements

**Accès :** public

**Query params :**
- `page`, `limit` : pagination
- `category` : AFRICAN, EUROPEAN, etc.
- `type` : BREAKFAST, LUNCH, etc.
- `duration` : DAY, WEEK, etc.
- `cityId` : filtrage géographique
- `landmarkId` : filtrage par zone

**Utilisation mobile :** Page d'accueil (sections), page Explorer

**Réponse 200 ✅ :**
```json
{
  "success": true,
  "message": "Liste des abonnements",
  "data": {
    "subscriptions": [
      {
        "id": "sub-uuid",
        "name": "Abonnement Repas Africain",
        "description": "Repas traditionnels africains",
        "price": 25000,
        "currency": "XOF",
        "type": "LUNCH",
        "category": "AFRICAN",
        "duration": "WORK_WEEK",
        "mealCount": 5,
        "images": ["url1", "url2"],
        "provider": {
          "id": "prov-uuid",
          "name": "Chez Mariam",
          "logo": "logo-url",
          "isVerified": true
        },
        "rating": 4.8,
        "reviewCount": 120,
        "isActive": true
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 245,
      "totalPages": 13
    }
  }
}
```

### GET /subscriptions/:id — Détail abonnement

**Accès :** public

**Utilisation mobile :** Page détail abonnement

---

## PARTIE 5 — COMMANDES (Mobile Transaction)

Endpoints pour le flow de commande complet.

### POST /orders — Créer une commande

**Accès :** auth

**Body :**
```json
{
  "subscriptionId": "sub-uuid",
  "deliveryMethod": "DELIVERY",
  "deliveryAddress": "Quartier Étoile Rouge, Cotonou",
  "landmarkId": "landmark-uuid",  // optionnel
  "notes": "Sonnette rouge",      // optionnel
  "paymentMethod": "MOBILE_MONEY_WAVE"
}
```

**Utilisation mobile :** Étape 3 du flow de commande

### GET /orders/me — Mes commandes

**Accès :** auth

**Query params :**
- `status` : PENDING, CONFIRMED, etc.
- `page`, `limit`

**Utilisation mobile :** Page "Mes commandes"

### GET /orders/:id — Détail commande + QR

**Accès :** auth

**Utilisation mobile :** Affichage commande avec QR code

### PUT /orders/:id/cancel — Annuler commande

**Accès :** auth

**Utilisation mobile :** Bouton annuler (si status autorise)

---

## PARTIE 6 — AVIS & NOTIFICATIONS

### POST /reviews — Créer un avis

**Accès :** auth

**Utilisation mobile :** Formulaire avis après commande

### GET /reviews/subscription/:id — Avis d'un abonnement

**Accès :** public

**Utilisation mobile :** Section avis page détail

### GET /notifications — Mes notifications

**Accès :** auth

**Utilisation mobile :** Page notifications, badge header

### PUT /notifications/:id/read — Marquer comme lu

**Accès :** auth

### PUT /notifications/read-all — Tout marquer lu

**Accès :** auth

---

## PARTIE 7 — UPLOAD & PROVIDER

### POST /upload/:folder — Upload image

**Accès :** auth

**Content-Type :** `multipart/form-data`

**Utilisation mobile :** Photo de profil, logo provider, image repas

**`:folder` — valeurs acceptées :**
| Valeur | Usage |
|--------|-------|
| `avatars` | Photo de profil utilisateur |
| `providers` | Logo fournisseur |
| `meals` | Photo d'un repas |
| `subscriptions` | Image d'un abonnement |
| `documents` | Documents provider |

**Champ du fichier :** `image` (pas `file`, pas `avatar` — exactement `image`)

**Types MIME acceptés :** `image/jpeg`, `image/jpg`, `image/png`, `image/webp`

**Taille maximale :** 5 Mo (5 242 880 bytes)

**Exemple :**
```
POST /api/v1/upload/avatars
Authorization: Bearer <token>
Content-Type: multipart/form-data

image: <fichier binaire>
```

**Réponse 201 ✅ :**
```json
{
  "success": true,
  "message": "Image uploadée avec succès",
  "data": {
    "url": "https://res.cloudinary.com/dm9561wpm/image/upload/v.../juna/avatars/xxxx.jpg",
    "publicId": "juna/avatars/xxxx",
    "folder": "avatars",
    "size": 123456,
    "mimetype": "image/jpeg"
  }
}
```

**Réponse 400 ❌ — Champ `image` absent :**
```json
{
  "success": false,
  "message": ["Aucun fichier fourni"],
  "error": { "code": "INVALID_INPUT" }
}
```

**Réponse 400 ❌ — Format non supporté :**
```json
{
  "success": false,
  "message": ["Format non supporté. Formats acceptés : JPG, PNG, WEBP"],
  "error": { "code": "INVALID_INPUT" }
}
```

> Après upload, utiliser `data.url` pour mettre à jour le profil via `PUT /users/me` ou `PUT /providers/me`.

### POST /auth/provider/register — Inscription prestataire

**Accès :** public

**Utilisation mobile :** Flow "Devenir prestataire"

### GET /auth/provider/me — Infos prestataire

**Accès :** auth

### PUT /auth/provider/me — Update profil provider

**Accès :** auth

---

## Codes d'erreur courants (Mobile)

| Code | Description | Action mobile |
|------|-------------|---------------|
| `INVALID_CREDENTIALS` | Email/mot de passe incorrect | Message rouge formulaire |
| `USER_NOT_FOUND` | Utilisateur inexistant | Redirection inscription |
| `TOKEN_EXPIRED` | Token expiré | Auto-refresh ou re-login |
| `INSUFFICIENT_PERMISSIONS` | Droits insuffisants | Message d'erreur |
| `RESOURCE_NOT_FOUND` | Ressource inexistante | Page 404 ou message |
| `VALIDATION_ERROR` | Données invalides | Messages sous champs |
| `RATE_LIMIT_EXCEEDED` | Trop de requêtes | Attendre 15 minutes |

---

## Flow mobile typique

```
1. Premier lancement → GET /countries → sélection pays
2. Sélection ville → GET /countries/:code/cities → choix ville
3. Page accueil → GET /home?cityId=... (sections popular/recent/providers)
4. Filtre actif → GET /subscriptions?cityId=...&category=... (bascule sur Explorer)
5. Détail abonnement → GET /subscriptions/:id
6. S'abonner → POST /auth/login si pas connecté
7. Commande → POST /orders
8. Suivi → GET /orders/me
9. Profil → GET /users/me, PUT /users/me/* pour personnalisation
10. Paramètres → PUT /users/me/preferences, PUT /users/me/location
11. Notifications → GET /notifications
```

---

## Optimisations mobile

- **Caching** : Stocker localement pays/villes (changent rarement)
- **Pagination** : Utiliser `page`/`limit` pour performance
- **Images** : URLs Cloudinary optimisées automatiquement
- **Offline** : Cache des données statiques
- **Retry** : Logic de retry automatique sur échec réseau

---

*Cette documentation est focalisée sur les endpoints critiques pour l'app mobile. Pour la documentation complète, voir `api-documentation.md`.*</content>
<parameter name="filePath">mobile-api-documentation.md