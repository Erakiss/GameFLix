// lib/games/imposter/imp_lobby.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/games/imposter/imp_game.dart';
import 'package:gameflix/shared/widgets/neon_category_switch.dart';
import 'package:gameflix/shared/widgets/neon_lobby_banner.dart';

// --- MODÈLE ---
class ImpCard {
  final String category;
  final String word;
  final String imposterWord;
  final String? imagePath;

  ImpCard({required this.category, required this.word, required this.imposterWord, this.imagePath});

  factory ImpCard.fromJson(Map<String, dynamic> json) {
    return ImpCard(
      category: json['category'] ?? '',
      word: json['word'] ?? '',
      imposterWord: json['imposter_word'] ?? '',
      imagePath: json['imagePath'],
    );
  }
}

class ImpLobbyScreen extends StatefulWidget {
  final List<Player> players;
  const ImpLobbyScreen({super.key, required this.players});

  @override
  State<ImpLobbyScreen> createState() => _ImpLobbyScreenState();
}

class _ImpLobbyScreenState extends State<ImpLobbyScreen> {
  List<ImpCard> _allCards = [];
  
  bool _isAnimaux = true;
  bool _isSport = true;
  bool _isLieu = true;
  bool _isPerso = true;
  bool _isFilm = true;
  bool _isMisterWhiteMode = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final String response = await rootBundle.loadString('assets/data/imp_cards.json');
    final List<dynamic> data = json.decode(response);
    setState(() => _allCards = data.map((j) => ImpCard.fromJson(j)).toList());
  }

  void _startGame() {
    List<ImpCard> deck = [];
    if (_isAnimaux) deck.addAll(_allCards.where((c) => c.category == 'Animaux'));
    if (_isSport) deck.addAll(_allCards.where((c) => c.category == 'Sport'));
    if (_isLieu) deck.addAll(_allCards.where((c) => c.category == 'Lieu'));
    if (_isPerso) deck.addAll(_allCards.where((c) => c.category == 'Personnage Animé'));
    if (_isFilm) deck.addAll(_allCards.where((c) => c.category == 'Film'));

    if (deck.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sélectionne au moins une catégorie !"), backgroundColor: Colors.redAccent));
      return;
    }

    final random = Random();
    ImpCard selectedCard = deck[random.nextInt(deck.length)];

    int totalPlayers = widget.players.length;
    int badGuysCount = 1;
    if (totalPlayers >= 5 && totalPlayers <= 7) badGuysCount = 2;
    if (totalPlayers >= 8) badGuysCount = 3;

    List<String> rolesToAssign = [];
    
    if (_isMisterWhiteMode) {
      rolesToAssign.add("MISTER_WHITE");
      for (int i = 1; i < badGuysCount; i++) {rolesToAssign.add("IMPOSTER");}
    } else {
      for (int i = 0; i < badGuysCount; i++) {rolesToAssign.add("IMPOSTER");}
    }

    while (rolesToAssign.length < totalPlayers) {rolesToAssign.add("CIVIL");}

    rolesToAssign.shuffle(random);

    Map<String, String> assignedRoles = {};
    for (int i = 0; i < totalPlayers; i++) {
      assignedRoles[widget.players[i].name] = rolesToAssign[i];
    }

    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => ImpDistributionScreen(
        players: widget.players, 
        selectedCard: selectedCard, 
        playerRoles: assignedRoles,
      ))
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF111122),
      appBar: AppBar(title: const Text("L'IMPOSTEUR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              NeonLobbyBanner(imagePath: 'assets/wyr_banner.png', borderColor: Colors.purpleAccent,),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.purpleAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.purpleAccent, width: 2)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Mode Mister White", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                          Text("L'imposteur n'aura AUCUN mot secret.", style: TextStyle(fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),
                    Switch(value: _isMisterWhiteMode, activeTrackColor: Colors.purpleAccent, activeThumbColor: Colors.white, onChanged: (val) => setState(() => _isMisterWhiteMode = val)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      NeonCategorySwitch(title: 'Animaux', color: Colors.greenAccent, value: _isAnimaux, onChanged: (val) => setState(() => _isAnimaux = val)),
                      NeonCategorySwitch(title: 'Sport', color: Colors.orangeAccent, value: _isSport, onChanged: (val) => setState(() => _isSport = val)),
                      NeonCategorySwitch(title: 'Lieu', color: Colors.blueAccent, value: _isLieu, onChanged: (val) => setState(() => _isLieu = val)),
                      NeonCategorySwitch(title: 'Personnage Animé', color: Colors.pinkAccent, value: _isPerso, onChanged: (val) => setState(() => _isPerso = val)),
                      NeonCategorySwitch(title: 'Film', color: Colors.amberAccent, value: _isFilm, onChanged: (val) => setState(() => _isFilm = val)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity, height: 60,
                child: ElevatedButton(
                  onPressed: _startGame, style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent.withValues(alpha: 0.1), side: const BorderSide(color: Colors.purpleAccent, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text("DISTRIBUER LES RÔLES", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purpleAccent, letterSpacing: 1.5)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}