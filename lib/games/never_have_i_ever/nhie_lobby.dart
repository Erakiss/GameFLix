// lib/games/never_have_i_ever/nhie_lobby.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/games/never_have_i_ever/nhie_game.dart';
import 'package:gameflix/shared/widgets/neon_category_switch.dart';
import 'package:gameflix/shared/widgets/neon_lobby_banner.dart';
import 'package:gameflix/shared/widgets/global_settings_button.dart';
import 'package:gameflix/shared/widgets/unlock_pack_sheet.dart';
import 'package:gameflix/services/pack_loader_service.dart';
import 'package:gameflix/services/audio_service.dart';
import 'package:gameflix/state/access_control_provider.dart';
import 'package:gameflix/l10n/app_strings.dart';
import 'package:gameflix/l10n/strings_tod_nhie.dart';

class NhieCard {
  final String difficulty;
  final String content;
  NhieCard({required this.difficulty, required this.content});
  factory NhieCard.fromJson(Map<String, dynamic> json) =>
      NhieCard(difficulty: json['difficulty'], content: json['content']);
}

class NhieLobbyScreen extends StatefulWidget {
  final List<Player> players;
  const NhieLobbyScreen({super.key, required this.players});

  @override
  State<NhieLobbyScreen> createState() => _NhieLobbyScreenState();
}

class _NhieLobbyScreenState extends State<NhieLobbyScreen> {
  List<NhieCard> _allCards = [];
  bool _isSoftSelected = true;
  bool _isFunSelected = true;
  bool _isGeekSelected = true;
  bool _isHotSelected = false;

  // Longueur de course : mode Classique (10 pts) vs Modulable (5 à 25 pts)
  bool _isCustomDistance = false;
  int _customTargetScore = 15;

  int get _effectiveTargetScore => _isCustomDistance ? _customTargetScore : 10;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await PackLoaderService.instance.loadCardsForGame<NhieCard>(
      'nhie',
      NhieCard.fromJson,
    );
    if (!mounted) return;
    setState(() => _allCards = cards);
  }

  void _startGame() {
    AudioService.instance.playSfx(SoundEffect.click);
    HapticFeedback.mediumImpact();

    final List<NhieCard> deck = [];
    if (_isSoftSelected) {
      deck.addAll(_allCards.where((c) => c.difficulty == 'SOFT'));
    }
    if (_isFunSelected) {
      deck.addAll(_allCards.where((c) => c.difficulty == 'FUN'));
    }
    if (_isGeekSelected) {
      deck.addAll(_allCards.where((c) => c.difficulty == 'GEEK'));
    }
    final bool canAccessHot =
        AccessControlProvider.instance.canAccess('nhie_hot', isPremium: true);
    if (_isHotSelected && canAccessHot) {
      deck.addAll(_allCards.where((c) => c.difficulty == 'HOT'));
    }

    if (deck.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.read(context).nhieSelectCategoryError),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    deck.shuffle(Random());
    for (final p in widget.players) {
      p.score = 0;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NhieRaceScreen(
          players: widget.players,
          deck: deck,
          targetScore: _effectiveTargetScore,
        ),
      ),
    );
  }

  Widget _buildDistanceSelector(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: [
              const Icon(Icons.flag_rounded, color: Colors.cyanAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                s.nhieRaceDistanceTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  AudioService.instance.playSfx(SoundEffect.click);
                  HapticFeedback.selectionClick();
                  setState(() => _isCustomDistance = false);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: !_isCustomDistance
                        ? Colors.cyanAccent.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: !_isCustomDistance ? Colors.cyanAccent : Colors.white24,
                      width: !_isCustomDistance ? 2 : 1,
                    ),
                    boxShadow: !_isCustomDistance
                        ? [
                            BoxShadow(
                              color: Colors.cyanAccent.withValues(alpha: 0.25),
                              blurRadius: 12,
                            )
                          ]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Text(
                        s.nhieClassicLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: !_isCustomDistance ? Colors.cyanAccent : Colors.white70,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.nhiePointsText(10),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: !_isCustomDistance ? Colors.white : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  AudioService.instance.playSfx(SoundEffect.click);
                  HapticFeedback.selectionClick();
                  setState(() => _isCustomDistance = true);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: _isCustomDistance
                        ? Colors.purpleAccent.withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isCustomDistance ? Colors.purpleAccent : Colors.white24,
                      width: _isCustomDistance ? 2 : 1,
                    ),
                    boxShadow: _isCustomDistance
                        ? [
                            BoxShadow(
                              color: Colors.purpleAccent.withValues(alpha: 0.25),
                              blurRadius: 12,
                            )
                          ]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Text(
                        s.nhieCustomLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: _isCustomDistance ? Colors.purpleAccent : Colors.white70,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isCustomDistance ? s.nhiePointsText(_customTargetScore) : s.nhiePointsRange,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _isCustomDistance ? Colors.white : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: _isCustomDistance
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF141128),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.purpleAccent.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                _buildStepButton(
                  icon: Icons.remove_rounded,
                  enabled: _customTargetScore > 5,
                  onTap: () {
                    if (_customTargetScore > 5) {
                      AudioService.instance.playSfx(SoundEffect.click);
                      HapticFeedback.selectionClick();
                      setState(() => _customTargetScore--);
                    }
                  },
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.purpleAccent,
                      inactiveTrackColor: Colors.white12,
                      thumbColor: Colors.cyanAccent,
                      overlayColor: Colors.purpleAccent.withValues(alpha: 0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _customTargetScore.toDouble(),
                      min: 5,
                      max: 25,
                      divisions: 20,
                      onChanged: (val) {
                        final int rounded = val.round();
                        if (rounded != _customTargetScore) {
                          HapticFeedback.selectionClick();
                          setState(() => _customTargetScore = rounded);
                        }
                      },
                    ),
                  ),
                ),
                _buildStepButton(
                  icon: Icons.add_rounded,
                  enabled: _customTargetScore < 25,
                  onTap: () {
                    if (_customTargetScore < 25) {
                      AudioService.instance.playSfx(SoundEffect.click);
                      HapticFeedback.selectionClick();
                      setState(() => _customTargetScore++);
                    }
                  },
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.purpleAccent),
                  ),
                  child: Text(
                    s.nhiePointsBadge(_customTargetScore),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? Colors.white38 : Colors.white10,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? Colors.white : Colors.white24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final access = context.watch<AccessControlProvider>();
    final bool canAccessHot = access.canAccess('nhie_hot', isPremium: true);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: buildUnifiedLobbyAppBar(
        context: context,
        gameId: 'nhie',
        accentColor: Colors.cyanAccent,
      ),
      body: Container(
        decoration: kLobbyBackgroundDecoration,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const NeonLobbyBanner(
                          imagePath: 'assets/banners/fr/nhie_banner.webp',
                          borderColor: Colors.purpleAccent,
                        ),
                        const SizedBox(height: 20),
                        NeonCategorySwitch(
                          title: 'SOFT',
                          color: Colors.greenAccent,
                          value: _isSoftSelected,
                          onChanged: (val) =>
                              setState(() => _isSoftSelected = val),
                        ),
                        NeonCategorySwitch(
                          title: 'FUN',
                          color: Colors.amberAccent,
                          value: _isFunSelected,
                          onChanged: (val) =>
                              setState(() => _isFunSelected = val),
                        ),
                        NeonCategorySwitch(
                          title: 'GEEK',
                          color: Colors.purpleAccent,
                          value: _isGeekSelected,
                          onChanged: (val) =>
                              setState(() => _isGeekSelected = val),
                        ),
                        NeonCategorySwitch(
                          title: 'HOT',
                          color: Colors.redAccent,
                          value: _isHotSelected,
                          isLocked: !canAccessHot,
                          onLockedTap: () {
                            UnlockPackSheet.show(
                              context,
                              packId: 'nhie_hot',
                              packTitle: s.nhieHotPackTitle,
                              onUnlocked: () {
                                setState(() => _isHotSelected = true);
                              },
                            );
                          },
                          onChanged: (val) {
                            if (!canAccessHot) {
                              UnlockPackSheet.show(
                                context,
                                packId: 'nhie_hot',
                                packTitle: s.nhieHotPackTitle,
                                onUnlocked: () {
                                  setState(() => _isHotSelected = true);
                                },
                              );
                            } else {
                              setState(() => _isHotSelected = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDistanceSelector(s),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent.withValues(alpha: 0.12),
                      side: const BorderSide(color: Colors.cyanAccent, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      s.nhieStartRaceButton(_effectiveTargetScore),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyanAccent,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
