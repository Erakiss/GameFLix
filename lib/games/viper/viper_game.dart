// lib/games/viper/viper_game.dart
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'package:gameflix/games/viper/viper_scoreboard.dart';
import 'package:gameflix/models/player.dart';
import 'package:gameflix/services/audio_service.dart';
import 'package:gameflix/services/pack_loader_service.dart';
import 'package:gameflix/shared/widgets/global_settings_button.dart';
import 'package:gameflix/l10n/app_strings.dart';
import 'package:gameflix/l10n/locale_controller.dart';
import 'package:gameflix/l10n/strings_wyr_viper.dart';

// --- MODES DU PLATEAU (EXPRESS 47, NORMAL 63, SPIRALE 90) ---
enum ViperBoardMode {
  express(
    totalTiles: 47,
    label: 'MODE EXPRESS',
    subtitle: 'Rapide & Intense',
    hasFlameBadge: false,
  ),
  normal(
    totalTiles: 63,
    label: 'MODE NORMAL',
    subtitle: 'Parcours Classique',
    hasFlameBadge: false,
  ),
  spiral(
    totalTiles: 90,
    label: 'MODE SPIRALE',
    subtitle: '+ de Hasard !',
    hasFlameBadge: true,
  );

  final int totalTiles;
  final String label;
  final String subtitle;
  final bool hasFlameBadge;

  const ViperBoardMode({
    required this.totalTiles,
    required this.label,
    required this.subtitle,
    this.hasFlameBadge = false,
  });

  bool get isSpiral => this == ViperBoardMode.spiral;
}

// --- AMBIANCES DE DECK (DIFFICULTÉ / THÈME) ---
enum ViperDeckMood {
  classic(
    label: 'CLASSIQUE',
    subtitle: 'Mix équilibré',
    emoji: '⚡',
    color: Colors.cyanAccent,
  ),
  hot(
    label: 'HOT 🌶️',
    subtitle: 'Vérités & Défis osés',
    emoji: '🌶️',
    color: Color(0xFFFF2A85),
  ),
  blackout(
    label: 'BLACK OUT',
    subtitle: 'Gorgées & Chaos',
    emoji: '🥃',
    color: Colors.amberAccent,
  );

  final String label;
  final String subtitle;
  final String emoji;
  final Color color;
  const ViperDeckMood({
    required this.label,
    required this.subtitle,
    required this.emoji,
    required this.color,
  });
}

// --- MACHINE D'ÉTAT ABSOLUE ---
enum GamePhase { idle, rolling, moving, card, transition, victory }

// --- MODÈLES LOCAUX ---
enum TileType { action, question, drink, spicy, special }

class TileAction {
  final String title;
  final String description;
  final TileType type;
  final int movement;
  final bool shield;
  final bool reroll;

  TileAction({
    required this.title,
    required this.description,
    required this.type,
    this.movement = 0,
    this.shield = false,
    this.reroll = false,
  });

  factory TileAction.fromJson(Map<String, dynamic> json) {
    final TileType parsedType = TileType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => TileType.action,
    );
    final String rawTitle = json['title'] ?? 'ACTION';
    final String normalizedTitle =
        (parsedType == TileType.special &&
                (rawTitle.toUpperCase() == 'SPÉCIAL' ||
                    rawTitle.toUpperCase() == 'ACTION DE MOUVEMENT'))
            ? 'GLITCH'
            : rawTitle;
    final String desc = json['description'] ?? '';
    final String lowerDesc = desc.toLowerCase();
    final bool hasShield = json['shield'] == true ||
        lowerDesc.contains('anti-venin') ||
        lowerDesc.contains('bouclier');
    final bool hasReroll =
        json['reroll'] == true || lowerDesc.contains('relance');

    return TileAction(
      title: normalizedTitle,
      description: desc,
      type: parsedType,
      movement: json['movement'] ?? 0,
      shield: hasShield,
      reroll: hasReroll,
    );
  }
}

class BoardLadder {
  final int fromTile;
  final int toTile;
  final Color color;

  const BoardLadder({
    required this.fromTile,
    required this.toTile,
    required this.color,
  });

  bool get isLadder => toTile > fromTile;
}

class BoardPlayer {
  final Player player;
  final Color color;
  int currentTileIndex;
  bool hasShield; // Sérum Anti-Venin actif

  // STATS DE FIN DE PARTIE
  int sipsCount = 0;
  int laddersClimbed = 0;
  int snakesSlid = 0;

  BoardPlayer({
    required this.player,
    required this.color,
    this.currentTileIndex = 0,
    this.hasShield = false,
  });
}

// --- DÉFINITION DES ANNEAUX CONCENTRIQUES (MODE SPIRALE) ---
class RingDef {
  final int start;
  final int count;
  const RingDef({required this.start, required this.count});
  int get end => start + count - 1;
  bool contains(int tile) => tile >= start && tile <= end;
}

/// Retourne les 3 anneaux concentriques fermés du Mode Spirale :
/// - Anneau 1 (Grand : 12 de large × 13 de haut) : 46 cases (0..45)
/// - Anneau 2 (Médian : 8 de large × 9 de haut) : 30 cases (46..75)
/// - Anneau 3 (Petit : 4 de large × 5 de haut) : 14 cases (76..89)
List<RingDef> getRingsForMode([ViperBoardMode mode = ViperBoardMode.spiral]) {
  return const [
    RingDef(start: 0, count: 46),
    RingDef(start: 46, count: 30),
    RingDef(start: 76, count: 14),
  ];
}

/// Calcule la trajectoire case par case d'un déplacement de [steps] cases.
/// - En mode LACETS (Express / Normal) : avance linéaire avec rebond si dépassement de [lastTile].
/// - En mode SPIRALE : boucle sur l'anneau actuel (pas de rebond !).
///   Sur l'anneau 3, s'arrête sur [lastTile] (case milieu droite du petit cercle) pour la victoire.
List<int> computeStepTrajectory({
  required int startTile,
  required int steps,
  required int lastTile,
  ViperBoardMode mode = ViperBoardMode.express,
}) {
  if (steps == 0) return const [];
  final List<int> path = [];

  if (!mode.isSpiral) {
    int current = startTile;
    if (steps > 0) {
      int direction = 1;
      for (int i = 0; i < steps; i++) {
        if (current == lastTile && direction == 1) {
          direction = -1;
        }
        current = (current + direction).clamp(0, lastTile);
        path.add(current);
      }
    } else {
      for (int i = 0; i < steps.abs(); i++) {
        current = (current - 1).clamp(0, lastTile);
        path.add(current);
      }
    }
    return path;
  }

  // --- MODE SPIRALE : 3 Anneaux fermés, ZÉRO rebond ---
  final rings = getRingsForMode(mode);
  int ringIdx = 0;
  for (int r = 0; r < rings.length; r++) {
    if (rings[r].contains(startTile)) {
      ringIdx = r;
      break;
    }
  }

  final currentRing = rings[ringIdx];
  int current = startTile;

  if (steps < 0) {
    for (int i = 0; i < steps.abs(); i++) {
      if (ringIdx == 0 && current == 0) break;
      current = currentRing.start +
          ((current - currentRing.start - 1 + currentRing.count) %
              currentRing.count);
      path.add(current);
    }
    return path;
  }

  if (ringIdx < 2) {
    // Anneau 1 ou 2 : boucle sans fin le long de l'anneau (modulo sa taille)
    for (int i = 0; i < steps; i++) {
      current = currentRing.start +
          ((current - currentRing.start + 1) % currentRing.count);
      path.add(current);
    }
  } else {
    // Anneau 3 (Intérieur) : avance vers la case victoire (lastTile = 89).
    // Dès qu'on l'atteint ou la dépasse, victoire immédiate sans rebond !
    for (int i = 0; i < steps; i++) {
      if (current < lastTile) {
        current++;
      }
      path.add(current);
      if (current == lastTile) {
        break; // Victoire sur la case milieu droite du petit cercle !
      }
    }
  }

  return path;
}

/// Calcule les positions logiques `(x, y)` en coordonnées relatives pour chaque case :
/// - En LACETS (47 ou 63 cases) : Boustrophédon continu avec vraies cases de virage à angle droit fermé.
/// - En SPIRALE (90 cases) : 3 anneaux rectangulaires concentriques :
///   * Grand anneau : 12 de large × 13 de haut (départ en bas à gauche `(0, 12)`)
///   * Anneau médian : 8 de large × 9 de haut
///   * Petit anneau : 4 de large × 5 de haut (arrivée au milieu à droite `(7, 6)`)
List<Offset> computeBoardGridPositions(ViperBoardMode mode) {
  final List<Offset> positions = [];

  if (!mode.isSpiral) {
    final int totalTiles = mode.totalTiles;
    // Ruban lacet continu : 7 cases horizontales + 1 case de virage verticale montante.
    int curX = 0;
    int curY = 0;
    bool goingRight = true;

    for (int i = 0; i < totalTiles; i++) {
      positions.add(Offset(curX.toDouble(), curY.toDouble()));

      final int stepInBlock = i % 16;
      if (stepInBlock == 6) {
        curY -= 1;
        goingRight = false;
      } else if (stepInBlock == 7) {
        curY -= 1;
      } else if (stepInBlock == 14) {
        curY -= 1;
        goingRight = true;
      } else if (stepInBlock == 15) {
        curY -= 1;
      } else {
        curX += goingRight ? 1 : -1;
      }
    }
    return positions;
  }

  // --- MODE SPIRALE : 3 Anneaux concentriques (12x13, 8x9, 4x5) ---
  // 1. Grand cercle (Anneau 1) : 12 de large (x: 0..11) × 13 de haut (y: 0..12) = 46 cases (0..45)
  // Départ en bas à gauche : (0, 12)
  for (int x = 0; x <= 11; x++) {
    positions.add(Offset(x.toDouble(), 12.0)); // Bas : gauche -> droite
  }
  for (int y = 11; y >= 0; y--) {
    positions.add(Offset(11.0, y.toDouble())); // Droite : bas -> haut
  }
  for (int x = 10; x >= 0; x--) {
    positions.add(Offset(x.toDouble(), 0.0)); // Haut : droite -> gauche
  }
  for (int y = 1; y <= 11; y++) {
    positions.add(Offset(0.0, y.toDouble())); // Gauche : haut -> bas
  }

  // 2. Cercle médian (Anneau 2) : 8 de large (x: 2..9) × 9 de haut (y: 2..10) = 30 cases (46..75)
  for (int x = 2; x <= 9; x++) {
    positions.add(Offset(x.toDouble(), 10.0)); // Bas : gauche -> droite
  }
  for (int y = 9; y >= 2; y--) {
    positions.add(Offset(9.0, y.toDouble())); // Droite : bas -> haut
  }
  for (int x = 8; x >= 2; x--) {
    positions.add(Offset(x.toDouble(), 2.0)); // Haut : droite -> gauche
  }
  for (int y = 3; y <= 9; y++) {
    positions.add(Offset(2.0, y.toDouble())); // Gauche : haut -> bas
  }

  // 3. Petit cercle (Anneau 3) : 4 de large (x: 4..7) × 5 de haut (y: 4..8) = 14 cases (76..89)
  // Ordonné dans le sens de marche pour se terminer pile sur la case milieu à droite (7, 6) !
  const List<(int, int)> innerRingCoords = [
    (7, 5),
    (7, 4),
    (6, 4),
    (5, 4),
    (4, 4),
    (4, 5),
    (4, 6),
    (4, 7),
    (4, 8),
    (5, 8),
    (6, 8),
    (7, 8),
    (7, 7),
    (7, 6), // Case 89 (lastTile) : Milieu à droite du petit cercle = VICTOIRE !
  ];
  for (final (int x, int y) in innerRingCoords) {
    positions.add(Offset(x.toDouble(), y.toDouble()));
  }

  return positions;
}

/// Génère dynamiquement les connecteurs :
/// - En LACETS (Express & Normal) : 5 Échelles et 5 Serpents en Express (7 en Normal).
///   Règle dynamique : Davantage d'Échelles au début pour propulser les joueurs,
///   et davantage de Serpents vers la fin pour créer du suspense !
/// - En SPIRALE (90 cases) : Portails néon UP et DOWN reliant les anneaux voisins à travers les couloirs.
/// - Espacement garanti : au moins 3 cases de distance entre départs de même type.
List<BoardLadder> getBoardLaddersForMode(
  ViperBoardMode mode, {
  Random? random,
}) {
  final Random rng = random ?? Random();

  if (mode.isSpiral) {
    final List<Offset> grid = computeBoardGridPositions(ViperBoardMode.spiral);
    final int totalSpiralTiles = grid.length; // 90
    final rings = getRingsForMode(ViperBoardMode.spiral);

    bool isCleanCorridorBridge(int t1, int t2) {
      final Offset p1 = grid[t1];
      final Offset p2 = grid[t2];
      final int dx = (p1.dx - p2.dx).abs().round();
      final int dy = (p1.dy - p2.dy).abs().round();

      if (dy == 2 && dx <= 1) {
        final int minY = min(p1.dy.round(), p2.dy.round());
        if (minY == 0 || minY == 10) {
          return p1.dx >= 2 && p1.dx <= 9 && p2.dx >= 2 && p2.dx <= 9;
        }
        if (minY == 2 || minY == 8) {
          return p1.dx >= 4 && p1.dx <= 7 && p2.dx >= 4 && p2.dx <= 7;
        }
      }
      if (dx == 2 && dy <= 1) {
        final int minX = min(p1.dx.round(), p2.dx.round());
        if (minX == 0 || minX == 9) {
          return p1.dy >= 2 && p1.dy <= 10 && p2.dy >= 2 && p2.dy <= 10;
        }
        if (minX == 2 || minX == 7) {
          return p1.dy >= 4 && p1.dy <= 8 && p2.dy >= 4 && p2.dy <= 8;
        }
      }
      return false;
    }

    bool bridgesOverlap(int a1, int b1, int a2, int b2) {
      final Offset p1 = grid[a1];
      final Offset p2 = grid[b1];
      final Offset p3 = grid[a2];
      final Offset p4 = grid[b2];
      final Offset m1 = (p1 + p2) / 2.0;
      final Offset m2 = (p3 + p4) / 2.0;
      return (m1.dx - m2.dx).abs() + (m1.dy - m2.dy).abs() < 1.3;
    }

    for (int attempt = 0; attempt < 80; attempt++) {
      final List<BoardLadder> connectors = [];
      final Set<int> usedTiles = {};
      final List<int> upStarts = [];
      final List<int> downStarts = [];
      bool ok = true;

      // 1. Portails UP : 4 de R1 -> R2, et 3 de R2 -> R3 (7 Portails UP au total)
      for (final (int r, int needed) in const [(0, 4), (1, 3)]) {
        final RingDef fromRing = rings[r];
        final RingDef toRing = rings[r + 1];
        int added = 0;
        final List<int> candidates = [
          for (int t = fromRing.start; t <= fromRing.end; t++)
            if (t > 0 && t < totalSpiralTiles - 1 && t % 6 != 0 && !usedTiles.contains(t)) t
        ]..shuffle(rng);

        for (final int fromT in candidates) {
          if (upStarts.any((s) => (s - fromT).abs() < 3)) continue;

          final List<int> targets = [
            for (int tt = toRing.start; tt <= toRing.end; tt++)
              if (tt < totalSpiralTiles - 2 &&
                  tt % 6 != 0 &&
                  !usedTiles.contains(tt) &&
                  isCleanCorridorBridge(fromT, tt))
                tt
          ]..shuffle(rng);

          int? chosenTarget;
          for (final int tt in targets) {
            if (!connectors.any((c) => bridgesOverlap(fromT, tt, c.fromTile, c.toTile))) {
              chosenTarget = tt;
              break;
            }
          }

          if (chosenTarget != null) {
            usedTiles.add(fromT);
            usedTiles.add(chosenTarget);
            upStarts.add(fromT);
            connectors.add(
              BoardLadder(
                fromTile: fromT,
                toTile: chosenTarget,
                color: const Color(0xFF00E676),
              ),
            );
            added++;
            if (added >= needed) break;
          }
        }
        if (added < needed) {
          ok = false;
          break;
        }
      }

      if (!ok) continue;

      // 2. Portails DOWN : 2 de R3 -> R2, et 4 de R2 -> R1 (6 Portails DOWN au total)
      for (final (int r, int needed) in const [(2, 2), (1, 4)]) {
        final RingDef fromRing = rings[r];
        final RingDef toRing = rings[r - 1];
        int added = 0;
        final List<int> candidates = [
          for (int t = fromRing.start; t <= fromRing.end; t++)
            if (t > 0 && t < totalSpiralTiles - 1 && t % 6 != 0 && !usedTiles.contains(t)) t
        ]..shuffle(rng);

        for (final int fromT in candidates) {
          if (downStarts.any((s) => (s - fromT).abs() < 3)) continue;

          final List<int> targets = [
            for (int tt = toRing.start; tt <= toRing.end; tt++)
              if (tt > 0 &&
                  tt % 6 != 0 &&
                  !usedTiles.contains(tt) &&
                  isCleanCorridorBridge(fromT, tt))
                tt
          ]..shuffle(rng);

          int? chosenTarget;
          for (final int tt in targets) {
            if (!connectors.any((c) => bridgesOverlap(fromT, tt, c.fromTile, c.toTile))) {
              chosenTarget = tt;
              break;
            }
          }

          if (chosenTarget != null) {
            usedTiles.add(fromT);
            usedTiles.add(chosenTarget);
            downStarts.add(fromT);
            connectors.add(
              BoardLadder(
                fromTile: fromT,
                toTile: chosenTarget,
                color: const Color(0xFFE040FB),
              ),
            );
            added++;
            if (added >= needed) break;
          }
        }
        if (added < needed) {
          ok = false;
          break;
        }
      }

      if (ok) {
        return connectors;
      }
    }
  }

  // --- MODE LACETS : 5 Échelles et 5 Serpents en Express (7 en Normal) ---
  // RÈGLE DE RÉPARTITION : Davantage d'Échelles au début, davantage de Serpents vers la fin !
  final int totalTiles = mode.totalTiles;
  final int countPerType = mode == ViperBoardMode.express ? 5 : 7;
  final List<Offset> grid = computeBoardGridPositions(mode);

  bool isEligibleTile(int t) {
    if (t <= 1 || t >= totalTiles - 1) return false;
    if (t % 6 == 0) return false; // Réservé GLITCH
    final int mod16 = t % 16;
    if (mod16 == 7 || mod16 == 15) return false;
    return true;
  }

  final List<(int, int)> corridorPairs = [];
  for (int a = 2; a < totalTiles - 3; a++) {
    if (!isEligibleTile(a)) continue;
    for (int b = a + 4; b < totalTiles - 2; b++) {
      if (!isEligibleTile(b)) continue;
      final Offset pa = grid[a];
      final Offset pb = grid[b];
      final int dy = (pa.dy - pb.dy).abs().round();
      final int dx = (pa.dx - pb.dx).abs().round();

      if (dy == 2 && dx <= 2) {
        corridorPairs.add((a, b));
      }
    }
  }

  for (int attempt = 0; attempt < 50; attempt++) {
    final Set<int> usedTiles = {};
    final List<int> ladderStarts = [];
    final List<int> snakeStarts = [];
    final List<BoardLadder> laddersUp = [];
    final List<BoardLadder> snakesDown = [];

    // 1. Échelles au début : on trie les paires par indice de départ croissant (+ léger bruit aléatoire)
    final List<(int, int)> ladderCandidates = List.of(corridorPairs)
      ..sort((a, b) => (a.$1 + rng.nextInt(7) - 3).compareTo(b.$1 + rng.nextInt(7) - 3));

    for (final (int low, int high) in ladderCandidates) {
      if (usedTiles.contains(low) || usedTiles.contains(high)) continue;

      if (ladderStarts.every((s) => (s - low).abs() >= 3)) {
        usedTiles.add(low);
        usedTiles.add(high);
        ladderStarts.add(low);
        laddersUp.add(
          BoardLadder(
            fromTile: low,
            toTile: high,
            color: const Color(0xFF00E676),
          ),
        );
        if (laddersUp.length >= countPerType) break;
      }
    }

    if (laddersUp.length < countPerType) continue;

    // 2. Serpents vers la fin : on trie les paires par indice de tête décroissant (+ léger bruit aléatoire)
    final List<(int, int)> snakeCandidates = List.of(corridorPairs)
      ..sort((a, b) => (-a.$2 + rng.nextInt(7) - 3).compareTo(-b.$2 + rng.nextInt(7) - 3));

    for (final (int low, int high) in snakeCandidates) {
      if (usedTiles.contains(low) || usedTiles.contains(high)) continue;

      if (snakeStarts.every((s) => (s - high).abs() >= 3)) {
        usedTiles.add(low);
        usedTiles.add(high);
        snakeStarts.add(high);
        snakesDown.add(
          BoardLadder(
            fromTile: high,
            toTile: low,
            color: const Color(0xFFE040FB),
          ),
        );
        if (snakesDown.length >= countPerType) break;
      }
    }

    if (laddersUp.length >= countPerType && snakesDown.length >= countPerType) {
      return [...laddersUp, ...snakesDown];
    }
  }

  return const [];
}

/// Détermine le type de case normal selon son index et l'ambiance de deck choisie.
TileType getTileTypeForIndex(int index, ViperDeckMood mood) {
  if (index % 6 == 0) return TileType.special;

  switch (mood) {
    case ViperDeckMood.classic:
      final int mod = index % 4;
      if (mod == 1) return TileType.question;
      if (mod == 2) return TileType.action;
      if (mod == 3) return TileType.drink;
      return TileType.question;

    case ViperDeckMood.hot:
      final int mod = index % 4;
      if (mod == 0) return TileType.spicy;
      if (mod == 1) return TileType.question;
      if (mod == 2) return TileType.spicy;
      return TileType.action;

    case ViperDeckMood.blackout:
      final int mod = index % 3;
      if (mod == 0 || mod == 1) return TileType.drink;
      return index.isOdd ? TileType.action : TileType.question;
  }
}

// --- ÉCRAN PRINCIPAL ---
class ViperGameScreen extends StatefulWidget {
  final List<Player> players;
  final ViperBoardMode boardMode;
  final ViperDeckMood deckMood;

  const ViperGameScreen({
    super.key,
    required this.players,
    this.boardMode = ViperBoardMode.express, // Mode Express par défaut !
    this.deckMood = ViperDeckMood.classic,
  });

  @override
  State<ViperGameScreen> createState() => _ViperGameScreenState();
}

class _ViperGameScreenState extends State<ViperGameScreen>
    with SingleTickerProviderStateMixin {
  final TransformationController _cameraController = TransformationController();
  late AnimationController _cameraAnimController;
  Animation<Matrix4>? _cameraAnimation;

  // --- PARAMÈTRES DU PLATEAU ---
  late final int _totalTiles;
  late final List<BoardLadder> _ladders;
  final double _tileWidth = 92.0;
  final double _tileHeight = 58.0;

  bool get _isSpiral => widget.boardMode.isSpiral;

  List<Offset> _tileCenters = [];
  List<Widget> _boardTiles = [];
  double _boardWidth = 0;
  double _boardHeight = 0;

  // --- ÉTAT DU JEU ---
  GamePhase _phase = GamePhase.idle;

  final List<BoardPlayer> _boardPlayers = [];
  int _currentPlayerIndex = 0;
  int _diceValue = 1;
  double _diceRotation = 0.0;
  String? _statusBannerText;
  Color _statusBannerColor = Colors.cyanAccent;

  List<TileAction> _actionPool = [];
  TileAction? _currentAction;

  Completer<void>? _cardDismissed;
  AppLocale? _lastBoardLocale;

  @override
  void initState() {
    super.initState();
    final List<Offset> positions = computeBoardGridPositions(widget.boardMode);
    _totalTiles = positions.length;
    _ladders = getBoardLaddersForMode(widget.boardMode);

    _cameraAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    final List<Color> availableColors = [
      const Color(0xFF00E5FF), // Cyan
      const Color(0xFFFF2A85), // Magenta
      const Color(0xFFFFD600), // Ambre
      const Color(0xFF00E676), // Émeraude
      const Color(0xFFFF5252), // Corail
      const Color(0xFFD500F9), // Violet
    ];
    for (int i = 0; i < widget.players.length; i++) {
      _boardPlayers.add(
        BoardPlayer(
          player: widget.players[i],
          color: availableColors[i % availableColors.length],
        ),
      );
    }

    final initialStrings = AppStrings(LocaleController.instance.currentLocale);
    _lastBoardLocale = initialStrings.locale;
    _buildBoardLayout(initialStrings);
    _loadCards();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _boardPlayers.isNotEmpty) {
        _focusCameraOnTile(0, scale: 0.75, animate: false);
      }
    });
  }

  @override
  void dispose() {
    if (_cardDismissed != null && !_cardDismissed!.isCompleted) {
      _cardDismissed!.complete();
    }
    _cameraAnimation?.removeListener(_updateCamera);
    _cameraController.dispose();
    _cameraAnimController.dispose();
    super.dispose();
  }

  Future<bool> _wait(int ms) async {
    await Future.delayed(Duration(milliseconds: ms));
    return mounted;
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _loadCards() async {
    var pool = await PackLoaderService.instance.loadCardsForGame<TileAction>(
      'viper',
      TileAction.fromJson,
    );
    if (pool.isEmpty) {
      pool = await PackLoaderService.instance.loadCardsForGame<TileAction>(
        'board',
        TileAction.fromJson,
      );
    }
    if (!mounted) return;
    final strings = AppStrings(LocaleController.instance.currentLocale);
    _safeSetState(
      () => _actionPool = pool.isEmpty
          ? [
              TileAction(
                title: strings.viperErrorTitle,
                description: strings.viperErrorDescription,
                type: TileType.action,
              ),
            ]
          : pool,
    );
  }

  void _focusCameraOnTile(
    int tileIndex, {
    required double scale,
    required bool animate,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    if (!mounted || _tileCenters.isEmpty) return;
    final Offset target = _tileCenters[tileIndex];
    final size = MediaQuery.of(context).size;

    final Matrix4 endMatrix = Matrix4.identity()
      ..multiply(Matrix4.translationValues(size.width / 2, size.height / 2, 0.0))
      ..multiply(Matrix4.diagonal3Values(scale, scale, 1.0))
      ..multiply(Matrix4.translationValues(-target.dx, -target.dy, 0.0));

    if (animate) {
      _cameraAnimation?.removeListener(_updateCamera);
      _cameraAnimController.duration = duration;
      _cameraAnimation = Matrix4Tween(
        begin: _cameraController.value,
        end: endMatrix,
      ).animate(
        CurvedAnimation(
          parent: _cameraAnimController,
          curve: Curves.easeInOutCubic,
        ),
      );
      _cameraAnimation!.addListener(_updateCamera);
      _cameraAnimController.forward(from: 0.0);
    } else {
      _cameraController.value = endMatrix;
    }
  }

  void _updateCamera() => _cameraController.value = _cameraAnimation!.value;

  Offset _getOffsetForPlayer(int playerIndexOnTile, int totalPlayersOnTile) {
    switch (totalPlayersOnTile) {
      case 2:
        return playerIndexOnTile == 0 ? const Offset(-11, -9) : const Offset(11, 9);
      case 3:
        if (playerIndexOnTile == 0) return const Offset(-11, -9);
        if (playerIndexOnTile == 1) return const Offset(11, 9);
        return const Offset(0, 0);
      case 4:
        if (playerIndexOnTile == 0) return const Offset(-11, -9);
        if (playerIndexOnTile == 1) return const Offset(11, -9);
        if (playerIndexOnTile == 2) return const Offset(-11, 9);
        return const Offset(11, 9);
      default:
        if (totalPlayersOnTile <= 1) return const Offset(0, 0);
        final double angle = (2 * pi * playerIndexOnTile) / totalPlayersOnTile;
        return Offset(cos(angle) * 14, sin(angle) * 14);
    }
  }

  // --- GÉNÉRATION DU PLATEAU EN RUBAN NÉON CONTINU ---
  void _buildBoardLayout(AppStrings strings) {
    final List<Offset> positions = computeBoardGridPositions(widget.boardMode);

    final double stepX = _tileWidth;
    final double stepY = _tileHeight;
    _tileCenters = [];
    _boardTiles = [];

    final double minX = positions.map((p) => p.dx).reduce(min);
    final double minY = positions.map((p) => p.dy).reduce(min);
    final double maxX = positions.map((p) => p.dx).reduce(max);
    final double maxY = positions.map((p) => p.dy).reduce(max);

    for (int i = 0; i < positions.length; i++) {
      final double finalX = (positions[i].dx - minX) * stepX + 60;
      final double finalY = (positions[i].dy - minY) * stepY + 60;
      _tileCenters.add(
        Offset(finalX + _tileWidth / 2, finalY + _tileHeight / 2),
      );

      final BoardLadder? departureLadder =
          _ladders.where((l) => l.fromTile == i).firstOrNull;
      final BoardLadder? arrivalLadder =
          _ladders.where((l) => l.toTile == i).firstOrNull;

      Color tileBackgroundColor = const Color(0xFF0A0E1C);
      late Color neonColor;
      late String tileText;
      late Widget centerIcon;

      if (i == 0) {
        neonColor = Colors.greenAccent;
        tileBackgroundColor = const Color(0xFF07221A);
        tileText = strings.viperTileStart;
        centerIcon = const Icon(
          Icons.double_arrow_rounded,
          color: Colors.greenAccent,
          size: 22,
        );
      } else if (i == positions.length - 1) {
        neonColor = Colors.amberAccent;
        tileBackgroundColor = const Color(0xFF241B06);
        tileText = strings.viperTileVictory;
        centerIcon = const Icon(
          Icons.emoji_events_rounded,
          color: Colors.amberAccent,
          size: 24,
        );
      } else if (departureLadder != null) {
        if (departureLadder.isLadder) {
          neonColor = const Color(0xFF00E676);
          tileBackgroundColor = const Color(0xFF082419);
          tileText = strings.viperTileConnectorUp(_isSpiral);
          centerIcon = _isSpiral
              ? const Icon(
                  Icons.toll_rounded,
                  color: Color(0xFF00E676),
                  size: 22,
                )
              : const MinimalLadderIcon(
                  color: Color(0xFF00E676),
                  size: 22,
                );
        } else {
          neonColor = const Color(0xFFE040FB);
          tileBackgroundColor = const Color(0xFF210A2B);
          tileText = strings.viperTileConnectorDown(_isSpiral);
          centerIcon = _isSpiral
              ? const Icon(
                  Icons.cyclone_rounded,
                  color: Color(0xFFE040FB),
                  size: 22,
                )
              : const MinimalSnakeIcon(
                  color: Color(0xFFE040FB),
                  size: 24,
                );
        }
      } else if (arrivalLadder != null) {
        neonColor = arrivalLadder.color.withValues(alpha: 0.75);
        tileBackgroundColor = const Color(0xFF080C18);
        tileText = strings.viperTileArrival;
        centerIcon = Icon(
          Icons.my_location_rounded,
          color: arrivalLadder.color.withValues(alpha: 0.85),
          size: 20,
        );
      } else {
        final TileType tType = getTileTypeForIndex(i, widget.deckMood);
        switch (tType) {
          case TileType.special:
            neonColor = Colors.amberAccent;
            tileBackgroundColor = const Color(0xFF1D1708);
            tileText = strings.viperTileSpecial;
            centerIcon = const Icon(
              Icons.bolt_rounded,
              color: Colors.amberAccent,
              size: 24,
            );
            break;
          case TileType.spicy:
            neonColor = const Color(0xFFFF2A85);
            tileBackgroundColor = const Color(0xFF220818);
            tileText = strings.viperTileSpicy;
            centerIcon = const Icon(
              Icons.whatshot_rounded,
              color: Color(0xFFFF2A85),
              size: 22,
            );
            break;
          case TileType.drink:
            neonColor = const Color(0xFF00E5FF);
            tileBackgroundColor = const Color(0xFF071B24);
            tileText = strings.viperTileDrink;
            centerIcon = const Icon(
              Icons.local_bar_rounded,
              color: Color(0xFF00E5FF),
              size: 22,
            );
            break;
          case TileType.question:
            neonColor = const Color(0xFF40C4FF);
            tileBackgroundColor = const Color(0xFF0A1426);
            tileText = strings.viperTileQuestion;
            centerIcon = const Icon(
              Icons.chat_bubble_rounded,
              color: Color(0xFF40C4FF),
              size: 20,
            );
            break;
          case TileType.action:
            neonColor = const Color(0xFFFF5252);
            tileBackgroundColor = const Color(0xFF200B12);
            tileText = strings.viperTileAction;
            // Vrai visage de démon cartoon néon 😈
            centerIcon = const CartoonDemonIcon(
              color: Color(0xFFFF5252),
              size: 23,
            );
            break;
        }
      }

      _boardTiles.add(
        Positioned(
          left: finalX,
          top: finalY,
          child: Container(
            width: _tileWidth,
            height: _tileHeight,
            decoration: BoxDecoration(
              color: tileBackgroundColor,
              border: Border.all(
                color: const Color(0xFF00B0FF).withValues(alpha: 0.65),
                width: 1.2,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                border: Border.all(
                  color: neonColor.withValues(alpha: 0.75),
                  width: 1.2,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 2,
                    left: 4,
                    child: Text(
                      '$i',
                      style: TextStyle(
                        color: neonColor.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w800,
                        fontSize: 8.0,
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 2),
                        centerIcon, // Icône + grosse
                        const SizedBox(height: 1),
                        Text(
                          tileText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: neonColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 7.5, // Texte + petit
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    _boardWidth = (maxX - minX) * stepX + _tileWidth + 120;
    _boardHeight = (maxY - minY) * stepY + _tileHeight + 120;
  }

  void _navigateToScoreboard() {
    if (!mounted) return;
    setState(() => _phase = GamePhase.victory);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ViperScoreboardScreen(
          boardPlayers: List<BoardPlayer>.from(_boardPlayers),
          players: widget.players,
        ),
      ),
    );
  }

  Future<bool> _presentCardAndWait(TileAction action) async {
    final completer = Completer<void>();
    _cardDismissed = completer;

    AudioService.instance.playSfx(SoundEffect.cardSlide);

    setState(() {
      _currentAction = action;
      _phase = GamePhase.card;
    });

    await completer.future;
    _cardDismissed = null;
    return mounted;
  }

  // --- LOGIQUE SÉCURISÉE DU JEU ---
  Future<void> _rollDiceAndMove() async {
    if (_phase != GamePhase.idle || _boardPlayers.isEmpty) return;

    setState(() {
      _phase = GamePhase.rolling;
      _statusBannerText = null;
    });

    AudioService.instance.playSfx(SoundEffect.dice);

    _focusCameraOnTile(
      _boardPlayers[_currentPlayerIndex].currentTileIndex,
      scale: 1.0,
      animate: true,
      duration: const Duration(milliseconds: 400),
    );

    final random = Random();
    for (int i = 0; i < 8; i++) {
      if (!await _wait(50)) return;
      setState(() {
        _diceValue = random.nextInt(6) + 1;
        _diceRotation += 0.35;
      });
    }

    final int steps = random.nextInt(6) + 1;
    setState(() {
      _diceValue = steps;
      _diceRotation = 0.0;
    });
    if (!await _wait(400)) return;

    setState(() => _phase = GamePhase.moving);

    final BoardPlayer currentPlayer = _boardPlayers[_currentPlayerIndex];
    final int lastTile = _totalTiles - 1;
    final List<int> trajectory = computeStepTrajectory(
      startTile: currentPlayer.currentTileIndex,
      steps: steps,
      lastTile: lastTile,
      mode: widget.boardMode,
    );

    for (final nextTile in trajectory) {
      setState(() => currentPlayer.currentTileIndex = nextTile);
      _focusCameraOnTile(
        currentPlayer.currentTileIndex,
        scale: 1.0,
        animate: true,
        duration: const Duration(milliseconds: 340),
      );
      if (!await _wait(370)) return;
    }

    // Victoire uniquement si le joueur s'arrête pile sur la case finale
    if (currentPlayer.currentTileIndex == lastTile) {
      _navigateToScoreboard();
      return;
    }

    bool grantedExtraRoll = false;

    // 1. Connecteurs interactifs avec gages au départ
    final BoardLadder? connector = _ladders
        .where((l) => l.fromTile == currentPlayer.currentTileIndex)
        .firstOrNull;

    final strings = AppStrings(LocaleController.instance.currentLocale);

    if (connector != null) {
      if (connector.isLadder) {
        // Montée : Gage / Shot offert aux autres joueurs
        final TileAction upCard = TileAction(
          title: strings.viperUpCardTitle(_isSpiral),
          description: strings.viperUpCardDesc(_isSpiral),
          type: TileType.action,
        );
        if (!await _presentCardAndWait(upCard)) return;

        setState(() {
          _phase = GamePhase.moving;
          currentPlayer.currentTileIndex = connector.toTile;
          currentPlayer.laddersClimbed++;
        });
        _focusCameraOnTile(
          currentPlayer.currentTileIndex,
          scale: 1.0,
          animate: true,
          duration: const Duration(milliseconds: 550),
        );
        if (!await _wait(600)) return;
      } else {
        // Descente : Anti-Venin ou Gage/Shot pour soi-même
        if (currentPlayer.hasShield) {
          setState(() {
            currentPlayer.hasShield = false;
            _statusBannerText = strings.viperShieldBlockedBanner(_isSpiral);
            _statusBannerColor = Colors.greenAccent;
          });
          if (!await _wait(750)) return;
          setState(() => _statusBannerText = null);
        } else {
          final TileAction downCard = TileAction(
            title: strings.viperDownCardTitle(_isSpiral),
            description: strings.viperDownCardDesc(_isSpiral),
            type: TileType.drink,
          );
          currentPlayer.sipsCount += 2;
          if (!await _presentCardAndWait(downCard)) return;

          setState(() {
            _phase = GamePhase.moving;
            currentPlayer.currentTileIndex = connector.toTile;
            currentPlayer.snakesSlid++;
          });
          _focusCameraOnTile(
            currentPlayer.currentTileIndex,
            scale: 1.0,
            animate: true,
            duration: const Duration(milliseconds: 550),
          );
          if (!await _wait(600)) return;
        }
      }
    } else {
      // 2. Cases classiques
      final bool? extraRollResult =
          await _triggerTileAction(currentPlayer.currentTileIndex);
      if (extraRollResult == null) return;
      grantedExtraRoll = extraRollResult;
    }

    if (currentPlayer.currentTileIndex == lastTile) {
      _navigateToScoreboard();
      return;
    }

    if (grantedExtraRoll) {
      setState(() {
        _statusBannerText = strings.viperDoubleTurnBanner;
        _statusBannerColor = Colors.amberAccent;
      });
      if (!await _wait(650)) return;
      setState(() {
        _statusBannerText = null;
        _phase = GamePhase.idle;
      });
      return;
    }

    setState(() {
      _phase = GamePhase.transition;
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _boardPlayers.length;
    });

    _focusCameraOnTile(
      _boardPlayers[_currentPlayerIndex].currentTileIndex,
      scale: 0.9,
      animate: true,
      duration: const Duration(milliseconds: 400),
    );
    if (!await _wait(350)) return;

    setState(() => _phase = GamePhase.idle);
  }

  Future<bool?> _triggerTileAction(int index) async {
    if (index == 0 || index == _totalTiles - 1) return false;
    if (_actionPool.isEmpty) return false;

    final bool isConnectorTile =
        _ladders.any((l) => l.fromTile == index || l.toTile == index);
    if (isConnectorTile) return false;

    final TileType targetType = getTileTypeForIndex(index, widget.deckMood);

    List<TileAction> possibleCards = _actionPool.where((card) {
      if (widget.deckMood != ViperDeckMood.hot &&
          card.type == TileType.spicy) {
        return false;
      }
      return card.type == targetType;
    }).toList();

    if (possibleCards.isEmpty) {
      possibleCards = _actionPool
          .where(
            (c) =>
                widget.deckMood == ViperDeckMood.hot ||
                c.type != TileType.spicy,
          )
          .toList();
    }
    if (possibleCards.isEmpty) possibleCards = _actionPool;

    final TileAction action =
        possibleCards[Random().nextInt(possibleCards.length)];

    if (action.type == TileType.drink || action.type == TileType.spicy) {
      _boardPlayers[_currentPlayerIndex].sipsCount += 2;
    } else if (action.type == TileType.action || action.reroll) {
      _boardPlayers[_currentPlayerIndex].sipsCount += 1;
    }

    if (!await _presentCardAndWait(action)) return null;

    final BoardPlayer activePlayer = _boardPlayers[_currentPlayerIndex];
    final int lastTile = _totalTiles - 1;

    if (action.shield) {
      final strings = AppStrings(LocaleController.instance.currentLocale);
      setState(() {
        activePlayer.hasShield = true;
        _statusBannerText = strings.viperAntiVenomActivatedBanner;
        _statusBannerColor = Colors.greenAccent;
      });
      if (!await _wait(550)) return null;
      setState(() => _statusBannerText = null);
    } else if (action.reroll) {
      return true;
    } else if (action.movement != 0) {
      final trajectory = computeStepTrajectory(
        startTile: activePlayer.currentTileIndex,
        steps: action.movement,
        lastTile: lastTile,
        mode: widget.boardMode,
      );
      for (final nextTile in trajectory) {
        setState(() {
          _phase = GamePhase.moving;
          activePlayer.currentTileIndex = nextTile;
        });
        _focusCameraOnTile(
          nextTile,
          scale: 1.0,
          animate: true,
          duration: const Duration(milliseconds: 340),
        );
        if (!await _wait(370)) return null;
      }
    } else if (action.type == TileType.special && _boardPlayers.length > 1) {
      final others = _boardPlayers.where((p) => p != activePlayer).toList()
        ..sort((a, b) => a.currentTileIndex.compareTo(b.currentTileIndex));
      final BoardPlayer targetPlayer = others.first;
      if (targetPlayer.currentTileIndex != activePlayer.currentTileIndex) {
        final int oldPos = activePlayer.currentTileIndex;
        final int swappedPos = targetPlayer.currentTileIndex;
        setState(() {
          _phase = GamePhase.moving;
          activePlayer.currentTileIndex = swappedPos;
          targetPlayer.currentTileIndex = oldPos;
        });
        _focusCameraOnTile(
          swappedPos,
          scale: 1.0,
          animate: true,
          duration: const Duration(milliseconds: 500),
        );
        if (!await _wait(550)) return null;
      }
    }
    return false;
  }

  void _dismissCard() {
    if (_phase != GamePhase.card) return;
    setState(() => _phase = GamePhase.moving);
    final completer = _cardDismissed;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    if (_lastBoardLocale != strings.locale) {
      _lastBoardLocale = strings.locale;
      _buildBoardLayout(strings);
    }

    if (_boardPlayers.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF050512),
        body: Center(child: Text(strings.viperAddPlayersMessage)),
      );
    }

    final BoardPlayer currentPlayer = _boardPlayers[_currentPlayerIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF050512),
      body: ViperCyberBackground(
        child: SafeArea(
          child: Stack(
            children: [
              InteractiveViewer(
                transformationController: _cameraController,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(1200),
                minScale: 0.15,
                maxScale: 2.5,
                child: SizedBox(
                  width: _boardWidth,
                  height: _boardHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      RepaintBoundary(
                        child: SizedBox(
                          width: _boardWidth,
                          height: _boardHeight,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ..._boardTiles,
                              IgnorePointer(
                                child: CustomPaint(
                                  size: Size(_boardWidth, _boardHeight),
                                  painter: LaddersPainter(
                                    tileCenters: _tileCenters,
                                    ladders: _ladders,
                                    isSpiral: _isSpiral,
                                    tileWidth: _tileWidth,
                                    tileHeight: _tileHeight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_tileCenters.isNotEmpty)
                        ..._boardPlayers.map((p) {
                          final List<BoardPlayer> onSameTile = _boardPlayers
                              .where(
                                (other) =>
                                    other.currentTileIndex ==
                                    p.currentTileIndex,
                              )
                              .toList();
                          final int indexOnTile = onSameTile.indexOf(p);
                          final Offset dynamicOffset = _getOffsetForPlayer(
                            indexOnTile,
                            onSameTile.length,
                          );
                          final Offset center =
                              _tileCenters[p.currentTileIndex];
                          final bool isActive = p == currentPlayer;

                          return AnimatedPositioned(
                            duration: const Duration(milliseconds: 340),
                            curve: Curves.easeInOutCubic,
                            left: center.dx - 18 + dynamicOffset.dx,
                            top: center.dy - 18 + dynamicOffset.dy,
                            child: NeonPlayerOrb(
                              boardPlayer: p,
                              isActive: isActive,
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),

              // Gros dé
              IgnorePointer(
                ignoring: _phase != GamePhase.rolling,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  color: _phase == GamePhase.rolling
                      ? Colors.black.withValues(alpha: 0.55)
                      : Colors.transparent,
                  child: Center(
                    child: AnimatedScale(
                      scale: _phase == GamePhase.rolling ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      child: AnimatedRotation(
                        turns: _diceRotation,
                        duration: const Duration(milliseconds: 45),
                        child: DiceFace(
                          value: _diceValue,
                          color: currentPlayer.color,
                          size: 130,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Transition de tour
              IgnorePointer(
                ignoring: true,
                child: AnimatedOpacity(
                  opacity: _phase == GamePhase.transition ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 160),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF090C1C).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: currentPlayer.color,
                          width: 2.5,
                        ),
                      ),
                      child: Text(
                        strings.viperTransitionBanner(currentPlayer.player.name),
                        style: TextStyle(
                          color: currentPlayer.color,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bannière d'état
              if (_statusBannerText != null)
                Positioned(
                  top: 70,
                  left: 24,
                  right: 24,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF081426).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _statusBannerColor, width: 2),
                      ),
                      child: Text(
                        _statusBannerText!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _statusBannerColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),

              // HUD Fixe
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        '${strings.viperModeLabel(widget.boardMode)} • ${strings.viperMoodLabel(widget.deckMood)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(
                top: 10,
                right: 14,
                child: GlobalSettingsButton(),
              ),

              // Barre inférieure
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: AnimatedOpacity(
                  opacity: (_phase == GamePhase.idle ||
                          _phase == GamePhase.rolling ||
                          _phase == GamePhase.moving)
                      ? 1.0
                      : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: _phase != GamePhase.idle,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF080B18).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: currentPlayer.color,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                strings.viperPlayerTurnLabel(
                                  currentPlayer.player.name,
                                ),
                                style: TextStyle(
                                  color: currentPlayer.color,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              if (currentPlayer.hasShield) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.science_rounded,
                                  color: Colors.greenAccent,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        GestureDetector(
                          onTap:
                              _phase == GamePhase.idle ? _rollDiceAndMove : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 65,
                            decoration: BoxDecoration(
                              color: _phase != GamePhase.idle
                                  ? Colors.grey.shade900
                                  : currentPlayer.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(35),
                              border: Border.all(
                                color: _phase != GamePhase.idle
                                    ? Colors.grey
                                    : currentPlayer.color,
                                width: 3,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.casino,
                                  color: _phase != GamePhase.idle
                                      ? Colors.grey
                                      : Colors.white,
                                  size: 28,
                                ),
                                const SizedBox(width: 15),
                                Text(
                                  _phase != GamePhase.idle
                                      ? strings.viperRollingButton
                                      : strings.viperRollDiceButton,
                                  style: TextStyle(
                                    color: _phase != GamePhase.idle
                                        ? Colors.grey
                                        : Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Carte FlipCard
              if (_phase == GamePhase.card && _currentAction != null)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _dismissCard,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.72),
                      child: Center(
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 450),
                          tween: Tween<double>(begin: 0, end: 1),
                          builder: (context, double val, child) {
                            return Transform(
                              transform: Matrix4.rotationY(val * pi),
                              alignment: Alignment.center,
                              child: val < 0.5
                                  ? Container(
                                      width: 300,
                                      height: 400,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0E1326),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                          color: Colors.cyanAccent.withValues(
                                            alpha: 0.5,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '?',
                                          style: TextStyle(
                                            color: Colors.cyanAccent,
                                            fontSize: 54,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Transform(
                                      transform: Matrix4.rotationY(pi),
                                      alignment: Alignment.center,
                                      child: FlipCard(action: _currentAction!),
                                    ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- FOND CYBER-PERSPECTIVE STATIQUE ET FLUIDE ---
class ViperCyberBackground extends StatelessWidget {
  final Widget child;
  const ViperCyberBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: const _ViperCyberBackgroundPainter(),
        child: child,
      ),
    );
  }
}

class _ViperCyberBackgroundPainter extends CustomPainter {
  const _ViperCyberBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    final Paint basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF04040E),
          Color(0xFF08071B),
          Color(0xFF10061E),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    final Paint gridPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.045)
      ..strokeWidth = 1.0;

    const double gridSpacing = 48.0;
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- ORBE JOUEUR NÉON ÉPURÉE + BADGE ANTI-VENIN ---
class NeonPlayerOrb extends StatelessWidget {
  final BoardPlayer boardPlayer;
  final bool isActive;

  const NeonPlayerOrb({
    super.key,
    required this.boardPlayer,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = boardPlayer.color;

    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (isActive)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 1.6,
                ),
              ),
            ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.25, -0.25),
                radius: 0.85,
                colors: [
                  Colors.white,
                  Color.lerp(Colors.white, color, 0.6)!,
                  color,
                ],
                stops: const [0.0, 0.35, 1.0],
              ),
              border: Border.all(color: Colors.white, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.75),
                  blurRadius: isActive ? 10 : 5,
                  spreadRadius: isActive ? 1.5 : 0.5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                boardPlayer.player.name.isNotEmpty
                    ? boardPlayer.player.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Color(0xFF050512),
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
          if (boardPlayer.hasShield)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFF051E14),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.greenAccent, width: 1.4),
                ),
                child: const Icon(
                  Icons.science_rounded,
                  size: 10,
                  color: Colors.greenAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- VRAIE ICÔNE DE DÉMON CARTOON NÉON 😈 (CUSTOMPAINT) ---
class CartoonDemonIcon extends StatelessWidget {
  final Color color;
  final double size;
  const CartoonDemonIcon({super.key, required this.color, this.size = 23});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CartoonDemonPainter(color: color),
    );
  }
}

class _CartoonDemonPainter extends CustomPainter {
  final Color color;
  const _CartoonDemonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Petites cornes pointues malicieuses néon
    final Path leftHorn = Path()
      ..moveTo(w * 0.28, h * 0.32)
      ..quadraticBezierTo(w * 0.16, h * 0.18, w * 0.12, h * 0.05)
      ..quadraticBezierTo(w * 0.28, h * 0.12, w * 0.40, h * 0.24)
      ..close();
    final Path rightHorn = Path()
      ..moveTo(w * 0.72, h * 0.32)
      ..quadraticBezierTo(w * 0.84, h * 0.18, w * 0.88, h * 0.05)
      ..quadraticBezierTo(w * 0.72, h * 0.12, w * 0.60, h * 0.24)
      ..close();

    final Paint hornPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftHorn, hornPaint);
    canvas.drawPath(rightHorn, hornPaint);

    // 2. Visage rond cartoon
    final Offset center = Offset(w * 0.5, h * 0.58);
    final double radius = w * 0.40;

    final Paint faceFill = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    final Paint faceStroke = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, faceFill);
    canvas.drawCircle(center, radius, faceStroke);

    // 3. Yeux triangulaires malicieux blancs
    final Path leftEye = Path()
      ..moveTo(w * 0.32, h * 0.48)
      ..lineTo(w * 0.45, h * 0.54)
      ..lineTo(w * 0.36, h * 0.58)
      ..close();
    final Path rightEye = Path()
      ..moveTo(w * 0.68, h * 0.48)
      ..lineTo(w * 0.55, h * 0.54)
      ..lineTo(w * 0.64, h * 0.58)
      ..close();

    final Paint eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftEye, eyePaint);
    canvas.drawPath(rightEye, eyePaint);

    // 4. Large sourire malicieux avec petites canines
    final Path smile = Path()
      ..moveTo(w * 0.32, h * 0.68)
      ..quadraticBezierTo(w * 0.5, h * 0.88, w * 0.68, h * 0.68);

    final Paint smilePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(smile, smilePaint);

    // Deux petites canines cartoon
    final Path leftFang = Path()
      ..moveTo(w * 0.40, h * 0.73)
      ..lineTo(w * 0.44, h * 0.81)
      ..lineTo(w * 0.46, h * 0.74)
      ..close();
    final Path rightFang = Path()
      ..moveTo(w * 0.60, h * 0.73)
      ..lineTo(w * 0.56, h * 0.81)
      ..lineTo(w * 0.54, h * 0.74)
      ..close();
    canvas.drawPath(leftFang, eyePaint);
    canvas.drawPath(rightFang, eyePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- ICÔNES MINIMALISTES SERPENT (SNAKE) & ÉCHELLE (LADDER) ---
class MinimalSnakeIcon extends StatelessWidget {
  final Color color;
  final double size;
  const MinimalSnakeIcon({super.key, required this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MinimalSnakeIconPainter(color: color),
    );
  }
}

class _MinimalSnakeIconPainter extends CustomPainter {
  final Color color;
  const _MinimalSnakeIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bodyPaint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.82)
      ..cubicTo(
        size.width * 0.85,
        size.height * 0.85,
        size.width * 0.1,
        size.height * 0.42,
        size.width * 0.62,
        size.height * 0.26,
      );
    canvas.drawPath(path, bodyPaint);

    final Offset headCenter = Offset(size.width * 0.66, size.height * 0.24);
    canvas.drawCircle(
      headCenter,
      size.width * 0.16,
      Paint()..color = color,
    );
    canvas.drawCircle(
      headCenter + Offset(size.width * 0.03, -size.height * 0.02),
      1.2,
      Paint()..color = const Color(0xFF14051E),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MinimalLadderIcon extends StatelessWidget {
  final Color color;
  final double size;
  const MinimalLadderIcon({super.key, required this.color, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MinimalLadderIconPainter(color: color),
    );
  }
}

class _MinimalLadderIconPainter extends CustomPainter {
  final Color color;
  const _MinimalLadderIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint railPaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final Paint rungPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.88),
      Offset(size.width * 0.42, size.height * 0.12),
      railPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.62, size.height * 0.88),
      Offset(size.width * 0.76, size.height * 0.12),
      railPaint,
    );

    for (final double t in [0.28, 0.52, 0.76]) {
      final double y = size.height * t;
      final double shift = (1 - t) * size.width * 0.14;
      canvas.drawLine(
        Offset(size.width * 0.28 + shift, y),
        Offset(size.width * 0.62 + shift, y),
        rungPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- WIDGETS ANNEXES (CARTES, DÉ) ---
class FlipCard extends StatelessWidget {
  final TileAction action;
  const FlipCard({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    late final Color accentColor;
    late final IconData headerIcon;

    switch (action.type) {
      case TileType.special:
        accentColor = Colors.amberAccent;
        headerIcon = action.shield
            ? Icons.science_rounded
            : (action.reroll ? Icons.casino_rounded : Icons.bolt_rounded);
        break;
      case TileType.spicy:
        accentColor = const Color(0xFFFF2A85);
        headerIcon = Icons.whatshot_rounded;
        break;
      case TileType.drink:
        accentColor = const Color(0xFF00E5FF);
        headerIcon = Icons.local_bar_rounded;
        break;
      case TileType.question:
        accentColor = const Color(0xFF40C4FF);
        headerIcon = Icons.chat_bubble_outline_rounded;
        break;
      case TileType.action:
        accentColor = const Color(0xFFFF5252);
        headerIcon = Icons.mood_bad_rounded;
        break;
    }

    return Container(
      width: 300,
      height: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF0E1022),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: accentColor, width: 3),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: 0.45), blurRadius: 18),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            headerIcon,
            color: accentColor,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            action.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accentColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            action.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class DiceFace extends StatelessWidget {
  final int value;
  final Color color;
  final double size;
  const DiceFace({
    super.key,
    required this.value,
    required this.color,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final double padding = size * 0.15;
    final double dotSize = size * 0.20;
    final Widget dot = Container(
      width: dotSize,
      height: dotSize,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
    final List<Widget> dots = [];
    if (value % 2 != 0) dots.add(Center(child: dot));
    if (value > 1) {
      dots.add(Positioned(top: padding, left: padding, child: dot));
      dots.add(Positioned(bottom: padding, right: padding, child: dot));
    }
    if (value > 3) {
      dots.add(Positioned(top: padding, right: padding, child: dot));
      dots.add(Positioned(bottom: padding, left: padding, child: dot));
    }
    if (value == 6) {
      dots.add(
        Positioned(top: (size / 2) - (dotSize / 2), left: padding, child: dot),
      );
      dots.add(
        Positioned(top: (size / 2) - (dotSize / 2), right: padding, child: dot),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: Stack(children: dots),
    );
  }
}

// --- PAINTER NÉON VECTORIEL ÉPURÉ ---
class LaddersPainter extends CustomPainter {
  final List<Offset> tileCenters;
  final List<BoardLadder> ladders;
  final bool isSpiral;
  final double tileWidth;
  final double tileHeight;

  const LaddersPainter({
    required this.tileCenters,
    required this.ladders,
    this.isSpiral = false,
    this.tileWidth = 92.0,
    this.tileHeight = 58.0,
  });

  Offset _anchorNearTileEdge(
    Offset center,
    Offset toward, {
    double edgeFactor = 0.82,
  }) {
    final Offset delta = toward - center;
    if (delta.distance < 1.0) return center;
    final Offset dir = delta / delta.distance;

    final double halfW = tileWidth / 2;
    final double halfH = tileHeight / 2;
    final double tx =
        dir.dx.abs() > 1e-4 ? halfW / dir.dx.abs() : double.infinity;
    final double ty =
        dir.dy.abs() > 1e-4 ? halfH / dir.dy.abs() : double.infinity;
    final double distToBorder = min(tx, ty);

    return center + dir * (distToBorder * edgeFactor);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (tileCenters.isEmpty) return;

    if (isSpiral) {
      // Mode Spirale : Portails néon reliant les anneaux voisins à travers le couloir
      for (final portal in ladders) {
        if (portal.fromTile < tileCenters.length &&
            portal.toTile < tileCenters.length) {
          final Offset rawStart = tileCenters[portal.fromTile];
          final Offset rawEnd = tileCenters[portal.toTile];
          _paintSpiralPortalBeam(
            canvas,
            _anchorNearTileEdge(rawStart, rawEnd, edgeFactor: 0.85),
            _anchorNearTileEdge(rawEnd, rawStart, edgeFactor: 0.82),
            portal.color,
          );
        }
      }
      return;
    }

    // Mode Lacets : Échelles (LADDER) et Serpents (SNAKE) dans les couloirs
    for (final ladder in ladders.where((l) => l.isLadder)) {
      if (ladder.fromTile < tileCenters.length &&
          ladder.toTile < tileCenters.length) {
        final Offset rawStart = tileCenters[ladder.fromTile];
        final Offset rawEnd = tileCenters[ladder.toTile];
        _paintCleanNeonLadder(
          canvas,
          _anchorNearTileEdge(rawStart, rawEnd, edgeFactor: 0.82),
          _anchorNearTileEdge(rawEnd, rawStart, edgeFactor: 0.82),
          ladder.color,
        );
      }
    }

    for (final snake in ladders.where((l) => !l.isLadder)) {
      if (snake.fromTile < tileCenters.length &&
          snake.toTile < tileCenters.length) {
        final Offset rawStart = tileCenters[snake.fromTile];
        final Offset rawEnd = tileCenters[snake.toTile];
        _paintCleanNeonSnake(
          canvas,
          _anchorNearTileEdge(rawStart, rawEnd, edgeFactor: 1.02),
          _anchorNearTileEdge(rawEnd, rawStart, edgeFactor: 0.82),
          snake.color,
        );
      }
    }
  }

  void _paintSpiralPortalBeam(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
  ) {
    final double dist = (end - start).distance;
    if (dist < 1.0) return;

    final Offset dir = (end - start) / dist;
    final Offset perp = Offset(-dir.dy, dir.dx);

    // Glow externe
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color.withValues(alpha: 0.22)
        ..strokeWidth = 9.0
        ..strokeCap = StrokeCap.round,
    );

    // Faisceau central néon
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );

    // Coeur blanc lumineux
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    // Anneau d'entrée du portail
    canvas.drawCircle(
      start,
      5.0,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      start,
      4.5,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    canvas.drawCircle(
      start,
      1.8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Flèche d'arrivée directionnelle
    final Offset arrowBase = end - dir * 8.5;
    final Path arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowBase.dx + perp.dx * 5.5, arrowBase.dy + perp.dy * 5.5)
      ..lineTo(arrowBase.dx - perp.dx * 5.5, arrowBase.dy - perp.dy * 5.5)
      ..close();
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void _paintCleanNeonLadder(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
  ) {
    final double dist = (end - start).distance;
    if (dist < 1.0) return;

    final Offset dir = (end - start) / dist;
    final Offset perp = Offset(-dir.dy, dir.dx) * 8.0;

    final Offset lStart = start - perp;
    final Offset lEnd = end - perp;
    final Offset rStart = start + perp;
    final Offset rEnd = end + perp;

    final Paint railShadowPaint = Paint()
      ..color = const Color(0xFF050711).withValues(alpha: 0.45)
      ..strokeWidth = 4.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(lStart, lEnd, railShadowPaint);
    canvas.drawLine(rStart, rEnd, railShadowPaint);

    final Paint glowPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(lStart, lEnd, glowPaint);
    canvas.drawLine(rStart, rEnd, glowPaint);

    final Paint rungPaint = Paint()
      ..color = color.withValues(alpha: 0.78)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final int count = max(3, (dist / 16).floor());
    for (int i = 1; i < count; i++) {
      final Offset c = Offset.lerp(start, end, i / count)!;
      canvas.drawLine(c - perp, c + perp, rungPaint);
    }

    final Paint railPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(lStart, lEnd, railPaint);
    canvas.drawLine(rStart, rEnd, railPaint);
  }

  void _paintCleanNeonSnake(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
  ) {
    final double dist = (end - start).distance;
    if (dist < 1.0) return;

    final Offset dir = (end - start) / dist;
    final Offset perp = Offset(-dir.dy, dir.dx);

    const int steps = 40;
    const double amplitude = 12.0;
    final Path bodyPath = Path();
    final List<Offset> pts = [];

    for (int i = 0; i <= steps; i++) {
      final double t = i / steps;
      final Offset base = Offset.lerp(start, end, t)!;
      final double wave = sin(t * pi * 2.0) * amplitude * sin(t * pi);
      final Offset p = base + perp * wave;
      pts.add(p);
      if (i == 0) {
        bodyPath.moveTo(p.dx, p.dy);
      } else {
        bodyPath.lineTo(p.dx, p.dy);
      }
    }

    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..strokeWidth = 14.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = color
        ..strokeWidth = 10.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFF070914)
        ..strokeWidth = 5.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final ui.PathMetrics metrics = bodyPath.computeMetrics();
    final Paint dashPaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final ui.PathMetric metric in metrics) {
      double d = 8.0;
      while (d < metric.length - 6.0) {
        final Path dash = metric.extractPath(d, min(d + 3.0, metric.length));
        canvas.drawPath(dash, dashPaint);
        d += 7.5;
      }
    }

    final Offset headDir = pts.length > 2 ? (pts[2] - start) : (end - start);
    final double headAngle = atan2(headDir.dy, headDir.dx);

    canvas.save();
    canvas.translate(start.dx, start.dy);
    canvas.rotate(headAngle + pi);

    final Path headPath = Path()
      ..moveTo(-4.0, -3.5)
      ..cubicTo(0.0, -9.5, 5.5, -8.5, 9.5, -3.0)
      ..quadraticBezierTo(12.5, 0.0, 9.5, 3.0)
      ..cubicTo(5.5, 8.5, 0.0, 9.5, -4.0, 3.5)
      ..close();

    final Path tonguePath = Path()
      ..moveTo(11.5, 0.0)
      ..lineTo(15.0, 0.0)
      ..moveTo(15.0, 0.0)
      ..lineTo(18.0, -2.5)
      ..moveTo(15.0, 0.0)
      ..lineTo(18.0, 2.5);

    canvas.drawPath(
      tonguePath,
      Paint()
        ..color = Colors.redAccent
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawPath(
      headPath,
      Paint()
        ..color = color.withValues(alpha: 0.22)
        ..strokeWidth = 5.0
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawPath(
      headPath,
      Paint()
        ..color = const Color(0xFF070914)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      headPath,
      Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );

    final Paint eyePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(4.0, -3.2), 1.6, eyePaint);
    canvas.drawCircle(const Offset(4.0, 3.2), 1.6, eyePaint);

    final Paint pupilSparkle = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(4.4, -3.2), 0.65, pupilSparkle);
    canvas.drawCircle(const Offset(4.4, 3.2), 0.65, pupilSparkle);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LaddersPainter oldDelegate) {
    return oldDelegate.ladders != ladders ||
        oldDelegate.tileCenters != tileCenters ||
        oldDelegate.isSpiral != isSpiral;
  }
}
