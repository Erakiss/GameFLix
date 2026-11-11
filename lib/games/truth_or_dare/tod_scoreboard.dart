// lib/games/truth_or_dare/tod_scoreboard.dart
import 'package:flutter/material.dart';
import 'package:gameflix/models/player.dart';
import 'package:gameflix/shared/navigation.dart';
import 'package:gameflix/shared/widgets/global_settings_button.dart';
import 'package:gameflix/l10n/app_strings.dart';
import 'package:gameflix/l10n/strings_tod_nhie.dart';

class TodScoreboardScreen extends StatelessWidget {
  final List<Player> players;
  const TodScoreboardScreen({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final sortedPlayers = List<Player>.from(players)
      ..sort((a, b) => b.score.compareTo(a.score));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: const [
          GlobalSettingsButton(),
          SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF050515), Color(0xFF1A1A40), Color(0xFF4B0082)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(
                s.todGameOverTitle,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.cyanAccent,
                  shadows: [Shadow(color: Colors.cyan, blurRadius: 15)],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                s.todScoreboardSubtitle,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.builder(
                    itemCount: sortedPlayers.length,
                    itemBuilder: (context, i) {
                      final player = sortedPlayers[i];
                      final isFirst = i == 0;
                      final String playerTitle = s.todPlayerTitle(
                        i,
                        player.score,
                        sortedPlayers.length,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isFirst ? Colors.redAccent : Colors.white24,
                            width: isFirst ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              "#${i + 1}",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isFirst
                                    ? Colors.redAccent
                                    : Colors.white54,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              player.gender == 'M' ? '♂' : '♀',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: player.gender == 'M'
                                    ? Colors.blue
                                    : Colors.pink,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    player.name,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: isFirst
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    playerTitle,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: isFirst
                                          ? Colors.redAccent
                                          : Colors.cyanAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "${player.score} 🍺",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: isFirst
                                    ? Colors.redAccent
                                    : Colors.pinkAccent,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.home, size: 28),
                  label: Text(
                    s.todBackToHubButton,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () => goToHub(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
