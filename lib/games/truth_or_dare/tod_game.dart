import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/models/game_card.dart';
import 'package:gameflix/services/audio_service.dart';
import 'package:gameflix/state/players_controller.dart';
import 'package:gameflix/shared/navigation.dart';
import 'package:gameflix/shared/widgets/global_settings_button.dart';
import 'package:gameflix/shared/widgets/procedural_neon_background.dart';
import 'package:gameflix/shared/widgets/neon_table_mat.dart';
import 'package:gameflix/games/truth_or_dare/tod_scoreboard.dart';
import 'package:gameflix/l10n/app_strings.dart';
import 'package:gameflix/l10n/locale_controller.dart';
import 'package:gameflix/l10n/strings_tod_nhie.dart';

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
  final List<String> _activeDecks = [];
  final List<String> _shuffleCards = [];

  Offset _swipeOffset = Offset.zero;
  bool _isDragging = false;
  
  // Contrôleurs d'animations
  late AnimationController _drawController;
  late AnimationController _choiceController; // Apparition et retrait des panneaux Action / Vérité
  late AnimationController _shuffleController; // Contrôleur du mélange à la française
  
  late Animation<double> _flipAnimation, _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _choiceScaleAnimation;
  late Animation<double> _choiceFadeAnimation;

  @override
  void initState() {
    super.initState();
    _drawController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1150));
    
    // Initialisation du contrôleur d'apparition des panneaux de choix Action / Vérité
    _choiceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _choiceScaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _choiceController, curve: Curves.easeOutBack),
    );
    _choiceFadeAnimation = CurvedAnimation(parent: _choiceController, curve: Curves.easeIn);

    // Contrôleur du mélange de cartes (synchronisé avec le bruitage de cartes)
    _shuffleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));

    // Phase 1 (0ms -> 200ms, poids 20) : La carte s'illumine/prend sa couleur au repos sur le paquet
    // Phase 2 (200ms -> 550ms, poids 35) : La carte coulisse vers le bas hors du paquet (Y: 0.0 -> 0.85)
    // Phase 3 (550ms -> 1150ms, poids 45) : La carte remonte au centre du tapis en s'agrandissant et se retournant
    _slideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: ConstantTween<Offset>(Offset.zero),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.85))
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(0, 0.85), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
    ]).animate(_drawController);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.38, end: 0.40)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.40, end: 0.43)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.43, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 45,
      ),
    ]).animate(_drawController);

    _flipAnimation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(
        parent: _drawController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeInOut),
      ),
    );

    if (widget.deck.any((c) => c.difficulty == 'SOFT')) _activeDecks.add('SOFT');
    if (widget.deck.any((c) => c.difficulty == 'FUN')) _activeDecks.add('FUN');
    if (widget.deck.any((c) => c.difficulty == 'HOT')) _activeDecks.add('HOT');
    if (widget.deck.any((c) => c.difficulty == 'CUSTOM')) _activeDecks.add('CUSTOM');

    // Génération d'un paquet 4x plus riche pour un mélange à la française immersif
    final baseDecks = _activeDecks.isEmpty ? ['SOFT'] : _activeDecks;
    int targetCardCount = baseDecks.length * 4;
    if (targetCardCount < 12) targetCardCount = 12;
    _shuffleCards.clear();
    for (int i = 0; i < targetCardCount; i++) {
      _shuffleCards.add(baseDecks[i % baseDecks.length]);
    }

    _startShuffleSequence();
  }

  @override
  void dispose() {
    _drawController.dispose();
    _choiceController.dispose();
    _shuffleController.dispose();
    super.dispose();
  }

  void _startShuffleSequence() {
    // Déclenchement du bruitage réaliste de mélange de cartes
    AudioService.instance.playSfx(SoundEffect.cardShuffle);

    // Lancement de la chorégraphie du mélange à la française
    _shuffleController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      setState(() => _isShuffling = false);
      _choiceController.forward(from: 0.0);
    });
  }

  void _selectType(String type) {
    if (_chosenType != null) return;
    HapticFeedback.mediumImpact();
    AudioService.instance.playSfx(SoundEffect.click);
    setState(() => _chosenType = type);
    // Retrait fluide des panneaux de choix, puis tirage et retournement 3D
    _choiceController.reverse().then((_) {
      if (mounted) _drawRandomCard();
    });
  }

  String _processCardContent(GameCard card, Player currentPlayer) {
    final String content = card.content;
    if (!content.contains('{TARGET}')) return content;

    // 1. Sélection d'un partenaire selon que la carte est tactile/Hot ou amicale
    final bool requireCompatibility = card.requiresCompatibleTarget;
    Player? target = PlayersController.pickTargetFor(
      currentPlayer,
      widget.players,
      requireCompatibility: requireCompatibility,
    );

    // 2. Fallback étape 1 : chercher une paire compatible dans le groupe si le joueur actif n'en a pas
    if (target == null && requireCompatibility) {
      final pair = PlayersController.pickCompatiblePair(
        widget.players,
        primary: currentPlayer,
        requireCompatibility: true,
      );
      if (pair != null) {
        target = pair.$2;
      }
    }

    // 3. Fallback amical si aucune cible trouvée
    target ??= PlayersController.pickTargetFor(
      currentPlayer,
      widget.players,
      requireCompatibility: false,
    );

    final String fallbackName =
        AppStrings(LocaleController.instance.currentLocale).todSomeoneFallback;
    return content.replaceAll('{TARGET}', target != null ? target.name : fallbackName);
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
      _choiceController.value = 0.0; // Les panneaux de choix restent masqués sur la carte restaurée
    });
  }

  void _nextTurn() {
    setState(() {
      _isTransitioning = true;
      _currentCard = null;
      _chosenType = null;
      _swipeOffset = Offset.zero;
      _choiceController.reset();
      _currentPlayerIndex = (_currentPlayerIndex + 1) % widget.players.length;
      if (_currentPlayerIndex == 0) _currentTurnCount++;
    });

    if (_currentTurnCount > widget.maxTurns) {
      HapticFeedback.heavyImpact();
      AudioService.instance.playSfx(SoundEffect.victory);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TodScoreboardScreen(players: widget.players)));
      return;
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _isTransitioning = false);
        _choiceController.forward(from: 0.0);
      }
    });
  }

  void _handleSuccess() {
    HapticFeedback.lightImpact();
    AudioService.instance.playSfx(SoundEffect.click);
    _recordTurn(false);
    _nextTurn();
  }

  void _handleFail() {
    HapticFeedback.mediumImpact();
    AudioService.instance.playSfx(SoundEffect.buzzer);
    _recordTurn(true);
    setState(() => widget.players[_currentPlayerIndex].score += _currentCard!.shots);
    _nextTurn();
  }

  void _drawRandomCard() {
    final player = widget.players[_currentPlayerIndex];
    final bool playerHasCompatiblePartner = PlayersController.pickTargetFor(
          player,
          widget.players,
          requireCompatibility: true,
        ) !=
        null;

    // 1. Filtrage des cartes du type choisi et du genre du joueur
    var allCategoryCards = widget.deck
        .where((c) =>
            c.type == _chosenType &&
            (c.targetGender == null || c.targetGender == player.gender) &&
            !_hiddenCards.contains(c))
        .toList();

    // 2. Fallback étape 2 : si le joueur n'a aucun partenaire compatible pour un gage tactile/Hot,
    // on privilégie les cartes solo ou non-tactiles pour ne jamais bloquer la partie.
    if (!playerHasCompatiblePartner) {
      final nonTactileOrSolo = allCategoryCards
          .where((c) => !(c.hasTargetPlaceholder && c.requiresCompatibleTarget))
          .toList();
      if (nonTactileOrSolo.isNotEmpty) {
        allCategoryCards = nonTactileOrSolo;
      }
    }

    var availableCards = allCategoryCards.where((c) => !_playedCards.contains(c)).toList();

    if (availableCards.isEmpty) {
      setState(() => _playedCards.removeWhere((c) => c.type == _chosenType));
      availableCards = allCategoryCards;
    }

    if (availableCards.isNotEmpty) {
      availableCards.shuffle();
      AudioService.instance.playSfx(SoundEffect.cardSlide);
      setState(() {
        _currentCard = availableCards.first;
        _currentDisplayContent = _processCardContent(_currentCard!, player);
        _playedCards.add(_currentCard!);
        _drawController.forward(from: 0.0);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.read(context).todNoCardsAvailableError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final currentPlayer = widget.players[_currentPlayerIndex];
    
    double valuesRefuse = (_swipeOffset.dx < -50) ? min(1.0, (_swipeOffset.dx.abs() - 50) / 100) : 0.0;
    double valuesFait = (_swipeOffset.dx > 50) ? min(1.0, (_swipeOffset.dx - 50) / 100) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0C1A),
      body: Stack(
        children: [
          const Positioned.fill(
            child: ProceduralNeonBackground(
              child: SizedBox.expand(),
            ),
          ),
          if (_currentCard != null && !_isTransitioning) ...[
            IgnorePointer(child: Container(color: Colors.green.withValues(alpha: valuesFait * 0.8), alignment: Alignment.center, child: valuesFait > 0.1 ? Transform.rotate(angle: 0.2, child: Text(s.todSwipeDoneOverlay, style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Colors.white))) : null)),
            IgnorePointer(child: Container(color: Colors.red.withValues(alpha: valuesRefuse * 0.8), alignment: Alignment.center, child: valuesRefuse > 0.1 ? Transform.rotate(angle: -0.2, child: Text(s.todSwipeRefusedOverlay, style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Colors.white))) : null)),
          ],
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation), child: child)),
            child: _isTransitioning ? _buildTransitionScreen(currentPlayer, s) : _buildMainGameArea(currentPlayer, s),
          ),
        ],
      ),
    );
  }

  Widget _buildTransitionScreen(Player currentPlayer, AppStrings s) {
    return Center(
      key: const ValueKey('TransitionScreen'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(s.todGetReadyBanner, style: const TextStyle(fontSize: 24, color: Colors.white70, letterSpacing: 4)),
          const SizedBox(height: 20),
          Text(currentPlayer.name.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: currentPlayer.gender == 'M' ? Colors.cyanAccent : Colors.pinkAccent, shadows: [Shadow(color: currentPlayer.gender == 'M' ? Colors.cyan : Colors.pink, blurRadius: 20), Shadow(color: currentPlayer.gender == 'M' ? Colors.blue : Colors.purple, blurRadius: 40)])),
          const SizedBox(height: 20),
          Text(s.todYourTurnSubtitle, style: const TextStyle(fontSize: 20, color: Colors.white54, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildMainGameArea(Player currentPlayer, AppStrings s) {
    return SafeArea(
      key: const ValueKey('GameScreen'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double matHeight = constraints.maxHeight * 0.58;
          final double matWidth = constraints.maxWidth * 0.95;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.home, size: 30, color: Colors.white70), onPressed: () => goToHub(context)),
                        if (_history.isNotEmpty && _currentCard == null)
                          IconButton(icon: const Icon(Icons.undo, size: 28, color: Colors.cyanAccent), onPressed: _undoTurn),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
                      child: Text(s.todTurnCounter(_currentTurnCount, widget.maxTurns), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                    ),
                    const GlobalSettingsButton(),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                s.todTurnOfLabel,
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              Text(
                currentPlayer.name,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: currentPlayer.gender == 'M' ? Colors.cyanAccent : Colors.pinkAccent,
                  shadows: [
                    Shadow(
                      color: (currentPlayer.gender == 'M' ? Colors.cyanAccent : Colors.pinkAccent).withValues(alpha: 0.8),
                      blurRadius: 18,
                    ),
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF101024),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.pinkAccent.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pinkAccent.withValues(alpha: 0.25),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sports_bar_rounded, size: 15, color: Colors.amberAccent),
                    const SizedBox(width: 6),
                    Text(
                      s.todSipsCounter(currentPlayer.score),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              Expanded(
                child: Stack(
                  alignment: Alignment.center, 
                  clipBehavior: Clip.none,    
                  children: [
                    Hero(
                      tag: 'tapis_hero',
                      child: Material(
                        color: Colors.transparent,
                        child: NeonTableMat(
                          height: matHeight,
                          width: matWidth,
                        ),
                      ),
                    ),
                    if (_isShuffling) _buildShuffleAnimation(),
                    if (!_isShuffling) _buildRestingDeck(),
                    if (!_isShuffling && _currentCard != null) _buildSwipeableCard(s),
                    if (!_isShuffling && _currentCard == null) _buildDuelChoiceArea(matWidth, matHeight, s),
                  ],
                ),
              ),
              
              // --- BOUTONS SOUS LA CARTE ---
              SizedBox(
                height: 80, 
                child: (!_isShuffling && _currentCard != null)
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _handleFail,
                                icon: const Icon(Icons.close, color: Colors.redAccent),
                                label: Text(s.todRefusedButton, style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                                  side: const BorderSide(color: Colors.redAccent, width: 2),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _handleSuccess,
                                icon: const Icon(Icons.check, color: Colors.greenAccent),
                                label: Text(s.todDoneButton, style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.greenAccent.withValues(alpha: 0.1),
                                  side: const BorderSide(color: Colors.greenAccent, width: 2),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }

  // Paquet neutre posé au repos sur le tapis
  Widget _buildRestingDeck() {
    const double cardW = 90;
    const double cardH = 135;

    return Center(
      child: SizedBox(
        width: cardW,
        height: cardH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Couches inférieures créant l'épaisseur 3D de la pile
            Positioned(
              top: 4,
              left: 1,
              child: Container(
                width: cardW,
                height: cardH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF0C0B1E),
                  border: Border.all(color: Colors.white12, width: 1),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 5)),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 2,
              left: 0.5,
              child: Container(
                width: cardW,
                height: cardH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF100F26),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
              ),
            ),
            // Carte supérieure neutre avec texture néon dédiée (sans titre de difficulté, motif cartes + ?)
            Container(
              width: cardW,
              height: cardH,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: const DecorationImage(
                  image: AssetImage('assets/Deck_Neutral.png'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.15),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- NOUVEAU COMPOSANT : Les Panneaux de Duel Action / Vérité ---
  Widget _buildDuelChoiceArea(double matWidth, double matHeight, AppStrings s) {
    return FadeTransition(
      opacity: _choiceFadeAnimation,
      child: ScaleTransition(
        scale: _choiceScaleAnimation,
        child: SizedBox(
          width: matWidth,
          height: matHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Row(
              children: [
                // --- PANNEAU ACTION (GAUCHE - CYAN) ---
                Expanded(
                  child: _buildChoiceCard(
                    type: 'ACTION',
                    label: s.todActionLabel,
                    subtitle: s.todActionSubtitle,
                    tapHint: s.todTapHint,
                    icon: Icons.bolt_rounded,
                    primaryColor: const Color(0xFF00E5FF),
                    darkBgStart: const Color(0xCC0B1E2B),
                    darkBgEnd: const Color(0xDD061019),
                  ),
                ),
                const SizedBox(width: 14),
                // --- PANNEAU VÉRITÉ (DROITE - MAGENTA/VIOLET) ---
                Expanded(
                  child: _buildChoiceCard(
                    type: 'VERITE',
                    label: s.todTruthLabel,
                    subtitle: s.todTruthSubtitle,
                    tapHint: s.todTapHint,
                    icon: Icons.visibility_rounded,
                    primaryColor: const Color(0xFFFF2A85),
                    darkBgStart: const Color(0xCC260D22),
                    darkBgEnd: const Color(0xDD150716),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String type,
    required String label,
    required String subtitle,
    required String tapHint,
    required IconData icon,
    required Color primaryColor,
    required Color darkBgStart,
    required Color darkBgEnd,
  }) {
    return GestureDetector(
      onTap: () => _selectType(type),
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [darkBgStart, darkBgEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.85),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Médaillon néon circulaire
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(alpha: 0.15),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.9),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.4),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Titre ACTION / VÉRITÉ
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                      color: primaryColor,
                      shadows: [
                        Shadow(
                          color: primaryColor,
                          blurRadius: 16,
                        ),
                        const Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Sous-titre d'accroche
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Petit indicateur "CHOISIR"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tapHint,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 9, color: primaryColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShuffleAnimation() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        const double cardW = 90;
        const double cardH = 135;
        final double centerX = (width - cardW) / 2;
        final double centerY = (height - cardH) / 2;

        return AnimatedBuilder(
          animation: _shuffleController,
          builder: (context, _) {
            final double t = _shuffleController.value;
            final int count = _shuffleCards.length;
            final int split1 = (count / 3).round();
            final int split2 = ((2 * count) / 3).round();

            double clamp01(double v) => v < 0.0 ? 0.0 : (v > 1.0 ? 1.0 : v);
            double lerp(double a, double b, double p) => a + (b - a) * p;

            return Stack(
              clipBehavior: Clip.none,
              children: List.generate(count, (idx) {
                final String deck = _shuffleCards[idx];

                String img = 'assets/Soft_Card.png';
                if (deck == 'FUN') img = 'assets/Fun_Card.png';
                if (deck == 'HOT') img = 'assets/Hot_Card.png';
                if (deck == 'CUSTOM') img = 'assets/Custom_Card.png';

                // Repos initial avec micro-variations
                final double stackThickness = (idx * 1.2);
                final double restX = centerX;
                final double restY = centerY - stackThickness;
                final double restAngle = sin(idx * 2.3) * 0.005;

                double x = restX;
                double y = restY;
                double angle = restAngle;
                double scale = 1.0;
                bool isLifted = false;

                // --- Séquence du mélange à la française ---
                if (t <= 0.22) {
                  // Phase 1 : Prise du paquet supérieur et levée vers la droite
                  final double p1 = Curves.easeInOutCubic.transform(clamp01(t / 0.22));
                  if (idx < split1) {
                    // Paquet base gauche
                    x = lerp(restX, centerX - 32, p1);
                    y = restY;
                    angle = lerp(restAngle, -0.015, p1);
                  } else {
                    // Paquet levé à droite
                    isLifted = true;
                    final double liftDx = 45.0 + (idx - split1) * 0.5;
                    final double liftDy = -40.0 - (idx - split1) * 0.8;
                    x = lerp(restX, centerX + liftDx, p1);
                    y = lerp(restY, restY + liftDy, p1);
                    angle = lerp(restAngle, 0.038, p1);
                    scale = lerp(1.0, 1.04, p1);
                  }
                } else if (t <= 0.46) {
                  // Phase 2 : Chute progressive des cartes du paquet 2 sur la gauche
                  if (idx < split1) {
                    x = centerX - 32;
                    y = restY;
                    angle = -0.015;
                  } else if (idx < split2) {
                    // Cartes qui tombent par cascade
                    final int k = idx - split1;
                    final int m2 = split2 - split1;
                    final double tStart = 0.22 + (k / m2) * 0.15;
                    final double tEnd = tStart + 0.08;

                    final double xRight = centerX + 45.0 + k * 0.5;
                    final double yRight = (centerY - (idx * 1.2)) - 40.0;
                    final double xLeft = centerX - 32;
                    final double yLeft = centerY - (split1 + k) * 1.2;

                    if (t < tStart) {
                      isLifted = true;
                      x = xRight;
                      y = yRight;
                      angle = 0.038;
                      scale = 1.04;
                    } else if (t >= tEnd) {
                      x = xLeft;
                      y = yLeft;
                      angle = -0.012 + sin(idx) * 0.004;
                      scale = 1.0;
                    } else {
                      isLifted = true;
                      final double u = clamp01((t - tStart) / (tEnd - tStart));
                      final double arcY = -sin(u * pi) * 20.0;
                      x = lerp(xRight, xLeft, Curves.easeOutQuad.transform(u));
                      y = lerp(yRight, yLeft, Curves.easeInQuad.transform(u)) + arcY;
                      angle = lerp(0.038, -0.012, u);
                      scale = lerp(1.04, 1.0, u);
                    }
                  } else {
                    // Paquet 3 reste en l'air dans la main droite
                    isLifted = true;
                    x = centerX + 45.0 + (idx - split1) * 0.5;
                    y = (centerY - (idx * 1.2)) - 40.0;
                    angle = 0.038;
                    scale = 1.04;
                  }
                } else if (t <= 0.60) {
                  // Phase 3 : Nouvelle élévation du paquet 3 restant
                  if (idx < split2) {
                    x = centerX - 32;
                    y = centerY - (idx * 1.2);
                    angle = -0.012;
                  } else {
                    isLifted = true;
                    final double p3 = Curves.easeInOut.transform(clamp01((t - 0.46) / 0.14));
                    final double liftDx = 48.0 + sin(p3 * pi) * 6;
                    final double liftDy = -42.0 - 12.0 * p3;
                    x = centerX + liftDx;
                    y = (centerY - (idx * 1.2)) + liftDy;
                    angle = lerp(0.038, 0.045, p3);
                    scale = 1.04;
                  }
                } else if (t <= 0.82) {
                  // Phase 4 : Deuxième chute des cartes du paquet 3 sur la pile gauche
                  if (idx < split2) {
                    x = centerX - 32;
                    y = centerY - (idx * 1.2);
                    angle = -0.012;
                  } else {
                    final int k = idx - split2;
                    final int m3 = count - split2;
                    final double tStart = 0.60 + (k / m3) * 0.14;
                    final double tEnd = tStart + 0.07;

                    final double xRight = centerX + 48.0;
                    final double yRight = (centerY - (idx * 1.2)) - 54.0;
                    final double xLeft = centerX - 32;
                    final double yLeft = centerY - (split2 + k) * 1.2;

                    if (t < tStart) {
                      isLifted = true;
                      x = xRight;
                      y = yRight;
                      angle = 0.045;
                      scale = 1.04;
                    } else if (t >= tEnd) {
                      x = xLeft;
                      y = yLeft;
                      angle = -0.01 + sin(idx * 3.1) * 0.005;
                      scale = 1.0;
                    } else {
                      isLifted = true;
                      final double u = clamp01((t - tStart) / (tEnd - tStart));
                      final double arcY = -sin(u * pi) * 18.0;
                      x = lerp(xRight, xLeft, Curves.easeOutQuad.transform(u));
                      y = lerp(yRight, yLeft, Curves.easeInQuad.transform(u)) + arcY;
                      angle = lerp(0.045, -0.01, u);
                      scale = lerp(1.04, 1.0, u);
                    }
                  }
                } else if (t <= 0.92) {
                  // Phase 5 : Retour de la pile complète vers le centre
                  final double p5 = Curves.easeInOutCubic.transform(clamp01((t - 0.82) / 0.10));
                  x = lerp(centerX - 32, centerX, p5);
                  y = centerY - (idx * 1.2);
                  angle = lerp(-0.01, 0.0, p5);
                  scale = 1.0;
                } else {
                  // Phase 6 : Tapotement net sur le tapis pour tasser les cartes
                  final double ptap = clamp01((t - 0.92) / 0.08);
                  final double tapY = -sin(ptap * pi) * 8.0;
                  x = centerX;
                  y = centerY - (idx * 1.2) + tapY;
                  angle = 0.0;
                  scale = 1.0;
                }

                return Positioned(
                  left: x,
                  top: y,
                  child: Transform.rotate(
                    angle: angle * 2 * pi,
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: cardW,
                        height: cardH,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(image: AssetImage(img), fit: BoxFit.cover),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isLifted ? 0.45 : 0.28),
                              blurRadius: isLifted ? 14 : 7,
                              offset: Offset(0, isLifted ? 8 : 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }

  Widget _buildSwipeableCard(AppStrings s) {
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
                if (_swipeOffset.dx > 120) {_handleSuccess();} 
                else if (_swipeOffset.dx < -120) {_handleFail();}
                else {_swipeOffset = Offset.zero;}
              },
              child: AnimatedContainer(
                duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400), curve: Curves.elasticOut,
                transform: Matrix4.translationValues(_swipeOffset.dx, _swipeOffset.dy, 0)..rotateZ(_swipeOffset.dx / 1000),
                child: Transform(alignment: FractionalOffset.center, transform: Matrix4.identity()..setEntry(3, 2, 0.0015)..rotateY(angle), child: isFront ? _buildCardFront(s) : _buildCardBack(backImage)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardFront(AppStrings s) {
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
              Text("${s.todCardTypeDisplay(_currentCard!.type)} • ${_currentCard!.difficulty}", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
              Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: Text(s.todPenaltyLabel(_currentCard!.shots), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
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
