// lib/games/would_you_rather/wyr_lobby.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:math';

import 'package:gameflix/games/would_you_rather/wyr_game.dart';
import 'package:gameflix/shared/widgets/neon_category_switch.dart';
import 'package:gameflix/shared/widgets/neon_lobby_banner.dart';

// --- MODÈLE ---
class WyrCard {
  final String category;
  final String choice1;
  final String choice2;

  WyrCard({required this.category, required this.choice1, required this.choice2});

  factory WyrCard.fromJson(Map<String, dynamic> json) {
    return WyrCard(
      category: json['category'] ?? '',
      choice1: json['choice1'] ?? '',
      choice2: json['choice2'] ?? '',
    );
  }
}

// --- ÉCRAN 1 : LE LOBBY ---
class WyrLobbyScreen extends StatefulWidget {
  const WyrLobbyScreen({super.key});

  @override
  State<WyrLobbyScreen> createState() => _WyrLobbyScreenState();
}

class _WyrLobbyScreenState extends State<WyrLobbyScreen> {
  List<WyrCard> _allCards = [];
  
  bool _isSoftSelected = true;
  bool _isGeekSelected = true;
  bool _isHardSelected = false;
  bool _isHotSelected = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final String response = await rootBundle.loadString('assets/data/wyr_cards.json');
    final List<dynamic> data = json.decode(response);
    setState(() => _allCards = data.map((j) => WyrCard.fromJson(j)).toList());
  }

  void _startGame() {
    List<WyrCard> deck = [];
    if (_isSoftSelected) deck.addAll(_allCards.where((c) => c.category == 'Soft'));
    if (_isGeekSelected) deck.addAll(_allCards.where((c) => c.category == 'Geek'));
    if (_isHardSelected) deck.addAll(_allCards.where((c) => c.category == 'Hard'));
    if (_isHotSelected) deck.addAll(_allCards.where((c) => c.category == 'Hot'));

    if (deck.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sélectionne au moins une catégorie !"), backgroundColor: Colors.redAccent));
      return;
    }

    deck.shuffle(Random());
    Navigator.push(context, MaterialPageRoute(builder: (context) => WyrGameScreen(deck: deck)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111122),
      appBar: AppBar(title: const Text("TU PRÉFÈRES ?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              NeonLobbyBanner(imagePath: 'assets/wyr_banner.png', borderColor: Colors.orangeAccent,),
              const SizedBox(height: 40),
              NeonCategorySwitch(title: 'SOFT',color: Colors.greenAccent, value: _isSoftSelected, onChanged: (val) => setState(() => _isSoftSelected = val)),
              NeonCategorySwitch(title: 'GEEK', color: Colors.blueAccent, value: _isGeekSelected, onChanged: (val) => setState(() => _isGeekSelected = val)),
              NeonCategorySwitch(title: 'HARD', color: Colors.orangeAccent, value: _isHardSelected, onChanged: (val) => setState(() => _isHardSelected = val)),
              NeonCategorySwitch(title: 'HOT', color: Colors.redAccent, value: _isHotSelected, onChanged: (val) => setState(() => _isHotSelected = val)),
              const Spacer(),
              SizedBox(
                width: double.infinity, height: 60,
                child: ElevatedButton(
                  onPressed: _startGame, 
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent.withValues(alpha: 0.1), side: const BorderSide(color: Colors.orangeAccent, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text("LANCER LE JEU", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orangeAccent, letterSpacing: 2)),
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