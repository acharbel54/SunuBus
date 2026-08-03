# SunuBus

Application Flutter simulant le suivi en temps réel des bus de transport en
commun à Dakar (Tata, Dem Dikk), avec données GPS **entièrement simulées**
(aucun capteur physique requis).

> « Sunu » signifie « notre » en wolof — SunuBus, c'est le suivi de « notre
> bus » en temps réel.

## Fonctionnalités

L'application est organisée autour de 4 onglets (`RootShell`) : **Carte**,
**Itinéraires**, **Réservations**, **Profil**. Un compte (téléphone + mot de
passe) et un abonnement actif sont requis pour y accéder (voir
[`app_gate.dart`](lib/app_gate.dart)).

### Carte (suivi temps réel)
- Carte interactive (OpenStreetMap via `flutter_map`, sans clé API) centrée
  sur Dakar.
- 3 lignes de bus simulées : **Ligne 4** (Colobane → Guédiawaye), **Ligne 75**
  (Plateau → Pikine), **Dem Dikk** (Petersen → Yoff), avec leurs arrêts.
- `BusSimulationService` : fait avancer chaque bus le long de sa ligne
  toutes les 2,5 secondes, calcule la position GPS interpolée, le prochain
  arrêt, l'ETA (minutes) et un niveau de remplissage.
- Panneau inférieur rétractable : liste des bus actifs, filtre par ligne,
  recherche d'arrêt.
- Tap sur un arrêt → horaires officiels des prochains passages.
- Bouton cloche : active une alerte notification quand un bus de la ligne
  sélectionnée est à moins de 3 minutes.

### Itinéraires (recherche & planification multimodale)
- Recherche d'itinéraire origine → destination, avec géolocalisation réelle
  de l'appareil (`geolocator`) pour "Ma position".
- Recherche multimodale : bus, tram (TER), taxi, navette — un itinéraire par
  mode autorisé dans les préférences, un trajet direct en taxi étant
  toujours proposé en secours.
- Comparaison des propositions par prix, durée ou confort.
- Planification à l'avance (choix d'une date/heure de départ) ou départ
  immédiat.
- Détail d'un itinéraire : étapes marche/transport, aperçu carte, prix et
  durée par tronçon.

### Réservations
- Réservation d'un itinéraire choisi, avec récapitulatif et activation
  optionnelle d'un rappel de départ (notification locale 15 min avant).
- Liste "Mes réservations" (à venir / historique), annulation.

### Profil
- Préférences de trajet : modes de transport autorisés, niveau de confort,
  temps de marche maximum — persistées par compte.
- Sécurité des trajets : contact d'urgence, partage du trajet en cours
  (message copié dans le presse-papiers, simulation), bouton SOS.
- Accès à l'abonnement et déconnexion.

### Abonnement & compte
- Compte réel (téléphone + mot de passe, hashé) stocké sur l'appareil —
  aucun backend.
- Écran d'abonnement fictif (100 à 200 FCFA/mois) avec simulation de
  paiement Orange Money / Wave / Free Money (aucune transaction réelle),
  bloquant l'accès à l'app tant qu'il n'est pas actif.

### Architecture
- Feature-first + gestion d'état avec **Riverpod**
  (`StateNotifier`/`StateNotifierProvider`, `Timer.periodic` pour le temps
  réel, providers `.family` par numéro de téléphone pour les données propres
  à chaque compte).
- Toutes les données sont simulées localement (aucun backend). Chaque
  service de la partie "Itinéraires/Réservations/Sécurité" porte un
  commentaire `//` indiquant son point d'intégration API réel envisagé
  (moteur d'itinéraires, GTFS, notifications push, passerelle SMS) — voir
  [`services/`](lib/services/).

## Arborescence

```
lib/
├── main.dart                          # Point d'entrée, ProviderScope, thème
├── app_gate.dart                      # Routage : session -> abonnement -> RootShell
├── core/
│   └── theme/app_theme.dart           # Thème Material 3
├── data/
│   ├── models/                        # Bus, BusLine, BusStop, OccupancyLevel,
│   │                                   # PaymentMethod, TransportMode, Itinerary,
│   │                                   # ItineraryLeg, ScheduleDeparture, Booking,
│   │                                   # TripPreferences, EmergencyContact
│   └── datasources/
│       ├── dakar_network.dart         # Données mock : lignes de bus + arrêts
│       └── multimodal_network.dart    # Stations taxi, navettes, TER, tarifs/durées
├── services/                          # Un service = une responsabilité, testable
│   │                                   # isolément (voir test/services/)
│   ├── bus_simulation_service.dart    # Moteur de simulation temps réel des bus
│   ├── auth_service.dart              # Comptes locaux (SharedPreferences, SHA-256)
│   ├── subscription_service.dart      # Persistance de l'abonnement
│   ├── geolocation_service.dart       # Position réelle de l'appareil (geolocator)
│   ├── route_planning_service.dart    # Recherche multimodale d'itinéraires
│   ├── schedule_service.dart          # Horaires "officiels" par arrêt
│   ├── notification_service.dart      # Notifications locales
│   ├── booking_service.dart           # Persistance des réservations
│   ├── preferences_service.dart       # Persistance des préférences de trajet
│   └── trip_security_service.dart     # Contact d'urgence, partage de trajet
├── providers/                         # Providers Riverpod, un fichier par domaine
├── features/
│   ├── home/screens/root_shell.dart   # Navigation à 4 onglets (IndexedStack)
│   ├── map/                           # Carte + marqueurs bus/arrêts
│   ├── bus_list/                      # Panneau liste/filtre/recherche de bus
│   ├── trip_planner/                  # Recherche, résultats, détail d'itinéraire
│   ├── booking/                       # Mes réservations, confirmation
│   ├── schedule/                      # Feuille d'horaires d'un arrêt
│   ├── profile/                       # Profil, sécurité des trajets
│   ├── auth/                          # Connexion / inscription
│   └── subscription/                  # Écran d'abonnement (paiement simulé)
└── shared/
    └── widgets/bus_detail_sheet.dart  # Détail d'un bus (bottom sheet)

test/
├── test_helpers.dart                  # pumpAuthenticatedApp() + doublures de services
├── widget_test.dart                   # Démarrage app : connexion / navigation
├── services/                          # Tests unitaires de chaque service
├── data/                              # Tests du jeu de données multimodal
└── features/                          # Parcours complets (recherche → réservation,
                                        # profil/sécurité, horaires d'arrêt)
```

Voir [`TESTING.md`](TESTING.md) pour la liste détaillée des tests automatisés et
un guide de test manuel, fonctionnalité par fonctionnalité.

## Lancer le projet

1. **Prérequis** : [Flutter SDK](https://docs.flutter.dev/get-started/install)
   (canal stable) installé et fonctionnel :
   ```bash
   flutter doctor
   ```

2. **Installer les dépendances** :
   ```bash
   cd SunuBus
   flutter pub get
   ```

3. **Lancer l'application** (émulateur, simulateur ou appareil connecté) :
   ```bash
   flutter run
   ```

   Sur Linux desktop :
   ```bash
   flutter run -d linux
   ```

   Sur Chrome (aucun émulateur nécessaire) :
   ```bash
   flutter run -d chrome
   ```

## Lancer les tests

```bash
flutter test
```

Voir [`TESTING.md`](TESTING.md) pour le détail (tests unitaires des services,
parcours complets simulant un utilisateur, et un guide de test manuel pour
vérifier chaque fonctionnalité à la main).

## Identifiants du projet

- Nom d'affichage : **SunuBus**
- Nom de package Dart : `sunu_bus`
- Identifiant d'application : `com.dakarbus.sunu_bus`

## Notes

- Aucune clé API n'est nécessaire : la carte utilise les tuiles publiques
  OpenStreetMap. Pour un usage en production, prévoyez votre propre
  politique d'utilisation (cache de tuiles, attribution, ou passage à un
  fournisseur payant).
- Les coordonnées GPS des lignes sont approximatives et fictives ; elles ne
  suivent pas exactement la voirie réelle, mais respectent la géographie
  générale des quartiers de Dakar cités.
- Le paiement (Orange Money / Wave / Free Money) est **entièrement simulé** :
  aucun SDK de paiement réel n'est intégré.
- La géolocalisation (`geolocator`) et les notifications locales
  (`flutter_local_notifications`) nécessitent une implémentation de
  plateforme mobile (Android/iOS) ; sur desktop Linux, ces appels échouent
  silencieusement (le bouton "Ma position" affiche un message d'erreur, les
  notifications ne s'affichent simplement pas). Tester ces deux
  fonctionnalités sur un appareil ou émulateur Android/iOS.
- Les modules Itinéraires/Réservations/Sécurité sont entièrement simulés
  (calcul local, aucun serveur) : voir le tableau des points d'intégration
  API dans [`TESTING.md`](TESTING.md#points-dintégration-api-réels) pour ce
  qu'il faudrait brancher en production.
