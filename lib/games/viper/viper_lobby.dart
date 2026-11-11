// lib/games/viper/viper_lobby.dart
import 'package:flutter/material.dart';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/games/viper/viper_game.dart';
import 'package:gameflix/services/audio_service.dart';
import 'package:gameflix/shared/widgets/global_settings_button.dart';
import 'package:gameflix/shared/widgets/neon_lobby_banner.dart';
import 'package:gameflix/shared/widgets/unlock_pack_sheet.dart';
import 'package:gameflix/state/access_control_provider.dart';
import 'package:gameflix/l10n/app_strings.dart';
import 'package:gameflix/l10n/strings_wyr_viper.dart';

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

    final bool canAccessHot =
        AccessControlProvider.instance.canAccess('viper_hot', isPremium: true);
    if (_selectedMood == ViperDeckMood.hot && !canAccessHot) {
      final strings = AppStrings.read(context);
      UnlockPackSheet.show(
        context,
        packId: 'viper_hot',
        packTitle: strings.viperHotPackTitle,
        onUnlocked: () {
          setState(() => _selectedMood = ViperDeckMood.hot);
        },
      );
      return;
    }

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
    required AppStrings strings,
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
                      strings.viperModeLabel(mode),
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
                      strings.viperModeSubtitle(mode),
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
                    horizontal: 5,
                    vertical: 3,
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
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.amberAccent,
                    size: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodOption(
    ViperDeckMood mood, {
    required AppStrings strings,
    bool isLocked = false,
  }) {
    final bool isSelected = _selectedMood == mood && !isLocked;
    final Color accentColor = mood.color;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AudioService.instance.playSfx(SoundEffect.click);
          if (isLocked) {
            UnlockPackSheet.show(
              context,
              packId: 'viper_hot',
              packTitle: strings.viperHotPackTitle,
              onUnlocked: () {
                setState(() => _selectedMood = mood);
              },
            );
            return;
          }
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
              color: isLocked
                  ? Colors.redAccent.withValues(alpha: 0.65)
                  : (isSelected
                      ? accentColor
                      : Colors.white.withValues(alpha: 0.2)),
              width: isSelected ? 2.0 : 1.1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      strings.viperMoodLabel(mood),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? accentColor : Colors.white70,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  if (isLocked) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.lock_rounded,
                      size: 12,
                      color: Colors.redAccent,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                strings.viperMoodSubtitle(mood),
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
    final strings = AppStrings.of(context);

    return ListenableBuilder(
      listenable: AccessControlProvider.instance,
      builder: (context, _) {
        final bool canAccessHot = AccessControlProvider.instance
            .canAccess('viper_hot', isPremium: true);

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const NeonLobbyBanner(
                              imagePath: 'assets/banners/fr/board_banner.webp',
                              borderColor: Colors.amberAccent,
                            ),
                            const SizedBox(height: 18),
                            // --- 1. SÉLECTEUR DE MODE DU PLATEAU (EXPRESS / NORMAL / SPIRALE 🔥) ---
                            _buildSectionTitle(strings.viperGameModeSection),
                            Row(
                              children: [
                                _buildModeOption(
                                  mode: ViperBoardMode.express,
                                  icon: Icons.flash_on_rounded,
                                  accentColor: Colors.cyanAccent,
                                  strings: strings,
                                ),
                                const SizedBox(width: 8),
                                _buildModeOption(
                                  mode: ViperBoardMode.normal,
                                  icon: Icons.grid_4x4_rounded,
                                  accentColor: Colors.amberAccent,
                                  strings: strings,
                                ),
                                const SizedBox(width: 8),
                                _buildModeOption(
                                  mode: ViperBoardMode.spiral,
                                  icon: Icons.all_inclusive_rounded,
                                  accentColor: Colors.purpleAccent,
                                  strings: strings,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            // --- 2. SÉLECTEUR D'AMBIANCE (DECK) ---
                            _buildSectionTitle(strings.viperDeckMoodSection),
                            Row(
                              children: [
                                _buildMoodOption(
                                  ViperDeckMood.classic,
                                  strings: strings,
                                ),
                                const SizedBox(width: 8),
                                _buildMoodOption(
                                  ViperDeckMood.hot,
                                  strings: strings,
                                  isLocked: !canAccessHot,
                                ),
                                const SizedBox(width: 8),
                                _buildMoodOption(
                                  ViperDeckMood.blackout,
                                  strings: strings,
                                ),
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
                        child: Text(
                          strings.viperStartGameButton,
                          style: const TextStyle(
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
      },
    );
  }
}
