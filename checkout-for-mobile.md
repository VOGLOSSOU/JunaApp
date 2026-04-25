# Checkout Flow — Documentation complète pour Flutter

> Référence d'implémentation basée sur la version web fonctionnelle.  
> Toutes les routes, valeurs, écrans et comportements sont ceux en production.

---

## Table des matières

1. [Vue d'ensemble du flow](#1-vue-densemble-du-flow)
2. [Écran 1 — Page de commande (formulaire)](#2-écran-1--page-de-commande-formulaire)
3. [Écran 2 — Saisie du numéro Mobile Money](#3-écran-2--saisie-du-numéro-mobile-money)
4. [Écran 3 — Traitement du paiement (polling)](#4-écran-3--traitement-du-paiement-polling)
5. [Écran 4 — Échec du paiement](#5-écran-4--échec-du-paiement)
6. [Écran 5 — Confirmation finale](#6-écran-5--confirmation-finale)
7. [Toutes les routes API](#7-toutes-les-routes-api)
8. [Méthodes de paiement & providers PawaPay](#8-méthodes-de-paiement--providers-pawapay)
9. [Format du numéro de téléphone](#9-format-du-numéro-de-téléphone)
10. [Statuts et gestion des erreurs](#10-statuts-et-gestion-des-erreurs)
11. [Couleurs et design system](#11-couleurs-et-design-system)

---

## 1. Vue d'ensemble du flow

L'user arrive ici depuis la page détail d'un abonnement après avoir cliqué sur **"S'abonner"**.

```
Page détail abonnement
        │
        ▼ clic "S'abonner"
┌───────────────────────┐
│  Écran 1 : Formulaire │  ← mode livraison + adresse + méthode paiement
│  POST /orders         │
└───────────┬───────────┘
            │
     ┌──────┴──────┐
     │             │
   CASH        Mobile Money
     │             │
     ▼             ▼
Confirmation  ┌───────────────────────────┐
              │  Écran 2 : Numéro MM      │  ← pays + numéro local
              │  POST /payments/initiate  │
              └───────────┬───────────────┘
                          │
                          ▼
              ┌───────────────────────────┐
              │  Écran 3 : Processing     │  ← spinner + polling toutes les 5s
              │  GET /payments/:id/status │
              └───────────┬───────────────┘
                          │
              ┌───────────┴───────────┐
              │                       │
           SUCCESS                 FAILED / TIMEOUT
              │                       │
              ▼                       ▼
        Confirmation            Écran 4 : Échec
                                      │
                                      ▼
                                  Réessayer → Écran 2
```

Une fois la commande CONFIRMED (via webhook backend) :
- L'user voit sa commande avec statut CONFIRMED
- Il clique **"Activer"** → `PUT /orders/:id/activate`
- La commande passe en ACTIVE et un ActiveSubscription est créé automatiquement

---

## 2. Écran 1 — Page de commande (formulaire)

### Déclencheur
L'user arrive ici avec l'`id` de l'abonnement (passé en paramètre depuis la page détail).  
Premier appel à faire : charger l'abonnement complet.

```
GET /api/v1/subscriptions/:subscriptionId
Authorization: Bearer <token>
```

Cet appel retourne notamment les `deliveryZones` du prestataire, nécessaires pour le sélecteur de ville.

---

### Layout général
- Fond : `#F5F5F5` (gris très clair)
- Padding horizontal : 24px
- Padding vertical : 40px
- Largeur max : 672px, centrée
- Les sections sont des **cartes blanches** (`#FFFFFF`) avec bordure `#E5E7EB`, coins arrondis 12px, padding 20px, empilées verticalement avec un espacement de 24px entre elles

---

### Section 1 — Récapitulatif de l'abonnement

Carte blanche en haut. Contenu en ligne :
- **Gauche** : image de l'abonnement, 96×80px, coins 8px, `object-fit: cover`. Si pas d'image : fond gris `#F5F5F5` avec icône avion centré couleur `#BDBDBD`
- **Droite** :
  - Nom de l'abonnement : 16px, `font-weight: 600`, `#1C1C1C`
  - Nom du prestataire : 12px, `#757575`
  - 2 badges côte à côte :
    - Type (ex: Déjeuner) : fond `#1A5C2A`, texte blanc, 12px, coins full, padding 8px horizontal 2px vertical
    - Durée (ex: 1 semaine) : fond `#F5F5F5`, texte `#757575`, même style
  - Prix : 16px, `font-weight: 700`, couleur `#1A5C2A`

---

### Section 2 — Mode de livraison

Titre : `Mode de livraison`, 16px, `font-weight: 600`

**2 boutons en grille 2 colonnes :**

| État | Bordure | Fond | Texte |
|---|---|---|---|
| Non sélectionné | `#E5E7EB` 2px | `#FFFFFF` | `#757575` |
| Sélectionné | `#1A5C2A` 2px | `rgba(26,92,42,0.08)` | `#1A5C2A` |

- **Bouton Livraison à domicile** : icône camion (Truck) 20px + label centré
- **Bouton Retrait sur place** : icône MapPin 20px + label centré

---

#### Si "Livraison à domicile" sélectionné — sélecteur de zones

Les zones viennent de `subscription.deliveryZones` retourné par l'API.  
Chaque zone est un objet `{ city: string, cost: number }`.

**Affichage des zones :**  
Liste verticale de boutons sélectionnables. Chaque bouton :
- Gauche : nom de la ville, 14px, `font-weight: 500`
- Droite : coût de livraison, 12px, `font-weight: 600`
  - Si `cost === 0` : afficher `"Gratuit"` en vert `#1A5C2A`
  - Sinon : afficher `"+ 500 XOF"` en gris `#757575` (ou vert si sélectionné)

**États du bouton zone :**

| État | Bordure | Fond | Texte |
|---|---|---|---|
| Non sélectionné | `#E5E7EB` 2px | `#FFFFFF` | `#1C1C1C` |
| Sélectionné | `#1A5C2A` 2px | `rgba(26,92,42,0.08)` | `#1A5C2A` |

**Champ adresse précise** (apparaît sous le sélecteur de zone) :
- Label : `Adresse précise *`, 14px, `font-weight: 500`
- Input texte, hauteur 44px, bordure `#E5E7EB` 1px, coins 8px, padding 16px
- Placeholder : `"Ex : Rue 234, Quartier Cadjehoun"`
- Focus : bordure `#1A5C2A` 2px

---

#### Message informatif livraison

Affiché sous la section livraison si "Livraison à domicile" est sélectionné.  
Carte avec fond `#F0FDF4`, bordure `#BBF7D0` :
- Icône info (cercle avec `?`) vert `#1A5C2A`, 14px, dans un cercle 24px fond `#DCFCE7`
- Titre : `"Information importante sur la livraison"`, 14px, `font-weight: 600`, `#14532D`
- Corps : `"Si vous souhaitez être livré durant toute la période de votre abonnement, cela sera discuté directement avec le fournisseur de repas qui vous communiquera les frais et modalités."`, 14px, `#166534`

---

### Section 3 — Date de début

Titre : `Date de début`, 16px, `font-weight: 600`

Checkbox : `Démarrer dès que possible` (coché par défaut)  
- Si décoché → afficher un date-time picker

---

### Section 4 — Méthode de paiement

Titre : `Méthode de paiement`, 16px, `font-weight: 600`

Liste de radio buttons (une option par ligne) :

| Valeur | Label |
|---|---|
| `MOBILE_MONEY_MTN` | MTN Mobile Money |
| `MOBILE_MONEY_MOOV` | Moov Money |
| `MOBILE_MONEY_ORANGE` | Orange Money |
| `MOBILE_MONEY_WAVE` | Wave |
| `CASH` | Espèces à la livraison |

Chaque option : carte avec bordure 2px, padding 12px, coins 8px  
- Non sélectionnée : bordure `#E5E7EB`
- Sélectionnée : bordure `#1A5C2A`, fond `rgba(26,92,42,0.08)`
- Radio + label 14px `font-weight: 500`

Note sous la liste (si Mobile Money sélectionné) :  
`"Vous serez redirigé vers la saisie de votre numéro Mobile Money après confirmation."` — 12px, `#757575`

---

### Section 5 — Récapitulatif total & bouton CTA

- Ligne : `Abonnement` (gauche, 14px gris) + montant (droite, 14px `font-weight: 500`)
- Si livraison + zone sélectionnée : ligne `Frais de livraison (Cotonou)` + `"Négociés avec le prestataire"` en orange `#F97316`
- Séparateur 1px `#E5E7EB`
- **Total à payer maintenant** : 16px `font-weight: 600` + montant en gros 20px bold vert `#1A5C2A`
- **Bouton CTA** full-width, hauteur 52px, coins 12px, fond `#1A5C2A`, texte blanc 16px bold :
  - Si CASH → `"Confirmer la commande"`
  - Si Mobile Money → `"Continuer vers le paiement"`

---

### Validations avant de soumettre

- Si livraison : une zone doit être sélectionnée (sinon toast erreur `"Choisissez une ville de livraison"`)
- Si livraison : l'adresse précise doit être renseignée (sinon toast `"Renseignez votre adresse précise"`)

---

### Appel API à la soumission

```
POST /api/v1/orders
Authorization: Bearer <token>
Content-Type: application/json
```

**Body pour livraison :**
```json
{
  "subscriptionId": "uuid-abonnement",
  "deliveryMethod": "DELIVERY",
  "deliveryAddress": "Rue 234, Quartier Cadjehoun",
  "deliveryCity": "Cotonou",
  "startAsap": true
}
```

**Body pour retrait :**
```json
{
  "subscriptionId": "uuid-abonnement",
  "deliveryMethod": "PICKUP",
  "pickupLocation": "Adresse physique du prestataire",
  "startAsap": true
}
```

> ⚠️ **Ne jamais envoyer `paymentMethod` dans ce body** — le backend renvoie une erreur 400.

**Réponse succès :**
```json
{
  "success": true,
  "data": {
    "id": "uuid-commande",
    "orderNumber": "ORD-XXXX",
    "status": "PENDING",
    "deliveryMethod": "DELIVERY",
    "deliveryCity": "Cotonou",
    "deliveryAddress": "Rue 234, Quartier Cadjehoun",
    "amount": 15000,
    "currency": "XOF",
    "createdAt": "2024-01-15T10:30:00Z"
  }
}
```

Conserver l'`id` de la commande → c'est l'`orderId` utilisé dans toutes les étapes suivantes.

**Si CASH** : naviguer directement vers l'écran de confirmation avec l'`orderId`.  
**Si Mobile Money** : naviguer vers l'Écran 2.

---

## 3. Écran 2 — Saisie du numéro Mobile Money

### Déclencheur
Arrive ici après création réussie de la commande (Mobile Money uniquement).

---

### Layout
- Fond : `#F5F5F5`
- Largeur max : 448px, centrée
- Padding : 24px horizontal, 40px vertical
- Espacement entre sections : 24px

---

### Titre
- `"Payer par Mobile Money"` : 24px, `font-weight: 600`, `#1C1C1C`
- Sous-titre : `"Entrez le numéro associé à votre compte Mobile Money."` — 14px, `#757575`

---

### Carte récapitulatif (mini)

Carte blanche, bordure `#E5E7EB`, coins 12px, padding 20px, contenu en ligne :
- Image abonnement : 64×56px, coins 8px
- Nom abonnement : 14px `font-weight: 600`
- Nom provider : 12px `#757575`
- Prix total : 16px bold vert `#1A5C2A`

---

### Formulaire numéro

Carte blanche, bordure `#E5E7EB`, coins 12px, padding 20px.

**Sélecteur de pays :**
- Label : `"Pays *"`, 14px, `font-weight: 500`
- Dropdown avec 3 options :

| Code | Label dans la liste |
|---|---|
| `BEN` | Bénin (+229) |
| `CIV` | Côte d'Ivoire (+225) |
| `SEN` | Sénégal (+221) |

**Champ numéro :**
- Label : `"Numéro Mobile Money *"`, 14px, `font-weight: 500`
- Input en ligne :
  - Préfixe fixe (non éditable) : `+229` (ou selon pays sélectionné), fond `#F5F5F5`, bordure droite `#E5E7EB`, padding 12px, 14px `font-weight: 600`, `#757575`
  - Champ texte : numérique uniquement, placeholder `"97123456"`, 14px
- Bordure globale `#E5E7EB` 2px, coins 8px — devient `#1A5C2A` au focus
- Note sous le champ : `"Numéro sans indicatif ni zéro initial"`, 12px, `#757575`

---

### Bouton payer

Full-width, hauteur 52px, coins 12px, fond `#1A5C2A`, texte blanc 16px bold :  
`"Payer 15 000 XOF"` (montant dynamique)

Lien retour sous le bouton :  
`"Retour"` — 14px, `#757575`, souligné, centré → revient à l'Écran 1

---

### Appel API

```
POST /api/v1/payments/initiate
Authorization: Bearer <token>
Content-Type: application/json
```

Body :
```json
{
  "orderId": "uuid-commande",
  "phoneNumber": "22997123456",
  "provider": "MTN_MOMO_BEN"
}
```

**Réponse succès :**
```json
{
  "success": true,
  "data": {
    "paymentId": "uuid-paiement",
    "depositId": "uuid",
    "status": "PROCESSING",
    "message": "..."
  }
}
```

Conserver le `paymentId` → utilisé pour le polling. Naviguer vers l'Écran 3.

---

## 4. Écran 3 — Traitement du paiement (polling)

### Layout
- Fond : `#F5F5F5`
- Contenu centré verticalement et horizontalement
- Largeur max : 448px
- Padding : 24px horizontal, 80px vertical

---

### Contenu (centré, colonne)

**Icône spinner :**
- Cercle 80×80px, fond `rgba(26,92,42,0.08)`
- À l'intérieur : icône de chargement (CircularProgressIndicator) couleur `#1A5C2A`, taille 36px
- Animation de rotation en continu

**Titre :** `"Validation en cours…"` — 20px, `font-weight: 600`, `#1C1C1C`

**Description :**
```
"Une demande de confirmation a été envoyée sur votre téléphone.
Saisissez votre code PIN Mobile Money pour valider le paiement."
```
14px, `#757575`, interligne 1.6, centré

**Carte info paiement :**
Fond `#F5F5F5`, coins 12px, padding 16px :
- `"Montant à payer"`, 12px, `#757575`
- Montant : 20px, bold, `#1A5C2A`
- Numéro : `"+22997123456"`, 12px, `#757575`

**Lien discret en bas :**  
`"Voir mes commandes"` — 14px, `#757575`, souligné → naviguer vers la liste des commandes

---

### Logique de polling

```
Démarrer dès réception du paymentId

Toutes les 5 secondes :
  GET /api/v1/payments/:paymentId/status

  Si status === "SUCCESS"
    → Naviguer vers Écran 5 (confirmation) avec orderId
    → Arrêter le polling

  Si status === "FAILED"
    → Message : "Le paiement a échoué. Vérifiez votre solde et réessayez."
    → Naviguer vers Écran 4 (échec)
    → Arrêter le polling

  Si erreur réseau
    → Ignorer, retenter au prochain intervalle

Après 3 minutes (180 secondes) sans résultat :
  → Message : "Le paiement prend plus de temps que prévu. Vérifiez votre historique de transactions."
  → Naviguer vers Écran 4 (échec)
  → Arrêter le polling
```

---

## 5. Écran 4 — Échec du paiement

### Layout
Même layout que l'Écran 3 (centré, largeur 448px, padding 80px vertical).

---

### Contenu

**Icône erreur :**
- Cercle 80×80px, fond `#FEF2F2`
- À l'intérieur : icône X (Close) couleur `#EF4444`, taille 36px, dans un cercle

**Titre :** `"Paiement échoué"` — 20px, `font-weight: 600`, `#1C1C1C`

**Message d'erreur :** (dynamique selon la cause)
- Paiement FAILED : `"Le paiement a échoué. Vérifiez votre solde et réessayez."`
- Timeout : `"Le paiement prend plus de temps que prévu. Vérifiez votre historique de transactions."`

14px, `#757575`, centré

**2 boutons empilés :**
1. **"Réessayer"** — full-width, hauteur 52px, fond `#1A5C2A`, texte blanc, coins 12px  
   → Rappelle `POST /payments/initiate` avec le même `orderId` (ne pas recréer une commande)  
   → Retourne à l'Écran 3

2. **"Voir mes commandes"** — full-width, hauteur 52px, bordure `#E5E7EB` 2px, fond blanc, texte `#1C1C1C`, coins 12px  
   → Naviguer vers la liste des commandes

---

## 6. Écran 5 — Confirmation finale

Naviguer vers la page de détail de la commande avec l'`orderId`.  
La commande sera en statut `PENDING` puis passera en `CONFIRMED` automatiquement via le webhook backend.

L'user devra ensuite cliquer sur **"Activer"** depuis la page de détail commande.

---

## 7. Toutes les routes API

### Base URL
```
https://juna-app.up.railway.app/api/v1
```

Toutes les routes nécessitent le header :
```
Authorization: Bearer <access_token>
```

---

| Route | Méthode | Description |
|---|---|---|
| `/subscriptions/:id` | GET | Charger l'abonnement (inclut deliveryZones) |
| `/orders` | POST | Créer la commande |
| `/payments/initiate` | POST | Initier le paiement PawaPay |
| `/payments/:paymentId/status` | GET | Vérifier le statut du paiement (polling) |
| `/orders/:id` | GET | Détail d'une commande |
| `/orders/:id/activate` | PUT | Activer la commande (CONFIRMED → ACTIVE) |
| `/active-subscriptions/me` | GET | Liste des abonnements actifs de l'user |

---

## 8. Méthodes de paiement & providers PawaPay

### Méthodes disponibles

| Valeur API | Label affiché |
|---|---|
| `MOBILE_MONEY_MTN` | MTN Mobile Money |
| `MOBILE_MONEY_MOOV` | Moov Money |
| `MOBILE_MONEY_ORANGE` | Orange Money |
| `MOBILE_MONEY_WAVE` | Wave |
| `CASH` | Espèces à la livraison |

---

### Table méthode + pays → provider PawaPay

Ce mapping est géré **côté client**. C'est le `provider` envoyé dans `POST /payments/initiate`.

| Méthode | Pays | Provider PawaPay |
|---|---|---|
| `MOBILE_MONEY_MTN` | Bénin (BEN) | `MTN_MOMO_BEN` |
| `MOBILE_MONEY_MTN` | Côte d'Ivoire (CIV) | `MTN_MOMO_CIV` |
| `MOBILE_MONEY_MTN` | Sénégal (SEN) | `MTN_MOMO_SEN` |
| `MOBILE_MONEY_MOOV` | Bénin (BEN) | `MOOV_BEN` |
| `MOBILE_MONEY_MOOV` | Côte d'Ivoire (CIV) | `MOOV_CIV` |
| `MOBILE_MONEY_ORANGE` | Côte d'Ivoire (CIV) | `ORANGE_CIV` |
| `MOBILE_MONEY_ORANGE` | Sénégal (SEN) | `ORANGE_SEN` |

Si la combinaison méthode + pays ne retourne pas de provider → ne pas afficher cette méthode ou désactiver le bouton.

---

## 9. Format du numéro de téléphone

Le champ `phoneNumber` envoyé à l'API doit être au format **MSISDN** :  
`indicatif_pays` + `numéro_local_sans_zéro_initial`, sans `+`, sans espaces.

| Pays | Indicatif | Saisie user | MSISDN envoyé |
|---|---|---|---|
| Bénin | 229 | `97123456` | `22997123456` |
| Côte d'Ivoire | 225 | `0712345678` | `2250712345678` |
| Sénégal | 221 | `771234567` | `221771234567` |

Construction : `phoneNumber = indicatif + localNumber.replaceAll(" ", "")`

### Numéros de test (sandbox PawaPay)

L'environnement actuel est **sandbox**. Aucun argent réel n'est débité.  
En sandbox, il n'y a pas de demande de PIN sur le téléphone — le résultat arrive automatiquement en quelques secondes.

| Numéro | Opérateur | Résultat |
|---|---|---|
| `22997000001` | `MTN_MOMO_BEN` | Paiement SUCCESS |
| `22997000002` | `MTN_MOMO_BEN` | Paiement FAILED |
| `22997000003` | `MTN_MOMO_BEN` | Paiement TIMEOUT |

---

## 10. Statuts et gestion des erreurs

### Statuts d'un paiement

| Statut | Signification | Action |
|---|---|---|
| `PROCESSING` | En attente du PIN de l'user | Continuer le polling |
| `SUCCESS` | Validé | Aller à la confirmation |
| `FAILED` | Rejeté (solde, PIN, refus) | Écran d'échec |

### Statuts d'une commande

| Statut | Signification |
|---|---|
| `PENDING` | Créée, paiement en attente |
| `CONFIRMED` | Paiement validé par webhook |
| `ACTIVE` | Activée par l'user (abonnement en cours) |
| `COMPLETED` | Abonnement terminé |
| `CANCELLED` | Annulée |

### Erreurs sur `POST /orders`

| Code HTTP | Cause | Solution |
|---|---|---|
| `400` | `paymentMethod` envoyé dans le body | Ne jamais l'envoyer |
| `400` | Ville de livraison non reconnue | Toujours utiliser les zones de `subscription.deliveryZones` |

### Erreurs sur `POST /payments/initiate`

| Code HTTP | `error.code` | Cause | Solution |
|---|---|---|---|
| `404` | `ORDER_NOT_FOUND` | `orderId` inexistant | Vérifier l'ID commande |
| `403` | `FORBIDDEN` | Commande appartenant à un autre user | Ne devrait pas arriver |
| `409` | `PAYMENT_ALREADY_PROCESSED` | Commande déjà payée ou paiement en cours | Rediriger vers le statut existant |
| `400` | `INVALID_PHONE_NUMBER` | Numéro rejeté par PawaPay | Afficher "Numéro invalide", laisser corriger — passer `provider` explicitement si la détection auto échoue |
| `400` | `PAYMENT_FAILED` | PawaPay rejette immédiatement (montant invalide, provider indisponible) | Afficher le message de la réponse |
| `503` | `PAWAPAY_ERROR` | PawaPay indisponible ou mauvais format de numéro | Afficher "Service momentanément indisponible" |
| `422` | `VALIDATION_ERROR` | Champs manquants ou invalides | Corriger le formulaire |

### Précautions importantes

- **Ne jamais recréer une commande pour réessayer.** En cas d'échec du paiement, réutiliser le même `orderId` dans un nouvel appel à `POST /payments/initiate`.
- **Ne jamais afficher le `depositId` à l'user.** C'est un identifiant interne PawaPay, sans utilité pour l'utilisateur final.
- **Gérer l'expiration du JWT pendant le polling.** Le token expire après 15 minutes. Si le polling dure longtemps, gérer un `401` en rafraîchissant le token via `POST /auth/refresh` avant de continuer.

### Gestion des messages d'erreur API

Les erreurs retournent :
```json
{
  "success": false,
  "message": "Description de l'erreur"
}
```
Le champ `message` peut être une `string` ou un `string[]`. Toujours gérer les deux cas.

---

## 11. Couleurs et design system

| Rôle | Valeur hex |
|---|---|
| Vert primaire JUNA | `#1A5C2A` |
| Vert secondaire | `#2D7A3A` |
| Fond primaire surface | `rgba(26,92,42,0.08)` |
| Orange alerte | `#F97316` |
| Orange clair | `#FB923C` |
| Rouge erreur | `#EF4444` |
| Fond erreur | `#FEF2F2` |
| Fond page | `#F5F5F5` |
| Fond carte | `#FFFFFF` |
| Bordure carte | `#E5E7EB` |
| Texte principal | `#1C1C1C` |
| Texte secondaire | `#757575` |
| Texte gris clair | `#BDBDBD` |
| Vert success light | `#F0FDF4` |
| Bordure success | `#BBF7D0` |
| Texte success dark | `#14532D` |

### Typographie

| Usage | Taille | Poids |
|---|---|---|
| Titre d'écran | 24px | 600 |
| Titre de section / carte | 16–20px | 600 |
| Corps / labels | 14px | 400–500 |
| Notes / sous-titres | 12px | 400 |
| Badges / chips | 10–12px | 600 |

### Coins arrondis

| Élément | Radius |
|---|---|
| Écran / carte principale | 12px |
| Bouton CTA | 12px |
| Input | 8px |
| Badge / chip | 999px (full) |
| Avatar | 999px (cercle) |

### Bouton CTA principal

- Hauteur : 52px
- Fond : `#1A5C2A`
- Texte : blanc, 16px, `font-weight: 700`
- Coins : 12px
- État désactivé : opacité 50%
- État loading : spinner blanc centré + texte masqué
