# To-do — Audit technique Juna (05/10/2026)

État général : app en production sur le Play Store (v1.0.3+13), code propre. `flutter analyze` → 2 infos mineures, 9/9 tests OK.
Les points ci-dessous visent la maintenabilité et la robustesse des prochaines mises à jour.

## ✅ Points forts (à préserver)

- Architecture feature-first cohérente (`data/domain/presentation`) sur les 12 features.
- Couche réseau solide (`lib/core/api/api_client.dart`) : refresh token partagé entre requêtes concurrentes, retry unique, invalidation de session seulement sur refus serveur — et testé (`test/auth_refresh_test.dart`).
- Tokens dans `flutter_secure_storage`, `.env` et `key.properties` ignorés par git.
- README honnête et à jour.

## 🔴 À traiter en priorité

- [x] **Build Android impossible sans `key.properties`** (nouvelle machine, CI) — `android/app/build.gradle.kts` castait `null` en `String` à la configuration. Corrigé : config release créée seulement si le fichier existe, fallback sur la clé debug sinon. Aucun impact sur les builds de prod actuels.
- [ ] **`.env` embarqué dans l'APK** — déclaré dans les assets du `pubspec.yaml` alors que rien ne le lit. Ne jamais y mettre de secret. Soit le brancher réellement (`API_BASE_URL` pour basculer dev/prod au lieu de l'URL en dur dans `api_endpoints.dart`), soit le retirer.
- [ ] **iOS non configuré** — pas de `Runner.xcodeproj` ni d'`Info.plist`. Le README annonce iOS + Android, l'app est en réalité Android-only. À faire si iOS est visé : `flutter create --platforms=ios .`, compte Apple Developer, certificats / provisioning profiles.

## 🟡 Dette technique

- [ ] **Vérification d'auth dupliquée écran par écran** — choix assumé (navigation invité, chaque écran privé affiche un prompt de connexion avec `?redirect=`, ex. `orders_screen.dart`, `my_proposals_screen.dart`). Fonctionne, mais chaque nouvel écran privé doit y penser. Option : centraliser dans le `redirect` de `app_router.dart` (actuellement no-op) ou un widget `AuthGate` commun.
- [ ] **Écrans trop gros** — à découper en widgets dans `presentation/widgets/` :
  - `subscriptions/.../subscription_detail_screen.dart` (1311 lignes)
  - `orders/.../orders_screen.dart` (1300 lignes)
  - `provider_space/.../provider_profile_screen.dart` (991 lignes)
- [ ] **Code mort** — `lib/core/utils/mock_data.dart` (401 lignes, importé nulle part), dépendance `connectivity_plus` inutilisée, `ApiEndpoints.baseUrlDev` jamais utilisé.
- [ ] **Incohérence de nom** — `title: 'Juna Eats'` dans `main.dart` vs « Juna » partout ailleurs.
- [ ] **Couverture de tests faible** — ~350 lignes de tests pour ~21 500 lignes de code. Priorités : polling de `payment_processing_screen.dart`, repositories (checkout, subscriptions, orders), parsing des modèles.
- [ ] **Lints** — `withOpacity` déprécié (`core/widgets/juna_badge.dart:34`), `BuildContext` après un `await` (`auth/.../geo_modal.dart:113`).
- [ ] **Hygiène git** — messages de commit non descriptifs (« bonn », « god », « good », « biennn »). Faire des commits plus petits avec des messages clairs (ex. `fix(orders): ...`) pour retrouver facilement une régression entre deux mises à jour.
- [ ] **Racine du repo encombrée** — 2 `.pptx` (pitch decks), candidature agritech, 8 guides `.md`. Ranger les guides dans `docs/`, sortir les pitch decks du repo.

## Ordre recommandé

1. ~~Fix `build.gradle.kts`~~ ✅
2. Supprimer le code mort, brancher ou retirer `.env`
3. Tests sur le paiement et les repositories (protège les prochaines mises à jour)
4. Découper les 3 gros écrans au fil des modifications

> Note : audit fait sur la config, la couche API, le router, le splash et une recherche ciblée dans les écrans — pas une lecture ligne à ligne des ~86 fichiers.
