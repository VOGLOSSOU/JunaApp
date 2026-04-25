# Guide d'intégration du paiement — JUNA

> Ce document est destiné aux équipes frontend (web et mobile).
> Il décrit le flux complet de paiement via PawaPay Mobile Money,
> du déclenchement jusqu'à la confirmation de commande.

---

## Vue d'ensemble

JUNA utilise **PawaPay** comme passerelle de paiement Mobile Money.
Le paiement est **asynchrone** : on initie, l'opérateur envoie une notification de confirmation à notre backend, et notre backend met à jour la commande.

**Opérateurs supportés :** MTN MoMo, Moov Money, Orange Money.

**Flux global :**

```
[User] → POST /payments/initiate → [Backend JUNA] → POST /v2/predict-provider (validation numéro)
                                                               ↓
                                                    POST /v2/deposits (initier le dépôt)
                                                               ↓
                                              (user reçoit une demande PIN sur son téléphone)
                                                               ↓
                                              (user valide ou refuse)
                                                               ↓
                                         PawaPay → POST /payments/webhook/deposit → [Backend JUNA]
                                                               ↓
                                              (commande passe à CONFIRMED)
                                                               ↓
[Frontend] → GET /payments/:id/status ← polling jusqu'à statut final
```

---

## Base URL

**Production :**
```
https://juna-app.up.railway.app/api/v1
```

**Local :**
```
http://localhost:5000/api/v1
```

Tous les endpoints protégés nécessitent : `Authorization: Bearer {accessToken}`

---

## Les 3 endpoints de paiement

### 1. `POST /payments/initiate` — Initier un paiement

**Auth requise :** oui (user connecté)

**Quand l'appeler :** quand l'utilisateur clique sur "Payer" après avoir sélectionné son abonnement et avoir une commande créée.

**Body :**
```json
{
  "orderId": "uuid-de-la-commande",
  "phoneNumber": "22997123456",
  "provider": "MTN_MOMO_BEN"
}
```

| Champ | Type | Requis | Description |
|---|---|---|---|
| `orderId` | UUID | ✅ | ID de la commande à payer (créée via `POST /orders`) |
| `phoneNumber` | string | ✅ | Numéro Mobile Money **avec indicatif, sans `+`** (ex: `22997123456`) |
| `provider` | string | ❌ | Code opérateur (ex: `MTN_MOMO_BEN`, `MOOV_BEN`). Si omis, détecté automatiquement depuis le numéro |

**Réponse succès (200) :**
```json
{
  "success": true,
  "data": {
    "paymentId": "uuid-du-paiement",
    "depositId": "uuid-pawapay",
    "status": "PROCESSING",
    "message": "Paiement initié. Veuillez valider sur votre téléphone."
  }
}
```

**Que faire après :** sauvegarder le `paymentId` et démarrer le **polling** sur `GET /payments/:id/status`.

---

### 2. `GET /payments/:id/status` — Vérifier le statut

**Auth requise :** oui

**Quand l'appeler :** en polling régulier après avoir initié le paiement, jusqu'à obtenir un statut final.

**Exemple :**
```
GET /payments/uuid-du-paiement/status
```

**Réponse (200) :**
```json
{
  "success": true,
  "data": {
    "id": "uuid-du-paiement",
    "orderId": "uuid-de-la-commande",
    "amount": 5000,
    "currency": "XOF",
    "method": "MOBILE_MONEY_MTN",
    "status": "PROCESSING",
    "paidAt": null,
    "createdAt": "2025-05-15T10:00:00.000Z"
  }
}
```

**Valeurs possibles du champ `status` :**

| Valeur | Signification | Action frontend |
|---|---|---|
| `PROCESSING` | En attente de validation PIN par le user | Afficher un écran d'attente, continuer le polling |
| `SUCCESS` | Paiement validé, commande confirmée | Arrêter le polling, afficher confirmation |
| `FAILED` | Paiement échoué (refus, solde insuffisant…) | Arrêter le polling, afficher erreur avec option de réessayer |

---

### 3. `POST /payments/webhook/deposit` — Webhook (backend only)

**Auth requise :** non

Cet endpoint est appelé **directement par PawaPay**, pas par le frontend. Vous n'avez pas à l'intégrer. Il est documenté ici pour information.

---

## Erreurs possibles sur `POST /payments/initiate`

| Code HTTP | `error.code` | Cause | Que faire |
|---|---|---|---|
| 404 | `ORDER_NOT_FOUND` | L'`orderId` n'existe pas | Vérifier l'ID de commande |
| 403 | `FORBIDDEN` | La commande n'appartient pas au user connecté | Ne devrait pas arriver normalement |
| 409 | `PAYMENT_ALREADY_PROCESSED` | Commande déjà payée ou paiement déjà en cours | Rediriger vers le statut existant |
| 400 | `INVALID_PHONE_NUMBER` | Numéro de téléphone invalide ou non reconnu par PawaPay | Afficher "Numéro invalide", laisser corriger |
| 400 | `PAYMENT_FAILED` | PawaPay a rejeté immédiatement (provider indisponible, montant invalide…) | Afficher le message d'erreur de la réponse |
| 503 | `PAWAPAY_ERROR` | PawaPay est indisponible (réseau, panne opérateur) | Afficher "service momentanément indisponible" |
| 422 | `VALIDATION_ERROR` | Champs manquants ou invalides | Corriger le formulaire |

---

## Format du numéro de téléphone

PawaPay attend le format **MSISDN** : indicatif international + numéro, **sans `+`**, **sans espace**, **sans zéro initial**.

| Format | Exemple | Valide |
|---|---|---|
| Indicatif + numéro, sans `+` | `22997123456` | ✅ |
| Avec `+` | `+22997123456` | ❌ |
| Avec zéro initial après indicatif | `229097123456` | ❌ |
| Avec espaces | `229 97 12 34 56` | ❌ |
| Numéro local sans indicatif | `97123456` | ❌ |

**Recommandation :** afficher le sélecteur de pays avec le préfixe (`+229`) et laisser l'utilisateur saisir uniquement les chiffres sans indicatif (`97123456`). Concaténer avant l'envoi : `"229" + "97123456"` → `"22997123456"`.

---

## Numéros de test (environnement sandbox)

L'environnement actuel est **sandbox** (`https://api.sandbox.pawapay.io`). Aucun argent réel n'est débité. Utiliser ces numéros pour tester :

| Scénario | Numéro | Opérateur |
|---|---|---|
| Paiement réussi (COMPLETED) | `22997000001` | `MTN_MOMO_BEN` |
| Paiement échoué (FAILED) | `22997000002` | `MTN_MOMO_BEN` |
| Paiement timeout | `22997000003` | `MTN_MOMO_BEN` |

> En sandbox, il n'y a pas de demande de code PIN sur le téléphone. Le callback de statut final arrive automatiquement en quelques secondes.

> Les numéros de test exacts sont disponibles dans votre dashboard PawaPay sandbox sous **"Test numbers"**. Si les numéros ci-dessus ne fonctionnent pas, se référer au dashboard.

---

## Codes opérateurs PawaPay (pays couverts)

| Opérateur | Code `provider` | Pays | Devise |
|---|---|---|---|
| MTN Mobile Money | `MTN_MOMO_BEN` | Bénin | XOF |
| Moov Money | `MOOV_BEN` | Bénin | XOF |
| MTN Mobile Money | `MTN_MOMO_CIV` | Côte d'Ivoire | XOF |
| Moov Money | `MOOV_CIV` | Côte d'Ivoire | XOF |
| Orange Money | `ORANGE_CIV` | Côte d'Ivoire | XOF |
| MTN Mobile Money | `MTN_MOMO_SEN` | Sénégal | XOF |
| Orange Money | `ORANGE_SEN` | Sénégal | XOF |

> La liste exacte des opérateurs actifs sur votre compte PawaPay est configurable depuis le dashboard PawaPay. Ce tableau couvre les marchés principaux de JUNA.

---

## Flux d'implémentation étape par étape

### Étape 1 — Créer la commande

Avant de payer, une commande doit exister. Si ce n'est pas encore fait :

```
POST /orders
{
  "subscriptionId": "...",
  "deliveryMethod": "DELIVERY" | "PICKUP",
  "deliveryAddress": "...",
  "pickupLocation": "..."
}
```

Récupérer l'`orderId` dans la réponse.

---

### Étape 2 — Afficher le formulaire de paiement

Collecter auprès de l'utilisateur :
- Son **numéro Mobile Money** (sans indicatif — le frontend ajoute l'indicatif avant l'envoi)
- Son **opérateur** (optionnel — le backend le détecte automatiquement depuis le numéro)

**Recommandation UX :** ne pas forcer l'utilisateur à choisir l'opérateur. Affichez un sélecteur de pays avec préfixe, laissez le backend détecter le provider. En cas d'erreur `INVALID_PHONE_NUMBER`, invitez à corriger le numéro.

---

### Étape 3 — Appeler `POST /payments/initiate`

```javascript
// Le user a saisi "97123456", le pays Bénin (+229)
const phoneNumber = '229' + userInput.replace(/\s/g, ''); // → "22997123456"

const response = await fetch('/api/v1/payments/initiate', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${accessToken}`,
  },
  body: JSON.stringify({
    orderId,
    phoneNumber,
    // provider: "MTN_MOMO_BEN" // optionnel, omettre pour détection auto
  }),
});

const json = await response.json();

if (!json.success) {
  // Gérer l'erreur selon json.error.code
  // INVALID_PHONE_NUMBER → afficher "Numéro invalide"
  // PAYMENT_ALREADY_PROCESSED → rediriger vers le statut
  // PAWAPAY_ERROR → afficher "Service indisponible"
  return;
}

const { paymentId } = json.data;
// Démarrer le polling
```

---

### Étape 4 — Polling sur `GET /payments/:id/status`

Démarrer un polling toutes les **5 secondes**, avec un timeout maximum de **3 minutes**.

```javascript
const POLL_INTERVAL = 5000;
const MAX_WAIT = 180000;
const startTime = Date.now();

async function pollPaymentStatus(paymentId, orderId) {
  while (Date.now() - startTime < MAX_WAIT) {
    await new Promise(resolve => setTimeout(resolve, POLL_INTERVAL));

    const res = await fetch(`/api/v1/payments/${paymentId}/status`, {
      headers: { 'Authorization': `Bearer ${accessToken}` },
    });

    // Gérer l'expiration du token JWT (15 min)
    if (res.status === 401) {
      await refreshAccessToken();
      continue;
    }

    const { data } = await res.json();

    if (data.status === 'SUCCESS') {
      navigateTo(`/orders/${orderId}/confirmation`);
      return;
    }

    if (data.status === 'FAILED') {
      showError('Le paiement a échoué. Vérifiez votre solde et réessayez.');
      return;
    }

    // PROCESSING → continuer le polling
  }

  // Timeout atteint
  showError('Le paiement prend plus de temps que prévu. Vérifiez votre historique de transactions.');
}
```

---

### Étape 5 — Écrans à prévoir

**Écran en cours de paiement (PROCESSING) :**
- Spinner ou animation de chargement
- Message : "Validation en cours… Saisissez votre code PIN sur votre téléphone."
- Montant et opérateur affichés
- Bouton "Annuler" (pas d'appel API — redirige vers les commandes du user, le paiement reste en attente côté backend)

**Écran de succès (SUCCESS) :**
- Confirmation visuelle (checkmark, animation)
- Récapitulatif : abonnement, montant, date
- Bouton "Voir ma commande"

**Écran d'échec (FAILED) :**
- Message d'erreur clair
- Bouton "Réessayer" → relancer le formulaire avec le **même `orderId`** (ne pas recréer de commande)
- Bouton "Annuler" → retour à la page de l'abonnement

---

## Précautions importantes

**Ne jamais recréer une commande pour réessayer un paiement.** Si un paiement a échoué, réutiliser le même `orderId` dans un nouvel appel à `POST /payments/initiate`. Le backend gère la réinitialisation automatiquement.

**Gérer le cas où le token expire pendant le polling.** Le token JWT expire après 15 minutes. Si le polling dure longtemps, gérer le 401 en rafraîchissant le token via `POST /auth/refresh` avant de continuer.

**Ne pas afficher le `depositId` à l'utilisateur.** C'est un identifiant interne PawaPay. Utiliser uniquement le `paymentId` JUNA pour les appels API.

**En environnement sandbox :** les paiements sont validés automatiquement, pas de PIN requis, callback en quelques secondes. En production, l'utilisateur doit saisir son PIN sur son téléphone — le délai peut aller jusqu'à 1-2 minutes.

**Si `INVALID_PHONE_NUMBER` (400) :** le numéro est rejeté par PawaPay avant même d'initier le dépôt. Afficher un message clair et laisser l'utilisateur corriger son numéro. Vous pouvez aussi passer `provider` explicitement si la détection automatique échoue sur certains numéros.
