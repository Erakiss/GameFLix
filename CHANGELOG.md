# Changelog - GameFlix

Toutes les modifications notables apportées au projet GameFlix sont documentées dans ce fichier.

---

## [2.0.0] - 2026-10-25 — Refonte V2 (Architecture, Audio, Monétisation & UI)

### 🏗️ 1. Architecture & Clean Code
- **Ticket #1** : Nettoyage en profondeur du code source, correction des chemins d'accès aux bannières (`nhie_banner.png`, `imp_banner.png`), suppression du dossier vide `lib/data/` et harmonisation du triptyque de fichiers par jeu.
- **Ticket #2 — `GameConfig` & `GameRegistry`** :
  - Création des modèles déclaratifs dans `lib/models/game_config.dart`.
  - Découplage total du Hub : l'ajout, le tri ou le verrouillage d'un mini-jeu se fait désormais en une ligne dans `GameRegistry.games` sans modifier le widget de roue `ListWheelScrollView`.
- **Ticket #4 — Manifeste & Découplage des Packs de Données** :
  - Création du fichier central `assets/data/packs_manifest.json` recensant tous les packs avec leurs métadonnées (`id`, `gameId`, `title`, `description`, `isPremium`, `filePath`).
  - Implémentation du service singleton `PackLoaderService` (`lib/services/pack_loader_service.dart`) permettant le chargement asynchrone et typé des données JSON.
  - Découplage des 6 mini-jeux existants (`tod`, `nhie`, `imp`, `wyr`, `code`, `board`).

---

### 🔊 2. Sound Design & Gestion Audio Globale
- **Ticket #5 — `AudioService` & `NeonVolumeControl`** :
  - **Coexistence musicale respectueuse** : Configuration de l'`AudioContext` (`AndroidAudioFocus.none` sur Android et `mixWithOthers` sur iOS) afin que la musique d'ambiance et les bruitages se mixent sans jamais couper Spotify ni Apple Music en soirée.
  - **Double canal indépendant** :
    - Canal BGM (`bgm_hub.wav`) : Nappe synthwave rétro en boucle pour le Hub.
    - Canal SFX : Bruitages à faible latence déclenchés lors des interactions.
  - **Énumération `SoundEffect`** :
    - `click` : Clic UI moderne sur boutons et sélections.
    - `timerTick` : Tic-tac d'horloge pour les comptes à rebours.
    - `buzzer` : Son d'échec / pénalité.
    - `victory` : Jingle fanfare de victoire.
    - `dice` : Lancer de dés pour le jeu de plateau.
    - `suspense` : Nappe de révélation secrète (Imposteur / Codenames).
    - `cardSlide` : Glissement de carte physique.
  - **Composant UI `NeonVolumeControl`** (`lib/shared/widgets/neon_volume_control.dart`) : Égaliseur AppBar compact avec bouton Mute/Unmute direct et 5 barres verticales néon cyan interactives (6px à 18px).

---

### 💰 3. Monétisation Hybride (AdMob & RevenueCat)
- **Ticket #6 — Google AdMob (`AdManager`)** :
  - Intégration de `google_mobile_ads: ^9.2.0` avec gestionnaire centralisé `AdManager` (`lib/services/ad_manager.dart`).
  - **Bannière discrète `HubBannerAd`** : Positionnée exclusivement en bas du Hub principal (jamais en cours de partie), avec repli invisible automatique hors-ligne.
  - **Interstitiels timés (Cooldown de 4 min)** : Protection absolue du rythme de soirée. Les publicités interstitielles ne s'affichent qu'au retour au Hub via `goToHub(context)` et uniquement si un intervalle d'au moins 4 minutes s'est écoulé.
  - Configuration native Android (`AndroidManifest.xml`) et iOS (`Info.plist`) avec les IDs de test Google.
- **Ticket #7 — RevenueCat & `AccessControlProvider`** :
  - Intégration de `purchases_flutter: ^10.18.1`.
  - Provider central `AccessControlProvider` (`lib/state/access_control_provider.dart`) gérant l'autorisation `canAccess(packId, isPremium: true)`.
  - Cadenas néon 🔒 et badge "SPICY" sur les catégories et packs payants (`tod_hot`, `nhie_hot`) dans `NeonCategorySwitch` et les lobbys.
  - Modale `UnlockPackSheet` (`lib/shared/widgets/unlock_pack_sheet.dart`) avec deux options :
    1. **Pass VIP Illimité** : Achat via RevenueCat débloquant instantanément et à vie tous les packs sans pub.
    2. **Déblocage 1 Partie** : Visionnage d'une publicité récompensée AdMob (Rewarded Ad) débloquant le pack pour la session active.
  - **Reverrouillage automatique** : Les déblocages temporaires sont automatiquement réinitialisés dès que les joueurs reviennent au Hub (`goToHub`).

---

### 🎨 4. Composants UI & Améliorations Visuelles
- **Ticket #3 — Modale universelle `GameRulesSheet`** (`lib/shared/widgets/game_rules_sheet.dart`) :
  - Fiche de règles stylisée cyber-néon (description, étapes numérotées, astuces de soirée).
  - Bouton d'aide `?` néon standardisé dans l'AppBar de tous les lobbys de jeu.
- **Ticket #8 — Arrière-plan procédural `ProceduralNeonBackground`** (`lib/shared/widgets/procedural_neon_background.dart`) :
  - Composant `CustomPainter` léger générant un fond sombre multi-stop avec 3 halos néon réactifs (Cyan, Magenta, Violet profond) et un vignettage périphérique.
  - Remplacement de l'image PNG statique de **2,37 Mo** (`assets/hub_bg.png`), supprimée du bundle.
  - Fluidité matérielle garantie à 60/120 FPS sur tous les formats d'écran.

---

## 🛠️ Guide du Développeur : Ajouter un nouveau mini-jeu

Pour ajouter un nouveau jeu dans GameFlix V2, suivez ces 4 étapes standardisées :

### Étape 1 : Créer le dossier et les fichiers du jeu
Dans `lib/games/<mon_nouveau_jeu>/`, créez le triptyque conventionnel :
- `<jeu>_lobby.dart` : Écran de configuration (catégories, packs, nombre de tours).
- `<jeu>_game.dart` : Moteur de jeu interactif sur le téléphone.
- `<jeu>_scoreboard.dart` : Écran des scores de fin de partie avec bouton `goToHub(context)`.

### Étape 2 : Déclarer les packs de données
Dans `assets/data/packs_manifest.json`, ajoutez le ou les packs de votre jeu :
```json
{
  "id": "mon_jeu_classic",
  "gameId": "mon_jeu",
  "title": "Pack Classique",
  "description": "Cartes officielles de lancement.",
  "isPremium": false,
  "filePath": "assets/data/mon_jeu_cards.json"
}
```
Chargez-les simplement dans votre lobby avec :
```dart
final cards = await PackLoaderService.instance.loadCardsForGame<MaCarte>(
  'mon_jeu',
  MaCarte.fromJson,
);
```

### Étape 3 : Déclarer les règles du jeu
Dans `lib/shared/widgets/game_rules_sheet.dart`, ajoutez l'entrée correspondante dans `DefaultGameRules` :
```dart
'mon_jeu': const GameRules(
  gameId: 'mon_jeu',
  title: 'Mon Nouveau Jeu',
  emoji: '🎮',
  description: 'Description en une phrase du concept.',
  steps: [
    'Étape 1 : ...',
    'Étape 2 : ...',
  ],
  tips: 'Astuce pour mettre l\'ambiance !',
),
```

### Étape 4 : Enregistrer le jeu dans la roue du Hub
Dans `lib/models/game_config.dart`, ajoutez l'instance `GameConfig` dans la liste `GameRegistry.games` :
```dart
GameConfig(
  id: 'mon_jeu',
  title: 'MON NOUVEAU JEU',
  subtitle: 'Sous-titre accrocheur',
  bannerPath: 'assets/mon_jeu_banner.png',
  minPlayers: 3,
  maxPlayers: 12,
  isNew: true, // Affiche le badge rose "NEW"
  builder: (sessionPlayers) => MonJeuLobbyScreen(players: sessionPlayers),
),
```

Le jeu apparaîtra instantanément dans la roue 3D du Hub, avec gestion automatique du nombre de joueurs, respect de la musique externe, déblocage des packs et publicités timées !
