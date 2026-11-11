// lib/games/imposter/imp_scoreboard.dart
import 'package:flutter/material.dart';
import 'package:gameflix/shared/navigation.dart';
import 'package:gameflix/models/player.dart';
import 'package:gameflix/games/imposter/imp_lobby.dart';
import 'package:gameflix/l10n/app_strings.dart';
import 'package:gameflix/l10n/strings_imp_code.dart';
import 'package:gameflix/shared/widgets/global_settings_button.dart';
import 'package:gameflix/shared/widgets/neon_confetti.dart';

class ImpScoreboardScreen extends StatefulWidget {
  final List<Player> players;
  final Map<String, String> playerRoles;
  final ImpCard selectedCard;

  const ImpScoreboardScreen({
    super.key,
    required this.players,
    required this.playerRoles,
    required this.selectedCard,
  });

  @override
  State<ImpScoreboardScreen> createState() => _ImpScoreboardScreenState();
}

class _ImpScoreboardScreenState extends State<ImpScoreboardScreen> {
  final Set<String> _revealedPlayers = {};
  final TextEditingController _mwGuessController = TextEditingController();

  int _badGuysTotal = 0;
  int _civilsTotal = 0;
  int _badGuysFound = 0;
  int _civilsFound = 0;

  // État du jeu : "VOTING", "MW_GUESS", "FINISHED"
  String _gameState = "VOTING";
  String _winner = "";

  @override
  void initState() {
    super.initState();
    for (String role in widget.playerRoles.values) {
      if (role == "IMPOSTER" || role == "MISTER_WHITE") {
        _badGuysTotal++;
      } else {
        _civilsTotal++;
      }
    }
  }

  @override
  void dispose() {
    _mwGuessController.dispose();
    super.dispose();
  }

  String _normalizeString(String str) {
    return str
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ûü]'), 'u');
  }

  void _revealPlayer(String playerName) {
    if (_gameState != "VOTING" || _revealedPlayers.contains(playerName)) return;

    setState(() {
      _revealedPlayers.add(playerName);
      String role = widget.playerRoles[playerName]!;

      if (role == "IMPOSTER" || role == "MISTER_WHITE") {
        _badGuysFound++;

        if (role == "MISTER_WHITE") {
          _gameState = "MW_GUESS";
          return;
        }
      } else {
        _civilsFound++;
      }

      _checkEndGameConditions();
    });
  }

  void _checkEndGameConditions() {
    int aliveBadGuys = _badGuysTotal - _badGuysFound;
    int aliveCivils = _civilsTotal - _civilsFound;

    if (_badGuysFound == _badGuysTotal) {
      _finishGame("CIVILS");
    } else if (aliveBadGuys >= aliveCivils) {
      _finishGame("IMPOSTERS");
    }
  }

  void _checkMisterWhiteGuess() {
    String guess = _normalizeString(_mwGuessController.text);
    String actualWord = _normalizeString(widget.selectedCard.word);

    if (guess == actualWord) {
      _finishGame("MISTER_WHITE");
    } else {
      setState(() {
        _gameState = "VOTING";
        _mwGuessController.clear();
        _checkEndGameConditions();
      });
    }
  }

  void _finishGame(String winner) {
    setState(() {
      _gameState = "FINISHED";
      _winner = winner;
      for (var p in widget.players) {
        _revealedPlayers.add(p.name);
      }
    });
  }

  Widget _buildPlayerCard(Player player, AppStrings strings) {
    bool isRevealed = _revealedPlayers.contains(player.name);
    String role = widget.playerRoles[player.name]!;

    Color roleColor = Colors.white;
    String roleName = "";
    if (role == "MISTER_WHITE") {
      roleColor = Colors.white;
      roleName = strings.impRoleMisterWhite;
    } else if (role == "IMPOSTER") {
      roleColor = Colors.redAccent;
      roleName = strings.impRoleImposter;
    } else {
      roleColor = Colors.greenAccent;
      roleName = strings.impRoleCivil;
    }

    bool isWinner = false;
    if (_gameState == "FINISHED") {
      if (_winner == "CIVILS" && role == "CIVIL") isWinner = true;
      if (_winner == "IMPOSTERS" &&
          (role == "IMPOSTER" || role == "MISTER_WHITE")) {
        isWinner = true;
      }
      if (_winner == "MISTER_WHITE" && role == "MISTER_WHITE") isWinner = true;
    }

    return GestureDetector(
      onTap: () => _revealPlayer(player.name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isRevealed
              ? roleColor.withValues(alpha: 0.1)
              : const Color(0xFF111122),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isWinner
                ? Colors.amber
                : (isRevealed
                    ? roleColor
                    : Colors.purpleAccent.withValues(alpha: 0.3)),
            width: isWinner ? 4 : 2,
          ),
          boxShadow: isWinner
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              player.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isWinner
                    ? Colors.amber
                    : (isRevealed ? roleColor : Colors.white),
              ),
            ),
            if (isRevealed)
              Row(
                children: [
                  if (isWinner)
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 24,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    roleName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isWinner ? Colors.amber : roleColor,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              )
            else
              const Icon(Icons.touch_app, color: Colors.purpleAccent),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    bool isFinished = _gameState == "FINISHED";

    String headerText = strings.impEliminationPhaseTitle;
    Color headerColor = Colors.purpleAccent;
    if (isFinished) {
      if (_winner == "CIVILS") {
        headerText = strings.impCivilsVictory;
        headerColor = Colors.greenAccent;
      }
      if (_winner == "IMPOSTERS") {
        headerText = strings.impImpostersVictory;
        headerColor = Colors.redAccent;
      }
      if (_winner == "MISTER_WHITE") {
        headerText = strings.impMisterWhiteVictory;
        headerColor = Colors.white;
      }
    } else if (_gameState == "MW_GUESS") {
      headerText = strings.impMisterWhiteSaveYourself;
      headerColor = Colors.white;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050515),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: const [
          GlobalSettingsButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Text(
                    headerText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: headerColor,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!isFinished && _gameState != "MW_GUESS")
                    Text(
                      strings.impTapEliminatedPlayer,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111122),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isFinished ? headerColor : Colors.white10,
                        width: 2,
                      ),
                    ),
                    child: isFinished
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    strings.impRoleCivil,
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    widget.selectedCard.word,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    strings.impRoleImposter,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    widget.selectedCard.imposterWord,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Center(
                            child: Text(
                              strings.impWordsHiddenLabel,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 30),
                  if (_gameState == "MW_GUESS") ...[
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                strings.impMisterWhiteLastChance,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _mwGuessController,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  hintText: strings.impMisterWhiteGuessHint,
                                  hintStyle: const TextStyle(
                                    color: Colors.white38,
                                  ),
                                  filled: true,
                                  fillColor: Colors.black45,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _checkMisterWhiteGuess,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: Text(
                                  strings.impValidateWordButton,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: widget.players
                            .map((p) => _buildPlayerCard(p, strings))
                            .toList(),
                      ),
                    ),
                  ],
                  if (isFinished)
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: () => goToHub(context),
                        icon: const Icon(
                          Icons.home,
                          color: Colors.purpleAccent,
                        ),
                        label: Text(
                          strings.backToHubButton,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purpleAccent,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent.withValues(
                            alpha: 0.1,
                          ),
                          side: const BorderSide(
                            color: Colors.purpleAccent,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isFinished)
              const Positioned.fill(
                child: IgnorePointer(
                  child: NeonConfettiWidget(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
