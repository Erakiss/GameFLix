// lib/games/viper/viper_scoreboard.dart
import 'package:flutter/material.dart';

import 'package:gameflix/games/viper/viper_game.dart';
import 'package:gameflix/games/viper/viper_lobby.dart';
import 'package:gameflix/models/player.dart';
import 'package:gameflix/services/audio_service.dart';
import 'package:gameflix/shared/navigation.dart';
import 'package:gameflix/shared/widgets/global_settings_button.dart';
import 'package:gameflix/shared/widgets/neon_confetti.dart';

class ViperScoreboardScreen extends StatefulWidget {
  final List<BoardPlayer> boardPlayers;
  final List<Player> players;

  const ViperScoreboardScreen({
    super.key,
    required this.boardPlayers,
    required this.players,
  });

  @override
  State<ViperScoreboardScreen> createState() => _ViperScoreboardScreenState();
}

class _ViperScoreboardScreenState extends State<ViperScoreboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService.instance.playSfx(SoundEffect.victory);
    });
  }

  Widget _buildStatBadge(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<BoardPlayer>.from(widget.boardPlayers)
      ..sort((a, b) => b.currentTileIndex.compareTo(a.currentTileIndex));

    final BoardPlayer? winner = sorted.isNotEmpty ? sorted.first : null;
    final Color winnerColor = winner?.color ?? Colors.amberAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF050515),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'FIN DE PARTIE',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
            letterSpacing: 2,
          ),
        ),
        actions: const [
          GlobalSettingsButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            const IgnorePointer(child: NeonConfettiWidget()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  if (winner != null) ...[
                    Icon(
                      Icons.emoji_events,
                      color: winnerColor,
                      size: 80,
                      shadows: [
                        BoxShadow(
                          color: winnerColor.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'VICTOIRE !',
                      style: TextStyle(
                        color: winnerColor,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      winner.player.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Expanded(
                    child: ListView.builder(
                      itemCount: sorted.length,
                      itemBuilder: (context, index) {
                        final bp = sorted[index];
                        final bool isFirst = index == 0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C1020),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isFirst ? bp.color : Colors.white24,
                              width: isFirst ? 2 : 1,
                            ),
                            boxShadow: isFirst
                                ? [
                                    BoxShadow(
                                      color: bp.color.withValues(alpha: 0.25),
                                      blurRadius: 15,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Text(
                                '#${index + 1}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: isFirst ? bp.color : Colors.white54,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bp.player.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Case ${bp.currentTileIndex}',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildStatBadge(
                                Icons.local_bar,
                                '${bp.sipsCount}',
                                Colors.amberAccent,
                              ),
                              const SizedBox(width: 6),
                              _buildStatBadge(
                                Icons.keyboard_double_arrow_up,
                                '${bp.laddersClimbed}',
                                Colors.greenAccent,
                              ),
                              const SizedBox(width: 6),
                              _buildStatBadge(
                                Icons.keyboard_double_arrow_down,
                                '${bp.snakesSlid}',
                                Colors.purpleAccent,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.refresh, color: Colors.amberAccent),
                          label: const Text(
                            'REJOUER',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.amberAccent,
                              letterSpacing: 1,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.amberAccent, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ViperLobbyScreen(players: widget.players),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.home, color: Colors.black),
                          label: const Text(
                            'HUB',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 1,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => goToHub(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
