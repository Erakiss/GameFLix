// lib/games/would_you_rather/wyr_game.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/games/would_you_rather/wyr_lobby.dart';
import 'package:gameflix/games/would_you_rather/wyr_scoreboard.dart';
import 'package:gameflix/shared/widgets/neon_volume_control.dart';
import 'package:gameflix/services/audio_service.dart';

class WyrGameScreen extends StatefulWidget {
  final List<Player> players;
  final List<WyrCard> deck;
  final int totalRounds;

  const WyrGameScreen({
    super.key,
    required this.players,
    required this.deck,
    required this.totalRounds,
  });

  @override
  State<WyrGameScreen> createState() => _WyrGameScreenState();
}

class _WyrGameScreenState extends State<WyrGameScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isRevealed = false;

  // Joueurs pénalisés sur la manche courante :
  // Clé = nom du joueur, Valeur = points pénalité (2 = minorité seule, 3 = minorité + choix de la honte)
  final Map<String, int> _roundPenalties = {};

  late AnimationController _revealAnimController;
  late Animation<double> _revealCurvedAnimation;

  late AnimationController _cardTransitionController;
  late Animation<Offset> _cardSlideAnimation;

  @override
  void initState() {
    super.initState();

    _revealAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _revealCurvedAnimation = CurvedAnimation(
      parent: _revealAnimController,
      curve: Curves.easeOutBack,
    );

    _cardTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _cardSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.2, 0.0),
    ).animate(CurvedAnimation(
      parent: _cardTransitionController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _revealAnimController.dispose();
    _cardTransitionController.dispose();
    super.dispose();
  }

  void _revealResults() {
    if (_isRevealed) return;
    HapticFeedback.mediumImpact();
    AudioService.instance.playSfx(SoundEffect.suspense);

    setState(() {
      _isRevealed = true;
      _roundPenalties.clear();
    });
    _revealAnimController.forward(from: 0.0);
  }

  void _togglePlayerPenalty(Player player, bool hasShameOption) {
    HapticFeedback.lightImpact();
    AudioService.instance.playSfx(SoundEffect.click);

    setState(() {
      final current = _roundPenalties[player.name];
      if (current == null) {
        // 1er tap : pénalité de base pour minorité (+2)
        _roundPenalties[player.name] = 2;
      } else if (current == 2 && hasShameOption) {
        // 2e tap : si choix honteux présent, passe à +3 (minorité + malus honteux)
        _roundPenalties[player.name] = 3;
      } else {
        // Annulation
        _roundPenalties.remove(player.name);
      }
    });
  }

  void _nextCard() {
    // Application des pénalités validées aux joueurs
    for (final entry in _roundPenalties.entries) {
      final player = widget.players.firstWhere((p) => p.name == entry.key);
      player.score += entry.value;
    }

    final bool isLastRound = (_currentIndex + 1 >= widget.totalRounds) ||
        (_currentIndex + 1 >= widget.deck.length);

    if (isLastRound) {
      HapticFeedback.heavyImpact();
      AudioService.instance.playSfx(SoundEffect.victory);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WyrScoreboardScreen(
            players: widget.players,
            onRestart: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => WyrLobbyScreen(players: widget.players),
                ),
              );
            },
          ),
        ),
      );
      return;
    }

    AudioService.instance.playSfx(SoundEffect.cardSlide);
    _cardTransitionController.forward().then((_) {
      if (!mounted) return;
      setState(() {
        _currentIndex++;
        _isRevealed = false;
        _roundPenalties.clear();
      });
      _cardTransitionController.reset();
      _revealAnimController.reset();
    });
  }

  void _showLiveLeaderboard() {
    AudioService.instance.playSfx(SoundEffect.click);

    final sorted = List<Player>.from(widget.players)
      ..sort((a, b) => b.score.compareTo(a.score));

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16162D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.leaderboard_rounded,
                            color: Colors.amberAccent, size: 24),
                        SizedBox(width: 8),
                        Text(
                          "SCORES EN DIRECT",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  "Le joueur avec le plus de points boira le shot final !",
                  style: TextStyle(fontSize: 13, color: Colors.white60),
                ),
                const SizedBox(height: 15),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sorted.length,
                    itemBuilder: (context, i) {
                      final p = sorted[i];
                      final isFirst = i == 0 && p.score > 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isFirst
                              ? Colors.redAccent.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFirst
                                ? Colors.redAccent
                                : Colors.white12,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              "#${i + 1}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isFirst
                                    ? Colors.redAccent
                                    : Colors.white54,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "${p.score} pts",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isFirst
                                    ? Colors.redAccent
                                    : Colors.cyanAccent,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Quitter la partie ?",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          "La progression et les pénalités de cette manche seront perdues.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CONTINUER",
                style: TextStyle(color: Colors.cyanAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("QUITTER",
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.deck.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text("Aucune carte", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final card = widget.deck[_currentIndex];
    final int maxRoundDisplay = min(widget.totalRounds, widget.deck.length);
    final bool hasShameOption =
        card.percentage1 < 35 || card.percentage2 < 35;
    final bool isLastCard = (_currentIndex + 1 >= maxRoundDisplay);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _onWillPop();
        if (shouldLeave && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0C0C1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white70, size: 20),
            onPressed: () async {
              final shouldLeave = await _onWillPop();
              if (shouldLeave && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            "MANCHE ${_currentIndex + 1} / $maxRoundDisplay",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
          centerTitle: true,
          actions: [
            // Bouton Classement en direct
            IconButton(
              icon: const Icon(Icons.leaderboard_rounded,
                  color: Colors.amberAccent, size: 24),
              tooltip: 'Classement en direct',
              onPressed: _showLiveLeaderboard,
            ),
            const NeonVolumeControl(),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Zone de la Carte principale (prend le maximum de hauteur disponible)
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SlideTransition(
                    position: _cardSlideAnimation,
                    child: _buildDilemmaCard(card, hasShameOption),
                  ),
                ),
              ),

              // Zone d'interaction inférieure
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: _isRevealed
                    ? _buildRevealedInteractionSection(
                        hasShameOption, isLastCard)
                    : _buildPreRevealButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET CARTE DU DILEMME : 2 CARTES DUEL FLOTTANTES ---
  Widget _buildDilemmaCard(WyrCard card, bool hasShameOption) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            // CARTE DUEL CHOIX A (Rose fuchsia néon)
            Expanded(
              child: _buildFloatingDuelCard(
                badgeLabel: "CHOIX A",
                text: card.choice1,
                percentage: card.percentage1,
                primaryColor: const Color(0xFFFF2A85),
                darkBgStart: const Color(0xFF260D22),
                darkBgEnd: const Color(0xFF150716),
                isShame: card.percentage1 < 35,
              ),
            ),

            // Espace pour faire respirer les deux cartes et accueillir le badge VS
            const SizedBox(height: 20),

            // CARTE DUEL CHOIX B (Cyan électrique néon)
            Expanded(
              child: _buildFloatingDuelCard(
                badgeLabel: "CHOIX B",
                text: card.choice2,
                percentage: card.percentage2,
                primaryColor: const Color(0xFF00E5FF),
                darkBgStart: const Color(0xFF0B1E2B),
                darkBgEnd: const Color(0xFF061019),
                isShame: card.percentage2 < 35,
              ),
            ),
          ],
        ),

        // Badge central VS électrisant
        _buildCentralVsBadge(),

        // Bannière Mini-Gage éventuelle
        if (card.miniGage != null && _isRevealed)
          Positioned(
            top: -4,
            left: 8,
            right: 8,
            child: _buildMiniGageBanner(card.miniGage!),
          ),
      ],
    );
  }

  // --- CARTE FLOTTANTE INDÉPENDANTE POUR CHAQUE CHOIX ---
  Widget _buildFloatingDuelCard({
    required String badgeLabel,
    required String text,
    required int percentage,
    required Color primaryColor,
    required Color darkBgStart,
    required Color darkBgEnd,
    required bool isShame,
  }) {
    return GestureDetector(
      onTap: _isRevealed ? null : _revealResults,
      child: AnimatedBuilder(
        animation: _revealCurvedAnimation,
        builder: (context, child) {
          final double anim = _revealCurvedAnimation.value;
          final double fillRatio = _isRevealed ? (percentage / 100.0) : 0.0;
          final int currentDisplayedPercentage =
              (fillRatio * anim * 100).round();

          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [darkBgStart, darkBgEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.8),
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
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Jauge animée en arrière-plan
                  if (_isRevealed)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: max(0.01, fillRatio * anim),
                        heightFactor: 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor.withValues(alpha: 0.2),
                                primaryColor.withValues(alpha: 0.55),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Contenu de la carte
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête : Badge CHOIX A / B + Badge Honte éventuel
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.7),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                badgeLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: primaryColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            if (_isRevealed && isShame && anim > 0.8)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.redAccent,
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  "💀 CHOIX DE LA HONTE (<35%) • +1 PT MALUS",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.redAccent,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Texte central du dilemme
                        Expanded(
                          child: Center(
                            child: AutoSizeText(
                              text,
                              textAlign: TextAlign.center,
                              maxLines: 4,
                              minFontSize: 15,
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.25,
                                shadows: [
                                  Shadow(
                                    color: primaryColor.withValues(alpha: 0.6),
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Section inférieure : Pourcentage communautaire
                        if (_isRevealed)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                "$currentDisplayedPercentage%",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: primaryColor,
                                  shadows: [
                                    Shadow(
                                      color: primaryColor,
                                      blurRadius: 15,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "MONDE",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white54,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          )
                        else
                          const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- BADGE CENTRAL VS ÉLECTRISANT ---
  Widget _buildCentralVsBadge() {
    return GestureDetector(
      onTap: _isRevealed ? null : _revealResults,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF101024),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.85),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(-4, 0),
            ),
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(4, 0),
            ),
            const BoxShadow(
              color: Colors.black87,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, color: Colors.amberAccent, size: 18),
            SizedBox(width: 3),
            Text(
              "VS",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            SizedBox(width: 3),
            Icon(Icons.bolt_rounded, color: Colors.amberAccent, size: 18),
          ],
        ),
      ),
    );
  }

  // --- BANNIÈRE MINI-GAGE ---
  Widget _buildMiniGageBanner(String miniGage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF261904),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amberAccent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amberAccent.withValues(alpha: 0.35),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.flash_on, color: Colors.amberAccent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "MINI-GAGE : $miniGage",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.amberAccent,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // --- BOUTON AVANT RÉVÉLATION ---
  Widget _buildPreRevealButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_vote_outlined,
                color: Colors.white60, size: 18),
            SizedBox(width: 8),
            Text(
              "Votez à main levée à la table !",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _revealResults,
            icon: const Icon(Icons.pie_chart_outline_rounded,
                color: Colors.black, size: 24),
            label: const Text(
              "RÉVÉLER LES POURCENTAGES",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: 1.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: Colors.cyanAccent.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  // --- SECTION INTERACTIVE APRÈS RÉVÉLATION ---
  Widget _buildRevealedInteractionSection(
      bool hasShameOption, bool isLastCard) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête : consigne de pénalités
        Row(
          children: [
            const Icon(Icons.touch_app_rounded,
                color: Colors.redAccent, size: 18),
            const SizedBox(width: 6),
            Text(
              hasShameOption
                  ? "QUI EST EN MINORITÉ ? (+2 pts, tap = +3 si honte)"
                  : "QUI EST EN MINORITÉ ? (+2 pts)",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.redAccent,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Rangée horizontale des puces des joueurs
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.players.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final player = widget.players[index];
              final penalty = _roundPenalties[player.name];
              final bool isPenalized = penalty != null;

              final Color genderColor = player.gender == 'M'
                  ? Colors.cyanAccent
                  : Colors.pinkAccent;

              return GestureDetector(
                onTap: () => _togglePlayerPenalty(player, hasShameOption),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPenalized
                        ? Colors.redAccent.withValues(alpha: 0.25)
                        : const Color(0xFF1C1C36),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPenalized
                          ? Colors.redAccent
                          : genderColor.withValues(alpha: 0.4),
                      width: isPenalized ? 2.5 : 1.5,
                    ),
                    boxShadow: isPenalized
                        ? [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.5),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Macaron Avatar avec initiale
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPenalized
                              ? Colors.redAccent
                              : genderColor.withValues(alpha: 0.2),
                          border: Border.all(
                            color: isPenalized
                                ? Colors.white
                                : genderColor,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            player.name.isNotEmpty
                                ? player.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isPenalized ? Colors.white : genderColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Prénom et badge de pénalité
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isPenalized
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (isPenalized)
                            Text(
                              "+$penalty pts",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.redAccent,
                              ),
                            )
                          else
                            Text(
                              "${player.score} pts",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white38,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Bouton Suivant / Fin de partie
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _nextCard,
            icon: Icon(
              isLastCard ? Icons.emoji_events : Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 22,
            ),
            label: Text(
              isLastCard
                  ? "VOIR LE HALL OF SHAME 💀"
                  : "DILEMME SUIVANT ➔",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isLastCard ? Colors.redAccent : Colors.orangeAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              shadowColor: (isLastCard ? Colors.redAccent : Colors.orangeAccent)
                  .withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}
