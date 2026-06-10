import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';

import 'package:gameflix/models/player.dart';

// --- NOUVEAU : LA MACHINE D'ÉTAT ABSOLUE ---
enum GamePhase { idle, rolling, moving, card, transition }

// --- MODÈLES ---
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

  final int _totalTiles = 62; 
  final double _tileWidth = 90.0;
  final double _tileHeight = 55.0;

  List<Offset> _tileCenters = [];
  List<Widget> _boardTiles = [];
  double _boardWidth = 0;
  double _boardHeight = 0;

  // --- ÉTAT DU JEU ---
  GamePhase _phase = GamePhase.idle; // Remplace tous les booléens !
  
  final List<BoardPlayer> _boardPlayers = [];
  int _currentPlayerIndex = 0;
  int _diceValue = 1;
  double _diceRotation = 0.0;

  List<TileAction> _actionPool = [];
  TileAction? _currentAction;

  Offset _getOffsetForPlayer(int playerIndexOnTile, int totalPlayersOnTile) {
  
  // Logique type "Dé" :
  // 1 joueur : au centre (0,0)
  // 2 joueurs : en diagonale
  // 3 joueurs : triangle
  // 4 joueurs : coins
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
    default: // 1 ou plus de 4
      return const Offset(0, 0);
  }
}

  final List<BoardLadder> _ladders = [
    // --- LADDERS (Vertes) : Pour accélérer la progression ---
    const BoardLadder(fromTile: 8, toTile: 25, color: Colors.greenAccent),
    const BoardLadder(fromTile: 9, toTile: 19, color: Colors.greenAccent),
    const BoardLadder(fromTile: 33, toTile: 48, color: Colors.greenAccent),
    const BoardLadder(fromTile: 44, toTile: 56, color: Colors.greenAccent),

    // --- SNAKES (Violettes) : Pour pimenter la fin de partie ---
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

  void _buildBoardLayout() {
    List<List<int>> segments = [[11, 1, 0], [9, 0, -1], [11, -1, 0], [7, 0, 1], [9, 1, 0], [5, 0, -1], [7, -1, 0], [3, 0, 1], [2, 1, 0]];
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

    double stepX = 90.0; double stepY = 55.0;
    _tileCenters = []; _boardTiles = [];

    double minX = positions.map((p) => p.dx).reduce(min);
    double minY = positions.map((p) => p.dy).reduce(min);
    double maxX = positions.map((p) => p.dx).reduce(max);
    double maxY = positions.map((p) => p.dy).reduce(max);

    for (int i = 0; i < positions.length; i++) {
      double finalX = (positions[i].dx - minX) * stepX + 50; 
      double finalY = (positions[i].dy - minY) * stepY + 50;

      _tileCenters.add(Offset(finalX + _tileWidth / 2, finalY + _tileHeight / 2));

      late Color tileColor;
      late String tileText;

      if (i == 0) {
        tileColor = Colors.greenAccent;
        tileText = "DÉPART";
      } else if (i == positions.length - 1) {
        tileColor = Colors.amber;
        tileText = "FIN";
      } else {
        bool isActionTile = i % 2 == 0;
        tileColor = isActionTile ? Colors.pinkAccent : Colors.cyanAccent;
        tileText = isActionTile ? "GAGE\n$i" : "Q\n$i";
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
              color: const Color(0xFF0A0A14), 
              border: Border.all(color: tileColor, width: 1.5), // Utilisation correcte
              boxShadow: [BoxShadow(color: tileColor.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: -2)]
            ),
            child: Stack(
              children: [
                // 2. Texte centré, sobre
                Center(
                  child: Text(
                    tileText.replaceAll('\n', ' '), 
                    textAlign: TextAlign.center, 
                    style: const TextStyle(
                      color: Colors.white70, 
                      fontWeight: FontWeight.w900, 
                      fontSize: 11
                    )
                  ),
                ),
                // 3. Indicateur d'échelle élégant
                if (ladderBadge != null)
                  Positioned(bottom: 2, right: 2, child: ladderBadge),
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
    // Si on n'est pas "Idle", on ignore totalement le clic. Impossible de spammer.
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

    try {
      var ladder = _ladders.firstWhere((l) => l.fromTile == currentPlayer.currentTileIndex);
      setState(() => currentPlayer.currentTileIndex = ladder.toTile);
      _focusCameraOnTile(currentPlayer.currentTileIndex, scale: 1.0, animate: true, duration: const Duration(milliseconds: 400));
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (_) {}

    await _triggerTileAction(currentPlayer.currentTileIndex);

    // --- TRANSITION SÉCURISÉE ---
    setState(() => _phase = GamePhase.transition);
    
    int nextIndex = (_currentPlayerIndex + 1) % _boardPlayers.length;
    setState(() => _currentPlayerIndex = nextIndex);

    _focusCameraOnTile(_boardPlayers[_currentPlayerIndex].currentTileIndex, scale: 1.5, animate: true, duration: const Duration(milliseconds: 800));
    await Future.delayed(const Duration(milliseconds: 1200));

    _focusCameraOnTile(_boardPlayers[_currentPlayerIndex].currentTileIndex, scale: 0.8, animate: true, duration: const Duration(milliseconds: 600));
    await Future.delayed(const Duration(milliseconds: 600));

    // Fin officielle du tour. Le prochain joueur peut lancer.
    setState(() => _phase = GamePhase.idle);
  }

  Future<void> _triggerTileAction(int index) async {
    // 1. Pas de carte sur la case DÉPART (0) ni sur la FIN (59)
    if (index == 0 || index == _totalTiles - 1) {
      return; 
    }

    if (_actionPool.isEmpty) return;

    // 2. Déterminer la couleur de la case (Pair = Rose/Gage, Impair = Cyan/Question)
    bool isActionTile = index % 2 == 0;

    // 3. Filtrer les cartes du JSON selon le type de la case
    List<TileAction> possibleCards = _actionPool.where((card) {
      if (isActionTile) {
        // Sur une case Rose : Gages, Actions physiques, Boissons ou Mouvements Spéciaux
        return card.type == TileType.action || card.type == TileType.drink || card.type == TileType.special;
      } else {
        // Sur une case Cyan : Uniquement des Questions ou Vérités
        return card.type == TileType.question;
      }
    }).toList();

    // Sécurité : si tu n'as pas encore assez de cartes d'un certain type dans ton JSON
    if (possibleCards.isEmpty) {
      possibleCards = _actionPool;
    }

    // 4. Piocher UNE carte au hasard parmi la liste filtrée
    setState(() {
      _currentAction = possibleCards[Random().nextInt(possibleCards.length)];
      _phase = GamePhase.card;
    });

    // Boucle d'attente (le joueur lit sa carte)
    while (_phase == GamePhase.card) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // 5. Exécution d'un mouvement spécial (ex: Avance de 3)
    if (_currentAction!.movement != 0) {
      setState(() => _phase = GamePhase.moving); 
      
      int newIndex = (_boardPlayers[_currentPlayerIndex].currentTileIndex + _currentAction!.movement).clamp(0, _totalTiles - 1);
      setState(() => _boardPlayers[_currentPlayerIndex].currentTileIndex = newIndex);
      
      _focusCameraOnTile(newIndex, scale: 1.0, animate: true, duration: const Duration(milliseconds: 500));
      
      await Future.delayed(const Duration(milliseconds: 1500)); 
    }
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
            // --- 1. LE PLATEAU ET LA CAMÉRA ---
            InteractiveViewer(
              transformationController: _cameraController,
              constrained: false, boundaryMargin: const EdgeInsets.all(1200), minScale: 0.15, maxScale: 2.5,
              child: SizedBox(
                width: _boardWidth, height: _boardHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ..._boardTiles,
                    CustomPaint(
                      size: Size(_boardWidth, _boardHeight), 
                      painter: LaddersPainter(tileCenters: _tileCenters, ladders: _ladders)
                    ),
      
                    if (_tileCenters.isNotEmpty)
                      ..._boardPlayers.asMap().entries.map((entry) {
                      final _ = entry.key; 
                      BoardPlayer p = entry.value; 
                      Offset center = _tileCenters[p.currentTileIndex];

                      // 1. Trouver tous les autres joueurs sur la même case
                      List<BoardPlayer> onSameTile = _boardPlayers
                          .where((other) => other.currentTileIndex == p.currentTileIndex)
                          .toList();
                          
                      // 2. Trouver l'index de ce joueur spécifique parmi ceux sur la case
                      int indexOnTile = onSameTile.indexOf(p);
                      
                      // 3. Calculer le décalage dynamique
                      Offset dynamicOffset = _getOffsetForPlayer(indexOnTile, onSameTile.length);

                      return AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOutSine,
                        // On centre sur la case et on ajoute le décalage calculé
                        left: center.dx - 16 + dynamicOffset.dx, 
                        top: center.dy - 16 + dynamicOffset.dy,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, 
                            color: p.color, 
                            border: Border.all(color: Colors.white, width: 2), 
                            boxShadow: [BoxShadow(color: p.color.withValues(alpha: 0.8), blurRadius: 4, spreadRadius: 1)]
                          ),
                          child: Center(
                            child: Text(
                              p.player.name[0], 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                            )
                          ),
                        ),
                      );
                    }),
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

            // --- 4. HUD ---
            Positioned(top: 10, left: 10, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context))),
            
            Positioned(
              bottom: 30, left: 20, right: 20,
              child: AnimatedOpacity(
                opacity: _phase == GamePhase.transition ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
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
                      // SEUL MOMENT OÙ ON PEUT CLIQUER :
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

            // --- 5. CARTE (BOUCLIER ANTI-CLIC) ---
            if (_phase == GamePhase.card && _currentAction != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    // Ferme la carte et libère la boucle while !
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
          ],
        ),
      ),
    );
  }
}

// --- WIDGETS ANNEXES ---
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
        // --- DESIGN ÉCHELLE (déjà validé) ---
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
        // --- DESIGN SERPENT (Double trait + Tête + Pointe) ---
        final paintSnake = Paint()..color = ladder.color..strokeWidth = 2.0..style = PaintingStyle.stroke;
        
        Offset dir = (end - start) / (end - start).distance;
        Offset perp = Offset(-dir.dy, dir.dx); // Vecteur de largeur

        // On dessine deux chemins parallèles
        Path path1 = Path();
        Path path2 = Path();
        
        int segments = 20;
        for (int i = 0; i <= segments; i++) {
          double t = i / segments;
          Offset p = Offset.lerp(start, end, t)!;
          
          // Ondulation (amplitude qui diminue vers la queue)
          double wave = sin(t * pi * 4) * 15 * (1 - t); 
          Offset waveOffset = perp * wave;
          
          // Largeur du corps (plus large au début, fin à la queue)
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

        // --- LA TÊTE (Cercle au début) ---
        // --- LA TÊTE (Tête de Vipère agressive) ---
        canvas.save();
        canvas.translate(start.dx, start.dy);
        
        // Calcul de l'angle pour que la tête regarde à l'opposé du corps
        double angle = atan2(dir.dy, dir.dx);
        canvas.rotate(angle + pi); 

        // 1. La forme de la tête (un diamant incurvé)
        Path headPath = Path();
        headPath.moveTo(-6, -5); // Base du cou gauche
        headPath.quadraticBezierTo(4, -14, 10, -6); // Joue gauche large
        headPath.quadraticBezierTo(16, -2, 18, 0);  // Museau pointu gauche
        headPath.quadraticBezierTo(16, 2, 10, 6);   // Museau pointu droit
        headPath.quadraticBezierTo(4, 14, -6, 5);   // Joue droite large
        headPath.close();

        // Fond sombre pour masquer le corps en dessous
        canvas.drawPath(headPath, Paint()..color = const Color(0xFF0A0A14)..style = PaintingStyle.fill);
        // Contour néon de la tête
        canvas.drawPath(headPath, Paint()..color = ladder.color..strokeWidth = 2.0..style = PaintingStyle.stroke);

        // 2. Les yeux "méchants" (des traits en diagonale)
        final paintEye = Paint()..color = ladder.color..strokeWidth = 2.0..strokeCap = StrokeCap.round;
        // Oeil gauche
        canvas.drawLine(const Offset(6, -6), const Offset(10, -3), paintEye);
        // Oeil droit
        canvas.drawLine(const Offset(6, 6), const Offset(10, 3), paintEye);

        // 3. La langue fourchue
        Path tonguePath = Path();
        tonguePath.moveTo(18, 0); // Base de la langue au bout du museau
        tonguePath.quadraticBezierTo(22, 0, 26, -4); // Branche gauche
        tonguePath.moveTo(22, 0); // Milieu de la langue
        tonguePath.quadraticBezierTo(24, 0, 26, 4);  // Branche droite

        canvas.drawPath(tonguePath, Paint()
          ..color = Colors.redAccent 
          ..strokeWidth = 1.5 
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
        );

        canvas.restore();
        // Petits yeux
        canvas.drawCircle(start + dir * 3, 2, Paint()..color = Colors.black);
      }
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}