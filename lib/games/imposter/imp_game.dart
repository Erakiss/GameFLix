// lib/games/imposter/imp_game.dart
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/games/imposter/imp_lobby.dart';
import 'package:gameflix/games/imposter/imp_scoreboard.dart';
import 'package:gameflix/l10n/app_strings.dart';
import 'package:gameflix/l10n/strings_imp_code.dart';
import 'package:gameflix/shared/widgets/global_settings_button.dart';

// --- STAGE 1 : LA DISTRIBUTION ---
class ImpDistributionScreen extends StatefulWidget {
  final List<Player> players;
  final ImpCard selectedCard;
  final Map<String, String> playerRoles;

  const ImpDistributionScreen({
    super.key,
    required this.players,
    required this.selectedCard,
    required this.playerRoles,
  });

  @override
  State<ImpDistributionScreen> createState() => _ImpDistributionScreenState();
}

class _ImpDistributionScreenState extends State<ImpDistributionScreen> {
  int _currentPlayerIndex = 0;
  bool _isRevealed = false;

  void _toggleReveal() {
    final bool wasRevealed = _isRevealed;
    final bool isLastPlayer = _currentPlayerIndex >= widget.players.length - 1;

    if (wasRevealed && isLastPlayer) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ImpDebateScreen(
            players: widget.players,
            playerRoles: widget.playerRoles,
            selectedCard: widget.selectedCard,
          ),
        ),
      );
      return;
    }

    setState(() {
      _isRevealed = !wasRevealed;
      if (wasRevealed) _currentPlayerIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPlayerIndex >= widget.players.length) {
      return const SizedBox.shrink();
    }

    final strings = AppStrings.of(context);
    Player currentPlayer = widget.players[_currentPlayerIndex];
    String playerRole = widget.playerRoles[currentPlayer.name]!;

    String secretWord = "";
    String roleSubtext = "";
    bool isMisterWhite = false;

    if (playerRole == "MISTER_WHITE") {
      secretWord = strings.impYouAreMisterWhite;
      roleSubtext = strings.impMisterWhiteSubtext;
      isMisterWhite = true;
    } else if (playerRole == "IMPOSTER") {
      secretWord = widget.selectedCard.imposterWord;
      roleSubtext = strings.impSecretWordSubtext;
    } else {
      secretWord = widget.selectedCard.word;
      roleSubtext = strings.impSecretWordSubtext;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050515),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          GlobalSettingsButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: !_isRevealed
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.screen_lock_portrait,
                        size: 80,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 30),
                      Text(
                        strings.impPassPhoneTo,
                        style: const TextStyle(fontSize: 20, color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currentPlayer.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.purpleAccent,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 50),
                      ElevatedButton(
                        onPressed: _toggleReveal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          strings.impSeeRoleButton,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        strings.impPrivacyWarning,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentPlayer.name,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isMisterWhite
                            ? strings.impAttentionLabel
                            : strings.impYourSecretWordIs,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.purpleAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 40,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111122),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.purpleAccent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purpleAccent.withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              secretWord,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: secretWord.length > 15 ? 24 : 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              roleSubtext,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),
                      ElevatedButton.icon(
                        onPressed: _toggleReveal,
                        icon: const Icon(
                          Icons.visibility_off,
                          color: Colors.white,
                        ),
                        label: Text(
                          _currentPlayerIndex == widget.players.length - 1
                              ? strings.impHideAndStartButton
                              : strings.impHideAndPassButton,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          side: const BorderSide(
                            color: Colors.white54,
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
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

// --- STAGE 2 : LE DÉBAT ET LE CHRONOMÈTRE ---
class ImpDebateScreen extends StatefulWidget {
  final List<Player> players;
  final Map<String, String> playerRoles;
  final ImpCard selectedCard;

  const ImpDebateScreen({
    super.key,
    required this.players,
    required this.playerRoles,
    required this.selectedCard,
  });

  @override
  State<ImpDebateScreen> createState() => _ImpDebateScreenState();
}

class _ImpDebateScreenState extends State<ImpDebateScreen> {
  late int _timeLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.players.length * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _timeLeft <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _timeLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goToReveal() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ImpScoreboardScreen(
          players: widget.players,
          playerRoles: widget.playerRoles,
          selectedCard: widget.selectedCard,
        ),
      ),
    );
  }

  void _showForgetMenu() {
    showDialog(
      context: context,
      builder: (context) {
        final strings = AppStrings.of(context);
        return AlertDialog(
          backgroundColor: const Color(0xFF111122),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.purpleAccent, width: 2),
          ),
          title: Text(
            strings.impForgotWordDialogTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.players
                .map(
                  (p) => ListTile(
                    title: Text(
                      p.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showPlayerSecret(p);
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  void _showPlayerSecret(Player player) {
    String role = widget.playerRoles[player.name]!;

    showDialog(
      context: context,
      builder: (context) {
        bool isRevealed = false;
        return StatefulBuilder(
          builder: (context, setState) {
            final strings = AppStrings.of(context);
            final String secretWord;
            if (role == "MISTER_WHITE") {
              secretWord = strings.impYouAreMisterWhite;
            } else if (role == "IMPOSTER") {
              secretWord = widget.selectedCard.imposterWord;
            } else {
              secretWord = widget.selectedCard.word;
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF050515),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.purpleAccent, width: 2),
              ),
              title: Text(
                player.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    strings.impHideScreenFromOthers,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 100,
                    alignment: Alignment.center,
                    child: isRevealed
                        ? Text(
                            secretWord,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.visibility_off,
                            size: 50,
                            color: Colors.white54,
                          ),
                  ),
                ],
              ),
              actions: [
                Center(
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => isRevealed = true),
                    onTapUp: (_) => setState(() => isRevealed = false),
                    onTapCancel: () => setState(() => isRevealed = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        strings.impHoldToSeeButton,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    int minutes = _timeLeft ~/ 60;
    int seconds = _timeLeft % 60;
    String timeString =
        "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: const Color(0xFF050515),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          GlobalSettingsButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                strings.impDebateTimeTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purpleAccent,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                strings.impDebateSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 50),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _timeLeft <= 30
                        ? Colors.redAccent
                        : Colors.purpleAccent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_timeLeft <= 30
                              ? Colors.redAccent
                              : Colors.purpleAccent)
                          .withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Text(
                  timeString,
                  style: TextStyle(
                    fontSize: 70,
                    fontWeight: FontWeight.w900,
                    color: _timeLeft <= 30 ? Colors.redAccent : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              ElevatedButton.icon(
                onPressed: _goToReveal,
                icon: const Icon(Icons.how_to_vote, color: Colors.white),
                label: Text(
                  strings.impGoToVoteButton,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              TextButton.icon(
                onPressed: _showForgetMenu,
                icon: const Icon(Icons.help_outline, color: Colors.white54),
                label: Text(
                  strings.impForgotWordButton,
                  style: const TextStyle(
                    color: Colors.white54,
                    decoration: TextDecoration.underline,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
