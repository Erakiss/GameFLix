// lib/games/never_have_i_ever/nhie_game.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/games/never_have_i_ever/nhie_lobby.dart';
import 'package:gameflix/games/never_have_i_ever/nhie_scoreboard.dart';
import 'package:gameflix/shared/widgets/global_settings_button.dart';
import 'package:gameflix/shared/widgets/game_rules_sheet.dart';
import 'package:gameflix/services/audio_service.dart';
import 'package:gameflix/l10n/app_strings.dart';
import 'package:gameflix/l10n/strings_tod_nhie.dart';

class _NhieTurnRecord {
  final int cardIndex;
  final Set<String> selectedPlayers;

  _NhieTurnRecord({
    required this.cardIndex,
    required this.selectedPlayers,
  });
}

class NhieRaceScreen extends StatefulWidget {
  final List<Player> players;
  final List<NhieCard> deck;
  final int targetScore;

  const NhieRaceScreen({
    super.key,
    required this.players,
    required this.deck,
    this.targetScore = 10,
  });

  @override
  State<NhieRaceScreen> createState() => _NhieRaceScreenState();
}

class _NhieRaceScreenState extends State<NhieRaceScreen>
    with TickerProviderStateMixin {
  int _cardIndex = 0;
  final Map<String, bool> _currentTurnSelections = {};
  final List<_NhieTurnRecord> _history = [];

  late AnimationController _cardAnimController;
  late Animation<Offset> _cardSlideAnimation;
  late AnimationController _pulseController;

  double _dragOffsetX = 0.0;
  bool _isTransitioning = false;

  static const List<Color> _playerPalette = [
    Color(0xFFFF3366), // Rose néon
    Color(0xFF00E5FF), // Cyan électrique
    Color(0xFFFFAB00), // Ambre solaire
    Color(0xFFD500F9), // Violet plasma
    Color(0xFF00E676), // Vert laser
    Color(0xFFFF6D00), // Orange magma
    Color(0xFF2979FF), // Bleu cobalt néon
    Color(0xFFFFEA00), // Jaune volt
  ];

  @override
  void initState() {
    super.initState();
    for (final p in widget.players) {
      p.score = 0;
    }

    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _cardSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.15, 0.0),
    ).animate(
      CurvedAnimation(parent: _cardAnimController, curve: Curves.easeInCubic),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cardAnimController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'SOFT':
        return Colors.greenAccent;
      case 'FUN':
        return Colors.amberAccent;
      case 'GEEK':
        return Colors.purpleAccent;
      case 'HOT':
        return Colors.redAccent;
      default:
        return Colors.cyanAccent;
    }
  }

  IconData _getCategoryIcon(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'SOFT':
        return Icons.spa_rounded;
      case 'FUN':
        return Icons.celebration_rounded;
      case 'GEEK':
        return Icons.sports_esports_rounded;
      case 'HOT':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.bolt_rounded;
    }
  }

  void _togglePlayer(Player player) {
    if (_isTransitioning) return;
    HapticFeedback.lightImpact();
    AudioService.instance.playSfx(SoundEffect.click);

    setState(() {
      final bool current = _currentTurnSelections[player.name] ?? false;
      if (current) {
        _currentTurnSelections.remove(player.name);
      } else {
        _currentTurnSelections[player.name] = true;
      }
    });
  }

  Future<void> _nextCard() async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    final Set<String> chosenThisTurn = {};
    for (final p in widget.players) {
      if (_currentTurnSelections[p.name] == true) {
        chosenThisTurn.add(p.name);
        p.score += 1;
      }
    }

    final bool hasWinner =
        widget.players.any((p) => p.score >= widget.targetScore);

    if (hasWinner) {
      HapticFeedback.heavyImpact();
      AudioService.instance.playSfx(SoundEffect.victory);
      _isTransitioning = false;
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NhieScoreboardScreen(
            players: widget.players,
            targetScore: widget.targetScore,
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    AudioService.instance.playSfx(SoundEffect.cardSlide);

    _history.add(
      _NhieTurnRecord(
        cardIndex: _cardIndex,
        selectedPlayers: chosenThisTurn,
      ),
    );

    await _cardAnimController.forward();
    if (!mounted) return;

    setState(() {
      _currentTurnSelections.clear();
      _dragOffsetX = 0.0;
      _cardIndex = (_cardIndex + 1) % widget.deck.length;
    });

    _cardAnimController.reset();
    _isTransitioning = false;
  }

  void _undoLastTurn() {
    if (_history.isEmpty || _isTransitioning) return;
    HapticFeedback.mediumImpact();
    AudioService.instance.playSfx(SoundEffect.click);

    final lastRecord = _history.removeLast();
    setState(() {
      for (final p in widget.players) {
        if (lastRecord.selectedPlayers.contains(p.name)) {
          p.score = max(0, p.score - 1);
        }
      }
      _cardIndex = lastRecord.cardIndex;
      _currentTurnSelections
        ..clear()
        ..addEntries(
          lastRecord.selectedPlayers.map((name) => MapEntry(name, true)),
        );
    });
  }

  int _visualScoreOf(Player p) {
    final bool isSelected = _currentTurnSelections[p.name] ?? false;
    return p.score + (isSelected ? 1 : 0);
  }

  Widget _buildFinishBanner(AppStrings s) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.cyanAccent.withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.5),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _CheckeredBannerPainter(),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF070718).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("🏁", style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Text(
                    s.nhieFinishBanner(widget.targetScore),
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text("🏁", style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRaceTrack({
    required Player player,
    required int index,
    required double laneWidth,
    required int maxVisualScore,
  }) {
    final bool isSelected = _currentTurnSelections[player.name] ?? false;
    final int visualScore = _visualScoreOf(player);
    final double progress =
        (visualScore / widget.targetScore).clamp(0.0, 1.0);
    final Color trackColor = _playerPalette[index % _playerPalette.length];

    final bool isLeader =
        visualScore > 0 && visualScore == maxVisualScore;
    final bool isAtFinish = visualScore >= widget.targetScore;
    final bool isMatchPoint = visualScore == widget.targetScore - 1;

    final double tubeWidth = (laneWidth * 0.68).clamp(38.0, 50.0);
    const double avatarSize = 34.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _togglePlayer(player),
      child: SizedBox(
        width: laneWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            children: [
              // Piste verticale (Tube Hippodrome Néon)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: tubeWidth,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? trackColor.withValues(alpha: 0.12)
                        : const Color(0xFF0B0B1E),
                    borderRadius: BorderRadius.circular(tubeWidth / 2),
                    border: Border.all(
                      color: isSelected
                          ? trackColor
                          : isLeader
                              ? Colors.amberAccent.withValues(alpha: 0.65)
                              : Colors.white.withValues(alpha: 0.14),
                      width: isSelected ? 2.2 : 1.4,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: trackColor.withValues(alpha: 0.45),
                          blurRadius: 14,
                          spreadRadius: 1,
                        )
                      else if (isLeader)
                        BoxShadow(
                          color: Colors.amberAccent.withValues(alpha: 0.2),
                          blurRadius: 10,
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular((tubeWidth / 2) - 2),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double maxTrackHeight = constraints.maxHeight;
                        final double usableTravel =
                            max(0.0, maxTrackHeight - avatarSize - 8);
                        final double horseTop =
                            4 + usableTravel * (1.0 - progress);
                        final double trailHeight = max(
                          0.0,
                          maxTrackHeight - horseTop - (avatarSize * 0.5),
                        );

                        return Stack(
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.none,
                          children: [
                            // Graduations des paliers (1 .. targetScore)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _TrackGraduationsPainter(
                                  targetScore: widget.targetScore,
                                  currentScore: visualScore,
                                  trackColor: trackColor,
                                  topPadding: 4 + avatarSize / 2,
                                  bottomPadding: 4 + avatarSize / 2,
                                ),
                              ),
                            ),

                            // Traînée lumineuse néon sous le cheval
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 450),
                              curve: Curves.easeOutBack,
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: trailHeight,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      trackColor.withValues(
                                        alpha: isSelected ? 0.65 : 0.42,
                                      ),
                                      trackColor.withValues(alpha: 0.06),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Pion Cheval animé
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 450),
                              curve: Curves.easeOutBack,
                              top: horseTop,
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: avatarSize,
                                    height: avatarSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: isSelected
                                            ? [
                                                trackColor,
                                                trackColor.withValues(
                                                  alpha: 0.75,
                                                ),
                                              ]
                                            : [
                                                const Color(0xFF1F1F3D),
                                                const Color(0xFF14142B),
                                              ],
                                      ),
                                      border: Border.all(
                                        color: isLeader
                                            ? Colors.amberAccent
                                            : trackColor,
                                        width: isLeader ? 2.2 : 1.8,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isLeader
                                                  ? Colors.amberAccent
                                                  : trackColor)
                                              .withValues(alpha: 0.55),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: isAtFinish
                                          ? const Icon(
                                              Icons.emoji_events_rounded,
                                              color: Colors.amberAccent,
                                              size: 19,
                                            )
                                          : FaIcon(
                                              FontAwesomeIcons.horseHead,
                                              color: isSelected
                                                  ? Colors.black
                                                  : Colors.white,
                                              size: 16,
                                            ),
                                    ),
                                  ),

                                  // Couronne du leader en tête
                                  if (isLeader && !isAtFinish)
                                    Positioned(
                                      top: -11,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF0B0B1E),
                                        ),
                                        child: const FaIcon(
                                          FontAwesomeIcons.crown,
                                          color: Colors.amberAccent,
                                          size: 10,
                                        ),
                                      ),
                                    ),

                                  // Badge pulsant "+1" quand sélectionné
                                  if (isSelected)
                                    Positioned(
                                      bottom: -14,
                                      child: ScaleTransition(
                                        scale: Tween<double>(
                                          begin: 0.92,
                                          end: 1.08,
                                        ).animate(_pulseController),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: trackColor,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: trackColor.withValues(
                                                  alpha: 0.6,
                                                ),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            "+1 🍺",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Badge de score du joueur
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? trackColor.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? trackColor
                        : isMatchPoint
                            ? Colors.orangeAccent.withValues(alpha: 0.7)
                            : Colors.white12,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isMatchPoint && !isAtFinish) ...[
                        const Text("🔥", style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 2),
                      ],
                      Text(
                        "$visualScore",
                        style: TextStyle(
                          color: isSelected ? Colors.white : trackColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        "/${widget.targetScore}",
                        style: const TextStyle(
                          color: Colors.white38,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Pseudo du joueur (sur 2 lignes max ou incliné légèrement pour lisibilité totale)
              SizedBox(
                height: 28,
                child: Center(
                  child: AutoSizeText(
                    player.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    minFontSize: 9,
                    stepGranularity: 0.5,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? trackColor : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 12,
                      height: 1.1,
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

  Widget _buildCompactCard(NhieCard card, Color accentColor, AppStrings s) {
    final double dragRatio = (_dragOffsetX / 180.0).clamp(-1.0, 1.0);

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (_isTransitioning) return;
        setState(() {
          _dragOffsetX += details.delta.dx;
        });
      },
      onHorizontalDragEnd: (details) {
        if (_isTransitioning) return;
        final double velocity = details.primaryVelocity ?? 0.0;
        if (_dragOffsetX.abs() > 75 || velocity.abs() > 450) {
          _nextCard();
        } else {
          setState(() => _dragOffsetX = 0.0);
        }
      },
      child: SlideTransition(
        position: _cardSlideAnimation,
        child: Transform.translate(
          offset: Offset(_dragOffsetX, 0),
          child: Transform.rotate(
            angle: dragRatio * 0.06,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 118,
                maxHeight: 148,
              ),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF15152C),
                    accentColor.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.75),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.25),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // En-tête de la carte : Badge Catégorie + Titre + Numéro de tour
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.7),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCategoryIcon(card.difficulty),
                              color: accentColor,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              card.difficulty.toUpperCase(),
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            s.nhieCardHeaderTitle,
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.8,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "#${_history.length + 1}",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Center(
                      child: AutoSizeText(
                        card.content,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        minFontSize: 13,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
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

  Widget _buildBottomActionBar(
    int selectedCount,
    bool willSomeoneWin,
    AppStrings s,
  ) {
    final bool hasSelection = selectedCount > 0;
    final Color buttonColor = willSomeoneWin
        ? Colors.amberAccent
        : hasSelection
            ? Colors.cyanAccent
            : Colors.white24;

    final String statusText = s.nhieStatusText(selectedCount);

    final String buttonLabel =
        s.nhieActionButtonLabel(selectedCount, willSomeoneWin);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              statusText,
              key: ValueKey<String>(statusText),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: hasSelection ? Colors.cyanAccent : Colors.white54,
                fontWeight: hasSelection ? FontWeight.w700 : FontWeight.normal,
                fontStyle:
                    hasSelection ? FontStyle.normal : FontStyle.italic,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Bouton Undo (Annuler le tour précédent)
              Tooltip(
                message: s.nhieUndoTooltip,
                child: GestureDetector(
                  onTap: _history.isNotEmpty ? _undoLastTurn : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 54,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: _history.isNotEmpty
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _history.isNotEmpty
                            ? Colors.white38
                            : Colors.white10,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.undo_rounded,
                      color:
                          _history.isNotEmpty ? Colors.white : Colors.white24,
                      size: 22,
                    ),
                  ),
                ),
              ),

              // Bouton principal dynamique
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _nextCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasSelection
                          ? buttonColor.withValues(alpha: 0.20)
                          : Colors.white.withValues(alpha: 0.07),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      side: BorderSide(
                        color: buttonColor,
                        width: hasSelection ? 2.0 : 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: AutoSizeText(
                      buttonLabel,
                      maxLines: 1,
                      minFontSize: 13,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: hasSelection ? buttonColor : Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final NhieCard card = widget.deck[_cardIndex];
    final Color accentColor = _getCategoryColor(card.difficulty);

    final int selectedCount =
        _currentTurnSelections.values.where((v) => v).length;
    int maxVisualScore = 0;
    bool willSomeoneWin = false;
    for (final p in widget.players) {
      final int vs = _visualScoreOf(p);
      if (vs > maxVisualScore) maxVisualScore = vs;
      if (vs >= widget.targetScore) willSomeoneWin = true;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050515),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          s.nhieRaceAppBarTitle,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.help_outline_rounded,
              color: Colors.cyanAccent,
              size: 24,
            ),
            tooltip: s.nhieRulesTooltip,
            onPressed: () => GameRulesSheet.show(
              context,
              DefaultGameRules.getRules('nhie'),
            ),
          ),
          const GlobalSettingsButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Carte compacte en haut (~22% de l'écran)
            _buildCompactCard(card, accentColor, s),

            const SizedBox(height: 4),

            // 2. Bandeau Damier d'arrivée
            _buildFinishBanner(s),

            const SizedBox(height: 6),

            // 3. Pistes verticales avec largeur adaptative + scroll horizontal si > 5-6 joueurs
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final int count = max(1, widget.players.length);
                    const double minLaneWidth = 64.0;
                    final double naturalWidth =
                        constraints.maxWidth / count;
                    final bool needsScroll = naturalWidth < minLaneWidth;
                    final double laneWidth =
                        needsScroll ? 68.0 : naturalWidth;

                    final Widget tracksRow = Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.players.length, (i) {
                        return _buildRaceTrack(
                          player: widget.players[i],
                          index: i,
                          laneWidth: laneWidth,
                          maxVisualScore: maxVisualScore,
                        );
                      }),
                    );

                    if (!needsScroll) {
                      return tracksRow;
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                          maxHeight: constraints.maxHeight,
                        ),
                        child: tracksRow,
                      ),
                    );
                  },
                ),
              ),
            ),

            // 4. Barre d'action dynamique + Undo
            _buildBottomActionBar(selectedCount, willSomeoneWin, s),
          ],
        ),
      ),
    );
  }
}

/// Peintre du bandeau damier néon de la ligne d'arrivée.
class _CheckeredBannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double squareSize = 10.0;
    final int cols = (size.width / squareSize).ceil();
    final int rows = (size.height / squareSize).ceil();

    final Paint lightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16);
    final Paint darkPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final bool isEven = (r + c) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(
            c * squareSize,
            r * squareSize,
            squareSize,
            squareSize,
          ),
          isEven ? lightPaint : darkPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Peintre des graduations de paliers à l'intérieur de chaque couloir vertical.
class _TrackGraduationsPainter extends CustomPainter {
  final int targetScore;
  final int currentScore;
  final Color trackColor;
  final double topPadding;
  final double bottomPadding;

  _TrackGraduationsPainter({
    required this.targetScore,
    required this.currentScore,
    required this.trackColor,
    required this.topPadding,
    required this.bottomPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (targetScore <= 1) return;
    final double usableHeight =
        max(0.0, size.height - topPadding - bottomPadding);

    for (int step = 1; step < targetScore; step++) {
      final double ratio = step / targetScore;
      final double y = topPadding + usableHeight * (1.0 - ratio);
      final bool isPassed = currentScore >= step;
      final bool isMidway = (targetScore >= 6 && step == targetScore ~/ 2);

      final double tickWidth = isMidway ? size.width * 0.55 : size.width * 0.32;
      final double startX = (size.width - tickWidth) / 2;

      final Paint tickPaint = Paint()
        ..color = isPassed
            ? trackColor.withValues(alpha: 0.55)
            : isMidway
                ? Colors.white.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = isMidway ? 1.8 : 1.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + tickWidth, y),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrackGraduationsPainter oldDelegate) {
    return oldDelegate.targetScore != targetScore ||
        oldDelegate.currentScore != currentScore ||
        oldDelegate.trackColor != trackColor;
  }
}
