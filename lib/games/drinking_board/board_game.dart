import 'package:flutter/material.dart';
import 'dart:math';

// NOUVEAU : Import de ton vrai modèle de joueur
import 'package:gameflix/models/player.dart';

// --- MODÈLES LOCAUX ---

class BoardLadder {
  final int fromTile;
  final int toTile;
  final Color color;

  const BoardLadder({required this.fromTile, required this.toTile, required this.color});
}

enum TileType { action, question, drink, special }

class TileAction {
  final String title;
  final String description;
  final TileType type;
  final int movement; // ex: -3 pour reculer, 3 pour avancer, 0 pour rester

  TileAction({required this.title, required this.description, required this.type, this.movement = 0});
}

// Wrapper pour associer tes vrais joueurs à une couleur et une case sur le plateau
class BoardPlayer {
  final Player player; // Ton vrai objet Player (qui vient du Hub)
  final Color color;
  int currentTileIndex;

  BoardPlayer({required this.player, required this.color, this.currentTileIndex = 0});
}

// --- ÉCRAN PRINCIPAL ---

class BoardGameScreen extends StatefulWidget {
  final List<Player> players; // NOUVEAU : Récupère les joueurs du Hub

  const BoardGameScreen({super.key, required this.players});

  @override
  State<BoardGameScreen> createState() => _BoardGameScreenState();
}

// On ajoute TickerProviderStateMixin pour animer la caméra !
class _BoardGameScreenState extends State<BoardGameScreen> with TickerProviderStateMixin {
  final TransformationController _cameraController = TransformationController();
  
  // Animation de la caméra
  late AnimationController _cameraAnimController;
  Animation<Matrix4>? _cameraAnimation;

  // --- PARAMÈTRES DU PLATEAU ---
  final int _totalTiles = 60; 
  final double _tileWidth = 90.0;
  final double _tileHeight = 55.0;

  List<Offset> _tileCenters = [];
  List<Widget> _boardTiles = [];
  double _boardWidth = 0;
  double _boardHeight = 0;

  final List<TileAction> _actionPool = [
    TileAction(title: "GAGE", description: "Tous les garçons boivent 2 gorgées.", type: TileType.drink, movement: 0),
    TileAction(title: "AVANCE", description: "Avance de 3 cases !", type: TileType.special, movement: 3),
    TileAction(title: "RECULE", description: "Oups, recule de 3 cases.", type: TileType.special, movement: -3),
    TileAction(title: "VÉRITÉ", description: "Quelle est la chose la plus honteuse que tu as faite en soirée ?", type: TileType.question),
    TileAction(title: "COQUIN", description: "Fais un massage de 30 secondes au joueur à ta droite.", type: TileType.action),
  ];

  bool _isCardVisible = false;
  TileAction? _currentAction;

  Future<void> _triggerTileAction(int index) async {
    // Choisir une action aléatoire
    setState(() {
      _currentAction = _actionPool[Random().nextInt(_actionPool.length)];
      _isCardVisible = true;
    });

    while (_isCardVisible) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // --- ICI : PAS D'AWAIT INUTILE, ON ENCHAÎNE ---
    
    // Si mouvement spécial, on le fait maintenant
    if (_currentAction!.movement != 0) {
      int newIndex = (_boardPlayers[_currentPlayerIndex].currentTileIndex + _currentAction!.movement).clamp(0, _totalTiles - 1);
      setState(() => _boardPlayers[_currentPlayerIndex].currentTileIndex = newIndex);
      // La caméra bouge IMMÉDIATEMENT sans attendre
      _focusCameraOnTile(newIndex, scale: 1.0, animate: true, duration: const Duration(milliseconds: 300));
      await Future.delayed(const Duration(milliseconds: 350));
    }

    // Transition tour suivant (le délai global de 750ms est supprimé ici)
    int nextPlayerIndex = (_currentPlayerIndex + 1) % _boardPlayers.length;

    setState(() {
      _currentPlayerIndex = nextPlayerIndex;
      _isTurnTransition = true;
    });

    // Zoom immédiat sur le joueur suivant
    _focusCameraOnTile(_boardPlayers[nextPlayerIndex].currentTileIndex, scale: 1.8, animate: true, duration: const Duration(milliseconds: 600));

    await Future.delayed(const Duration(milliseconds: 600)); // Juste assez pour que le zoom soit visible

    _focusCameraOnTile(_boardPlayers[nextPlayerIndex].currentTileIndex, scale: 0.7, animate: true, duration: const Duration(milliseconds: 500));

    setState(() {
      _isTurnTransition = false;
      _isMoving = false; 
    });
  }

  // --- ÉTAT DU JEU ---
  final List<BoardPlayer> _boardPlayers = [];
  int _currentPlayerIndex = 0;
  bool _isMoving = false;
  bool _showDice = false; 
  bool _isTurnTransition = false; // NOUVEAU : Gère l'écran de chargement
  int _diceValue = 1;
  double _diceRotation = 0.0;

  // --- ÉCHELLES ---
  final List<BoardLadder> _ladders = [
    const BoardLadder(fromTile: 6, toTile: 13, color: Colors.greenAccent),
    const BoardLadder(fromTile: 14, toTile: 47, color: Colors.greenAccent),
    const BoardLadder(fromTile: 21, toTile: 43, color: Colors.greenAccent),
    const BoardLadder(fromTile: 42, toTile: 50, color: Colors.greenAccent),
    const BoardLadder(fromTile: 45, toTile: 7, color: Colors.purpleAccent),
    const BoardLadder(fromTile: 41, toTile: 27, color: Colors.purpleAccent),
    const BoardLadder(fromTile: 53, toTile: 23, color: Colors.purpleAccent),
    const BoardLadder(fromTile: 39, toTile: 5, color: Colors.purpleAccent),
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialisation du contrôleur d'animation (vitesse du zoom caméra)
    _cameraAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

    // Distribution des couleurs fluos à tes vrais joueurs
    List<Color> availableColors = [Colors.blueAccent, Colors.pinkAccent, Colors.amber, Colors.greenAccent, Colors.redAccent, Colors.purpleAccent];
    
    for (int i = 0; i < widget.players.length; i++) {
      _boardPlayers.add(BoardPlayer(
        player: widget.players[i],
        color: availableColors[i % availableColors.length],
      ));
    }

    _buildBoardLayout();
    
    // Centrer la caméra au lancement sur le premier joueur
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_boardPlayers.isNotEmpty) {
        _focusCameraOnTile(0, scale: 0.7, animate: false);
      }
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _cameraAnimController.dispose();
    super.dispose();
  }

  // --- ANIMATION DE LA CAMÉRA ---
  void _focusCameraOnTile(int tileIndex, {required double scale, required bool animate, Duration duration = const Duration(milliseconds: 1000)}) {
    if (_tileCenters.isEmpty) return;
    
    Offset target = _tileCenters[tileIndex];
    final size = MediaQuery.of(context).size;
    
    Matrix4 endMatrix = Matrix4.identity()
      ..translate(size.width / 2, size.height / 2)
      ..scale(scale)
      ..translate(-target.dx, -target.dy);

    if (animate) {
      _cameraAnimation?.removeListener(_updateCamera);
      
      // NOUVEAU : On met à jour la durée de l'animation à la volée !
      _cameraAnimController.duration = duration;

      _cameraAnimation = Matrix4Tween(
        begin: _cameraController.value,
        end: endMatrix,
      ).animate(CurvedAnimation(parent: _cameraAnimController, curve: Curves.easeInOutSine));
      
      _cameraAnimation!.addListener(_updateCamera);
      _cameraAnimController.forward(from: 0.0);
    } else {
      _cameraController.value = endMatrix;
    }
  }

  void _updateCamera() {
    _cameraController.value = _cameraAnimation!.value;
  }

  // --- LOGIQUE DU PLATEAU ---
  void _buildBoardLayout() {
    List<List<int>> segments = [
      [11, 1, 0], [9, 0, -1], [11, -1, 0], [7, 0, 1], [9, 1, 0], 
      [5, 0, -1], [7, -1, 0], [3, 0, 1], [2, 1, 0],   
    ];

    List<Offset> positions = [];
    int currentX = 0; int currentY = 0;

    for (var seg in segments) {
      int len = seg[0]; int dx = seg[1]; int dy = seg[2];
      for (int i = 0; i < len; i++) {
        if (positions.length < _totalTiles) {
          positions.add(Offset(currentX.toDouble(), currentY.toDouble()));
          currentX += dx; currentY += dy;
        }
      }
    }

    double stepX = 95.0; 
    double stepY = 60.0;

    _tileCenters = [];
    _boardTiles = [];

    double minX = positions.map((p) => p.dx).reduce(min);
    double minY = positions.map((p) => p.dy).reduce(min);
    double maxX = positions.map((p) => p.dx).reduce(max);
    double maxY = positions.map((p) => p.dy).reduce(max);

    for (int i = 0; i < positions.length; i++) {
      double finalX = (positions[i].dx - minX) * stepX + 50; 
      double finalY = (positions[i].dy - minY) * stepY + 50;

      _tileCenters.add(Offset(finalX + _tileWidth / 2, finalY + _tileHeight / 2));

      bool isActionTile = i % 2 == 0;
      Color tileColor = isActionTile ? Colors.pinkAccent : Colors.cyanAccent;
      String tileText = isActionTile ? "GAGE\n$i" : "Q\n$i";
      if (i == 0) { tileColor = Colors.greenAccent; tileText = "DÉPART"; }
      if (i == positions.length - 1) { tileColor = Colors.amber; tileText = "FIN"; }

      Widget? ladderBadge;
      try {
        var ladderOut = _ladders.firstWhere((l) => l.fromTile == i);
        ladderBadge = Icon(ladderOut.toTile > ladderOut.fromTile ? Icons.keyboard_double_arrow_up : Icons.keyboard_double_arrow_down, size: 16, color: ladderOut.color);
      } catch (_) {}
      
      try {
        _ladders.firstWhere((l) => l.toTile == i);
        if (ladderBadge == null) ladderBadge = const Icon(Icons.adjust, size: 12, color: Colors.white54);
      } catch (_) {}

      _boardTiles.add(
        Positioned(
          left: finalX, top: finalY,
          child: Container(
            width: _tileWidth, height: _tileHeight,
            decoration: BoxDecoration(color: const Color(0xFF111122), borderRadius: BorderRadius.circular(10), border: Border.all(color: tileColor, width: 2), boxShadow: [BoxShadow(color: tileColor.withValues(alpha: 0.25), blurRadius: 4)]),
            child: Stack(
              children: [
                Center(child: Text(tileText, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
                if (ladderBadge != null) Positioned(top: 2, right: 2, child: ladderBadge),
              ],
            ),
          ),
        )
      );
    }
    
    _boardWidth = (maxX - minX) * stepX + _tileWidth + 100;
    _boardHeight = (maxY - minY) * stepY + _tileHeight + 100;
  }

  // --- LOGIQUE DU JEU (LANCER LE DÉ) ---
  Future<void> _rollDiceAndMove() async {
    if (_isMoving || _boardPlayers.isEmpty) return;

    setState(() {
      _isMoving = true;
      _showDice = true; 
    });

    _focusCameraOnTile(_boardPlayers[_currentPlayerIndex].currentTileIndex, scale: 1.0, animate: true, duration: const Duration(milliseconds: 800));

    // Animation du dé
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      setState(() { _diceValue = Random().nextInt(6) + 1; _diceRotation += 0.35; });
    }

    int steps = Random().nextInt(6) + 1;
    setState(() { _diceValue = steps; _diceRotation = 0.0; });
    
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() => _showDice = false);
    await Future.delayed(const Duration(milliseconds: 300));

    // Déplacement du pion pas à pas avec caméra synchro
    BoardPlayer currentPlayer = _boardPlayers[_currentPlayerIndex];
    for (int i = 0; i < steps; i++) {
      if (currentPlayer.currentTileIndex < _totalTiles - 1) {
        setState(() => currentPlayer.currentTileIndex++);
        
        // Caméra ultra-rapide (250ms) pour suivre le pas du pion
        _focusCameraOnTile(
          currentPlayer.currentTileIndex, 
          scale: 1.0, 
          animate: true,
          duration: const Duration(milliseconds: 250) 
        );
        
        // On attend que l'animation finisse avant le prochain pas
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    

    // Échelles avec suivi de caméra
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      var ladder = _ladders.firstWhere((l) => l.fromTile == currentPlayer.currentTileIndex);
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => currentPlayer.currentTileIndex = ladder.toTile);
      
      // Glissade sur l'échelle (un peu plus long car la distance est plus grande)
      _focusCameraOnTile(
        currentPlayer.currentTileIndex, 
        scale: 1.0, 
        animate: true,
        duration: const Duration(milliseconds: 600)
      );
      await Future.delayed(const Duration(milliseconds: 600));
    } catch (_) {} 

    await _triggerTileAction(currentPlayer.currentTileIndex);

    // --- TRANSITION DU TOUR SUIVANT ---
    int nextPlayerIndex = (_currentPlayerIndex + 1) % _boardPlayers.length;

    setState(() {
      _currentPlayerIndex = nextPlayerIndex;
      _isTurnTransition = true;
    });

    // Zoom dramatique (X1.8 lent, 1200ms) sur le joueur suivant
    _focusCameraOnTile(
      _boardPlayers[nextPlayerIndex].currentTileIndex, 
      scale: 1.8, 
      animate: true,
      duration: const Duration(milliseconds: 1200)
    );

    await Future.delayed(const Duration(milliseconds: 750));

    // Dé-zoom (X0.7) avant qu'il ne lance
    _focusCameraOnTile(
      _boardPlayers[nextPlayerIndex].currentTileIndex, 
      scale: 0.7, 
      animate: true,
      duration: const Duration(milliseconds: 800)
    );

    setState(() {
      _isTurnTransition = false;
      _isMoving = false; 
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_boardPlayers.isEmpty) return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text("Ajoute des joueurs dans le HUB !", style: TextStyle(color: Colors.white))));

    BoardPlayer currentPlayer = _boardPlayers[_currentPlayerIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // --- 1. LE PLATEAU ET LA CAMÉRA ---
            InteractiveViewer(
              transformationController: _cameraController,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(1200), 
              minScale: 0.15, 
              maxScale: 2.5,
              child: SizedBox(
                width: _boardWidth, height: _boardHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(size: Size(_boardWidth, _boardHeight), painter: LaddersPainter(tileCenters: _tileCenters, ladders: _ladders)),
                    ..._boardTiles,
                    if (_tileCenters.isNotEmpty)
                      ..._boardPlayers.asMap().entries.map((entry) {
                        int index = entry.key; BoardPlayer p = entry.value; Offset center = _tileCenters[p.currentTileIndex];
                        double offsetX = (index * 12).toDouble() - 12; double offsetY = (index * 12).toDouble() - 12;

                        return AnimatedPositioned(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOutSine,
                          left: center.dx - 16 + offsetX, top: center.dy - 16 + offsetY,
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: p.color, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: p.color.withValues(alpha: 0.8), blurRadius: 10, spreadRadius: 2)]),
                            child: Center(child: Text(p.player.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            // --- 2. LE GROS DÉ AU CENTRE ---
            IgnorePointer(
              ignoring: !_showDice,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: _showDice ? Colors.black.withValues(alpha: 0.6) : Colors.transparent,
                child: Center(
                  child: AnimatedScale(
                    scale: _showDice ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    child: AnimatedRotation(
                      turns: _diceRotation,
                      duration: const Duration(milliseconds: 60),
                      child: DiceFace(value: _diceValue, color: currentPlayer.color, size: 130),
                    ),
                  ),
                ),
              ),
            ),

            // --- 3. L'ÉCRAN DE TRANSITION (Chargement) ---
            IgnorePointer(
              ignoring: !_isTurnTransition,
              child: AnimatedOpacity(
                opacity: _isTurnTransition ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5), // Fond noir translucide pour VOIR la caméra bouger
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: currentPlayer.color, strokeWidth: 6),
                        const SizedBox(height: 30),
                        Text(
                          "À ${currentPlayer.player.name.toUpperCase()} DE JOUER !",
                          style: TextStyle(color: currentPlayer.color, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2, shadows: const [Shadow(color: Colors.black, blurRadius: 10)]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // --- 4. INTERFACE HUD FIXE ---
            Positioned(top: 10, left: 10, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context))),
            
            Positioned(
              bottom: 30, left: 20, right: 20,
              child: AnimatedOpacity(
                opacity: _isTurnTransition ? 0.0 : 1.0, // Cache le HUD pendant le chargement
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
                      onTap: (_isMoving || _isTurnTransition) ? null : _rollDiceAndMove,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 65,
                        decoration: BoxDecoration(
                          color: _isMoving ? Colors.grey.shade900 : currentPlayer.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(color: _isMoving ? Colors.grey : currentPlayer.color, width: 3),
                          boxShadow: _isMoving ? [] : [BoxShadow(color: currentPlayer.color.withValues(alpha: 0.4), blurRadius: 15, spreadRadius: 1)]
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.casino, color: _isMoving ? Colors.grey : Colors.white, size: 28),
                            const SizedBox(width: 15),
                            Text(_isMoving ? "DÉPLACEMENT..." : "LANCER LE DÉ", style: TextStyle(color: _isMoving ? Colors.grey : Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
            ),
            // --- 5. LE FLIP CARD (cliquable pour fermeture rapide) ---
            if (_isCardVisible && _currentAction != null)
              GestureDetector(
                onTap: () {
                  setState(() => _isCardVisible = false);
                },
                child: Center(
                  child: TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double val, child) {
                      return Transform(
                        transform: Matrix4.rotationY(val * pi),
                        alignment: Alignment.center,
                        child: val < 0.5 
                          ? Container(width: 300, height: 400, color: Colors.blueGrey.shade900, child: const Center(child: Text("?", style: TextStyle(color: Colors.white, fontSize: 50))))
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
          ],
        ),
      ),
    );
  }
}

// --- CLASSE DU DÉ ---
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

    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 1)]),
      child: Stack(children: dots),
    );
  }
}

// --- PEINTRE D'ÉCHELLES ---
class LaddersPainter extends CustomPainter {
  final List<Offset> tileCenters; final List<BoardLadder> ladders;
  LaddersPainter({required this.tileCenters, required this.ladders});

  @override
  void paint(Canvas canvas, Size size) {
    if (tileCenters.isEmpty) return;
    for (var ladder in ladders) {
      if (ladder.fromTile >= tileCenters.length || ladder.toTile >= tileCenters.length) continue;
      Offset start = tileCenters[ladder.fromTile]; Offset end = tileCenters[ladder.toTile];
      final paintLine = Paint()..color = ladder.color.withValues(alpha: 0.5)..strokeWidth = 6.0..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
      final paintCore = Paint()..color = Colors.white..strokeWidth = 1.5..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, paintLine); canvas.drawLine(start, end, paintCore);
      double distance = (end - start).distance; int rungs = (distance / 20).floor(); 
      for (int i = 1; i < rungs; i++) {
        double ratio = i / rungs; Offset centerRung = Offset.lerp(start, end, ratio)!;
        Offset direction = (end - start) / distance; Offset perpendicular = Offset(-direction.dy, direction.dx) * 10; 
        canvas.drawLine(centerRung - perpendicular, centerRung + perpendicular, paintLine);
        canvas.drawLine(centerRung - perpendicular, centerRung + perpendicular, paintCore);
      }
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FlipCard extends StatelessWidget {
  final TileAction action;
  const FlipCard({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300, height: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.cyanAccent, width: 3),
        boxShadow: const [BoxShadow(color: Colors.cyanAccent, blurRadius: 20)]
      ),
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