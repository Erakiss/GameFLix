# 🎮 GameFlix

> Le hub mobile ultime de mini-jeux de soirée (17-25 ans) sur un seul téléphone partagé.

GameFlix réunit les meilleurs jeux d'ambiance en une seule application fluide et interactive : **Action ou Vérité**, **Je n'ai jamais**, **L'Imposteur**, **Tu préfères**, **Codenames** et le **Jeu de Plateau de l'enfer**.

---

## ✨ Fonctionnalités V2

- 🎡 **Hub Déclaratif & Dynamique** : Roue de sélection 3D orchestrée par `GameRegistry` et `GameConfig` sans couplage rigide.
- 🔊 **Sound Design & Coexistence Audio** : Gestionnaire global `AudioService` (canaux BGM & SFX) configuré pour se mixer avec Spotify et Apple Music sans jamais couper la playlist de soirée. Égaliseur néon compact dans l'AppBar.
- 📦 **Packs de Contenus Découplés** : Manifeste centralisé `assets/data/packs_manifest.json` avec chargement dynamique typé via `PackLoaderService`.
- 💰 **Monétisation Hybride & Respectueuse** :
  - **Google AdMob** : Bannières discrètes limitées au Hub et interstitiels timés soumis à un **cooldown strict de 4 minutes** en fin de partie.
  - **RevenueCat & Rewarded Ads** : `AccessControlProvider` avec modale à double choix (Pass VIP illimité ou déblocage à usage unique pour 1 partie via vidéo récompensée).
- 📜 **Règles Universelles** : Bouton d'aide `?` et modale interactive `GameRulesSheet` intégrés dans chaque lobby.
- 🎨 **Arrière-plan Procédural Néon** : `ProceduralNeonBackground` haute performance (60/120 FPS) en remplacement des images bitmap lourdes.

---

## 🏗️ Structure du Projet

```text
lib/
├── games/                     # Triptyque conventionnel par jeu (_lobby, _game, _scoreboard)
│   ├── codenames/
│   ├── drinking_board/
│   ├── imposter/
│   ├── never_have_i_ever/
│   ├── truth_or_dare/
│   └── would_you_rather/
├── hub/                       # Hub principal, splash screen et sélection
├── models/                    # Modèles de données (GameConfig, GamePack, Player, GameCard)
├── services/                  # Services singletons (AudioService, AdManager, PackLoaderService)
├── state/                     # Gestionnaires d'état Provider (PlayersController, AccessControlProvider)
└── shared/                    # Widgets réutilisables (Navigation, GameRulesSheet, Background, Switch)
```

---

## 🚀 Démarrage Rapide

### Prérequis
- Flutter SDK `^3.12.0`
- Dart SDK compatible

### Installation & Lancement

```bash
# Cloner le dépôt
git clone https://github.com/Erakiss/GameFLix.git
cd gameflix

# Installer les dépendances
flutter pub get

# Lancer la suite de tests
flutter test

# Exécuter l'application
flutter run
```

---

## 📖 Documentation & Historique

Consultez le fichier [`CHANGELOG.md`](CHANGELOG.md) pour le détail complet des 8 tickets de la refonte V2 et le guide pas à pas pour ajouter un nouveau mini-jeu.
