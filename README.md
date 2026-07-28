# SunuBus

Application Flutter simulant le suivi en temps réel des bus de transport en
commun à Dakar (Tata, Dem Dikk), avec données GPS **entièrement simulées**
(aucun capteur physique requis).

> « Sunu » signifie « notre » en wolof — SunuBus, c'est le suivi de « notre
> bus » en temps réel.

## Fonctionnalités

- Carte interactive (OpenStreetMap via `flutter_map`, sans clé API) centrée
  sur Dakar.
- 3 lignes simulées : **Ligne 4** (Colobane → Guédiawaye), **Ligne 75**
  (Plateau → Pikine), **Dem Dikk** (Petersen → Yoff), avec leurs arrêts.
- `BusSimulationService` : fait avancer chaque bus le long de sa ligne
  toutes les 2,5 secondes, calcule la position GPS interpolée, le prochain
  arrêt, l'ETA (minutes) et un niveau de remplissage.
- Panneau inférieur rétractable : liste des bus actifs, filtre par ligne,
  recherche d'arrêt.
- Écran d'abonnement fictif (100 à 200 FCFA/mois) avec simulation de
  paiement Orange Money / Wave / Free Money (aucune transaction réelle).
- Architecture feature-first + gestion d'état avec **Riverpod**
  (`StateNotifier` + `Timer.periodic`, adapté aux mises à jour temps réel).

## Arborescence

```
lib/
├── main.dart                          # Point d'entrée, ProviderScope, thème
├── core/
│   └── theme/app_theme.dart           # Thème Material 3
├── data/
│   ├── models/
│   │   ├── bus.dart                   # Modèle Bus (position, ETA, etc.)
│   │   ├── bus_line.dart              # Modèle BusLine (trajet, couleur)
│   │   ├── bus_stop.dart              # Modèle BusStop (arrêt)
│   │   ├── occupancy_level.dart       # Enum niveau de remplissage
│   │   └── payment_method.dart        # Enum moyens de paiement mobile
│   └── datasources/
│       └── dakar_network.dart         # Données mock : lignes + arrêts Dakar
├── services/
│   └── bus_simulation_service.dart    # Moteur de simulation temps réel
├── providers/
│   ├── bus_providers.dart             # Providers Riverpod (bus, filtres)
│   └── subscription_providers.dart    # Providers Riverpod (abonnement)
├── features/
│   ├── map/
│   │   ├── screens/home_map_screen.dart
│   │   └── widgets/ (bus_marker_icon, stop_marker_icon)
│   ├── bus_list/
│   │   └── widgets/ (bus_list_panel, bus_list_tile, line_filter_chips,
│   │                  search_stop_field, stop_search_result_tile,
│   │                  subscription_banner)
│   └── subscription/
│       ├── screens/subscription_screen.dart
│       └── widgets/payment_method_card.dart
└── shared/
    └── widgets/bus_detail_sheet.dart  # Détail d'un bus (bottom sheet)
```

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
