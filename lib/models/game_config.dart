// lib/models/game_config.dart
import 'package:flutter/widgets.dart';
import 'package:gameflix/models/player.dart';

// --- IMPORTS DES JEUX ET LOBBIES ---
import 'package:gameflix/games/truth_or_dare/tod_lobby.dart';
import 'package:gameflix/games/never_have_i_ever/nhie_lobby.dart';
import 'package:gameflix/games/imposter/imp_lobby.dart';
import 'package:gameflix/games/would_you_rather/wyr_lobby.dart';
import 'package:gameflix/games/drinking_board/board_game.dart';
import 'package:gameflix/games/codenames/code_lobby.dart';

/// Configuration déclarative d'un mini-jeu disponible dans GameFlix.
class GameConfig {
  /// Identifiant technique unique du jeu (ex: 'tod', 'nhie', etc.)
  final String id;

  /// Titre complet du jeu
  final String title;

  /// Sous-titre accrocheur affiché sur la bannière dans le Hub
  final String subtitle;

  /// Chemin vers l'image de bannière (null pour un jeu sans image)
  final String? bannerPath;

  /// Nombre minimum de joueurs requis (0 si le jeu ne demande pas de roster)
  final int minPlayers;

  /// Nombre maximum de joueurs acceptés (null si illimité)
  final int? maxPlayers;

  /// Affiche le badge visuel "NEW" sur la carte de la roue
  final bool isNew;

  /// Indique si la carte est verrouillée (jeu à venir ou en préparation)
  final bool isLocked;

  /// Constructeur de l'écran du jeu à partir des copies de joueurs de session
  final Widget Function(List<Player> sessionPlayers) builder;

  const GameConfig({
    required this.id,
    required this.title,
    required this.subtitle,
    this.bannerPath,
    this.minPlayers = 0,
    this.maxPlayers,
    this.isNew = false,
    this.isLocked = false,
    required this.builder,
  });
}

/// Registre centralisé listant tous les mini-jeux de l'application.
///
/// Permet au Hub d'itérer sur la liste sans dépendance directe
/// vers les écrans spécifiques de chaque jeu.
class GameRegistry {
  // Constructeur privé : cette classe ne s'instancie pas
  GameRegistry._();

  // --- CATALOGUE DES JEUX ENREGISTRÉS ---

  /// Liste ordonnée de tous les jeux affichés dans le carrousel du Hub.
  static final List<GameConfig> games = [
    // 1. Action ou Vérité
    GameConfig(
      id: 'tod',
      title: 'Action ou Vérité',
      subtitle: 'Action ou Vérité revisité',
      bannerPath: 'assets/tod_banner.png',
      minPlayers: 2,
      builder: (players) => TodLobbyScreen(players: players),
    ),

    // 2. Je n'ai jamais (course de 2 à 5 joueurs)
    GameConfig(
      id: 'nhie',
      title: "Je n'ai jamais",
      subtitle: "Je n'ai jamais... mais en course !",
      bannerPath: 'assets/nhie_banner.png',
      minPlayers: 2,
      maxPlayers: 5,
      isNew: true,
      builder: (players) => NhieLobbyScreen(players: players),
    ),

    // 3. L'Imposteur (3 joueurs minimum)
    GameConfig(
      id: 'imp',
      title: "L'Imposteur",
      subtitle: 'Imposteur ou Mister White ?',
      bannerPath: 'assets/imp_banner.png',
      minPlayers: 3,
      isNew: true,
      builder: (players) => ImpLobbyScreen(players: players),
    ),

    // 4. Tu préfères (aucun joueur requis)
    GameConfig(
      id: 'wyr',
      title: 'Tu préfères',
      subtitle: 'Le choix impossible',
      bannerPath: 'assets/wyr_banner.png',
      isNew: true,
      builder: (_) => const WyrLobbyScreen(),
    ),

    // 5. Le Jeu de Plateau (2 à 6 joueurs)
    GameConfig(
      id: 'board',
      title: 'Jeu de Plateau',
      subtitle: "Le plateau de l'enfer",
      bannerPath: 'assets/board_banner.png',
      minPlayers: 2,
      maxPlayers: 6,
      isNew: true,
      builder: (players) => BoardGameScreen(players: players),
    ),

    // 6. Codenames Express (4 joueurs minimum)
    GameConfig(
      id: 'code',
      title: 'Codenames',
      subtitle: 'Codenames Express',
      bannerPath: 'assets/code_banner.png',
      minPlayers: 4,
      isNew: true,
      builder: (players) => CodeLobbyScreen(players: players),
    ),

    // 7. Carte en préparation (verrouillée)
    GameConfig(
      id: 'coming_soon',
      title: 'Bientôt...',
      subtitle: 'Le code chauffe...',
      isLocked: true,
      builder: (_) => const SizedBox.shrink(),
    ),
  ];
}
