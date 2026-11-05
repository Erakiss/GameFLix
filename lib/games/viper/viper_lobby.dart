// lib/games/viper/viper_lobby.dart
import 'package:flutter/material.dart';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/games/viper/viper_game.dart';
import 'package:gameflix/services/audio_service.dart';
import 'package:gameflix/shared/widgets/global_settings_button.dart';
import 'package:gameflix/shared/widgets/neon_lobby_banner.dart';

class ViperLobbyScreen extends StatefulWidget {
  final List<Player> players;

  const ViperLobbyScreen({super.key, required this.players});

  @override
  State<ViperLobbyScreen> createState() => _ViperLobbyScreenState();
}

class _ViperLobbyScreenState extends State<ViperLobbyScreen> {
  ViperBoardMode _selectedMode = ViperBoardMode.express; // Mode Express par défaut !
  ViperDeckMood _selectedMood = ViperDeckMood.classic;

  void _startGame() {
    AudioService.instance.playSfx(SoundEffect.click);

    for (final player in widget.players) {
      player.score = 0;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ViperGameScreen(
          players: widget.players,
          boardMode: _selectedMode,
          deckMood: _selectedMood,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required ViperBoardMode mode,
    required IconData icon,
    required Color accentColor,
  }) {
    final bool isSelected = _selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AudioService.instance.playSfx(SoundEffect.click);
          setState(() => _selectedMode = mode);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              width: double.infinity,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.16)
                      : Colors.black45,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? accentColor
                        : Colors.white.withValues(alpha: 0.2),
                    width: isSelected ? 2.0 : 1.1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? accentColor : Colors.white54,
                      size: 22,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      mode.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? accentColor : Colors.white70,
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mode.subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (mode.hasFlameBadge)
              Positioned(
                top: -7,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6D00), Color(0xFFFF1744)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.amberAccent.withValues(alpha: 0.9),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF3D00).withValues(alpha: 0.65),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.amberAccent,
                        size: 12,
                      ),
                      SizedBox(width: 2),
                      Text(
                        'HOT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
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

  Widget _buildMoodOption(ViperDeckMood mood) {
    final bool isSelected = _selectedMood == mood;
    final Color accentColor = mood.color;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AudioService.instance.playSfx(SoundEffect.click);
          setState(() => _selectedMood = mood);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.18)
                : Colors.black45,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : Colors.white.withValues(alpha: 0.2),
              width: isSelected ? 2.0 : 1.1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mood.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? accentColor : Colors.white70,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                mood.subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: buildUnifiedLobbyAppBar(
        context: context,
        gameId: 'viper',
        accentColor: Colors.amberAccent,
      ),
      body: Container(
        decoration: kLobbyBackgroundDecoration,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const NeonLobbyBanner(
                          imagePath: 'assets/board_banner.png',
                          borderColor: Colors.amberAccent,
                        ),
                        const SizedBox(height: 18),
                        // --- 1. SÉLECTEUR DE MODE DU PLATEAU (EXPRESS / NORMAL / SPIRALE 🔥) ---
                        _buildSectionTitle('MODE DE JEU'),
                        Row(
                          children: [
                            _buildModeOption(
                              mode: ViperBoardMode.express,
                              icon: Icons.flash_on_rounded,
                              accentColor: Colors.cyanAccent,
                            ),
                            const SizedBox(width: 8),
                            _buildModeOption(
                              mode: ViperBoardMode.normal,
                              icon: Icons.grid_4x4_rounded,
                              accentColor: Colors.amberAccent,
                            ),
                            const SizedBox(width: 8),
                            _buildModeOption(
                              mode: ViperBoardMode.spiral,
                              icon: Icons.all_inclusive_rounded,
                              accentColor: Colors.purpleAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        // --- 2. SÉLECTEUR D'AMBIANCE (DECK) ---
                        _buildSectionTitle('AMBIANCE DU DECK'),
                        Row(
                          children: [
                            _buildMoodOption(ViperDeckMood.classic),
                            const SizedBox(width: 8),
                            _buildMoodOption(ViperDeckMood.hot),
                            const SizedBox(width: 8),
                            _buildMoodOption(ViperDeckMood.blackout),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.amberAccent.withValues(alpha: 0.12),
                      side: const BorderSide(
                        color: Colors.amberAccent,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'LANCER LA PARTIE',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.amberAccent,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
