# Favoris liés au compte

## API

- POST `/favorites` avec `{ "subscriptionId": "UUID" }` pour ajouter.
- DELETE `/favorites/:subscriptionId` pour retirer.
- GET `/favorites?page=1&limit=20` pour charger « Mes favoris ».
- L'état initial du cœur vient de `isFavorite` dans les réponses de découverte.
- La disponibilité dans les favoris vient de `isAvailable` ; un abonnement indisponible reste retirable mais n'ouvre pas un parcours d'achat.

Le client Dio existant ajoute le token et renouvelle la session si nécessaire. Un visiteur qui touche le cœur est dirigé vers la connexion avec un retour vers son écran.

## États et caches

Les mutations attendent la confirmation serveur et bloquent les clics répétés sur le même abonnement. Une erreur conserve le cœur précédent et affiche un message. Les indicateurs partagés synchronisent l'accueil, Explorer, le détail et les favoris.

La liste est paginée, se rafraîchit par glissement et propose un bouton « Voir plus ». Elle gère les états vide, erreur et chargement.

L'état des favoris est recréé pour chaque compte. Les listes et détails de découverte sont invalidés ou rechargés lors d'un changement de compte. Les réponses personnalisées des détails d'abonnement et de prestataire ne sont pas stockées dans le cache disque partagé ; seul le catalogue public visiteur peut utiliser ce cache. Les anciennes réponses en cours sont ignorées après la fermeture de leur contrôleur.

## Déploiement

Le backend doit exposer les trois routes et sa migration `20261026000000_add_favorites` doit être appliquée. Sans cela, l'app affiche l'erreur renvoyée par l'API et ne prétend pas avoir enregistré le favori.

Les tests utilisent des réponses HTTP simulées et vérifient les contrats, la pagination, les erreurs, les changements de compte et les interactions. Une validation avec un compte réel reste nécessaire après le déploiement backend.
