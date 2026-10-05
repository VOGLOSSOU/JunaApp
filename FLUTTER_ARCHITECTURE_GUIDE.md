# Guide d'architecture Flutter — basé sur Juna

Ce guide extrait l'architecture technique du projet Juna pour servir de point de départ à un nouveau projet Flutter. Ce n'est pas une doc théorique — chaque section, et surtout la partie "Pièges réels", vient de choses vérifiées ou corrigées dans ce projet précis.

---

## 1. Philosophie

**Feature-first + Clean Architecture légère.** Pas de couche use-case séparée, pas de code-gen (`freezed`/`json_serializable`/`riverpod_generator`) — le parsing JSON → entités est écrit à la main dans chaque repository. C'est un choix : moins de setup, moins de build_runner à attendre, mais ça demande de la discipline pour ne pas laisser le JSON brut fuiter au-delà de la couche `data`.

**Ne construis pas de composants/couches "au cas où".** Le design system de Juna n'a que 5 composants réutilisables (`JunaButton`, `JunaAvatar`, `JunaBadge`, `JunaRating`, `JunaSkeleton`) — le reste (cartes, inputs) est construit par écran. Ça a bien fonctionné : pas de sur-ingénierie prématurée. Factorise seulement quand un vrai doublon apparaît.

---

## 2. Structure de dossiers

```
lib/
├── main.dart                    # Point d'entrée — voir §7 sur le piège du blocage au démarrage
├── app/
│   ├── router/                  # go_router — voir §6 sur le piège ShellRoute
│   ├── shell/                   # Bottom navigation bar
│   ├── theme/                   # Couleurs, typographie, espacements (constantes statiques)
│   └── providers/               # Providers Riverpod globaux (peu nombreux)
├── core/
│   ├── api/                     # Client Dio + intercepteurs + endpoints
│   ├── storage/                 # Secure storage (tokens) + cache local (TTL)
│   ├── errors/                  # Exception unifiée + mapping DioException → AppException
│   ├── utils/                   # enums, formatters, helpers purs
│   └── widgets/                 # Design system — reste volontairement petit
└── features/
    └── <feature>/
        ├── data/                # Repositories + parsing JSON manuel
        ├── domain/              # Entités Dart pures (pas de dépendance Flutter/JSON)
        └── presentation/
            ├── screens/
            ├── controllers/     # Riverpod providers/notifiers
            └── widgets/
```

Chaque feature est autonome — une feature ne devrait dépendre que de `core/` et, ponctuellement, d'entités `domain/` d'une autre feature (jamais de sa couche `presentation/`).

---

## 3. Stack technique — choix et pourquoi

| Besoin | Package | Pourquoi ce choix |
|---|---|---|
| State management | `flutter_riverpod` | Voir §4 pour les deux patterns concrets |
| Navigation | `go_router` | Déclaratif, deep linking simple via `app_links` |
| HTTP | `dio` | Système d'intercepteurs propre, pas besoin de Retrofit/code-gen pour une API REST classique |
| Tokens JWT | `flutter_secure_storage` | Voir §7 — piège du fallback web |
| Cache local | `shared_preferences` + une petite classe maison | Pas besoin d'une vraie DB locale (Isar/Hive/sqflite) pour du cache API avec TTL — inutile de complexifier |
| Formulaires | `TextFormField` + `Form` natif | Pas de lib tierce (`reactive_forms`) — le Flutter natif suffit pour des formulaires simples |
| Images réseau | `cached_network_image` | Cache disque automatique |
| Liens externes | `url_launcher` | `tel:`, `wa.me/`, CGU — voir §7 pour le piège Android 11+ |
| Mise à jour forcée | `in_app_update` | Wrapper du Play Core In-App Updates — voir §8 |

**Règle générale** : n'ajoute une dépendance que quand le besoin est concret. Ce projet a évité `retrofit`, `reactive_forms`, `isar`, `firebase_messaging`, `mobile_scanner` — toutes "prévues" à un moment, jamais nécessaires en pratique.

---

## 4. State management — deux patterns, pas plus

### Pattern A — Page détail (lecture seule, un ID)

```dart
final xDetailProvider = FutureProvider.autoDispose
    .family<XEntity, String>((ref, id) async {
  ref.keepAlive(); // reste en cache pour la session, pas de re-fetch au retour
  return ref.read(xRepositoryProvider).getXById(id);
});
```

Le `ref.keepAlive()` est important : sans lui, `autoDispose` détruit le résultat dès que plus aucun widget ne l'observe, et revisiter le même écran re-déclenche un appel réseau.

### Pattern B — Liste paginée / flux avec état complexe

```dart
class XState {
  final List<XEntity> items;
  final bool isLoading, isLoadingMore, hasMore;
  final int page;
  final String? error;
  const XState({...});
  XState copyWith({...}) => XState(...);
}

class XController extends StateNotifier<XState> {
  Future<void> load() async { ... }
  Future<void> loadMore() async { ... }
}
```

Utilisé pour l'auth, les commandes, les propositions — tout ce qui a plusieurs étapes de chargement (pagination, refresh, retry).

---

## 5. Réseau — Dio + intercepteurs

Deux intercepteurs, pas plus :

**`AuthInterceptor`** :
- Injecte le token sur chaque requête sauf routes publiques (login, register, refresh...).
- Sur un 401, tente un refresh — **mutualisé** via un `Future` partagé, pour qu'un burst de requêtes en parallèle avec un token expiré ne déclenche qu'un seul refresh, pas N.
- Invalide la session (déconnexion locale) uniquement si le refresh échoue avec une vraie erreur d'auth (401/403), jamais sur une erreur réseau.

**`ErrorInterceptor`** :
- Transforme chaque `DioException` en une exception métier unifiée (`AppException`), avec code + message extraits du body de l'API (gère les formats variés : `body.code`, `body.error.code`, message en `String` ou en `List` façon validation errors).

### Cache — stale-while-error

Chaque repository suit le même patron :
1. Si `!forceRefresh`, lire le cache (avec `maxAge`) → si valide, retourner direct.
2. Sinon, fetch réseau → sauver en cache → retourner.
3. **En cas d'erreur réseau/serveur**, retourner le cache même expiré plutôt qu'une erreur — meilleure UX qu'un écran d'erreur pur pour une donnée qui a peu changé.

```dart
Future<List<X>> getX({bool forceRefresh = false}) async {
  final stale = await _readCache();
  if (!forceRefresh) {
    final fresh = await _cache.get(key, maxAge: someDuration);
    if (fresh != null) return fresh;
  }
  try {
    final data = await _dio.get(...);
    await _cache.save(key, data);
    return data;
  } catch (e) {
    if (isNetworkOrServerError(e) && stale != null) return stale;
    rethrow;
  }
}
```

---

## 6. Routing — go_router

Un seul `ShellRoute` pour les onglets du bottom nav. **Tout le reste (pages de détail) doit être en dehors du `ShellRoute`, en routes top-level.**

### ⚠️ Piège réel qu'on a payé cette session

Une page de détail (abonnement) avait été mise PAR ERREUR dans le `ShellRoute`. Résultat : quand on y accédait via `context.push()` depuis une page qui n'était PAS dans le shell (page repas, page prestataire...), la page s'affichait **complètement vide** — la bottom nav bar du shell s'affichait (donc pas un crash visible), mais le contenu ne s'insérait jamais. Le même `push()` depuis une page déjà dans le shell fonctionnait très bien.

**Règle à suivre dès le départ** : seules les 3-5 pages qui correspondent réellement aux onglets du bottom nav vont dans le `ShellRoute`. Toute page de détail/drill-down (accessible depuis n'importe où dans l'app) est top-level, même si tu veux qu'elle garde une bottom nav visible.

---

## 7. Pièges réels rencontrés (à éviter dès le départ)

Cette section vaut plus que le reste du guide — ce sont des bugs qu'on a vraiment eus, pas des risques théoriques.

### a) Ne jamais faire retomber le stockage sécurisé sur du clair, sur mobile

```dart
// ❌ Dangereux : le catch générique s'applique aussi sur mobile
try {
  await _secureStorage.write(...);
} catch (_) {
  await _webFallbackStorage.write(...); // censé être web-only !
}
```
Si `flutter_secure_storage` échoue pour n'importe quelle raison sur Android/iOS (bug Keystore connu sur certains devices), ce pattern fait atterrir les JWT en clair dans `SharedPreferences`. Le fallback non chiffré doit être strictement gated par `kIsWeb`, jamais dans un `catch` générique côté natif.

### b) `main()` ne doit jamais bloquer le premier rendu

```dart
// ❌ Rien ne s'affiche tant que dotenv n'a pas fini de charger
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(...);
}
```
Sur mobile c'est invisible (asset local, quasi instantané), mais sur web (ou tout chargement lent) l'app reste **totalement blanche**, pas même un splash, tant que l'await ne se résout pas. `runApp()` doit être appelé immédiatement ; tout chargement asynchrone non bloquant se fait après, ou dans le splash screen lui-même.

### c) `canLaunchUrl` (tel:/https) a besoin du manifest sur Android 11+

Depuis Android 11, `canLaunchUrl()` de `url_launcher` peut renvoyer `false` **même si l'app cible est installée**, si le schéma n'est pas déclaré dans `<queries>` (restriction de confidentialité "package visibility"). Sans ça, des boutons Appeler/WhatsApp fonctionnels en apparence renvoient un faux "non installé" chez tous les utilisateurs Android 11+.

```xml
<queries>
  <intent>
    <action android:name="android.intent.action.VIEW"/>
    <data android:scheme="tel"/>
  </intent>
  <intent>
    <action android:name="android.intent.action.VIEW"/>
    <data android:scheme="https"/>
  </intent>
</queries>
```
Ajoute-les dès que le projet utilise `url_launcher` pour `tel:`, `mailto:`, ou des liens externes — pas seulement quand le bug se manifeste.

### d) Ne fige jamais un ID de NDK sans vérifier qu'il est réellement installé

`android.ndkVersion` dans `build.gradle.kts` et `ndk.dir` dans `local.properties` (fichier local, gitignored) doivent être cohérents. Un dossier NDK peut exister sur le disque **sans être valide** (téléchargement interrompu — pas de `source.properties`). Avant de fixer une version en dur, vérifie que `<sdk>/ndk/<version>/source.properties` existe réellement, ou laisse `local.properties` sans `ndk.dir` explicite pour que Gradle résolve tout seul depuis `sdk.dir` + `ndkVersion`.

### e) Ne cache jamais un objet "liste" comme s'il était complet

Une page de détail qui privilégie une version en cache issue d'un endpoint LISTE (`GET /x`) peut silencieusement manquer des champs qui n'existent que sur l'endpoint DÉTAIL (`GET /x/:id`) — une fonctionnalité entière peut sembler "non implémentée" alors que le code est correct, juste la mauvaise source de données est utilisée. Une page de détail doit toujours privilégier son propre fetch par ID comme source de vérité, en utilisant le cache liste seulement comme affichage instantané pendant le chargement.

---

## 8. Mise à jour forcée (Play Store)

Package `in_app_update` (wrapper du Play Core In-App Updates), déclenché au splash screen, avant toute navigation :

```dart
Future<void> _checkForcedUpdate() async {
  try {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability == UpdateAvailability.updateAvailable &&
        info.immediateUpdateAllowed) {
      await InAppUpdate.performImmediateUpdate(); // écran plein écran Play, bloquant
    }
  } catch (_) {
    // Ne jamais bloquer l'app si la vérification elle-même échoue
  }
}
```
Ne fonctionne que pour une app installée depuis le Play Store, et seulement pour forcer vers une version **publiée après** celle qui contient ce code — à intégrer dès la première release si possible.

---

## 9. Tests — le minimum qui vaut le coup

Ce projet n'a que 3 fichiers de test, mais ciblés sur ce qui casse silencieusement si ça régresse :
- Le cache (`save`/`get`/expiration/invalidation).
- La logique de refresh de token (mutualisation, invalidation seulement sur vraie erreur d'auth, jamais sur erreur réseau).
- Un smoke test qui vérifie juste que l'app démarre.

Si le temps est limité, priorise les tests sur la logique d'auth et de cache plutôt que sur l'UI — ce sont les bugs les plus coûteux à détecter tard.

---

## 10. Checklist avant chaque release

1. `dart fix --apply` — nettoie les infos cosmétiques automatiquement.
2. `flutter analyze` — doit être à 0 erreur/warning avant de builder.
3. `flutter test` — tous verts.
4. Incrémenter le build number (`version: X.Y.Z+N` dans `pubspec.yaml`).
5. **Toujours valider un changement de config Android (NDK, manifest, gradle) par un vrai `flutter build appbundle`, jamais par lecture de code seule** — plusieurs "ça devrait marcher" de cette session ont cassé au premier vrai build.
6. Rédiger la note de version en decrivant ce qui change pour l'utilisateur, pas les détails techniques.
