# Guide de test — SunuBus

Ce document explique comment vérifier que les fonctionnalités de
l'application marchent : d'abord les tests automatisés (ce qu'ils couvrent,
comment les lancer), puis un guide de test manuel écran par écran.

## 1. Tests automatisés

```bash
flutter pub get
flutter test              # toute la suite
flutter test test/services       # uniquement les services (rapide)
flutter test test/features       # uniquement les parcours complets
flutter analyze                  # analyse statique (0 issue attendu)
```

24 tests au total, tous verts sur la dernière vérification.

### Pourquoi des doublures de service (`test/test_helpers.dart`)

Deux services parlent à de vraies API de plateforme qui n'existent pas dans
l'environnement de test (`flutter test` ne lance ni GPS ni système de
notifications) :

- `GeolocationService` (position réelle via `geolocator`)
- `NotificationService` (`flutter_local_notifications`)

Et deux autres lisent/écrivent un vrai stockage qu'on veut garder
déterministe pour les tests :

- `AuthService` (session)
- `SubscriptionService` (abonnement)

`test/test_helpers.dart` fournit `FakeGeolocationService`,
`FakeNotificationService`, `FakeAuthService`, `FakeSubscriptionService` (de
simples sous-classes qui surchargent les méthodes réseau/plateforme) et
`pumpAuthenticatedApp(tester)`, qui monte l'app avec une session déjà
ouverte et un abonnement déjà actif — pour aller droit aux fonctionnalités
à tester sans repasser par les écrans de connexion/paiement à chaque test.

Un `TileProvider` de test (tuile blanche statique) est aussi injecté via
`mapTileProviderProvider`, pour éviter que les tests widgets tentent de
télécharger de vraies tuiles OpenStreetMap.

À noter : `pumpAuthenticatedApp`/`settle()` n'utilisent jamais
`tester.pumpAndSettle()` une fois la carte affichée — le pouls "en direct"
de l'en-tête de la carte est une animation qui boucle indéfiniment, ce qui
ferait attendre `pumpAndSettle` pour toujours. On avance donc par petits pas
de temps simulé à la place.

### Ce que chaque test vérifie

| Fichier | Vérifie |
|---|---|
| `test/widget_test.dart` | Écran de connexion si personne n'est authentifié ; carte + barre de navigation à 4 onglets une fois connecté et abonné |
| `test/services/route_planning_service_test.dart` | La recherche multimodale renvoie des itinéraires cohérents (durée > 0, arrivée après départ), respecte le filtre de modes des préférences, propose toujours au moins un trajet (taxi en secours), respecte l'heure de départ planifiée |
| `test/services/schedule_service_test.dart` | Les horaires d'un arrêt sont triés par heure croissante, tous dans le futur, vides pour un arrêt inconnu |
| `test/services/booking_service_test.dart` | Les réservations persistent et se relisent, isolées par numéro de téléphone |
| `test/services/preferences_service_test.dart` | Les préférences par défaut puis personnalisées persistent correctement |
| `test/services/trip_security_service_test.dart` | Le contact d'urgence persiste/s'efface, le message de partage de trajet contient les bonnes informations |
| `test/data/multimodal_network_test.dart` | Les tarifs simulés varient bien par distance (taxi) ou restent fixes (bus), `nearest()` trouve le bon point, pas de doublons de lieux |
| `test/features/trip_planner_flow_test.dart` | **Parcours complet** : recherche d'itinéraire (Colobane → Guédiawaye) → résultats → détail → réservation → activation d'un rappel → apparition dans "Mes réservations" → annulation |
| `test/features/profile_and_security_test.dart` | Le profil affiche le compte et les entrées de menu ; les filtres de transport se togglent ; le contact d'urgence s'enregistre et débloque le SOS (dialogue de confirmation + message envoyé) |
| `test/features/schedule_sheet_test.dart` | Le tap sur un arrêt de la carte ouvre la feuille d'horaires officiels |

Ces tests ont déjà servi à trouver et corriger trois bugs réels avant
livraison : un crash à l'ouverture du détail d'un itinéraire (accès dynamique
à une extension Dart, invalide sur un type `dynamic`), une liste de
suggestions de lieux sans retour visuel au tap (`ListTile` hors d'un
`Material`), et un débordement de la feuille d'horaires quand un arrêt est
desservi par plusieurs lignes sur un petit écran.

## 2. Guide de test manuel

Pour tester à la main sur un appareil/émulateur (recommandé : Android ou
iOS, pour avoir la géolocalisation et les notifications réelles — voir la
section Limitations du README) :

```bash
flutter run
```

Créez un compte (numéro + mot de passe) puis validez un abonnement fictif
(n'importe quel moyen de paiement, aucune vraie transaction) pour accéder à
l'application.

### Carte
1. La carte se centre sur Dakar, des bus se déplacent le long de leur ligne
   toutes les ~2,5 s (voir le compteur "N bus actifs en direct" évoluer).
2. Filtrer par ligne dans le panneau du bas, chercher un arrêt par nom.
3. Taper sur un bus → détail (ETA, remplissage). Taper sur un arrêt → feuille
   d'horaires officiels (plusieurs lignes si l'arrêt est partagé).
4. Sélectionner une ligne dans le filtre, taper sur la cloche dans l'en-tête
   : elle devient active. Attendre qu'un bus de cette ligne passe sous 3 min
   d'ETA → une notification "arrive bientôt" doit apparaître.

### Itinéraires
1. Onglet **Itinéraires** → renseigner un départ (ou taper l'icône
   "ma position" — autorise la permission de localisation si demandée) et
   une destination parmi les suggestions (arrêts de bus, stations de taxi,
   navettes, TER).
2. Basculer "Plus tard" → choisir une date/heure → vérifier qu'elle
   s'affiche.
3. Ouvrir les filtres (icône réglages) : décocher un mode de transport,
   changer le confort, ajuster la marche max → vérifier que les résultats
   changent en conséquence après une nouvelle recherche.
4. Lancer la recherche : au moins un itinéraire s'affiche (le taxi direct
   est toujours disponible). Trier par prix / durée / confort.
5. Ouvrir le détail d'un itinéraire : aperçu carte, étapes, prix/durée par
   tronçon. Réserver.

### Réservations
1. Après réservation : écran de confirmation, activer le rappel de départ
   (une notification doit être programmée pour 15 min avant le départ).
2. Onglet **Réservations** : le trajet apparaît en "À venir".
3. Annuler la réservation → elle passe dans "Historique" avec le statut
   "Annulé".

### Profil & Sécurité
1. Onglet **Profil** : numéro de compte affiché, accès Préférences /
   Sécurité / Abonnement / Déconnexion.
2. **Préférences de trajet** : les changements de modes/confort/marche faits
   ici doivent se retrouver dans les filtres de l'écran Itinéraires (même
   provider, persistance partagée) — et survivre à un redémarrage de l'app.
3. **Sécurité des trajets** : enregistrer un contact d'urgence. Avec une
   réservation "à venir" en cours, taper "Partager" → un message est copié
   dans le presse-papiers (collez-le n'importe où pour vérifier son
   contenu). Taper "Envoyer une alerte SOS" → confirmer → notification de
   confirmation.
4. Déconnexion → retour à l'écran de connexion ; se reconnecter doit
   restaurer directement la carte (session persistée).

## Points d'intégration API réels

Toute la partie Itinéraires/Réservations/Sécurité fonctionne en local, sans
serveur. Chaque service concerné indique en commentaire son point de
branchement pour une vraie mise en production :

| Service | Aujourd'hui (simulé) | À brancher en production |
|---|---|---|
| `GeolocationService` | déjà réel (capteur GPS de l'appareil, via `geolocator`) | — |
| `RoutePlanningService` | calcul local (ligne la plus proche + marche) | moteur d'itinéraires (OpenTripPlanner, GTFS-RT, API Directions) |
| `ScheduleService` | grille générée localement | flux GTFS statique officiel de l'exploitant |
| `NotificationService` | notifications locales uniquement | notifications push distantes (FCM) pour les alertes en arrière-plan |
| `BookingService` | persistance locale (intention de trajet) | backend de réservation réel |
| `TripSecurityService` | message copié dans le presse-papiers | passerelle SMS (ex. Twilio) ou partage natif (`share_plus`) |
