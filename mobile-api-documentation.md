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
  "message": "Message lisible",
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
| `GET` | `/subscriptions` | public | Lister abonnements | Page d'accueil, Explorer |
| `GET` | `/subscriptions/:id` | public | Détail abonnement | Page détail abonnement |
| `POST` | `/orders` | auth | Créer commande | Flow de commande |
| `GET` | `/orders/me` | auth | Mes commandes | Page "Mes commandes" |
| `GET` | `/orders/:id` | auth | Détail commande | Détail commande + QR |
| `PUT` | `/orders/:id/cancel` | auth | Annuler commande | Bouton annuler |
| `POST` | `/reviews` | auth | Créer avis | Laisser avis commande |
| `GET` | `/reviews/subscription/:id` | public | Avis abonnement | Page détail abonnement |
| `POST` | `/upload/image` | auth | Upload image | Photo de profil |
| `GET` | `/notifications` | auth | Mes notifications | Page notifications |
| `PUT` | `/notifications/:id/read` | auth | Marquer lu | Action notification |
| `PUT` | `/notifications/read-all` | auth | Tout marquer lu | Bouton "Tout lire" |
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

## PARTIE 1 — AUTHENTIFICATION (Mobile Critical)

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

## PARTIE 2 — ABONNEMENTS (Mobile Core)

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

## PARTIE 3 — COMMANDES (Mobile Transaction)

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

## PARTIE 4 — AVIS & NOTIFICATIONS

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

## PARTIE 5 — UPLOAD & PROVIDER

### POST /upload/image — Upload image

**Accès :** auth

**Content-Type :** multipart/form-data

**Utilisation mobile :** Photo de profil, logo provider

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
2. Sélection ville → GET /cities → choix ville
3. Page accueil → GET /subscriptions (filtres géographiques)
4. Détail abonnement → GET /subscriptions/:id
5. S'abonner → POST /auth/login si pas connecté
6. Commande → POST /orders
7. Suivi → GET /orders/me
8. Notifications → GET /notifications
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