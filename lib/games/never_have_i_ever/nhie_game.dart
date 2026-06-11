// lib/games/never_have_i_ever/nhie_game.dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/games/never_have_i_ever/nhie_lobby.dart'; // Pour NhieCard
import 'package:gameflix/games/never_have_i_ever/nhie_scoreboard.dart';

class NhieRaceScreen extends StatefulWidget {
  final List<Player> players;
  final List<NhieCard> deck;
  const NhieRaceScreen({super.key, required this.players, required this.deck});

  @override
  State<NhieRaceScreen> createState() => _NhieRaceScreenState();
}

class _NhieRaceScreenState extends State<NhieRaceScreen> {
  int _cardIndex = 0;
  final Map<String, bool> _currentTurnSelections = {};

  @override
  void initState() {
    super.initState();
    for (var p in widget.players) { p.score = 0; }
  }

  void _nextCard() {
    bool hasWinner = false;
    setState(() {
      for (var p in widget.players) {
        if (_currentTurnSelections[p.name] == true) {
          p.score += 1;
          if (p.score >= 10) hasWinner = true;
        }
      }
      if (hasWinner) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NhieScoreboardScreen(players: widget.players)));
      } else {
        _currentTurnSelections.clear();
        _cardIndex = (_cardIndex + 1) % widget.deck.length;
        if (_cardIndex == 0) widget.deck.shuffle(); 
      }
    });
  }

  Widget _buildRaceTrack(Player player, int index) {
    bool isSelected = _currentTurnSelections[player.name] ?? false;
    int visualScore = player.score + (isSelected ? 1 : 0);
    double progress = min(visualScore / 10.0, 1.0); 

    final List<Color> playerColors = [Colors.redAccent, Colors.lightBlueAccent, Colors.orangeAccent, Colors.purpleAccent, Colors.greenAccent];
    Color trackColor = playerColors[index % playerColors.length];

    return GestureDetector(
      onTap: () => setState(() => _currentTurnSelections[player.name] = !isSelected),
      child: Container(
        color: Colors.transparent, 
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: 45, 
                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(25), border: Border.all(color: isSelected ? trackColor : Colors.white10, width: 2)),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double avatarSize = 35.0; double maxTop = constraints.maxHeight - avatarSize; 
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 500), curve: Curves.easeOutBack,
                          top: maxTop * (1.0 - progress),
                          child: Container(
                            width: avatarSize, height: avatarSize, margin: const EdgeInsets.symmetric(vertical: 2), 
                            decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? trackColor : Colors.white24),
                            child: Center(child: visualScore >= 10 ? const Icon(Icons.emoji_events, color: Colors.amber, size: 18) : const FaIcon(FontAwesomeIcons.horse, color: Colors.white, size: 18)),
                          ),
                        )
                      ],
                    );
                  }
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(player.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            Text("$visualScore", style: TextStyle(color: trackColor, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    NhieCard card = widget.deck[_cardIndex];
    Color accentColor = card.difficulty == 'SOFT' ? Colors.greenAccent : card.difficulty == 'GEEK' ? Colors.orangeAccent : Colors.redAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF050515),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(25), margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(color: const Color(0xFF111122), borderRadius: BorderRadius.circular(20), border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 2), boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("JE N'AI JAMAIS", style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 120, 
                    child: Center(child: AutoSizeText(card.content, textAlign: TextAlign.center, maxLines: 5, minFontSize: 12, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3))),
                  ),
                ],
              ),
            ),
            const Text("Appuyez sur votre ligne si vous l'avez fait 👇", style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: widget.players.asMap().entries.map((entry) => Expanded(child: _buildRaceTrack(entry.value, entry.key))).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity, height: 60,
                child: ElevatedButton(
                  onPressed: _nextCard, style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text("CARTE SUIVANTE", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}