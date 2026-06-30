# Nouveaux changements API — App Mobile

> Ce fichier recense tous les changements API récents qui impactent l'app mobile.
> L'app mobile est destinée aux **consommateurs** : découverte, abonnements, paiements.
> Les plus récents sont en haut.

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
