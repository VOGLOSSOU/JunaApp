# Documentation API JUNA — App Mobile

> Documentation des endpoints API utilisés par l'application mobile JUNA.
> Couvre le parcours **Consommateur** et le flow **Devenir prestataire**.

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

Toutes les réponses ont la structure suivante :
```json
{
  "success": true | false,
  "message": "Message lisible" | ["Message 1", "Message 2"],
  "data": { ... },
  "error": { "code": "ERROR_CODE" }
}
```

- `data` est présent uniquement en cas de succès
- `error` est présent uniquement en cas d'échec
- `message` peut être un tableau de strings pour les erreurs de validation
- Les endpoints protégés nécessitent : `Authorization: Bearer {accessToken}`
- `accessToken` expire après **15 minutes**, `refreshToken` après **7 jours**
- Rate limit auth : **5 requêtes / 15 minutes**

### Points critiques — erreurs fréquentes

| Problème | Cause | Solution |
|----------|-------|----------|
| `"Expected number, received string"` sur `page`/`limit` | Les query params arrivent toujours en string | Le serveur coerce automatiquement (`z.coerce.number()`) — envoyer `?page=1&limit=20` suffit |
| `400` sur `cityId` | UUID v4 attendu | Format exact : `xxxxxxxx-xxxx-4xxx-xxxx-xxxxxxxxxxxx` |
| Champ `isAvailable` non reconnu | Le champ s'appelle `isActive` | Utiliser exactement `isActive` |
| Upload `400 "Aucun fichier fourni"` | Mauvais nom de champ | Le champ multipart s'appelle exactement `image` (pas `file`, pas `avatar`) |
| `user.avatar null` dans les avis | L'utilisateur n'a pas de photo | Champ nullable — prévoir un fallback (initiales) |

---

## Table des routes

| Méthode | Route | Auth | Description |
|---------|-------|------|-------------|
| `POST` | `/auth/register` | public | Inscription utilisateur |
| `POST` | `/auth/login` | public | Connexion |
| `POST` | `/auth/refresh` | public | Rafraîchir accessToken |
| `POST` | `/auth/logout` | auth | Déconnexion |
| `GET` | `/auth/me` | auth | Infos utilisateur connecté |
| `PUT` | `/auth/me` | auth | Modifier profil (auth service) |
| `POST` | `/auth/change-password` | auth | Changer mot de passe |
| `GET` | `/countries` | public | Lister les pays |
| `GET` | `/countries/:code/cities` | public | Villes d'un pays |
| `GET` | `/cities/:cityId/landmarks` | public | Landmarks d'une ville |
| `GET` | `/home` | public | Feed page d'accueil |
| `GET` | `/subscriptions` | public | Lister abonnements (Explorer) |
| `GET` | `/subscriptions/:id` | public | Détail abonnement |
| `GET` | `/reviews/subscription/:id` | public | Avis d'un abonnement |
| `POST` | `/reviews` | auth | Créer un avis |
| `GET` | `/users/me` | auth | Profil utilisateur complet |
| `PUT` | `/users/me` | auth | Modifier profil |
| `PUT` | `/users/me/location` | auth | Changer de ville |
| `PUT` | `/users/me/preferences` | auth | Préférences alimentaires |
| `POST` | `/orders` | auth | Créer une commande |
| `GET` | `/orders/me` | auth | Mes commandes |
| `GET` | `/orders/:id` | auth | Détail commande |
| `DELETE` | `/orders/:id` | auth | Annuler commande |
| `PUT` | `/orders/:id/activate` | auth | Activer commande |
| `POST` | `/upload/:folder` | auth | Upload image |
| `GET` | `/active-subscriptions/me` | auth | Mes abonnements actifs |
| `GET` | `/active-subscriptions/check` | auth | Vérifier abonnement actif |
| `POST` | `/providers/register` | auth | Devenir prestataire |

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

**Paramètre :** `cityId` = UUID v4 de la ville

**Utilisation mobile :** Filtres par zone de référence dans l'app

**Réponse 200 ✅ :**
```json
{
  "success": true,
  "message": "Landmarks de la ville",
  "data": [
    {
      "id": "landmark-uuid",
      "name": "Étoile Rouge",
      "cityId": "city-uuid",
      "isActive": true,
      "createdAt": "2026-04-08T16:40:12.123Z"
    }
  ]
}
```

---

## PARTIE 1 — AUTHENTIFICATION (Mobile Critical)

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

| Champ | Type | Obligatoire | Contraintes |
|-------|------|-------------|-------------|
| `email` | string | ✅ | Format email valide |
| `password` | string | ✅ | Min 8 caractères |
| `name` | string | ✅ | Min 2 caractères |
| `phone` | string | ❌ | Format international (ex: `+22961111111`) |

**Utilisation mobile :** Formulaire d'inscription (4 champs)

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
    },
    "isProfileComplete": false
  }
}
```

> `isProfileComplete: false` → l'utilisateur n'a pas encore choisi sa ville. Rediriger vers l'écran de complétion de profil (sélection ville obligatoire).

**Réponses d'erreur :**
```json
{ "success": false, "message": ["Cet email est déjà utilisé"], "error": { "code": "EMAIL_ALREADY_EXISTS" } }
{ "success": false, "message": ["Ce numéro de téléphone est déjà utilisé"], "error": { "code": "PHONE_ALREADY_EXISTS" } }
```

---

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

**Réponse 200 ✅ :**
```json
{
  "success": true,
  "message": "Connexion réussie",
  "data": {
    "user": {
      "id": "user-uuid",
      "email": "user@example.com",
      "name": "Jean Dupont",
      "role": "USER",
      "isActive": true
    },
    "tokens": {
      "accessToken": "eyJhbGciOiJIUzI1NiIs...",
      "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
      "expiresIn": 900
    },
    "isProfileComplete": true
  }
}
```

> Vérifier `isProfileComplete` à chaque login. Si `false`, rediriger vers l'écran de sélection de ville (`PUT /users/me/location`).

**Réponses d'erreur :**
```json
{ "success": false, "message": "Email ou mot de passe incorrect", "error": { "code": "INVALID_CREDENTIALS" } }
{ "success": false, "message": "Compte suspendu ou banni", "error": { "code": "ACCOUNT_SUSPENDED" } }
```

---

### POST /auth/refresh — Rafraîchir token

**Accès :** public

**Body :**
```json
{ "refreshToken": "eyJhbGciOiJIUzI1NiIs..." }
```

**Utilisation mobile :** Auto-refresh des tokens expirés (déclencher quand 401 reçu)

**Réponse 200 ✅ :**
```json
{
  "success": true,
  "data": { "accessToken": "eyJhbGciOiJIUzI1NiIs..." }
}
```

**Réponse 401 ❌ :**
```json
{ "success": false, "message": "Refresh token invalide ou expiré", "error": { "code": "INVALID_TOKEN" } }
```

> Si le refresh échoue, déconnecter l'utilisateur et rediriger vers la page login.

---

### POST /auth/logout — Déconnexion

**Accès :** auth

**Body :**
```json
{ "refreshToken": "eyJhbGciOiJIUzI1NiIs..." }
```

**Utilisation mobile :** Bouton "Se déconnecter" dans les paramètres

**Réponse 200 ✅ :**
```json
{ "success": true, "message": "Déconnexion réussie" }
```

---

### GET /auth/me — Informations utilisateur connecté

**Accès :** auth

**Utilisation mobile :** Vérification auth, données profil rapide

---

### POST /auth/change-password — Changer mot de passe

**Accès :** auth

**Body :**
```json
{
  "currentPassword": "AncienMotDePasse123",
  "newPassword": "NouveauMotDePasse456"
}
```

**Utilisation mobile :** Écran "Changer mot de passe" dans les paramètres

**Réponse 200 ✅ :**
```json
{ "success": true, "message": "Mot de passe modifié avec succès" }
```

**Réponse 401 ❌ :**
```json
{ "success": false, "message": "Mot de passe actuel incorrect", "error": { "code": "INVALID_PASSWORD" } }
```

---

## PARTIE 2 — PROFIL UTILISATEUR (Mobile Core)

### GET /users/me — Obtenir mon profil

**Accès :** auth

**Utilisation mobile :** Affichage profil, vérification données complètes

**Réponse 200 ✅ :**
```json
{
  "success": true,
  "message": "Profil récupéré avec succès",
  "data": {
    "id": "user-uuid",
    "email": "user@example.com",
    "name": "Jean Dupont",
    "phone": "+22961111111",
    "role": "USER",
    "isVerified": false,
    "isActive": true,
    "isProfileComplete": true,
    "profile": {
      "avatar": "https://res.cloudinary.com/...",
      "address": "Quartier Cadjehoun",
      "city": {
        "id": "city-uuid",
        "name": "Cotonou",
        "country": { "code": "BJ", "translations": { "fr": "Bénin", "en": "Benin" } }
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

> `profile.avatar` peut être `null` si l'utilisateur n'a pas uploadé de photo.
> `profile.city` peut être `null` si la ville n'a pas encore été définie.

### PUT /users/me — Mettre à jour le profil

**Accès :** auth

**Body :** (tous les champs optionnels)
```json
{
  "name": "Jean Dupont Jr",
  "phone": "+22962222222",
  "address": "Nouvelle adresse",
  "cityId": "city-uuid",
  "avatarUrl": "https://res.cloudinary.com/..."
}
```

> `avatarUrl` = URL obtenue après `POST /upload/avatars`. Uploader d'abord, puis envoyer l'URL.

**Utilisation mobile :** Formulaire modification profil + upload avatar

### PUT /users/me/location — Choisir pays + ville

**Accès :** auth

**Body :**
```json
{ "cityId": "101a6a8c-ad3b-4071-b399-ba5cd5afed0c" }
```

**Utilisation mobile :** Modal choix géographique dans les paramètres

**Réponse 200 ✅ :**
```json
{
  "success": true,
  "message": "Localisation mise à jour avec succès",
  "data": {
    "cityId": "city-uuid",
    "cityName": "Cotonou",
    "countryCode": "BJ"
  }
}
```

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

---

## PARTIE 3 — HOME FEED (Mobile Discovery)

### GET /home — Feed page d'accueil

**Accès :** public

**Query params :**
| Param | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `cityId` | UUID v4 | ✅ | ID de la ville sélectionnée par l'utilisateur |
| `limit` | number | ❌ | Nb d'items par section (défaut : 10, max : 50) |

**Utilisation mobile :** Hydrate la page d'accueil en une seule requête (sections popular/recent/providers). Quand l'utilisateur applique un filtre (category, type, etc.), basculer sur `GET /subscriptions`.

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
    "recent": [ /* même structure que popular */ ],
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

> Score `popular` : `(rating × 0.3) + (log(reviewCount+1) × 0.2) + (log(orderCount+1) × 0.4) + (isVerified ? 0.1 : 0)`
> `providers` : uniquement les prestataires avec au moins un point de retrait physique dans la ville (via `ProviderLandmark`), status `APPROVED`.

---

## PARTIE 4 — ABONNEMENTS (Mobile Explorer)

### GET /subscriptions — Lister les abonnements (Explorer)

**Accès :** public

**Query params :**

| Param | Type | Défaut | Description |
|-------|------|--------|-------------|
| `cityId` | UUID v4 | — | Ville (recommandé) |
| `sort` | string | `popular` | Voir tableau ci-dessous |
| `page` | number | `1` | Pagination — coercé automatiquement depuis string |
| `limit` | number | `20` | Items par page (max 100) — coercé automatiquement |
| `category` | string | — | `AFRICAN` `EUROPEAN` `ASIAN` `AMERICAN` `FUSION` `VEGETARIAN` `VEGAN` `HALAL` `OTHER` |
| `type` | string | — | `BREAKFAST` `LUNCH` `DINNER` `SNACK` `BREAKFAST_LUNCH` `BREAKFAST_DINNER` `LUNCH_DINNER` `FULL_DAY` `CUSTOM` |
| `duration` | string | — | `DAY` `THREE_DAYS` `WEEK` `TWO_WEEKS` `MONTH` `WORK_WEEK` `WORK_WEEK_2` `WORK_MONTH` `WEEKEND` |
| `landmarkId` | UUID v4 | — | Filtrage par zone |
| `search` | string | — | Recherche texte (nom, description) |
| `minPrice` | number | — | Prix minimum |
| `maxPrice` | number | — | Prix maximum |

**Valeurs `sort` :**

| Valeur | Comportement |
|--------|-------------|
| `popular` *(défaut)* | Score pondéré : rating × 0.3 + log(reviews+1) × 0.2 + log(orders+1) × 0.4 + isVerified × 0.1 |
| `recent` | Plus récents en premier (`createdAt DESC`) |
| `rating` | Mieux notés en premier |
| `price_asc` | Prix croissant |
| `price_desc` | Prix décroissant |

**Utilisation mobile :** Page Explorer — infinite scroll, changement de tri ou de filtre recharge depuis page=1

**Réponse 200 ✅ :**
```json
{
  "success": true,
  "message": "Abonnements récupérés avec succès",
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
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 245,
      "totalPages": 13
    }
  }
}
```

> Les abonnements `isActive: false` sont toujours filtrés côté serveur — jamais retournés.

### GET /subscriptions/:id — Détail abonnement

**Accès :** public

**Paramètre :** `id` = UUID v4 de l'abonnement

**Utilisation mobile :** Page détail abonnement — affichage complet pour convaincre l'utilisateur de s'abonner

**Réponse 200 ✅ :**
```json
{
  "success": true,
  "message": "Abonnement récupéré avec succès",
  "data": {
    "id": "sub-uuid",
    "name": "Abonnement Repas Africain",
    "description": "Description complète et détaillée...",
    "price": 25000,
    "currency": "XOF",
    "type": "LUNCH",
    "category": "AFRICAN",
    "duration": "WORK_WEEK",
    "mealCount": 5,
    "images": ["https://res.cloudinary.com/..."],
    "rating": 4.8,
    "reviewCount": 120,
    "isActive": true,
    "provider": {
      "id": "prov-uuid",
      "name": "Chez Mariam",
      "logo": "https://...",
      "isVerified": true,
      "description": "Restaurant spécialisé en cuisine africaine traditionnelle...",
      "rating": 4.6,
      "reviewCount": 87,
      "acceptsDelivery": true,
      "acceptsPickup": true,
      "businessAddress": "Rue 234, Quartier Cadjehoun",
      "city": {
        "id": "city-uuid",
        "name": "Cotonou"
      }
    },
    "meals": [
      {
        "id": "meal-uuid",
        "name": "Riz sauce graine",
        "description": "Riz basmati avec sauce graine maison, poulet grillé...",
        "imageUrl": "https://..."
      }
    ],
    "deliveryZones": ["Plateau", "Akpakpa", "Cadjehoun"],
    "pickupPoints": ["Rue 234, Cadjehoun"],
    "providerSubscriptions": [
      {
        "id": "sub-uuid-2",
        "name": "Abonnement Petit-déjeuner",
        "price": 15000,
        "currency": "XOF",
        "type": "BREAKFAST",
        "category": "AFRICAN",
        "duration": "WORK_WEEK",
        "images": ["https://res.cloudinary.com/..."],
        "rating": 4.5,
        "reviewCount": 32,
        "isActive": true
      }
    ]
  }
}
```

> `meals[].price` n'est pas retourné — seul le prix global de l'abonnement est exposé.
> `provider.description` peut être `null`.
> `provider.city` peut être `null`.
> `meals[].imageUrl` peut être `null`.
> `providerSubscriptions` : 6 derniers abonnements actifs et publics du même provider, hors abonnement courant. Tableau vide `[]` si le provider n'en a pas d'autres.
> `pickupPoints` = adresse principale du provider (simplification MVP).

---

## PARTIE 5 — COMMANDES (Mobile Transaction)

### POST /orders — Créer une commande

**Accès :** auth (USER)

**Body :**

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `subscriptionId` | UUID v4 | ✅ | Abonnement commandé |
| `deliveryMethod` | string | ✅ | `DELIVERY` ou `PICKUP` |
| `deliveryAddress` | string | ❌ | Adresse de livraison (requis si `DELIVERY`) |
| `deliveryCity` | string | ❌ | Ville de livraison (requis si `DELIVERY`) |
| `pickupLocation` | string | ❌ | Adresse du provider (auto-rempli si `PICKUP`) |
| `startAsap` | boolean | ❌* | Démarrer dès que possible |
| `requestedStartDate` | string (ISO 8601) | ❌* | Date de début souhaitée |

> *`startAsap` OU `requestedStartDate` est obligatoire — l'un ou l'autre.
> Si `requestedStartDate`, la date doit respecter le délai de préparation du prestataire (`preparationHours`).
> Pour `PICKUP`, `pickupLocation` est automatiquement l'adresse du provider (`businessAddress`).

**Exemple body (livraison) :**
```json
{
  "subscriptionId": "sub-uuid",
  "deliveryMethod": "DELIVERY",
  "deliveryAddress": "Quartier Cadjehoun, Cotonou",
  "deliveryCity": "Cotonou",
  "startAsap": true
}
```

**Exemple body (retrait) :**
```json
{
  "subscriptionId": "sub-uuid",
  "deliveryMethod": "PICKUP",
  "startAsap": true
}
```

**Utilisation mobile :** Étape de commande — après sélection de l'abonnement

**Réponse 201 ✅ :**
```json
{
  "success": true,
  "message": "Commande créée avec succès",
  "data": {
    "id": "order-uuid",
    "orderNumber": "JUNA-0001",
    "status": "PENDING",
    "amount": 25000,
    "deliveryCost": 0,
    "deliveryMethod": "DELIVERY",
    "deliveryAddress": "Quartier Cadjehoun",
    "deliveryCity": "Cotonou",
    "scheduledFor": "2026-04-20T08:00:00Z",
    "qrCode": "JUNA-A1B2C3D4",
    "createdAt": "2026-04-19T10:00:00Z"
  }
}
```

> `amount` = prix abonnement uniquement (frais de livraison négociés directement avec le provider).
> `deliveryCost` = 0 — estimation affichée, négociation directe avec le provider.

**Réponses d'erreur :**
```json
{ "success": false, "message": "Cet abonnement n'est pas disponible", "error": { "code": "INVALID_INPUT" } }
{ "success": false, "message": "Ce prestataire ne propose pas la livraison", "error": { "code": "INVALID_INPUT" } }
```

---

### GET /orders/me — Mes commandes

**Accès :** auth (USER)

**Utilisation mobile :** Page "Mes commandes"

**Réponse 200 ✅ :**
```json
{
  "success": true,
  "message": "Commandes récupérées avec succès",
  "data": [
    {
      "id": "order-uuid",
      "orderNumber": "JUNA-0001",
      "status": "CONFIRMED",
      "amount": 25000,
      "currency": "XOF",
      "deliveryMethod": "DELIVERY",
      "deliveryAddress": "Quartier Cadjehoun",
      "pickupLocation": null,
      "scheduledFor": "2026-04-20T08:00:00Z",
      "completedAt": null,
      "createdAt": "2026-04-19T10:00:00Z",
      "updatedAt": "2026-04-19T11:00:00Z",
      "subscription": {
        "id": "sub-uuid",
        "name": "Abonnement Repas Africain"
      },
      "payment": {
        "id": "payment-uuid",
        "status": "SUCCESS",
        "amount": 25000
      }
    }
  ]
}
```

---

### GET /orders/:id — Détail commande

**Accès :** auth

**Utilisation mobile :** Affichage commande + QR code

**Réponse 200 ✅ :**
```json
{
  "success": true,
  "data": {
    "id": "order-uuid",
    "orderNumber": "JUNA-0001",
    "status": "CONFIRMED",
    "amount": 25000,
    "deliveryCost": 0,
    "deliveryMethod": "DELIVERY",
    "deliveryAddress": "Quartier Cadjehoun",
    "deliveryCity": "Cotonou",
    "scheduledFor": "2026-04-20T08:00:00Z",
    "qrCode": "JUNA-A1B2C3D4",
    "completedAt": null,
    "createdAt": "2026-04-19T10:00:00Z",
    "subscription": {
      "id": "sub-uuid",
      "name": "Abonnement Repas Africain",
      "provider": { "id": "prov-uuid", "businessName": "Chez Mariam" }
    }
  }
}
```

> `completedAt` est `null` tant que la commande n'est pas livrée/retirée.

---

### DELETE /orders/:id — Annuler commande

**Accès :** auth (USER ou ADMIN)

**Annulation possible uniquement si status :** `PENDING` ou `CONFIRMED`

**Utilisation mobile :** Bouton annuler (vérifier le status avant d'afficher le bouton)

**Réponse 200 ✅ :**
```json
{ "success": true, "message": "Commande annulée avec succès", "data": { "id": "...", "status": "CANCELLED" } }
```

**Réponse 409 ❌ :**
```json
{ "success": false, "message": "Cette commande ne peut plus être annulée", "error": { "code": "ORDER_CANNOT_BE_CANCELLED" } }
```

> **Attention** : Une commande `CONFIRMED` peut être annulée en base mais aucun remboursement automatique n'est déclenché pour l'instant. Afficher un message invitant l'utilisateur à contacter le support.

---

### PUT /orders/:id/activate — Activer une commande

**Accès :** auth (USER propriétaire)

**Pas de body.** L'utilisateur active sa commande après confirmation du paiement.

**Prérequis :** La commande doit être au status `CONFIRMED`.

**N'afficher le bouton d'activation que si `order.status === "CONFIRMED"`.**

**Actions déclenchées :**
- Commande passe de `CONFIRMED` → `ACTIVE`
- Crée automatiquement un enregistrement dans les abonnements actifs (`GET /active-subscriptions/me`)

**Utilisation mobile :** Bouton "J'ai reçu ma commande" ou "Activer mon abonnement" sur la page de détail commande

**Réponse 200 ✅ :**
```json
{
  "success": true,
  "message": "Commande activée avec succès"
}
```

**Réponse 400 ❌ :**
```json
{ "success": false, "message": "La commande doit être confirmée avant d'être activée", "error": { "code": "INVALID_INPUT" } }
```

---

### Cycle de vie d'une commande

```
POST /orders → PENDING
  │
  ├── DELETE /orders/:id → CANCELLED  (si PENDING ou CONFIRMED)
  │
  └── Paiement validé (confirmation provider)
        │
        └── CONFIRMED
              │
              ├── DELETE /orders/:id → CANCELLED
              │
              └── PUT /orders/:id/activate → ACTIVE
                    │
                    └── (abonnement actif créé automatiquement)
```

**Résumé des statuts :**
| Status | Signification | Action possible |
|--------|--------------|-----------------|
| `PENDING` | Commande créée, en attente de confirmation | Annuler |
| `CONFIRMED` | Paiement/commande confirmé | Activer, Annuler |
| `ACTIVE` | Abonnement en cours | Aucune |
| `CANCELLED` | Commande annulée | Aucune |

---

## PARTIE 6 — ABONNEMENTS ACTIFS

### GET /active-subscriptions/me — Mes abonnements actifs

**Accès :** auth (USER)

**Utilisation mobile :** Afficher les abonnements actifs dans le profil ou un onglet dédié

**Réponse 200 ✅ :**
```json
{
  "success": true,
  "message": "Abonnements actifs récupérés",
  "data": [
    {
      "id": "active-sub-uuid",
      "userId": "user-uuid",
      "orderId": "order-uuid",
      "subscriptionId": "sub-uuid",
      "startedAt": "2026-04-15T08:00:00Z",
      "endsAt": "2026-04-22T08:00:00Z",
      "duration": "WORK_WEEK",
      "subscription": {
        "id": "sub-uuid",
        "name": "Abonnement Repas Africain",
        "category": "AFRICAN",
        "type": "LUNCH",
        "provider": {
          "id": "prov-uuid",
          "businessName": "Chez Mariam"
        }
      }
    }
  ]
}
```

---

### GET /active-subscriptions/check — Vérifier abonnement actif

**Accès :** auth (USER)

**Query params :**
- `category` : AFRICAN, EUROPEAN, etc. (optionnel)
- `type` : BREAKFAST, LUNCH, etc. (optionnel)

**Exemple :** `GET /api/v1/active-subscriptions/check?category=AFRICAN&type=LUNCH`

**Utilisation mobile :** Afficher un badge "Abonné" sur un abonnement, personnaliser l'interface

**Réponse 200 ✅ :**
```json
{
  "success": true,
  "data": {
    "hasActive": true
  }
}
```

> `hasActive: true` → l'utilisateur a un abonnement actif correspondant aux filtres fournis.

**Expiration automatique :** Les abonnements expirés sont supprimés automatiquement par un job cron chaque nuit à 2h UTC.

---

## PARTIE 7 — UPLOAD D'IMAGES

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

**Champ du fichier :** `image` — exactement ce nom, pas `file`, pas `avatar`, pas `photo`

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

**Réponses d'erreur :**
```json
{ "success": false, "message": ["Aucun fichier fourni"], "error": { "code": "INVALID_INPUT" } }
{ "success": false, "message": ["Format non supporté. Formats acceptés : JPG, PNG, WEBP"], "error": { "code": "INVALID_INPUT" } }
```

> Après upload, utiliser `data.url` pour mettre à jour le profil via `PUT /users/me`.

---

## PARTIE 8 — DEVENIR PRESTATAIRE

### Notes importantes

**Rôle après inscription — le `role` reste `USER` jusqu'à validation admin**
À la soumission de `POST /providers/register`, le rôle dans le JWT reste `USER`. C'est uniquement quand l'admin approuve que le rôle passe à `PROVIDER`. Le provider devra se **reconnecter** (ou faire `POST /auth/refresh`) après approbation pour obtenir un token avec `role: "PROVIDER"`. Prévoir un écran "En attente de validation" et inviter l'utilisateur à se reconnecter une fois approuvé.

**Vérification du statut**
Aucune notification automatique à l'approbation pour l'instant. Implémenter un bouton "Vérifier le statut de ma demande" qui refait un login ou un refresh.

**`landmarkIds` — pour le filtrage géographique**
Servent à apparaître dans `GET /home` (section `providers`). Simplification MVP : pour le retrait, le client récupère toujours à l'adresse principale du provider (`businessAddress`).

---

### POST /providers/register — Inscription prestataire

**Accès :** auth (USER avec compte existant)

**Body :**

| Champ | Type | Obligatoire | Contraintes |
|-------|------|-------------|-------------|
| `businessName` | string | ✅ | Min 2 caractères |
| `description` | string | ❌ | Description libre |
| `businessAddress` | string | ✅ | Min 3 caractères |
| `logo` | string (URL) | ✅ | URL Cloudinary (`POST /upload/providers`) |
| `cityId` | UUID v4 | ✅ | Ville principale de l'établissement |
| `acceptsDelivery` | boolean | ✅ | Propose la livraison |
| `acceptsPickup` | boolean | ✅ | Accepte le retrait sur place |
| `deliveryZones` | array | ❌* | Requis si `acceptsDelivery: true` |
| `landmarkIds` | UUID[] | ❌ | Points de retrait |
| `documentUrl` | string (URL) | ❌ | Document justificatif |

> Au moins `acceptsDelivery` ou `acceptsPickup` doit être `true`.

**Format `deliveryZones` :**
```json
[
  { "city": "Cotonou", "country": "BJ", "cost": 500 },
  { "city": "Abomey-Calavi", "country": "BJ", "cost": 800 }
]
```

**Body complet exemple :**
```json
{
  "businessName": "Chez Mariam",
  "description": "Restaurant spécialisé en cuisine africaine traditionnelle",
  "businessAddress": "Rue 234, Quartier Cadjehoun",
  "logo": "https://res.cloudinary.com/...",
  "cityId": "city-uuid",
  "acceptsDelivery": true,
  "acceptsPickup": true,
  "deliveryZones": [
    { "city": "Cotonou", "country": "BJ", "cost": 500 }
  ],
  "landmarkIds": ["landmark-uuid-1", "landmark-uuid-2"],
  "documentUrl": "https://res.cloudinary.com/..."
}
```

**Utilisation mobile :** Flow "Devenir prestataire"

**Réponse 201 ✅ :**
```json
{
  "success": true,
  "message": "Fournisseur enregistré avec succès",
  "data": {
    "id": "prov-uuid",
    "businessName": "Chez Mariam",
    "status": "PENDING",
    "message": "Votre demande a été enregistrée. En attente de validation par l'admin."
  }
}
```

**Réponse 409 ❌ :**
```json
{ "success": false, "message": "Vous êtes déjà enregistré comme fournisseur", "error": { "code": "PROVIDER_EXISTS" } }
```

---

## PARTIE 9 — AVIS

### POST /reviews — Créer un avis

**Accès :** auth (USER)

**Body :**

| Champ | Type | Obligatoire | Contraintes |
|-------|------|-------------|-------------|
| `orderId` | UUID v4 | ✅ | La commande doit appartenir à l'utilisateur |
| `subscriptionId` | UUID v4 | ✅ | Doit correspondre à l'abonnement de la commande |
| `rating` | number | ✅ | Entier entre 1 et 5 |
| `comment` | string | ❌ | Texte libre |

```json
{
  "orderId": "order-uuid",
  "subscriptionId": "sub-uuid",
  "rating": 5,
  "comment": "Excellente cuisine, je recommande vivement !"
}
```

> La commande doit avoir un status autre que `PENDING`.
> Un seul avis par commande.

**Utilisation mobile :** Formulaire avis après commande

**Réponse d'erreur :**
```json
{ "success": false, "message": "Un avis existe déjà pour cette commande", "error": { "code": "REVIEW_ALREADY_EXISTS" } }
```

---

### GET /reviews/subscription/:id — Avis d'un abonnement

**Accès :** public

**Query params :**
- `page` : numéro de page (défaut : 1)
- `limit` : avis par page (défaut : 10, max : 50)

**Utilisation mobile :** Section avis page détail abonnement

**Réponse 200 ✅ :**
```json
{
  "success": true,
  "message": "Avis récupérés avec succès",
  "data": {
    "reviews": [
      {
        "id": "review-uuid",
        "rating": 5,
        "comment": "Excellente cuisine, je recommande vivement !",
        "createdAt": "2024-12-15T10:30:00Z",
        "user": {
          "name": "Adjoua D.",
          "avatar": "https://res.cloudinary.com/..."
        }
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 120,
      "totalPages": 12
    }
  }
}
```

> `user.avatar` peut être `null` — gérer avec un affichage par initiales côté mobile.
> `comment` peut être `null` — seule la note est obligatoire à la création.

---

## Codes d'erreur

| Code | Status HTTP | Description | Action mobile |
|------|-------------|-------------|---------------|
| `INVALID_CREDENTIALS` | 401 | Email/mot de passe incorrect | Message rouge formulaire |
| `INVALID_TOKEN` | 401 | Token invalide ou expiré | Auto-refresh ou re-login |
| `TOKEN_EXPIRED` | 401 | Refresh token expiré | Redirection login |
| `INVALID_PASSWORD` | 401 | Mot de passe actuel incorrect | Message formulaire |
| `ACCOUNT_SUSPENDED` | 403 | Compte suspendu | Message d'erreur + support |
| `FORBIDDEN` | 403 | Action non autorisée | Message d'erreur |
| `INSUFFICIENT_PERMISSIONS` | 403 | Rôle insuffisant | Message d'erreur |
| `PROVIDER_NOT_APPROVED` | 403 | Compte prestataire non approuvé | Écran "En attente" |
| `USER_NOT_FOUND` | 404 | Utilisateur inexistant | Redirection inscription |
| `SUBSCRIPTION_NOT_FOUND` | 404 | Abonnement introuvable | Page 404 |
| `ORDER_NOT_FOUND` | 404 | Commande introuvable | Page 404 |
| `RESOURCE_NOT_FOUND` | 404 | Ressource inexistante | Page 404 ou message |
| `EMAIL_ALREADY_EXISTS` | 409 | Email déjà utilisé | Message formulaire |
| `PHONE_ALREADY_EXISTS` | 409 | Téléphone déjà utilisé | Message formulaire |
| `PROVIDER_EXISTS` | 409 | Déjà enregistré comme prestataire | Rediriger vers écran attente |
| `REVIEW_ALREADY_EXISTS` | 409 | Avis déjà soumis | Masquer bouton avis |
| `ORDER_CANNOT_BE_CANCELLED` | 409 | Commande non annulable | Masquer bouton annuler |
| `INVALID_INPUT` | 400 | Données invalides (voir `message[]`) | Messages sous champs |
| `RATE_LIMIT_EXCEEDED` | 429 | Trop de requêtes (auth : 5/15min) | Attendre 15 minutes |

---

## Flow mobile typique

```
1.  Premier lancement → GET /countries → sélection pays
2.  Sélection ville → GET /countries/:code/cities → choix ville
3.  Inscription → POST /auth/register
    └── isProfileComplete: false → écran complétion profil
4.  Compléter profil → PUT /users/me/location + PUT /users/me/preferences
5.  Page accueil → GET /home?cityId=... (sections popular/recent/providers)
6.  Filtre actif → GET /subscriptions?cityId=...&category=... (bascule sur Explorer)
7.  Détail abonnement → GET /subscriptions/:id (vérifier provider.acceptsDelivery/acceptsPickup)
8.  Commande → POST /auth/login si pas connecté → POST /orders
9.  Suivi statut → GET /orders/me ou GET /orders/:id
10. Activation → order.status === "CONFIRMED" → PUT /orders/:id/activate
11. Abonnement actif → GET /active-subscriptions/me
12. Profil → GET /users/me, PUT /users/me/* pour personnalisation
13. Avis → POST /reviews après commande confirmée
```

---

## Optimisations mobile

- **Caching** : Stocker localement pays/villes (changent rarement)
- **Pagination** : Utiliser `page`/`limit` pour performance (infinite scroll)
- **Images** : URLs Cloudinary optimisées automatiquement
- **Token refresh** : Intercepteur HTTP qui fait `POST /auth/refresh` automatiquement sur 401
- **Retry** : Logic de retry automatique sur échec réseau (backoff exponentiel)

---

*Cette documentation couvre le parcours consommateur de l'app mobile JUNA. Pour le dashboard provider et le panel admin, voir `web-api-documentation.md` et `admin-api-documentation.md`.*

---

## ANNEXE — Libellés et explications UI (types, durées, catégories)

> Pour chaque valeur renvoyée par l'API, le libellé court à afficher en UI et l'explication complète à utiliser dans les tooltips ou pages de détail.

---

### Types d'abonnement — champ `type`

Le type décrit **quels repas de la journée** sont couverts.

| Valeur API | Libellé UI | Repas couverts |
|------------|------------|----------------|
| `BREAKFAST` | Petit-déjeuner | Matin |
| `LUNCH` | Déjeuner | Midi |
| `DINNER` | Dîner | Soir |
| `SNACK` | Collation | Entre les repas |
| `BREAKFAST_LUNCH` | Petit-déjeuner + Déjeuner | Matin + Midi |
| `BREAKFAST_DINNER` | Petit-déjeuner + Dîner | Matin + Soir |
| `LUNCH_DINNER` | Déjeuner + Dîner | Midi + Soir |
| `FULL_DAY` | Journée complète | Matin + Midi + Soir |
| `CUSTOM` | Formule personnalisée | Voir description |

**Explications complètes (tooltips / page détail) :**

**`BREAKFAST` — Petit-déjeuner**
Avec cet abonnement, vous recevez un petit-déjeuner chaque matin. Le prestataire prépare votre repas du matin — pain, œufs, bouillies, jus ou plats locaux — et vous le livre ou le met à disposition à l'heure du petit-déjeuner.

**`LUNCH` — Déjeuner**
Cet abonnement couvre votre repas de midi. Chaque jour, un repas complet préparé par le prestataire vous attend à l'heure du déjeuner. Fini de courir chercher à manger à la pause — votre repas est déjà prêt.

**`DINNER` — Dîner**
Avec cet abonnement, c'est le repas du soir qui est pris en charge. Le prestataire prépare votre dîner et vous le livre ou le met à disposition chaque soir à l'heure convenue. Vous rentrez chez vous — votre repas vous attend.

**`SNACK` — Collation**
Cet abonnement vous fournit une collation quotidienne — un encas, une petite faim de l'après-midi, un jus ou un goûter. Idéal pour tenir entre deux repas sans se soucier de quoi manger.

**`BREAKFAST_LUNCH` — Petit-déjeuner + Déjeuner**
Deux repas par jour : le matin et le midi. Vous commencez la journée avec un petit-déjeuner préparé, et vous retrouvez un déjeuner complet à la pause. Votre matinée et après-midi sont couvertes — il ne reste que le soir.

**`BREAKFAST_DINNER` — Petit-déjeuner + Dîner**
Cet abonnement prend en charge le début et la fin de votre journée. Le matin, un petit-déjeuner pour démarrer. Le soir, un dîner pour terminer. Le déjeuner reste à votre charge.

**`LUNCH_DINNER` — Déjeuner + Dîner**
Deux repas couverts : le midi et le soir. Plus besoin de penser à cuisiner après le travail ni à trouver quelque chose à manger le midi — le prestataire s'occupe des deux. Seul le petit-déjeuner reste à votre charge.

**`FULL_DAY` — Journée complète**
La formule la plus complète : petit-déjeuner, déjeuner et dîner sont tous inclus. Trois repas par jour, préparés par le prestataire, sans que vous ayez à vous soucier de quoi manger du matin au soir.

**`CUSTOM` — Formule personnalisée**
Le prestataire a composé une formule sur mesure. Les détails exacts des repas inclus sont précisés dans la description de l'abonnement. Lisez attentivement le contenu avant de souscrire.

---

### Durées d'abonnement — champ `duration`

La durée indique **sur combien de jours s'étend l'abonnement** à partir de la date de début choisie.

| Valeur API | Libellé UI | Nombre de jours |
|------------|------------|-----------------|
| `DAY` | 1 jour | 1 jour |
| `THREE_DAYS` | 3 jours | 3 jours consécutifs |
| `WEEK` | 1 semaine | 7 jours (week-end inclus) |
| `TWO_WEEKS` | 2 semaines | 14 jours (week-end inclus) |
| `MONTH` | 1 mois | ~30 jours (week-end inclus) |
| `WORK_WEEK` | Semaine de travail (5j) | 5 jours (lun–ven) |
| `WORK_WEEK_2` | 2 semaines de travail (10j) | 10 jours ouvrés |
| `WORK_MONTH` | Mois de travail (20j) | 20 jours ouvrés |
| `WEEKEND` | Week-end (2j) | 2 jours (sam–dim) |

**Explications complètes (tooltips / page détail) :**

**`DAY` — 1 jour**
Un abonnement d'une seule journée. Vous recevez les repas prévus pour une journée uniquement — idéal pour tester un prestataire ou pour un besoin ponctuel sans engagement.

**`THREE_DAYS` — 3 jours**
L'abonnement court sur 3 jours consécutifs. Pratique pour un début de semaine, une courte période ou un premier essai prolongé.

**`WEEK` — 1 semaine**
L'abonnement s'étend sur 7 jours complets, week-end inclus. Vous êtes couvert du lundi au dimanche sans interruption.

**`TWO_WEEKS` — 2 semaines**
Deux semaines complètes, soit 14 jours consécutifs, week-end inclus. Une bonne option pour tester un prestataire sur une durée significative avant de s'engager sur un mois.

**`MONTH` — 1 mois**
Un mois complet de repas, soit environ 30 jours consécutifs, week-end inclus. L'engagement le plus long dans la formule classique.

**`WORK_WEEK` — Semaine de travail (5 jours)**
Cet abonnement couvre exactement une semaine de travail : du lundi au vendredi, soit 5 jours. Le week-end n'est pas inclus. Parfait pour être bien nourri pendant la semaine active sans payer pour les jours de repos.

**`WORK_WEEK_2` — 2 semaines de travail (10 jours)**
Deux semaines de travail consécutives, soit 10 jours ouvrés (lundi à vendredi, deux fois). Les week-ends sont exclus.

**`WORK_MONTH` — Mois de travail (20 jours)**
Un mois entier de jours de travail, soit 20 jours ouvrés — 5 jours par semaine pendant 4 semaines. Les week-ends ne sont pas inclus. La formule idéale pour les actifs qui veulent être couverts tout le mois sans payer les jours de repos.

**`WEEKEND` — Week-end (2 jours)**
Cet abonnement couvre uniquement le week-end : le samedi et le dimanche. Les jours de semaine ne sont pas inclus. Idéal pour se faire plaisir les jours de repos.

---

### Catégories culinaires — champ `category`

| Valeur API | Libellé UI |
|------------|------------|
| `AFRICAN` | Cuisine africaine |
| `EUROPEAN` | Cuisine européenne |
| `ASIAN` | Cuisine asiatique |
| `AMERICAN` | Cuisine américaine |
| `FUSION` | Cuisine fusion |
| `VEGETARIAN` | Végétarien |
| `VEGAN` | Vegan |
| `HALAL` | Halal |
| `OTHER` | Autre |

**Explications complètes (tooltips / filtres) :**

**`AFRICAN` — Cuisine africaine**
Des plats inspirés des traditions culinaires africaines — riz, sauces, attiéké, igname, plantain, viandes et poissons préparés selon les recettes locales. Une cuisine authentique, généreuse et savoureuse.

**`EUROPEAN` — Cuisine européenne**
Des plats d'inspiration européenne — pâtes, grillades, salades composées, sandwichs élaborés, soupes. Un style occidental adapté aux saveurs d'Europe.

**`ASIAN` — Cuisine asiatique**
Des spécialités d'Asie — riz cantonnais, nouilles, plats sautés, soupes asiatiques, rouleaux. Des saveurs umami, épicées ou sucrées-salées.

**`AMERICAN` — Cuisine américaine**
Un style inspiré de la cuisine américaine — burgers, wraps, poulet frit, frites, plats généreux et comfort food. Des portions copieuses et des saveurs directes.

**`FUSION` — Cuisine fusion**
Un mélange créatif entre plusieurs traditions culinaires. Le prestataire combine des influences africaines, asiatiques, européennes ou autres pour créer des plats originaux. Idéal pour ceux qui aiment la variété et la découverte.

**`VEGETARIAN` — Végétarien**
Tous les plats sont sans viande ni poisson. Des légumes, légumineuses, œufs et produits laitiers composent les repas. Idéal pour les personnes qui ne consomment pas de chair animale.

**`VEGAN` — Vegan**
Aucun produit d'origine animale — ni viande, ni poisson, ni œufs, ni produits laitiers. Une alimentation 100 % végétale.

**`HALAL` — Halal**
Tous les repas sont préparés selon les règles alimentaires halal. Les viandes sont abattues et traitées conformément aux prescriptions islamiques.

**`OTHER` — Autre**
Le prestataire propose une cuisine qui ne rentre pas dans les catégories listées. Consultez la description de l'abonnement pour connaître le style exact des repas proposés.
