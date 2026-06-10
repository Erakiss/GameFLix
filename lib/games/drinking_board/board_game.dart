import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';

import 'package:gameflix/models/player.dart';

// --- MACHINE D'ÉTAT ABSOLUE ---
enum GamePhase { idle, rolling, moving, card, transition, victory }

// --- MODÈLES LOCAUX ---
enum TileType { action, question, drink, special }

class TileAction {
  final String title;
  final String description;
  final TileType type;
  final int movement;

  TileAction({required this.title, required this.description, required this.type, this.movement = 0});

  factory TileAction.fromJson(Map<String, dynamic> json) {
    return TileAction(
      title: json['title'] ?? 'ACTION',
      description: json['description'] ?? '',
      type: TileType.values.firstWhere((e) => e.name == json['type'], orElse: () => TileType.action),
      movement: json['movement'] ?? 0,
    );
  }
}

class BoardLadder {
  final int fromTile;
  final int toTile;
  final Color color;
  const BoardLadder({required this.fromTile, required this.toTile, required this.color});
}

class BoardPlayer {
  final Player player;
  final Color color;
  int currentTileIndex;

  // STATS DE FIN DE PARTIE
  int sipsCount = 0;
  int laddersClimbed = 0;
  int snakesSlid = 0;

  BoardPlayer({required this.player, required this.color, this.currentTileIndex = 0});
}

// --- ÉCRAN PRINCIPAL ---
class BoardGameScreen extends StatefulWidget {
  final List<Player> players;
  const BoardGameScreen({super.key, required this.players});

  @override
  State<BoardGameScreen> createState() => _BoardGameScreenState();
}

class _BoardGameScreenState extends State<BoardGameScreen> with TickerProviderStateMixin {
  final TransformationController _cameraController = TransformationController();
  late AnimationController _cameraAnimController;
  Animation<Matrix4>? _cameraAnimation;

  // --- PARAMÈTRES DU PLATEAU ---
  final int _totalTiles = 62; // 0 = Départ, 1-60 = Jeu, 61 = Fin
  final double _tileWidth = 90.0;
  final double _tileHeight = 55.0;

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

  List<TileAction> _actionPool = [];
  TileAction? _currentAction;

  // 4 Ladders (Montée) et 4 Snakes (Descente)
  final List<BoardLadder> _ladders = [
    const BoardLadder(fromTile: 8, toTile: 25, color: Colors.greenAccent),
    const BoardLadder(fromTile: 19, toTile: 35, color: Colors.greenAccent),
    const BoardLadder(fromTile: 33, toTile: 48, color: Colors.greenAccent),
    const BoardLadder(fromTile: 44, toTile: 56, color: Colors.greenAccent),
    const BoardLadder(fromTile: 28, toTile: 4, color: Colors.purpleAccent),
    const BoardLadder(fromTile: 40, toTile: 15, color: Colors.purpleAccent),
    const BoardLadder(fromTile: 52, toTile: 22, color: Colors.purpleAccent),
    const BoardLadder(fromTile: 57, toTile: 42, color: Colors.purpleAccent),
  ];

  @override
  void initState() {
    super.initState();
    _cameraAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

    List<Color> availableColors = [Colors.blueAccent, Colors.pinkAccent, Colors.amber, Colors.greenAccent, Colors.redAccent, Colors.purpleAccent];
    for (int i = 0; i < widget.players.length; i++) {
      _boardPlayers.add(BoardPlayer(player: widget.players[i], color: availableColors[i % availableColors.length]));
    }

    _buildBoardLayout();
    _loadCards();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_boardPlayers.isNotEmpty) _focusCameraOnTile(0, scale: 0.7, animate: false);
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _cameraAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    try {
      final String response = await rootBundle.loadString('assets/data/board_cards.json');
      final List<dynamic> data = json.decode(response);
      setState(() => _actionPool = data.map((item) => TileAction.fromJson(item)).toList());
    } catch (e) {
      debugPrint("Erreur JSON: $e");
      setState(() => _actionPool = [TileAction(title: "ERREUR", description: "Vérifie ton JSON", type: TileType.action)]);
    }
  }

  // --- LOGIQUE CAMÉRA ---
  void _focusCameraOnTile(int tileIndex, {required double scale, required bool animate, Duration duration = const Duration(milliseconds: 1000)}) {
    if (_tileCenters.isEmpty) return;
    Offset target = _tileCenters[tileIndex];
    final size = MediaQuery.of(context).size;
    
    Matrix4 endMatrix = Matrix4.identity()
      ..multiply(Matrix4.translationValues(size.width / 2, size.height / 2, 0.0))
      ..multiply(Matrix4.diagonal3Values(scale, scale, 1.0))
      ..multiply(Matrix4.translationValues(-target.dx, -target.dy, 0.0));

    if (animate) {
      _cameraAnimation?.removeListener(_updateCamera);
      _cameraAnimController.duration = duration;
      _cameraAnimation = Matrix4Tween(begin: _cameraController.value, end: endMatrix)
        .animate(CurvedAnimation(parent: _cameraAnimController, curve: Curves.easeInOutSine));
      _cameraAnimation!.addListener(_updateCamera);
      _cameraAnimController.forward(from: 0.0);
    } else {
      _cameraController.value = endMatrix;
    }
  }

  void _updateCamera() => _cameraController.value = _cameraAnimation!.value;

  // --- CALCUL DE POSITION (MOTIF DÉ) ---
  Offset _getOffsetForPlayer(int playerIndexOnTile, int totalPlayersOnTile) {
    switch (totalPlayersOnTile) {
      case 2:
        if (playerIndexOnTile == 0) return const Offset(-10, -10);
        return const Offset(10, 10);
      case 3:
        if (playerIndexOnTile == 0) return const Offset(-10, -10);
        if (playerIndexOnTile == 1) return const Offset(10, 10);
        return const Offset(0, 0);
      case 4:
        if (playerIndexOnTile == 0) return const Offset(-10, -10);
        if (playerIndexOnTile == 1) return const Offset(10, -10);
        if (playerIndexOnTile == 2) return const Offset(-10, 10);
        return const Offset(10, 10);
      default:
        return const Offset(0, 0);
    }
  }

  // --- GÉNÉRATION DU PLATEAU ---
  void _buildBoardLayout() {
    List<List<int>> segments = [[11, 1, 0], [9, 0, -1], [11, -1, 0], [7, 0, 1], [9, 1, 0], [5, 0, -1], [7, -1, 0], [3, 0, 1], [4, 1, 0]]; // Ajusté pour 62 cases
    List<Offset> positions = [];
    int currentX = 0; int currentY = 0;

    for (var seg in segments) {
      for (int i = 0; i < seg[0]; i++) {
        if (positions.length < _totalTiles) {
          positions.add(Offset(currentX.toDouble(), currentY.toDouble()));
          currentX += seg[1]; currentY += seg[2];
        }
      }
    }

    double stepX = 90.0; 
    double stepY = 55.0;
    _tileCenters = []; _boardTiles = [];

    double minX = positions.map((p) => p.dx).reduce(min);
    double minY = positions.map((p) => p.dy).reduce(min);
    double maxX = positions.map((p) => p.dx).reduce(max);
    double maxY = positions.map((p) => p.dy).reduce(max);

    for (int i = 0; i < positions.length; i++) {
      double finalX = (positions[i].dx - minX) * stepX + 50; 
      double finalY = (positions[i].dy - minY) * stepY + 50;
      _tileCenters.add(Offset(finalX + _tileWidth / 2, finalY + _tileHeight / 2));

      Color tileBackgroundColor = const Color(0xFF0C1020); 
      late Color neonColor; 
      late String tileText;

      if (i == 0) {
        neonColor = Colors.greenAccent;
        tileText = "DÉPART";
      } else if (i == positions.length - 1) {
        neonColor = Colors.amberAccent;
        tileText = "FIN";
      } else if (i % 6 == 0) {
        neonColor = Colors.white;
        tileText = "SPÉCIAL";
      } else {
        bool isTruth = i % 2 != 0; 
        neonColor = isTruth ? Colors.redAccent : Colors.lightBlueAccent; 
        tileText = isTruth ? "TRUTH" : "DARE"; 
      }

      Widget? ladderBadge;
      try {
        var ladderOut = _ladders.firstWhere((l) => l.fromTile == i);
        ladderBadge = Icon(ladderOut.toTile > ladderOut.fromTile ? Icons.keyboard_double_arrow_up : Icons.keyboard_double_arrow_down, size: 16, color: ladderOut.color);
      } catch (_) {}
      try {
        _ladders.firstWhere((l) => l.toTile == i);
        ladderBadge ??= const Icon(Icons.adjust, size: 12, color: Colors.white54);
      } catch (_) {}

      _boardTiles.add(
        Positioned(
          left: finalX, top: finalY,
          child: Container(
            width: _tileWidth, height: _tileHeight,
            decoration: BoxDecoration(
              color: tileBackgroundColor, 
              border: Border.all(color: neonColor, width: 2.0), 
              boxShadow: [
                BoxShadow(color: Colors.purpleAccent.withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 2)
              ]
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("$i", style: TextStyle(color: neonColor.withValues(alpha: 0.5), fontWeight: FontWeight.bold, fontSize: 9)),
                      const SizedBox(height: 1),
                      Text(tileText, textAlign: TextAlign.center, style: TextStyle(color: neonColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                if (ladderBadge != null) Positioned(bottom: 2, right: 2, child: ladderBadge),
              ],
            ),
          ),
        )
      );
    }
    _boardWidth = (maxX - minX) * stepX + _tileWidth + 100;
    _boardHeight = (maxY - minY) * stepY + _tileHeight + 100;
  }

  // --- LOGIQUE SÉCURISÉE DU JEU ---
  Future<void> _rollDiceAndMove() async {
    if (_phase != GamePhase.idle || _boardPlayers.isEmpty) return;

    setState(() => _phase = GamePhase.rolling);

    _focusCameraOnTile(_boardPlayers[_currentPlayerIndex].currentTileIndex, scale: 1.0, animate: true, duration: const Duration(milliseconds: 600));
    
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      setState(() { _diceValue = Random().nextInt(6) + 1; _diceRotation += 0.35; });
    }
    
    int steps = Random().nextInt(6) + 1;
    setState(() { _diceValue = steps; _diceRotation = 0.0; });
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() => _phase = GamePhase.moving);

    BoardPlayer currentPlayer = _boardPlayers[_currentPlayerIndex];
    for (int i = 0; i < steps; i++) {
      if (currentPlayer.currentTileIndex < _totalTiles - 1) {
        setState(() => currentPlayer.currentTileIndex++);
        _focusCameraOnTile(currentPlayer.currentTileIndex, scale: 1.0, animate: true, duration: const Duration(milliseconds: 250));
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    // Victoire immédiate
    if (currentPlayer.currentTileIndex == _totalTiles - 1) {
      setState(() => _phase = GamePhase.victory);
      return;
    }

    // Serpents et Échelles
    try {
      var ladder = _ladders.firstWhere((l) => l.fromTile == currentPlayer.currentTileIndex);
      setState(() {
        currentPlayer.currentTileIndex = ladder.toTile;
        if (ladder.toTile > ladder.fromTile) {
          currentPlayer.laddersClimbed++;
        } else {
          currentPlayer.snakesSlid++;
        }
      });
      _focusCameraOnTile(currentPlayer.currentTileIndex, scale: 1.0, animate: true, duration: const Duration(milliseconds: 400));
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (_) {}

    await _triggerTileAction(currentPlayer.currentTileIndex);

    // Si victoire post-carte
    if (currentPlayer.currentTileIndex == _totalTiles - 1) {
      setState(() => _phase = GamePhase.victory);
      return;
    }

    // --- TRANSITION DU TOUR ---
    setState(() => _phase = GamePhase.transition);
    
    int nextIndex = (_currentPlayerIndex + 1) % _boardPlayers.length;
    setState(() => _currentPlayerIndex = nextIndex);

    _focusCameraOnTile(_boardPlayers[_currentPlayerIndex].currentTileIndex, scale: 1.5, animate: true, duration: const Duration(milliseconds: 800));
    await Future.delayed(const Duration(milliseconds: 1200));

    _focusCameraOnTile(_boardPlayers[_currentPlayerIndex].currentTileIndex, scale: 0.8, animate: true, duration: const Duration(milliseconds: 600));
    await Future.delayed(const Duration(milliseconds: 600));

    setState(() => _phase = GamePhase.idle);
  }

  Future<void> _triggerTileAction(int index) async {
    if (index == 0 || index == _totalTiles - 1) return;
    if (_actionPool.isEmpty) return;

    bool isSpecial = index % 6 == 0;
    bool isQuestion = !isSpecial && index % 2 != 0;

    List<TileAction> possibleCards = _actionPool.where((card) {
      if (isSpecial) return card.type == TileType.special;
      if (isQuestion) return card.type == TileType.question;
      return card.type == TileType.action || card.type == TileType.drink;
    }).toList();

    if (possibleCards.isEmpty) possibleCards = _actionPool;

    setState(() {
      _currentAction = possibleCards[Random().nextInt(possibleCards.length)];
      
      if (_currentAction!.type == TileType.drink) {
        _boardPlayers[_currentPlayerIndex].sipsCount += 3;
      } else if (_currentAction!.type == TileType.action) {
        _boardPlayers[_currentPlayerIndex].sipsCount += 1;
      }
      
      _phase = GamePhase.card;
    });

    while (_phase == GamePhase.card) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (_currentAction!.movement != 0) {
      setState(() => _phase = GamePhase.moving); 
      int newIndex = (_boardPlayers[_currentPlayerIndex].currentTileIndex + _currentAction!.movement).clamp(0, _totalTiles - 1);
      setState(() => _boardPlayers[_currentPlayerIndex].currentTileIndex = newIndex);
      _focusCameraOnTile(newIndex, scale: 1.0, animate: true, duration: const Duration(milliseconds: 500));
      await Future.delayed(const Duration(milliseconds: 1500)); 
    }
  }

  // --- WIDGET UTILITAIRE (STATS) ---
  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_boardPlayers.isEmpty) return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text("Ajoute des joueurs !")));

    BoardPlayer currentPlayer = _boardPlayers[_currentPlayerIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // --- 1. LE PLATEAU ---
            InteractiveViewer(
              transformationController: _cameraController,
              constrained: false, boundaryMargin: const EdgeInsets.all(1200), minScale: 0.15, maxScale: 2.5,
              child: SizedBox(
                width: _boardWidth, height: _boardHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ..._boardTiles, // 1. Cases au fond
                    CustomPaint(size: Size(_boardWidth, _boardHeight), painter: LaddersPainter(tileCenters: _tileCenters, ladders: _ladders)), // 2. Échelles par dessus
                    if (_tileCenters.isNotEmpty)
                      ..._boardPlayers.map((p) {
                        List<BoardPlayer> onSameTile = _boardPlayers.where((other) => other.currentTileIndex == p.currentTileIndex).toList();
                        int indexOnTile = onSameTile.indexOf(p);
                        Offset dynamicOffset = _getOffsetForPlayer(indexOnTile, onSameTile.length);
                        Offset center = _tileCenters[p.currentTileIndex];

                        return AnimatedPositioned(
                          duration: const Duration(milliseconds: 250), curve: Curves.easeInOutSine,
                          left: center.dx - 16 + dynamicOffset.dx, top: center.dy - 16 + dynamicOffset.dy,
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: p.color, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: p.color.withValues(alpha: 0.8), blurRadius: 4, spreadRadius: 1)]),
                            child: Center(child: Text(p.player.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                          ),
                        );
                      }), // 3. Pions en haut
                  ],
                ),
              ),
            ),

            // --- 2. LE GROS DÉ ---
            IgnorePointer(
              ignoring: _phase != GamePhase.rolling,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: _phase == GamePhase.rolling ? Colors.black.withValues(alpha: 0.6) : Colors.transparent,
                child: Center(
                  child: AnimatedScale(
                    scale: _phase == GamePhase.rolling ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400), curve: Curves.elasticOut,
                    child: AnimatedRotation(
                      turns: _diceRotation, duration: const Duration(milliseconds: 60),
                      child: DiceFace(value: _diceValue, color: currentPlayer.color, size: 130),
                    ),
                  ),
                ),
              ),
            ),

            // --- 3. L'ÉCRAN DE TRANSITION ---
            IgnorePointer(
              ignoring: _phase != GamePhase.transition,
              child: AnimatedOpacity(
                opacity: _phase == GamePhase.transition ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5), 
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: currentPlayer.color, strokeWidth: 6),
                        const SizedBox(height: 30),
                        Text("À ${currentPlayer.player.name.toUpperCase()} DE JOUER !", style: TextStyle(color: currentPlayer.color, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2, shadows: const [Shadow(color: Colors.black, blurRadius: 10)])),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // --- 4. HUD FIXE ---
            Positioned(top: 10, left: 10, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context))),
            
            Positioned(
              bottom: 30, left: 20, right: 20,
              child: AnimatedOpacity(
                opacity: (_phase == GamePhase.idle || _phase == GamePhase.rolling || _phase == GamePhase.moving) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: _phase != GamePhase.idle,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20), border: Border.all(color: currentPlayer.color, width: 1.5)),
                        child: Text("Tour de ${currentPlayer.player.name}", style: TextStyle(color: currentPlayer.color, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                      const SizedBox(height: 15),
                      GestureDetector(
                        onTap: _phase == GamePhase.idle ? _rollDiceAndMove : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 65,
                          decoration: BoxDecoration(
                            color: _phase != GamePhase.idle ? Colors.grey.shade900 : currentPlayer.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(35),
                            border: Border.all(color: _phase != GamePhase.idle ? Colors.grey : currentPlayer.color, width: 3),
                            boxShadow: _phase != GamePhase.idle ? [] : [BoxShadow(color: currentPlayer.color.withValues(alpha: 0.4), blurRadius: 15, spreadRadius: 1)]
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.casino, color: _phase != GamePhase.idle ? Colors.grey : Colors.white, size: 28),
                              const SizedBox(width: 15),
                              Text(_phase != GamePhase.idle ? "EN COURS..." : "LANCER LE DÉ", style: TextStyle(color: _phase != GamePhase.idle ? Colors.grey : Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- 5. CARTE (BOUCLIER ANTI-CLIC) ---
            if (_phase == GamePhase.card && _currentAction != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    if (_phase == GamePhase.card) setState(() => _phase = GamePhase.moving); 
                  },
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Center(
                      child: TweenAnimationBuilder(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, double val, child) {
                          return Transform(
                            transform: Matrix4.rotationY(val * pi), alignment: Alignment.center,
                            child: val < 0.5 
                              ? Container(width: 300, height: 400, decoration: BoxDecoration(color: Colors.blueGrey.shade900, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white24, width: 2)), child: const Center(child: Text("?", style: TextStyle(color: Colors.white, fontSize: 50))))
                              : Transform(transform: Matrix4.rotationY(pi), alignment: Alignment.center, child: FlipCard(action: _currentAction!)),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

            // --- 6. ÉCRAN DE VICTOIRE ---
            if (_phase == GamePhase.victory)
              Positioned.fill(
                child: Container(
                  color: Colors.black87,
                  child: Stack(
                    children: [
                      const NeonConfettiWidget(),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emoji_events, color: currentPlayer.color, size: 100, shadows: [BoxShadow(color: currentPlayer.color.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 10)]),
                            const SizedBox(height: 10),
                            Text("VICTOIRE !", style: TextStyle(color: currentPlayer.color, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 3)),
                            const SizedBox(height: 5),
                            Text(currentPlayer.player.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            const SizedBox(height: 40),
                            Container(
                              width: 320, padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: const Color(0xFF0C1020), borderRadius: BorderRadius.circular(20), border: Border.all(color: currentPlayer.color, width: 2), boxShadow: [BoxShadow(color: currentPlayer.color.withValues(alpha: 0.2), blurRadius: 20)]),
                              child: Column(
                                children: [
                                  _buildStatRow(Icons.local_bar, "Gorgées cumulées", "${currentPlayer.sipsCount}", Colors.amberAccent),
                                  const Divider(color: Colors.white12, height: 20),
                                  _buildStatRow(Icons.keyboard_double_arrow_up, "Échelles grimpées", "${currentPlayer.laddersClimbed}", Colors.greenAccent),
                                  const Divider(color: Colors.white12, height: 20),
                                  _buildStatRow(Icons.keyboard_double_arrow_down, "Serpents subis", "${currentPlayer.snakesSlid}", Colors.purpleAccent),
                                ],
                              ),
                            ),
                            const SizedBox(height: 50),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: currentPlayer.color.withValues(alpha: 0.2),
                                side: BorderSide(color: currentPlayer.color, width: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              label: const Text("RETOURNER AU HUB", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGETS ANNEXES (CARTES, DÉ) ---
class FlipCard extends StatelessWidget {
  final TileAction action;
  const FlipCard({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300, height: 400,
      decoration: BoxDecoration(color: const Color(0xFF111122), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.cyanAccent, width: 3), boxShadow: const [BoxShadow(color: Colors.cyanAccent, blurRadius: 20)]),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(action.title, style: const TextStyle(color: Colors.cyanAccent, fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text(action.description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20)),
        ],
      ),
    );
  }
}

class DiceFace extends StatelessWidget {
  final int value; final Color color; final double size;
  const DiceFace({super.key, required this.value, required this.color, this.size = 60});

  @override
  Widget build(BuildContext context) {
    double padding = size * 0.15; double dotSize = size * 0.20;
    Widget dot = Container(width: dotSize, height: dotSize, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)]));
    List<Widget> dots = [];
    if (value % 2 != 0) dots.add(Center(child: dot)); 
    if (value > 1) { dots.add(Positioned(top: padding, left: padding, child: dot)); dots.add(Positioned(bottom: padding, right: padding, child: dot)); }
    if (value > 3) { dots.add(Positioned(top: padding, right: padding, child: dot)); dots.add(Positioned(bottom: padding, left: padding, child: dot)); }
    if (value == 6) { dots.add(Positioned(top: (size / 2) - (dotSize / 2), left: padding, child: dot)); dots.add(Positioned(top: (size / 2) - (dotSize / 2), right: padding, child: dot)); }
    return Container(width: size, height: size, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 1)]), child: Stack(children: dots));
  }
}

// --- PAINTER DES SERPENTS ET ÉCHELLES ---
class LaddersPainter extends CustomPainter {
  final List<Offset> tileCenters; final List<BoardLadder> ladders;
  LaddersPainter({required this.tileCenters, required this.ladders});

  @override
  void paint(Canvas canvas, Size size) {
    if (tileCenters.isEmpty) return;
    for (var ladder in ladders) {
      if (ladder.fromTile >= tileCenters.length || ladder.toTile >= tileCenters.length) continue;
      
      Offset start = tileCenters[ladder.fromTile]; 
      Offset end = tileCenters[ladder.toTile];
      bool isLadder = ladder.toTile > ladder.fromTile;

      if (isLadder) {
        final paintLadder = Paint()..color = ladder.color..strokeWidth = 3.0;
        final paintRung = Paint()..color = Colors.white..strokeWidth = 2.0;

        Offset dir = (end - start) / (end - start).distance;
        Offset perp = Offset(-dir.dy, dir.dx) * 8; 

        canvas.drawLine(start - perp, end - perp, paintLadder);
        canvas.drawLine(start + perp, end + perp, paintLadder);

        int count = ((end - start).distance / 20).floor();
        for (int i = 1; i < count; i++) {
          Offset center = Offset.lerp(start, end, i / count)!;
          canvas.drawLine(center - perp, center + perp, paintRung);
        }
      } else {
        final paintSnake = Paint()..color = ladder.color..strokeWidth = 2.0..style = PaintingStyle.stroke;
        Offset dir = (end - start) / (end - start).distance;
        Offset perp = Offset(-dir.dy, dir.dx); 

        Path path1 = Path(); Path path2 = Path();
        int segments = 20;
        for (int i = 0; i <= segments; i++) {
          double t = i / segments;
          Offset p = Offset.lerp(start, end, t)!;
          double wave = sin(t * pi * 4) * 15 * (1 - t); 
          Offset waveOffset = perp * wave;
          double width = 5 * (1 - t); 
          
          if (i == 0) {
            path1.moveTo(p.dx + waveOffset.dx + perp.dx * width, p.dy + waveOffset.dy + perp.dy * width);
            path2.moveTo(p.dx + waveOffset.dx - perp.dx * width, p.dy + waveOffset.dy - perp.dy * width);
          } else {
            path1.lineTo(p.dx + waveOffset.dx + perp.dx * width, p.dy + waveOffset.dy + perp.dy * width);
            path2.lineTo(p.dx + waveOffset.dx - perp.dx * width, p.dy + waveOffset.dy - perp.dy * width);
          }
        }
        
        canvas.drawPath(path1, paintSnake);
        canvas.drawPath(path2, paintSnake);

        canvas.save();
        canvas.translate(start.dx, start.dy);
        double angle = atan2(dir.dy, dir.dx);
        canvas.rotate(angle + pi); 

        Path headPath = Path();
        headPath.moveTo(-6, -5); headPath.quadraticBezierTo(4, -14, 10, -6);
        headPath.quadraticBezierTo(16, -2, 18, 0); headPath.quadraticBezierTo(16, 2, 10, 6);
        headPath.quadraticBezierTo(4, 14, -6, 5); headPath.close();

        canvas.drawPath(headPath, Paint()..color = const Color(0xFF0A0A14)..style = PaintingStyle.fill);
        canvas.drawPath(headPath, Paint()..color = ladder.color..strokeWidth = 2.0..style = PaintingStyle.stroke);

        final paintEye = Paint()..color = ladder.color..strokeWidth = 2.0..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(6, -6), const Offset(10, -3), paintEye);
        canvas.drawLine(const Offset(6, 6), const Offset(10, 3), paintEye);

        Path tonguePath = Path();
        tonguePath.moveTo(18, 0); tonguePath.quadraticBezierTo(22, 0, 26, -4);
        tonguePath.moveTo(22, 0); tonguePath.quadraticBezierTo(24, 0, 26, 4);  

        canvas.drawPath(tonguePath, Paint()..color = Colors.redAccent..strokeWidth = 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
        canvas.restore();
      }
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- WIDGET DES CONFETTIS DE VICTOIRE ---
class NeonConfettiWidget extends StatefulWidget {
  const NeonConfettiWidget({super.key});
  @override State<NeonConfettiWidget> createState() => _NeonConfettiWidgetState();
}

class _NeonConfettiWidgetState extends State<NeonConfettiWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    List<Color> colors = [Colors.pinkAccent, Colors.cyanAccent, Colors.purpleAccent, Colors.greenAccent, Colors.amberAccent];
    for (int i = 0; i < 80; i++) {
      _particles.add(_ConfettiParticle(
        x: _random.nextDouble() * 400, 
        y: _random.nextDouble() * -600,
        size: _random.nextDouble() * 6 + 4, 
        speed: _random.nextDouble() * 3 + 2,
        color: colors[_random.nextInt(colors.length)], 
        rotationSpeed: _random.nextDouble() * 0.05,
        rotation: _random.nextDouble() * pi * 2, 
      ));
    }
  }

  @override void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final size = MediaQuery.of(context).size;
        for (var p in _particles) {
          p.y += p.speed;
          p.x += sin(p.y / 30) * 0.5; 
          p.rotation += p.rotationSpeed;
          if (p.y > size.height) { p.y = -20; p.x = _random.nextDouble() * size.width; }
        }
        return CustomPaint(size: Size.infinite, painter: _ConfettiPainter(particles: _particles));
      },
    );
  }
}

class _ConfettiParticle {
  double x, y, size, speed, rotation, rotationSpeed; Color color;
  _ConfettiParticle({required this.x, required this.y, required this.size, required this.speed, required this.color, required this.rotationSpeed, this.rotation = 0});
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()..color = p.color..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(p.x.clamp(0, size.width), p.y);
      canvas.rotate(p.rotation);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size * 1.5, height: p.size), paint);
      canvas.restore();
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}