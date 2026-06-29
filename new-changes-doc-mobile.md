# Nouveaux changements API — App Mobile

> Ce fichier recense tous les changements API récents qui impactent l'app mobile.
> L'app mobile est destinée aux **consommateurs** : découverte, abonnements, paiements.
> Les plus récents sont en haut.

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
