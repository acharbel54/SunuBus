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
- `BusSimulationEngine` + `BusSimulationService` : le moteur de simulation
  (classe pure, testable) fait avancer chaque bus le long de sa ligne toutes
  les 2,5 secondes — position GPS interpolée, prochain arrêt, ETA (minutes)
  et niveau de remplissage. Le timer est **mis en pause quand l'app passe en
  arrière-plan** (cycle de vie observé par `RootShell`) et coupé dès que
  plus personne n'écoute le provider (`autoDispose`) pour économiser la
  batterie.
- Panneau inférieur rétractable : liste des bus actifs, filtre par ligne,
  recherche d'arrêt.
- Tap sur un arrêt → horaires officiels des prochains passages.
- Bouton cloche : active une alerte notification quand un bus de la ligne
  sélectionnée est à moins de 3 minutes (remplacée par un message à l'écran
  sur les plateformes sans support de notifications).

### Itinéraires (recherche & planification multimodale)
- Recherche d'itinéraire origine → destination, avec géolocalisation réelle
  de l'appareil (`geolocator`) pour "Ma position".
- Recherche multimodale : bus, tram (TER), taxi, navette — un itinéraire par
  mode autorisé dans les préférences, un trajet direct en taxi étant
  toujours proposé en secours.
- **Les préférences de trajet sont réellement appliquées** : le niveau de
  confort demandé élimine les modes trop basiques (ex: "Confort" n'affiche
  plus le bus), et le temps de marche maximum écarte les lignes dont les
  arrêts sont trop éloignés.
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
- Compte réel (téléphone + mot de passe) stocké sur l'appareil : le mot de
  passe n'est jamais conservé en clair (sel aléatoire + hash SHA-256),
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
│   ├── bus_simulation_engine.dart     # Moteur de simulation pur (testable,
│   │                                   # Random/durée injectables)
│   ├── bus_simulation_service.dart    # Timer temps réel + état Riverpod
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

Une **intégration continue (GitHub Actions)** est configurée
([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) : `flutter analyze`
et `flutter test` sont exécutés automatiquement à chaque push sur `main` et
à chaque pull request.

## 🎬 Guide de démonstration (vidéo)

Scénario prêt à filmer pour présenter toute l'application en ~5 minutes.
Chaque étape précise l'écran à montrer, le geste à faire et un commentaire
possible pendant la présentation.

### Préparation (avant de filmer)

1. **Lancer sur un émulateur Android ou un appareil** (recommandé pour avoir
   la géolocalisation et les notifications réelles) :
   ```bash
   flutter run
   ```
2. **Créer un compte de test** une première fois (ex: `77 000 00 00` /
   `demo1234`) et le garder connecté, pour éviter de montrer deux fois la
   création de compte dans la vidéo.
3. **Faire une réservation à l'avance** (Itinéraires → rechercher → réserver)
   pour que l'écran Sécurité des trajets ait un trajet « à venir » à
   partager pendant la démo.
4. Fermer puis relancer l'app : la session et l'abonnement sont persistés,
   l'app arrive directement sur la carte.

### Scénario pas à pas

#### 1. Démarrage & connexion (≈ 30 s)
- Montrer le premier lancement : écran **« Connectez-vous pour suivre vos
  bus en direct »**.
- Taper **« Pas encore de compte ? Créer un compte »**, saisir numéro +
  mot de passe + confirmation, puis **« Créer mon compte »**.
- Insister sur le sous-titre : *« Votre mot de passe est chiffré, jamais
  stocké en clair »* (sel + SHA-256 sur l'appareil).

#### 2. Abonnement (≈ 30 s)
- L'écran **« Abonnement »** bloque l'accès tant qu'il n'est pas actif :
  montrer la carte tarifaire *« À partir de 100 FCFA / mois »* et les
  avantages.
- Choisir **Orange Money** (ou Wave / Free Money), puis **« Payer maintenant
  · 150 FCFA »** → dialogue *« Paiement via Orange Money en cours... »* →
  **« Paiement réussi »** avec la date d'expiration.
- Préciser que c'est une simulation (aucune transaction réelle).

#### 3. Carte — suivi en temps réel (≈ 1 min)
- La carte s'ouvre centrée sur Dakar : **« N bus actifs en direct »**, des
  bus animés se déplacent le long des 3 lignes (Ligne 4, Ligne 75, Dem
  Dikk).
- Taper sur un **bus** → fiche détail : *« Arrivée estimée »* en minutes +
  prochain arrêt, et le **Remplissage** (calme / moyennement rempli / plein).
- Taper sur un **arrêt** → feuille *« Prochains passages (horaires
  officiels) »*.
- Relever le panneau inférieur : **recherche d'arrêt** (taper « Yoff »),
  **filtre par ligne** (ne garder que la Ligne 4), liste *« Bus actifs »*.
- **Alerte bus proche** : filtrer une ligne, taper la **cloche** dans
  l'en-tête → elle s'active ; quand un bus passe sous 3 min d'ETA, une
  notification *« arrive bientôt »* apparaît (sur desktop, un message
  s'affiche à la place).
- Optionnel : mettre l'app en arrière-plan puis revenir — les bus
  reprennent leur mouvement (simulation en pause pendant l'arrière-plan).

#### 4. Itinéraires — planification multimodale (≈ 1 min 30 s)
- Onglet **Itinéraires** → **« Planifier un trajet »**.
- Saisir le départ : taper sur le champ, choisir « Colobane » dans les
  suggestions. Puis la destination : « Guédiawaye ».
- Taper l'icône **« ma position »** sur le champ départ → la géolocalisation
  renseigne « Ma position actuelle » (sur desktop, position simulée au
  centre de Dakar).
- Basculer **« Plus tard »** → choisir une date/heure (elle s'affiche dans
  le bouton).
- Ouvrir **« Filtres (modes, confort, marche) »** : décocher un mode (ex:
  navette), passer le confort sur **« Confort »**, réduire la marche max à
  5 min → fermer.
- **« Rechercher »** → écran **« Itinéraires proposés »** : montrer le tri
  **« Trier : Prix / Durée / Confort »** et faire varier les résultats.
- Insister : *les préférences sont réellement appliquées* (le bus disparaît
  des résultats en niveau « Confort », une marche max faible écarte les
  lignes trop éloignées — le taxi direct reste toujours proposé en secours).

#### 5. Détail & réservation (≈ 45 s)
- Ouvrir un itinéraire → **« Détail de l'itinéraire »** : aperçu carte avec
  tracé (pointillés = marche, traits pleins = transport), étapes
  *« Plateau → Gare de Dakar · Tram · 12 min · 300 FCFA »*, heure de départ /
  arrivée et prix total.
- Taper **« Réserver ce trajet »** → écran **« Réservation confirmée »** :
  récapitulatif (départ, durée, prix) et interrupteur **« Rappel avant le
  départ »** (notification 15 min avant). L'activer.
- **« Voir mes réservations »** → le trajet apparaît en **« À venir »**.

#### 6. Réservations & annulation (≈ 20 s)
- Onglet **Réservations** : sections **« À venir »** et **« Historique »**.
- Annuler le trajet (icône ✕) → il bascule en **« Annulé »** dans
  l'Historique.

#### 7. Profil & sécurité (≈ 45 s)
- Onglet **Profil** : carte du compte (numéro), accès **« Préférences de
  trajet »**, **« Sécurité des trajets »**, **« Abonnement »**,
  **« Déconnexion »**.
- **Préférences de trajet** : re-ouvrir les filtres depuis le profil —
  montrer que les réglages sont partagés avec l'écran Itinéraires et
  persistés (redémarrer l'app et les retrouver).
- **Sécurité des trajets** : enregistrer un **contact d'urgence** (nom +
  numéro) → *« Contact d'urgence enregistré »*. Le trajet réservé à l'étape
  5 est proposé sous **« Partager mon trajet »** → **« Partager »** →
  *« message copié (simulation) »*. Taper **« Envoyer une alerte SOS »** →
  confirmer → *« Alerte envoyée (simulation) »*.

#### 8. Déconnexion & reconnexion (≈ 20 s)
- **« Déconnexion »** → retour à l'écran de connexion.
- Se reconnecter → l'app revient **directement sur la carte** (session et
  abonnement persistés).

### Conseils de capture

- **Enregistreur d'écran** : `adb exec-out screenrecord --time-limit 360
  /dev/stdout` (Android), ou un logiciel de capture desktop en affichant
  l'émulateur en plein écran.
- Cadrez un **émulateur en mode portrait**, bordure masquée, pour un rendu
  propre.
- Préférez un **émulateur Android** : les notifications et le GPS sont
  réels ; sur desktop Linux les notifications sont remplacées par des
  messages à l'écran.
- **Timing** : comptez ~30 s par étape et respirez entre deux ; la carte
  étant animée, laissez-la tourner 5 s sans action pour montrer le « en
  direct ».
- Préparez un **compte + un trajet réservé à l'avance** (voir Préparation)
  pour enchaîner sans temps mort.

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
  plateforme mobile (Android/iOS) pour fonctionner pleinement. Sur desktop
  Linux/Windows, où `geolocator` n'a pas de canal natif, le bouton "Ma
  position" renvoie une **position simulée au centre de Dakar** au lieu
  d'un échec ; sur les plateformes sans support de notifications (web), une
  **alerte visuelle (SnackBar)** remplace la notification système. Pour les
  vraies coordonnées GPS et de vraies notifications, tester sur un appareil
  ou émulateur Android/iOS.
- Les modules Itinéraires/Réservations/Sécurité sont entièrement simulés
  (calcul local, aucun serveur) : voir le tableau des points d'intégration
  API dans [`TESTING.md`](TESTING.md#points-dintégration-api-réels) pour ce
  qu'il faudrait brancher en production.
