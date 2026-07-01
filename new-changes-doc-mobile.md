# Nouveaux changements API — App Mobile

> Ce fichier recense tous les changements API récents qui impactent l'app mobile.
> L'app mobile est destinée aux **consommateurs** : découverte, abonnements, paiements.
> Les plus récents sont en haut.

---

## [2026-06-30] Nouvelle feature — Propositions d'abonnement (composer un abonnement sur mesure)

### Contexte

Sur la page profil d'un provider (`GET /api/v1/providers/:id`), le user peut désormais composer une **proposition d'abonnement personnalisé** à partir des plats du catalogue de ce provider, plutôt que de se limiter aux abonnements déjà publiés. Le provider reçoit la proposition, peut l'ajuster, fixe librement le prix, puis l'approuve ou la rejette.

Si la proposition est approuvée, un **nouvel abonnement public** est créé et devient immédiatement visible/souscriptible par tout le monde dans le catalogue du provider (ce n'est pas un abonnement privé réservé au demandeur). L'user est notifié dans tous les cas (approbation ou rejet).

### Toutes les routes nécessitent une authentification (`Authorization: Bearer <token>`)

| Méthode | Route | Usage |
|--------|-------|-------|
| `POST` | `/api/v1/subscription-proposals` | Créer une proposition |
| `GET` | `/api/v1/subscription-proposals/me` | Mes propositions envoyées (paginé) |
| `GET` | `/api/v1/subscription-proposals/:id` | Détail d'une proposition (si j'en suis l'auteur) |

> Les routes `GET /received`, `POST /:id/approve` et `POST /:id/reject` sont réservées aux providers (Dashboard web) — pas utilisées côté mobile.

### Créer une proposition — `POST /api/v1/subscription-proposals`

```json
{
  "providerId": "uuid",
  "type": "LUNCH",
  "category": "AFRICAN",
  "duration": "WORK_WEEK",
  "message": "Tous les midis du lundi au vendredi svp",
  "meals": [
    { "mealId": "uuid", "quantity": 1 },
    { "mealId": "uuid", "mealPricingLabel": "Demi", "quantity": 1 }
  ]
}
```

- `type`, `category`, `duration` : mêmes enums que pour un abonnement classique.
- `message` : optionnel, note libre pour expliquer ce que le user souhaite.
- `meals` : 1 à 20 plats du catalogue du provider ciblé (doivent être actifs).
- `mealPricingLabel` : **obligatoire** si le plat choisi a `priceType: "MULTIPLE"` (le label d'une variante existante, ex: "Demi", "Entier"), **à ne pas envoyer** sinon.
- Réponse `201 Created` avec la proposition créée (statut `PENDING`).

### Suivre mes propositions — `GET /api/v1/subscription-proposals/me`

Query params optionnels : `?status=PENDING&page=1&limit=20` (`status` ∈ `PENDING` / `APPROVED` / `REJECTED`).

```json
{
  "data": [
    {
      "id": "uuid",
      "type": "LUNCH",
      "category": "AFRICAN",
      "duration": "WORK_WEEK",
      "message": "...",
      "status": "PENDING",
      "rejectionReason": null,
      "resultingSubscriptionId": null,
      "provider": { "id": "uuid", "businessName": "K'foods", "logo": "https://..." },
      "meals": [
        {
          "mealId": "uuid",
          "mealPricingLabel": "Demi",
          "quantity": 1,
          "meal": { "id": "uuid", "name": "Poulet braisé", "imageUrl": "https://...", "priceType": "MULTIPLE", "price": 1500 }
        }
      ],
      "createdAt": "..."
    }
  ],
  "total": 3,
  "page": 1,
  "totalPages": 1
}
```

### Affichage recommandé selon `status`

| `status` | Affichage |
|----------|-----------|
| `PENDING` | "En attente de réponse du prestataire" |
| `APPROVED` | "Acceptée — disponible dans le catalogue" → lien vers `GET /api/v1/subscriptions/:resultingSubscriptionId` |
| `REJECTED` | "Non retenue" + afficher `rejectionReason` |

### Notifications reçues par le user

| Événement | `NotificationType` |
|-----------|---------------------|
| Proposition approuvée | `SUBSCRIPTION_PROPOSAL_APPROVED` |
| Proposition rejetée | `SUBSCRIPTION_PROPOSAL_REJECTED` |

Le `data` de la notification contient `proposalId` (et `subscriptionId` en cas d'approbation) pour naviguer directement vers le bon écran.

### Erreurs notables

| Cas | Code | Statut HTTP |
|-----|------|-------------|
| Provider non trouvé / pas encore approuvé par l'admin | `PROVIDER_NOT_FOUND` / `PROVIDER_NOT_APPROVED` | 404 / 403 |
| Plat invalide (hors catalogue du provider, inactif, variante de prix manquante ou incorrecte) | `INVALID_INPUT` | 409 |
| Proposition introuvable | `SUBSCRIPTION_PROPOSAL_NOT_FOUND` | 404 |
| Tentative de consulter la proposition d'un autre user | `FORBIDDEN` | 403 |

---

## [2026-06-30] Fix — `provider` incomplet sur les routes plats

### Routes concernées

**`GET /api/v1/meals/:id`** et **`GET /api/v1/meals`**

### Ce qui a changé

L'objet `provider` imbriqué ne contenait que `id` et `businessName`. Il inclut maintenant `logo` et `isVerified`, comme dans `GET /api/v1/subscriptions`.

```json
{
  "id": "uuid",
  "businessName": "K'foods",
  "logo": "https://...",
  "isVerified": true
}
```

Permet d'afficher la vraie photo de profil (au lieu des initiales) et le badge de certification sur la carte "Proposé par {provider}" de la page détail d'un plat.

---

## [2026-06-30] Fix — `isVerified` manquant sur le profil public d'un prestataire

### Route concernée

**`GET /api/v1/providers/:id`**

### Ce qui a changé

Le champ `isVerified` (boolean) était absent de la réponse. Il est maintenant inclus, au même niveau que `businessName`, `logo`, etc. — dérivé du statut du prestataire (`status === 'APPROVED'`).

```json
{
  "id": "uuid",
  "businessName": "K'foods",
  "isVerified": true,
  "logo": "https://...",
  "...": "..."
}
```

Permet d'afficher le badge de certification bleu sur la page profil public.

---

## [2026-06-29] Route home — prestataires de la ville désormais peuplés

### Route concernée

**`GET /api/v1/home?cityId=<uuid>`**

### Ce qui a changé

Le champ `providers` dans la réponse était retourné vide `[]`. Il est maintenant peuplé avec les prestataires approuvés de la ville demandée, triés par rating.

### Structure du champ `providers`

```json
{
  "providers": [
    {
      "id": "uuid",
      "name": "Restaurant Chez Maman",
      "logo": "https://...",
      "rating": 4.5,
      "isVerified": true,
      "city": "Cotonou"
    }
  ]
}
```

---

## [2026-06-29] Page publique d'un prestataire

### Nouvelle route

**`GET /api/v1/providers/:id`** — publique, sans authentification

### Réponse complète

```json
{
  "id": "uuid",
  "businessName": "Restaurant Chez Maman",
  "description": "Le meilleur du terroir béninois",
  "logo": "https://...",
  "businessAddress": "Rue des Cocotiers, Cotonou",
  "rating": 4.5,
  "reviewCount": 38,
  "acceptsDelivery": true,
  "acceptsPickup": true,
  "deliveryZones": ["Fidjrossè", "Cadjehoun"],
  "memberSince": "2025-01-15T10:00:00Z",
  "city": {
    "id": "uuid",
    "name": "Cotonou",
    "country": {
      "id": "uuid",
      "code": "BJ",
      "translations": { "fr": "Bénin", "en": "Benin" }
    }
  },
  "pickupPoints": [
    { "id": "uuid", "name": "Marché Dantokpa" }
  ],
  "subscriptions": [
    {
      "id": "uuid",
      "name": "Abonnement midi semaine",
      "description": "Un repas chaud chaque midi du lundi au vendredi",
      "price": 25000,
      "type": "LUNCH",
      "category": "AFRICAN",
      "duration": "WORK_WEEK",
      "imageUrl": "https://...",
      "rating": 4.7,
      "reviewCount": 12,
      "preparationHours": 2,
      "meals": [
        {
          "id": "uuid",
          "name": "Riz au gras",
          "description": "Riz bien assaisonné",
          "imageUrl": "https://...",
          "mealType": "LUNCH",
          "priceType": "FIXED",
          "price": 1500,
          "priceMin": null,
          "priceMax": null,
          "priceGuideline": null,
          "pricings": []
        }
      ]
    }
  ],
  "meals": [
    {
      "id": "uuid",
      "name": "Poulet braisé",
      "description": "Poulet mariné grillé au charbon",
      "imageUrl": "https://...",
      "mealType": "LUNCH",
      "priceType": "MULTIPLE",
      "price": 1500,
      "priceMin": null,
      "priceMax": null,
      "priceGuideline": "La différence est la taille de la portion",
      "pricings": [
        { "id": "uuid", "label": "Quart", "price": 1500 },
        { "id": "uuid", "label": "Demi", "price": 2500 },
        { "id": "uuid", "label": "Entier", "price": 4500 }
      ]
    }
  ]
}
```

### Navigation depuis le profil

Chaque abonnement et chaque plat retournés contiennent un `id`. Le mobile peut s'en servir pour naviguer vers les pages de détail :

| Cible | Route |
|-------|-------|
| Détail d'un abonnement | `GET /api/v1/subscriptions/:id` |
| Détail d'un plat | `GET /api/v1/meals/:id` |

Ces deux routes sont **publiques** (sans authentification). Le détail d'un plat inclut tous les champs de prix (`priceType`, `price`, `priceMin`, `priceMax`, `priceGuideline`, `pricings`).

### Notes
- Seuls les prestataires avec statut `APPROVED` sont accessibles via cette route.
- `subscriptions` ne contient que les abonnements `isActive: true` et `isPublic: true`, triés par rating.
- `meals` ne contient que les plats `isActive: true`.
- Si le prestataire n'existe pas ou n'est pas approuvé → `404`.

---

## [2026-06-29] Prix flexibles sur les plats

### Contexte
Les plats des providers peuvent maintenant avoir trois types de prix. L'app mobile doit adapter l'affichage selon le `priceType` reçu.

### Routes impactées

| Méthode | Route | Usage |
|--------|-------|-------|
| `GET` | `/api/v1/meals/:id` | Détail d'un plat |
| `GET` | `/api/v1/meals` | Liste des plats (avec filtres) |
| `GET` | `/api/v1/subscriptions/:id` | Détail abonnement — le tableau `meals` inclut maintenant les prix |

### Structure d'un plat reçu

```json
{
  "id": "uuid",
  "name": "Poulet braisé",
  "description": "...",
  "imageUrl": "https://...",
  "priceType": "MULTIPLE",
  "price": 1500,
  "priceMin": null,
  "priceMax": null,
  "priceGuideline": "La différence est la taille de la portion",
  "pricings": [
    { "id": "uuid", "label": "Quart", "price": 1500 },
    { "id": "uuid", "label": "Demi", "price": 2500 },
    { "id": "uuid", "label": "Entier", "price": 4500 }
  ]
}
```

> Pour `FIXED` et `RANGE`, `pricings` est toujours `[]`.
> Pour `RANGE`, `priceMin` et `priceMax` sont renseignés, `pricings` est `[]`.

### Affichage recommandé

| `priceType` | Affichage |
|-------------|-----------|
| `FIXED` | `1 500 FCFA` |
| `MULTIPLE` | `À partir de 1 500 FCFA` + liste des variantes |
| `RANGE` | `1 000 – 6 000 FCFA` |

Si `priceGuideline` est renseigné, l'afficher comme note sous le prix.
