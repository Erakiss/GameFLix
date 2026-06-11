// lib/games/never_have_i_ever/nhie_lobby.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/games/never_have_i_ever/nhie_game.dart';
import 'package:gameflix/shared/widgets/neon_category_switch.dart';
import 'package:gameflix/shared/widgets/neon_lobby_banner.dart';

class NhieCard {
  final String difficulty;
  final String content;
  NhieCard({required this.difficulty, required this.content});
  factory NhieCard.fromJson(Map<String, dynamic> json) => NhieCard(difficulty: json['difficulty'], content: json['content']);
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
  bool _isGeekSelected = true;
  bool _isHotSelected = false;

  @override
  void initState() { super.initState(); _loadCards(); }

  Future<void> _loadCards() async {
    final String response = await rootBundle.loadString('assets/data/nhie_cards.json');
    final List<dynamic> data = json.decode(response);
    setState(() => _allCards = data.map((j) => NhieCard.fromJson(j)).toList());
  }

  void _startGame() {
    List<NhieCard> deck = [];
    if (_isSoftSelected) deck.addAll(_allCards.where((c) => c.difficulty == 'SOFT'));
    if (_isGeekSelected) deck.addAll(_allCards.where((c) => c.difficulty == 'GEEK'));
    if (_isHotSelected) deck.addAll(_allCards.where((c) => c.difficulty == 'HOT'));

    if (deck.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sélectionne au moins une catégorie !"), backgroundColor: Colors.redAccent));
      return;
    }
    
    deck.shuffle();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NhieRaceScreen(players: widget.players, deck: deck)));
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF111122),
      appBar: AppBar(title: const Text("JE N'AI JAMAIS", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            NeonLobbyBanner(imagePath: 'assets/wyr_banner.png', borderColor: Colors.purpleAccent,),
            const SizedBox(height: 30),
            NeonCategorySwitch(title: 'SOFT', color: Colors.greenAccent, value: _isSoftSelected, onChanged: (val) => setState(() => _isSoftSelected = val)),
            NeonCategorySwitch(title: 'GEEK', color: Colors.orangeAccent, value: _isGeekSelected, onChanged: (val) => setState(() => _isGeekSelected = val)),
            NeonCategorySwitch(title: 'HOT', color: Colors.redAccent, value: _isHotSelected, onChanged: (val) => setState(() => _isHotSelected = val)),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                onPressed: _startGame, style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent.withValues(alpha: 0.1), side: const BorderSide(color: Colors.cyanAccent, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text("LANCER LA COURSE", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.cyanAccent, letterSpacing: 2)),
              ),
            )
          ],
        ),
      ),
    );
  }
}