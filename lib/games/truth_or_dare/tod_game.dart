import 'package:flutter/material.dart';
import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/models/game_card.dart';
import 'package:gameflix/hub/gameflix_hub.dart';
import 'package:gameflix/games/truth_or_dare/tod_scoreboard.dart';

class TurnRecord {
  final int playerIndex;
  final GameCard card;
  final String displayContent;
  final bool failed;
  final int turnCount;
  TurnRecord(this.playerIndex, this.card, this.displayContent, this.failed, this.turnCount);
}

class TodGameScreen extends StatefulWidget {
  final List<Player> players;
  final List<GameCard> deck;
  final int maxTurns; 

  const TodGameScreen({super.key, required this.players, required this.deck, required this.maxTurns});

  @override
  State<TodGameScreen> createState() => _TodGameScreenState();
}

class _TodGameScreenState extends State<TodGameScreen> with TickerProviderStateMixin {
  int _currentPlayerIndex = 0;
  int _currentTurnCount = 1;
  String? _chosenType;
  GameCard? _currentCard;
  String? _currentDisplayContent; 
  
  final List<GameCard> _hiddenCards = [];
  final List<GameCard> _playedCards = [];
  final List<TurnRecord> _history = []; 
  
  bool _isTransitioning = false; 

  bool _isShuffling = true;
  int _shuffleStep = 0; 
  final List<String> _activeDecks = [];

  Offset _swipeOffset = Offset.zero;
  bool _isDragging = false;
  
  // Contrôleurs d'animations
  late AnimationController _drawController;
  late AnimationController _doorController; // Le contrôleur des portes coulissantes
  
  late Animation<double> _flipAnimation, _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Offset> _leftDoorSlide, _rightDoorSlide;

  @override
  void initState() {
    super.initState();
    _drawController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    
    // --- NOUVEAU : Initialisation des portes coulissantes ---
    _doorController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _leftDoorSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(-1.0, 0.0)).animate(CurvedAnimation(parent: _doorController, curve: Curves.easeInOutCubic));
    _rightDoorSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(1.0, 0.0)).animate(CurvedAnimation(parent: _doorController, curve: Curves.easeInOutCubic));

    _flipAnimation = Tween<double>(begin: 0, end: pi).animate(CurvedAnimation(parent: _drawController, curve: Curves.easeInOut));
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _drawController, curve: Curves.elasticOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero).animate(CurvedAnimation(parent: _drawController, curve: Curves.easeOutQuart));

    if (widget.deck.any((c) => c.difficulty == 'SOFT')) _activeDecks.add('SOFT');
    if (widget.deck.any((c) => c.difficulty == 'FUN')) _activeDecks.add('FUN');
    if (widget.deck.any((c) => c.difficulty == 'HOT')) _activeDecks.add('HOT');
    if (widget.deck.any((c) => c.difficulty == 'CUSTOM')) _activeDecks.add('CUSTOM');

    _startShuffleSequence();
  }

  @override
  void dispose() {
    _drawController.dispose();
    _doorController.dispose();
    super.dispose();
  }

  void _startShuffleSequence() {
    // Les portes sont grandes ouvertes (1.0) pour laisser voir le shuffle !
    _doorController.value = 1.0; 

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _shuffleStep = 1);
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _shuffleStep = 2);
    });
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _shuffleStep = 3);
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() => _isShuffling = false);
        // Le shuffle est fini, on claque les portes pour cacher la table !
        _doorController.reverse();
      }
    });
  }

  // --- NOUVELLE FONCTION : Clic sur une porte ---
  void _selectType(String type) {
    setState(() => _chosenType = type);
    // On ouvre les portes, puis on tire la carte une fois qu'elles sont ouvertes
    _doorController.forward().then((_) {
      if (mounted) _drawRandomCard();
    });
  }

  String _processCardContent(String content, Player currentPlayer) {
    if (!content.contains('{TARGET}')) return content;
    List<Player> validTargets = widget.players.where((p) => p.name != currentPlayer.name && p.gender != currentPlayer.gender).toList();
    if (validTargets.isEmpty) validTargets = widget.players.where((p) => p.name != currentPlayer.name).toList();
    validTargets.shuffle();
    return content.replaceAll('{TARGET}', validTargets.isNotEmpty ? validTargets.first.name : "quelqu'un");
  }

  void _recordTurn(bool failed) => _history.add(TurnRecord(_currentPlayerIndex, _currentCard!, _currentDisplayContent!, failed, _currentTurnCount));

  void _undoTurn() {
    if (_history.isEmpty) return;
    final last = _history.removeLast();
    setState(() {
      _currentPlayerIndex = last.playerIndex;
      _currentCard = last.card;
      _currentDisplayContent = last.displayContent;
      _currentTurnCount = last.turnCount;
      _chosenType = last.card.type;
      if (last.failed) widget.players[_currentPlayerIndex].score -= last.card.shots;
      
      _isTransitioning = false;
      _swipeOffset = Offset.zero;
      _drawController.value = 1.0; 
      _doorController.value = 1.0; // On s'assure que les portes restent ouvertes
    });
  }

  void _nextTurn() {
    setState(() {
      _isTransitioning = true;
      _currentCard = null;
      _chosenType = null;
      _swipeOffset = Offset.zero;
      _currentPlayerIndex = (_currentPlayerIndex + 1) % widget.players.length;
      if (_currentPlayerIndex == 0) _currentTurnCount++;
    });

    if (_currentTurnCount > widget.maxTurns) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TodScoreboardScreen(players: widget.players)));
      return;
    }

    // On referme les portes en fond pendant que l'écran de transition s'affiche
    _doorController.reverse();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isTransitioning = false);
    });
  }

  void _handleSuccess() { _recordTurn(false); _nextTurn(); }
  void _handleFail() { _recordTurn(true); setState(() => widget.players[_currentPlayerIndex].score += _currentCard!.shots); _nextTurn(); }

  void _drawRandomCard() {
    final player = widget.players[_currentPlayerIndex];
    final allCategoryCards = widget.deck.where((c) => c.type == _chosenType && (c.targetGender == null || c.targetGender == player.gender) && !_hiddenCards.contains(c)).toList();
    var availableCards = allCategoryCards.where((c) => !_playedCards.contains(c)).toList();

    if (availableCards.isEmpty) {
      setState(() => _playedCards.removeWhere((c) => c.type == _chosenType));
      availableCards = allCategoryCards;
    }

    if (availableCards.isNotEmpty) {
      availableCards.shuffle();
      setState(() {
        _currentCard = availableCards.first;
        _currentDisplayContent = _processCardContent(_currentCard!.content, player);
        _playedCards.add(_currentCard!);
        _drawController.forward(from: 0.0);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Plus aucune carte disponible pour ce choix !")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayer = widget.players[_currentPlayerIndex];
    
    double valuesRefuse = (_swipeOffset.dx < -50) ? min(1.0, (_swipeOffset.dx.abs() - 50) / 100) : 0.0;
    double valuesFait = (_swipeOffset.dx > 50) ? min(1.0, (_swipeOffset.dx - 50) / 100) : 0.0;

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft,end: Alignment.bottomRight,colors: [Color.fromARGB(255, 119, 0, 187), Color(0xFF1A1A40),  Color.fromARGB(255, 0, 195, 255), ],stops: [0.0, 0.5, 1.0],),),), 
          Container(color: Colors.black.withValues(alpha: 0.3)),
          if (_currentCard != null && !_isTransitioning) ...[
            IgnorePointer(child: Container(color: Colors.green.withValues(alpha: valuesFait * 0.8), alignment: Alignment.center, child: valuesFait > 0.1 ? Transform.rotate(angle: 0.2, child: const Text("FAIT ! 😎", style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Colors.white))) : null)),
            IgnorePointer(child: Container(color: Colors.red.withValues(alpha: valuesRefuse * 0.8), alignment: Alignment.center, child: valuesRefuse > 0.1 ? Transform.rotate(angle: -0.2, child: const Text("REFUSÉ ! 🥴", style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Colors.white))) : null)),
          ],
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation), child: child)),
            child: _isTransitioning ? _buildTransitionScreen(currentPlayer) : _buildMainGameArea(currentPlayer),
          ),
        ],
      ),
    );
  }

  Widget _buildTransitionScreen(Player currentPlayer) {
    return Center(
      key: const ValueKey('TransitionScreen'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("🔥 PRÉPARE-TOI 🔥", style: TextStyle(fontSize: 24, color: Colors.white70, letterSpacing: 4)),
          const SizedBox(height: 20),
          Text(currentPlayer.name.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: currentPlayer.gender == 'M' ? Colors.cyanAccent : Colors.pinkAccent, shadows: [Shadow(color: currentPlayer.gender == 'M' ? Colors.cyan : Colors.pink, blurRadius: 20), Shadow(color: currentPlayer.gender == 'M' ? Colors.blue : Colors.purple, blurRadius: 40)])),
          const SizedBox(height: 20),
          const Text("C'est à ton tour de jouer...", style: TextStyle(fontSize: 20, color: Colors.white54, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildMainGameArea(Player currentPlayer) {
    return SafeArea(
      key: const ValueKey('GameScreen'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.home, size: 32, color: Colors.white70), onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const GameFlixHub()), (route) => false)),
                    if (_history.isNotEmpty && _currentCard == null)
                      IconButton(icon: const Icon(Icons.undo, size: 30, color: Colors.cyanAccent), onPressed: _undoTurn),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
                  child: Text("Tour $_currentTurnCount / ${widget.maxTurns}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                ),
              ],
            ),
          ),
          const Text("C'est au tour de", style: TextStyle(fontSize: 20, color: Colors.white70)),
          Text(currentPlayer.name, style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: currentPlayer.gender == 'M' ? Colors.blue : Colors.pink)),
          Text("Gorgées : ${currentPlayer.score} 🍺", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
          
          Expanded(
            child: Stack(
              alignment: Alignment.center, 
              clipBehavior: Clip.none,    
              children: [
                Hero(
                  tag: 'tapis_hero',
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.43, width: MediaQuery.of(context).size.width * 0.95,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), border: Border.all(color: Colors.white24, width: 2), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5)], image: const DecorationImage(image: AssetImage('assets/tapis.jpg'), fit: BoxFit.cover)),
                    ),
                  ),
                ),
                if (_isShuffling) _buildShuffleAnimation(),
                if (!_isShuffling && _currentCard != null) _buildSwipeableCard(),
                
                // --- LES VOLETS COULISSANTS SUR TOUT LE RESTE ---
                _buildDoors(),
              ],
            ),
          ),
          
          // --- BOUTONS SOUS LA CARTE ---
          // On fixe la hauteur à 90 pour éviter que l'UI saute quand les boutons apparaissent
          SizedBox(
            height: 90, 
            child: (!_isShuffling && _currentCard != null)
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _handleFail,
                            icon: const Icon(Icons.close, color: Colors.redAccent),
                            label: const Text('REFUSÉ', style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                              side: const BorderSide(color: Colors.redAccent, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _handleSuccess,
                            icon: const Icon(Icons.check, color: Colors.greenAccent),
                            label: const Text('FAIT', style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent.withValues(alpha: 0.1),
                              side: const BorderSide(color: Colors.greenAccent, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // --- NOUVEAU COMPOSANT : Les Portes Coulissantes ---
  // --- NOUVEAU COMPOSANT : Les Portes Coulissantes (Style Verre / Glassmorphism) ---
  // --- NOUVEAU COMPOSANT : Les Portes Coulissantes (Style Dark / Full Néon) ---
  Widget _buildDoors() {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // --- VOLET GAUCHE (ACTION) ---
              SlideTransition(
                position: _leftDoorSlide,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      if (_doorController.isDismissed) _selectType('ACTION');
                    },
                    child: Container(
                      width: constraints.maxWidth / 2,
                      decoration: BoxDecoration(
                        // Le même fond sombre "presque noir" que les cartes
                        color: const Color(0xFF050515).withValues(alpha: 0.95),
                        // Bordure lumineuse 100%
                        border: Border.all(color: Colors.cyanAccent, width: 2),
                        borderRadius: BorderRadius.circular(9),
                        // BoxShadow omnidirectionnel grâce au spreadRadius de 2
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withValues(alpha: 0.3), 
                            blurRadius: 20, 
                            spreadRadius: 2
                          )
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "ACTION", 
                          style: TextStyle(
                            color: Colors.cyanAccent, 
                            fontSize: 32, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 4,
                            // Ombre lumineuse de la même couleur pour l'effet tube néon
                            shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 15)]
                          )
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // --- VOLET DROIT (VÉRITÉ) ---
              SlideTransition(
                position: _rightDoorSlide,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      if (_doorController.isDismissed) _selectType('VERITE');
                    },
                    child: Container(
                      width: constraints.maxWidth / 2,
                      decoration: BoxDecoration(
                        // Le même fond sombre "presque noir" que les cartes
                        color: const Color(0xFF050515).withValues(alpha: 0.95),
                        // Bordure lumineuse 100%
                        border: Border.all(color: Colors.purpleAccent, width: 2),
                        borderRadius: BorderRadius.circular(9),
                        // BoxShadow omnidirectionnel grâce au spreadRadius de 2
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purpleAccent.withValues(alpha: 0.3), 
                            blurRadius: 20, 
                            spreadRadius: 2
                          )
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "VÉRITÉ", 
                          style: TextStyle(
                            color: Colors.purpleAccent, 
                            fontSize: 32, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 4,
                            // Ombre lumineuse de la même couleur pour l'effet tube néon
                            shadows: [Shadow(color: Colors.purpleAccent, blurRadius: 15)]
                          )
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildShuffleAnimation() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        double height = constraints.maxHeight;
        double cardW = 90;
        double cardH = 135;

        return Stack(
          children: _activeDecks.asMap().entries.map((e) {
            int idx = e.key;
            String deck = e.value;
            
            double leftPos;
            double topPos = height / 2 - cardH / 2;
            double angle = 0;
            double opacity = 1.0;

            if (_shuffleStep == 0) {
              leftPos = (width / (_activeDecks.length + 1)) * (idx + 1) - (cardW / 2);
            } else if (_shuffleStep == 1) {
              leftPos = width / 2 - cardW / 2;
            } else if (_shuffleStep == 2) {
              leftPos = width / 2 - cardW / 2;
              angle = (idx % 2 == 0 ? 0.05 : -0.05) * (idx + 1); 
            } else {
              leftPos = width / 2 - cardW / 2;
              opacity = 0.0;
            }

            String img = 'assets/Soft_Card.png';
            if (deck == 'FUN') img = 'assets/Fun_Card.png';
            if (deck == 'HOT') img = 'assets/Hot_Card.png';
            if (deck == 'CUSTOM') img = 'assets/Custom_Card.png';

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              left: leftPos,
              top: topPos,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: opacity,
                child: AnimatedRotation(
                  turns: angle,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    width: cardW, height: cardH,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(image: AssetImage(img), fit: BoxFit.cover),
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 5))]
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }
    );
  }

  Widget _buildSwipeableCard() {
    return AnimatedBuilder(
      animation: _drawController,
      builder: (context, child) {
        bool isFront = _flipAnimation.value >= (pi / 2);
        double angle = _flipAnimation.value;
        if (isFront) angle -= pi;
        
        String backImage = 'assets/Soft_Card.png';
        if (_currentCard!.difficulty == 'FUN') backImage = 'assets/Fun_Card.png';
        if (_currentCard!.difficulty == 'HOT') backImage = 'assets/Hot_Card.png';
        if (_currentCard!.difficulty == 'CUSTOM') backImage = 'assets/Custom_Card.png'; 

        return SlideTransition(
          position: _slideAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onPanStart: _drawController.isAnimating ? null : (d) => setState(() => _isDragging = true),
              onPanUpdate: _drawController.isAnimating ? null : (d) => setState(() => _swipeOffset += d.delta),
              onPanEnd: _drawController.isAnimating ? null : (d) {
                setState(() => _isDragging = false);
                if (_swipeOffset.dx > 120) _handleSuccess();
                else if (_swipeOffset.dx < -120) _handleFail();
                else _swipeOffset = Offset.zero;
              },
              child: AnimatedContainer(
                duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400), curve: Curves.elasticOut,
                transform: Matrix4.translationValues(_swipeOffset.dx, _swipeOffset.dy, 0)..rotateZ(_swipeOffset.dx / 1000),
                child: Transform(alignment: FractionalOffset.center, transform: Matrix4.identity()..setEntry(3, 2, 0.0015)..rotateY(angle), child: isFront ? _buildCardFront() : _buildCardBack(backImage)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardFront() {
    Color accentColor = _currentCard!.difficulty == 'SOFT' ? Colors.greenAccent : _currentCard!.difficulty == 'FUN' ? Colors.orangeAccent : _currentCard!.difficulty == 'HOT' ? Colors.redAccent : Colors.purpleAccent;

    return Container(
      width: 300, height: 450, padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF050515).withValues(alpha: 0.9), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 2), 
        boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)]
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("${_currentCard!.type} • ${_currentCard!.difficulty}", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 30),
              SizedBox(
                height: 180, 
                child: Center(
                  child: AutoSizeText(
                    _currentDisplayContent ?? _currentCard!.content, 
                    textAlign: TextAlign.center, 
                    maxLines: 7, 
                    minFontSize: 12, 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Colors.white, height: 1.4),
                  ),
                ),
              ),
              // -----------------------------------------------------

              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: Text("Pénalité : ${_currentCard!.shots} 🍺", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
            ],
          ),

          Positioned(
            right: -10, 
            top: -10, 
            child: IconButton(
              icon: const Icon(Icons.thumb_down, color: Colors.redAccent), 
              onPressed: () { 
                _hiddenCards.add(_currentCard!); 
                _drawRandomCard(); 
              }
            )
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(String imagePath) {
    return Container(width: 300, height: 450, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20, spreadRadius: 2)], image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover)));
  }
}
