// lib/games/never_have_i_ever/nhie_scoreboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/games/never_have_i_ever/nhie_lobby.dart';
import 'package:gameflix/shared/navigation.dart';
import 'package:gameflix/shared/widgets/global_settings_button.dart';
import 'package:gameflix/shared/widgets/neon_confetti.dart';
import 'package:gameflix/services/audio_service.dart';

class NhieScoreboardScreen extends StatelessWidget {
  final List<Player> players;
  final int targetScore;

  const NhieScoreboardScreen({
    super.key,
    required this.players,
    this.targetScore = 10,
  });

  String _getPlayerTitle(int score, int maxScore, int minScore) {
    if (score == maxScore && maxScore > 0) {
      return "Légende Vivante 🏆";
    }
    if (score == 0 || (score == minScore && maxScore > minScore)) {
      return "Ange Gardien 😇";
    }
    final double ratio = targetScore > 0 ? (score / targetScore) : 0.5;
    if (ratio >= 0.7) {
      return "Pur-Sang Déchaîné 🔥";
    }
    return "Galop d'Essai 🐎";
  }

  @override
  Widget build(BuildContext context) {
    final List<Player> sortedPlayers = List<Player>.from(players)
      ..sort((a, b) => b.score.compareTo(a.score));

    final int maxScore = sortedPlayers.isNotEmpty ? sortedPlayers.first.score : 0;
    final int minScore = sortedPlayers.isNotEmpty ? sortedPlayers.last.score : 0;
    final List<Player> winners =
        sortedPlayers.where((p) => p.score == maxScore).toList();
    final bool isPhotoFinish = winners.length > 1;
    final String winnersNames =
        winners.map((w) => w.name.toUpperCase()).join(' & ');

    return Scaffold(
      backgroundColor: const Color(0xFF050515),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "PODIUM DE LA COURSE",
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
        ),
        centerTitle: true,
        actions: const [
          GlobalSettingsButton(),
          SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: NeonConfettiWidget(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  // Bandeau titre sur une seule ligne (emojis hors du halo néon)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isPhotoFinish ? "📸" : "🏁",
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isPhotoFinish ? "PHOTO-FINISH !" : "ARRIVÉE FRANCHIE !",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.cyanAccent,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(color: Colors.cyanAccent, blurRadius: 14),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isPhotoFinish ? "📸" : "🏁",
                          style: const TextStyle(fontSize: 22),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Carte Champion(s)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.amberAccent.withValues(alpha: 0.22),
                          const Color(0xFF16122E),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.amberAccent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amberAccent.withValues(alpha: 0.3),
                          blurRadius: 22,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.crown,
                              color: Colors.amberAccent,
                              size: 15,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  isPhotoFinish
                                      ? "CHAMPIONS EX-AEQUO"
                                      : "GRAND VAINQUEUR DE LA SOIRÉE",
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    letterSpacing: 1.3,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const FaIcon(
                              FontAwesomeIcons.crown,
                              color: Colors.amberAccent,
                              size: 15,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        AutoSizeText(
                          winnersNames,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          minFontSize: 18,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(color: Colors.amber, blurRadius: 18),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isPhotoFinish
                              ? "Avec $maxScore aveux chacun, vous avez vécu mille vies ! 🍻"
                              : "Avec $maxScore aveux au compteur, rien ne t'arrête ! 🍻",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "CLASSEMENT DE L'HIPPODROME",
                      style: TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Liste des joueurs classés
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: sortedPlayers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final Player p = sortedPlayers[index];
                        final bool isTop = p.score == maxScore && maxScore > 0;
                        final String title =
                            _getPlayerTitle(p.score, maxScore, minScore);
                        final String ptsLabel =
                            "${p.score} pt${p.score > 1 ? 's' : ''}";

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isTop
                                ? Colors.amberAccent.withValues(alpha: 0.10)
                                : const Color(0xFF111126),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isTop
                                  ? Colors.amberAccent.withValues(alpha: 0.7)
                                  : Colors.white12,
                              width: isTop ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isTop
                                      ? Colors.amberAccent
                                      : Colors.white.withValues(alpha: 0.08),
                                ),
                                child: Text(
                                  "#${index + 1}",
                                  style: TextStyle(
                                    color: isTop ? Colors.black : Colors.white70,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isTop
                                            ? Colors.amberAccent
                                            : Colors.cyanAccent.withValues(
                                                alpha: 0.8,
                                              ),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isTop
                                        ? Colors.amberAccent.withValues(
                                            alpha: 0.5,
                                          )
                                        : Colors.white12,
                                  ),
                                ),
                                child: Text(
                                  ptsLabel,
                                  style: TextStyle(
                                    color: isTop
                                        ? Colors.amberAccent
                                        : Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Boutons Menu & Rejouer (sans coupure du mot MENU)
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: SizedBox(
                          height: 54,
                          child: OutlinedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              AudioService.instance.playSfx(SoundEffect.click);
                              goToHub(context);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              side: const BorderSide(
                                color: Colors.white24,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.home_rounded,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "MENU",
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 6,
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              AudioService.instance.playSfx(SoundEffect.click);
                              for (final p in players) {
                                p.score = 0;
                              }
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        NhieLobbyScreen(players: players),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.replay_rounded,
                                    color: Colors.black,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "REJOUER",
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
