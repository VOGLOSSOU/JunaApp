# Guide d'intégration — Système Email & Vérification
**Pour les équipes Web et Mobile**
**Version : 1.0 — Mai 2026**

---

## Contexte

Le système d'authentification de Juna a été mis à jour. L'email de chaque utilisateur doit désormais être **vérifié avant l'inscription**. Ce guide décrit tous les changements à intégrer côté application (web et mobile).

---

## Vue d'ensemble des changements

| Ce qui change | Avant | Après |
|---|---|---|
| Inscription | `email + password + name` | `email + verifiedToken + password + name` |
| isVerified au register | `false` | `true` (vérifié avant inscription) |
| Accès commandes | Libre | Bloqué si `isVerified: false` |
| Accès candidature prestataire | Libre | Bloqué si `isVerified: false` |
| `isVerified` dans les réponses | Présent mais ignoré | À lire et à utiliser |

---

## PARTIE 1 — Flow d'inscription (NOUVEAU)

L'inscription se fait maintenant en **3 étapes** au lieu d'une seule.

### Étape 1 — Saisie et envoi du code OTP

L'utilisateur entre son email. L'app appelle :

**`POST /api/v1/auth/send-verification-code`**

```json
// Request body
{
  "email": "user@example.com"
}
```

```json
// Response 200
{
  "success": true,
  "message": "Code de vérification envoyé"
}
```

Un email est envoyé à l'adresse indiquée contenant un **code à 6 chiffres**, valable **10 minutes**.

> **À faire côté app :** Stocker l'email en cache temporaire (state local, pas de localStorage) et naviguer vers l'écran de saisie du code.

---

**Erreurs possibles :**

| Code HTTP | Code erreur | Signification |
|---|---|---|
| 422 | `VALIDATION_ERROR` | Email invalide ou manquant |
| 429 | `RATE_LIMIT` | Trop de demandes — attendre avant de réessayer |

---

### Étape 2 — Vérification du code OTP

L'utilisateur saisit le code reçu par email. L'app appelle :

**`POST /api/v1/auth/verify-code`**

```json
// Request body
{
  "email": "user@example.com",
  "code": "482917"
}
```

```json
// Response 200
{
  "success": true,
  "message": "Email vérifié avec succès",
  "data": {
    "verified": true,
    "verifiedToken": "550e8400-e29b-41d4-a716-446655440000",
    "userExists": false
  }
}
```

> **À faire côté app :**
> - Si succès → stocker `verifiedToken` en mémoire (state local) et naviguer vers le formulaire d'inscription complet
> - Afficher l'email dans un champ **verrouillé/non modifiable** dans le formulaire suivant
> - `verifiedToken` est valable **30 minutes** — si l'user met trop de temps, il faudra recommencer depuis l'étape 1

---

**Erreurs possibles :**

| Code HTTP | Code erreur | Signification |
|---|---|---|
| 401 | `INVALID_TOKEN` | Code incorrect |
| 401 | `TOKEN_EXPIRED` | Code expiré (10 min dépassées) — renvoyer un nouveau code |
| 422 | `VALIDATION_ERROR` | Format invalide (le code doit faire exactement 6 chiffres) |
| 429 | `RATE_LIMIT` | Trop de tentatives |

---

### Étape 3 — Inscription complète

L'utilisateur remplit le reste du formulaire (nom, mot de passe, téléphone). L'app appelle :

**`POST /api/v1/auth/register`**

```json
// Request body
{
  "email": "user@example.com",
  "verifiedToken": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Jean Dupont",
  "password": "MonMotDePasse1",
  "phone": "+22890123456"
}
```

> ⚠️ `phone` est optionnel. `verifiedToken` est **obligatoire** — c'est le token retourné à l'étape 2.

```json
// Response 201
{
  "success": true,
  "message": "Inscription réussie",
  "data": {
    "user": {
      "id": "...",
      "email": "user@example.com",
      "name": "Jean Dupont",
      "phone": "+22890123456",
      "role": "USER",
      "isVerified": true,
      "isActive": true,
      "createdAt": "2026-05-01T..."
    },
    "tokens": {
      "accessToken": "eyJ...",
      "refreshToken": "eyJ..."
    },
    "isProfileComplete": false
  }
}
```

> **À noter :** `isVerified` est `true` dès le register — l'utilisateur n'a pas besoin de vérifier son email après coup. Un email de bienvenue lui est automatiquement envoyé par le backend.

---

**Erreurs possibles :**

| Code HTTP | Code erreur | Signification |
|---|---|---|
| 401 | `INVALID_TOKEN` | `verifiedToken` invalide ou ne correspond pas à l'email |
| 401 | `TOKEN_EXPIRED` | `verifiedToken` expiré (30 min dépassées) — recommencer depuis l'étape 1 |
| 409 | `EMAIL_ALREADY_EXISTS` | Email déjà utilisé |
| 409 | `PHONE_ALREADY_EXISTS` | Téléphone déjà utilisé |
| 422 | `VALIDATION_ERROR` | Champ manquant ou invalide |

---

### Résumé du flow inscription

```
[Écran 1] Saisie email
      ↓ POST /auth/send-verification-code
[Écran 2] Saisie code OTP (6 chiffres reçus par email)
      ↓ POST /auth/verify-code → verifiedToken
[Écran 3] Formulaire (nom, mot de passe, téléphone) + email verrouillé
      ↓ POST /auth/register { email, verifiedToken, name, password, phone? }
[Home] Utilisateur connecté — isVerified: true
```

---

## PARTIE 2 — Flow de reconnexion (utilisateur non vérifié)

Certains utilisateurs existants en base n'ont pas encore `isVerified: true`. Quand ces utilisateurs se connectent, l'app doit les rediriger vers la vérification.

### Comment détecter un utilisateur non vérifié

Lors du login, la réponse contient `isVerified` :

**`POST /api/v1/auth/login`**

```json
// Response 200
{
  "success": true,
  "data": {
    "user": {
      "isVerified": false,   // ← VÉRIFIER CE CHAMP
      ...
    },
    "tokens": { ... },
    "isProfileComplete": false
  }
}
```

> **Si `isVerified` est `false`** → ne pas diriger l'utilisateur vers l'accueil. Rediriger vers la page de vérification d'email.

---

### Flow de vérification post-connexion

C'est exactement le même flow que la vérification pré-inscription :

```
[Login réussi mais isVerified: false]
      ↓ Redirection vers page de vérification
[Écran] Message : "Vérifiez votre email pour continuer"
      ↓ POST /auth/send-verification-code { email }
[Écran] Saisie du code OTP
      ↓ POST /auth/verify-code { email, code }
      ↓ → Backend met isVerified: true en base automatiquement
      ↓ → userExists: true dans la réponse
[Écran] Message : "Email vérifié ! Reconnectez-vous pour continuer"
      ↓ Redirection vers la page de login
[Login] isVerified: true → accès normal
```

> **Remarque :** Après `verify-code`, la réponse contient `userExists: true`. C'est le signal que l'utilisateur existait déjà — son `isVerified` a été mis à jour. L'app doit alors lui demander de se reconnecter pour obtenir une session fraîche.

---

**Réponse `verify-code` pour un utilisateur existant :**

```json
{
  "success": true,
  "message": "Email vérifié avec succès",
  "data": {
    "verified": true,
    "verifiedToken": "...",
    "userExists": true    // ← user existant, isVerified mis à true
  }
}
```

---

## PARTIE 3 — `isVerified` dans l'app

### Où `isVerified` est disponible

`isVerified` est retourné dans toutes les réponses qui contiennent un objet `user` :

- `POST /auth/register` → `data.user.isVerified`
- `POST /auth/login` → `data.user.isVerified`
- `GET /users/me` → `data.isVerified`

### Ce qu'il faut afficher selon `isVerified`

| Situation | Comportement attendu |
|---|---|
| `isVerified: false` après login | Rediriger vers vérification email — ne pas afficher l'accueil |
| `isVerified: false` dans le profil | Afficher une bannière "Vérifiez votre email" |
| `isVerified: false` | **Ne pas afficher** l'option "Devenir prestataire" |
| `isVerified: true` | Accès normal à toutes les fonctionnalités |

> **Important :** L'option "Devenir prestataire" dans les paramètres ne doit être visible que si l'utilisateur est connecté ET que `isVerified` est `true`. Si l'user n'est pas connecté, ne pas l'afficher du tout. Si connecté mais non vérifié, ne pas l'afficher non plus.

---

## PARTIE 4 — Guards backend (erreurs à gérer)

Deux actions sont maintenant bloquées côté backend si `isVerified: false` :

### 1. Création de commande

`POST /api/v1/orders` retournera une erreur si l'user n'est pas vérifié :

```json
// Response 403
{
  "success": false,
  "error": {
    "code": "EMAIL_NOT_VERIFIED",
    "message": "Vous devez vérifier votre email avant de passer une commande"
  }
}
```

> **À gérer côté app :** Intercepter ce 403 et rediriger vers le flow de vérification email.

### 2. Candidature prestataire

`POST /api/v1/providers/register` retournera une erreur si l'user n'est pas vérifié :

```json
// Response 403
{
  "success": false,
  "error": {
    "code": "EMAIL_NOT_VERIFIED",
    "message": "Vous devez vérifier votre email avant de devenir prestataire"
  }
}
```

> **À gérer côté app :** Normalement, le bouton ne devrait pas être visible si `isVerified: false` (voir Partie 3). Ce guard est une sécurité côté serveur en cas de contournement.

---

## PARTIE 5 — Mot de passe oublié (inchangé)

Le flow de réinitialisation de mot de passe n'a **pas changé**. Pour référence :

### Étape 1 — Demander le lien

**`POST /api/v1/auth/forgot-password`**

```json
{ "email": "user@example.com" }
```

```json
// Response 200 (toujours, même si l'email n'existe pas)
{ "success": true, "message": "Si cet email existe, un lien de réinitialisation vous a été envoyé" }
```

L'utilisateur reçoit un email avec un lien vers `https://junaeats.com/auth/reset-password?token=...`

### Étape 2 — Soumettre le nouveau mot de passe

**`POST /api/v1/auth/reset-password`**

```json
{
  "token": "token-depuis-url",
  "newPassword": "NouveauMotDePasse1"
}
```

```json
// Response 200
{ "success": true, "message": "Mot de passe réinitialisé avec succès" }
```

> Après reset, tous les tokens de l'utilisateur sont révoqués — il doit se reconnecter.

**Erreurs possibles :**

| Code HTTP | Code erreur | Signification |
|---|---|---|
| 401 | `INVALID_TOKEN` | Token invalide |
| 401 | `TOKEN_EXPIRED` | Lien expiré (1h dépassée) |

---

## PARTIE 6 — Emails automatiques envoyés par le backend

Le backend envoie automatiquement les emails suivants. Aucune action n'est requise côté app pour les déclencher — ils partent au bon moment.

| Déclencheur | Destinataire | Objet de l'email |
|---|---|---|
| `POST /auth/send-verification-code` | User | Code OTP à 6 chiffres (valable 10 min) |
| `POST /auth/register` (succès) | User | Email de bienvenue sur Juna |
| `POST /auth/forgot-password` | User | Lien de réinitialisation de mot de passe |
| Paiement confirmé (webhook PawaPay) | User | Récapitulatif de commande confirmée |
| Paiement confirmé (webhook PawaPay) | Prestataire | Notification nouvelle commande |
| Admin approuve un prestataire | Prestataire | Email d'approbation |
| Admin rejette un prestataire | Prestataire | Email de rejet avec motif |

---

## PARTIE 7 — Récapitulatif des nouveaux endpoints

| Endpoint | Auth requise | Description |
|---|---|---|
| `POST /auth/send-verification-code` | Non | Envoie un OTP à l'email |
| `POST /auth/verify-code` | Non | Valide l'OTP, retourne un `verifiedToken` |
| `POST /auth/register` | Non | Inscription (requiert `verifiedToken`) |

---

## PARTIE 8 — Questions fréquentes

**Q : Que faire si l'utilisateur n'a pas reçu le code ?**
> Proposer un bouton "Renvoyer le code" qui rappelle `POST /auth/send-verification-code`. Un nouveau code est généré et l'ancien est automatiquement invalidé. Attendre au moins 60 secondes avant d'autoriser un renvoi (UX recommandée).

**Q : Combien de temps est valable le code ?**
> 10 minutes. Afficher un compte à rebours dans l'UI.

**Q : Combien de temps est valable le `verifiedToken` ?**
> 30 minutes. Si expiré au moment du register, le backend retourne `TOKEN_EXPIRED` — rediriger vers l'étape 1.

**Q : L'utilisateur peut-il changer d'email entre l'étape 2 et l'étape 3 ?**
> Non. Le champ email dans le formulaire d'inscription doit être verrouillé (non modifiable). Le backend vérifie que l'email dans le body correspond au `verifiedToken`.

**Q : Que se passe-t-il si l'utilisateur essaie de créer un compte avec un email déjà utilisé ?**
> Il passera les étapes 1 et 2 normalement (le code sera envoyé). C'est au `POST /auth/register` que le backend retournera `EMAIL_ALREADY_EXISTS (409)`. L'app doit alors afficher un message et proposer de se connecter.

**Q : Faut-il stocker le `verifiedToken` de manière persistante ?**
> Non. Le stocker uniquement en mémoire (state React/Flutter) pendant la durée du flow d'inscription. Ne pas le mettre en localStorage ou SharedPreferences.

---

## PARTIE 9 — Notifications in-app (Mobile uniquement)

L'app mobile affiche les notifications in-app de l'utilisateur connecté. Elles sont stockées en base de données et accessibles via l'API.

### Notifications déclenchées automatiquement par le backend

| Événement | Destinataire | Titre affiché |
|---|---|---|
| Inscription réussie | User | "Bienvenue sur Juna ! 🎉" |
| Mot de passe modifié | User | "Mot de passe mis à jour" |
| Paiement confirmé | User | "Commande confirmée ✅" |
| Paiement confirmé | Prestataire | "Nouvelle commande reçue 🍽️" |
| Candidature approuvée | Prestataire | "Candidature approuvée 🎊" |
| Candidature rejetée | Prestataire | "Mise à jour de votre candidature" |

Aucune action n'est requise côté app pour déclencher ces notifications — elles sont créées automatiquement par le backend au bon moment.

---

### Endpoints disponibles

| Méthode | Endpoint | Description |
|---|---|---|
| `GET` | `/api/v1/notifications` | Récupérer les notifications + compteur non lues |
| `PATCH` | `/api/v1/notifications/read-all` | Tout marquer comme lu |
| `PATCH` | `/api/v1/notifications/:id/read` | Marquer une notif comme lue |
| `DELETE` | `/api/v1/notifications/:id` | Supprimer une notif |

> Tous ces endpoints nécessitent un `Authorization: Bearer <accessToken>` dans le header.

---

### Format de réponse — GET /notifications

```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "type": "SYSTEM",
        "title": "Bienvenue sur Juna ! 🎉",
        "message": "Votre inscription est confirmée. Explorez les abonnements disponibles près de chez vous.",
        "isRead": false,
        "readAt": null,
        "createdAt": "2026-05-03T10:00:00.000Z",
        "data": null
      },
      {
        "id": "...",
        "type": "ORDER_CONFIRMATION",
        "title": "Commande confirmée ✅",
        "message": "Votre paiement pour \"Déjeuner africain\" a bien été reçu. Activez votre commande depuis l'application.",
        "isRead": true,
        "readAt": "2026-05-03T11:00:00.000Z",
        "createdAt": "2026-05-03T10:30:00.000Z",
        "data": {
          "orderNumber": "JUN-20260503-001",
          "orderId": "uuid-de-la-commande"
        }
      }
    ],
    "unreadCount": 1,
    "page": 1,
    "limit": 30
  }
}
```

**Champs importants :**
- `unreadCount` → nombre à afficher en badge sur l'icône 🔔
- `isRead` → `false` = non lue (afficher en surbrillance), `true` = déjà lue
- `data` → contient des IDs utiles pour naviguer vers la ressource concernée (commande, etc.)
- `type` → permet d'afficher une icône différente selon la catégorie

---

### Comportement recommandé côté app

**Badge de la cloche :**
- Appeler `GET /notifications` à chaque ouverture de l'app et à chaque retour sur l'écran notifications
- Afficher `unreadCount` en badge rouge sur l'icône cloche dans la barre de navigation
- Ne pas afficher le badge si `unreadCount === 0`

**Interaction avec une notif :**
- Quand l'user tape sur une notification → appeler `PATCH /notifications/:id/read` puis naviguer vers la ressource concernée si `data` contient un `orderId`
- Bouton "Tout marquer comme lu" → appeler `PATCH /notifications/read-all`

**Pagination :**
- Par défaut `limit=30` — suffisant pour la plupart des cas
- Utiliser `?page=2&limit=30` pour charger plus si l'user scroll jusqu'en bas

---

### Valeurs possibles de `type`

| Type | Contexte |
|---|---|
| `SYSTEM` | Actions liées au compte (inscription, mot de passe) |
| `ORDER_CONFIRMATION` | Commande confirmée (user) ou nouvelle commande reçue (prestataire) |
| `PROPOSAL_VALIDATED` | Candidature prestataire approuvée |
| `PROPOSAL_REJECTED` | Candidature prestataire rejetée |
