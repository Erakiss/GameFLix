// lib/games/would_you_rather/wyr_lobby.dart
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/games/would_you_rather/wyr_game.dart';
import 'package:gameflix/shared/widgets/neon_category_switch.dart';
import 'package:gameflix/shared/widgets/neon_lobby_banner.dart';
import 'package:gameflix/shared/widgets/game_rules_sheet.dart';
import 'package:gameflix/shared/widgets/neon_volume_control.dart';
import 'package:gameflix/services/pack_loader_service.dart';
import 'package:gameflix/services/audio_service.dart';

// --- MODÈLE ---
class WyrCard {
  final String category;
  final String choice1;
  final String choice2;
  final int percentage1;
  final int percentage2;
  final String? miniGage;

  WyrCard({
    required this.category,
    required this.choice1,
    required this.choice2,
    required this.percentage1,
    required this.percentage2,
    this.miniGage,
  });

  factory WyrCard.fromJson(Map<String, dynamic> json) {
    final String c1 = json['choice1'] ?? '';
    final String c2 = json['choice2'] ?? '';

    // Détermination des pourcentages :
    // 1. Si explicite dans le JSON, on le borne entre 5% et 95%
    // 2. Sinon, calcul déterministe basé sur le hash du texte pour garantir des stats stables (25% à 75%)
    int p1;
    if (json['percentage1'] != null) {
      p1 = (json['percentage1'] as num).toInt().clamp(5, 95);
    } else {
      final int hash = (c1.hashCode ^ (c2.hashCode * 31)).abs();
      p1 = 25 + (hash % 51); // Entre 25 et 75
    }
    final int p2 = 100 - p1;

    final String? gage =
        json['mini_gage'] as String? ?? json['gage'] as String?;

    return WyrCard(
      category: json['category'] ?? '',
      choice1: c1,
      choice2: c2,
      percentage1: p1,
      percentage2: p2,
      miniGage: (gage != null && gage.trim().isNotEmpty) ? gage.trim() : null,
    );
  }
}

// --- ÉCRAN DU LOBBY ---
class WyrLobbyScreen extends StatefulWidget {
  final List<Player> players;

  const WyrLobbyScreen({super.key, required this.players});

  @override
  State<WyrLobbyScreen> createState() => _WyrLobbyScreenState();
}

class _WyrLobbyScreenState extends State<WyrLobbyScreen> {
  List<WyrCard> _allCards = [];

  bool _isSoftSelected = true;
  bool _isGeekSelected = true;
  bool _isHardSelected = false;
  bool _isHotSelected = false;

  // Options de longueur de partie : 10, 15 (par défaut), 20 ou 0 (tout le deck)
  int _selectedRoundCount = 15;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await PackLoaderService.instance.loadCardsForGame<WyrCard>(
      'wyr',
      WyrCard.fromJson,
    );
    if (!mounted) return;
    setState(() => _allCards = cards);
  }

  void _startGame() {
    AudioService.instance.playSfx(SoundEffect.click);

    List<WyrCard> deck = [];
    if (_isSoftSelected) {
      deck.addAll(_allCards.where((c) => c.category == 'Soft'));
    }
    if (_isGeekSelected) {
      deck.addAll(_allCards.where((c) => c.category == 'Geek'));
    }
    if (_isHardSelected) {
      deck.addAll(_allCards.where((c) => c.category == 'Hard'));
    }
    if (_isHotSelected) {
      deck.addAll(_allCards.where((c) => c.category == 'Hot'));
    }

    if (deck.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sélectionne au moins une catégorie !"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    deck.shuffle(Random());

    final int totalRounds = (_selectedRoundCount > 0)
        ? min(_selectedRoundCount, deck.length)
        : deck.length;

    final finalDeck = deck.take(totalRounds).toList();

    // Réinitialisation des scores des joueurs pour la session
    for (final player in widget.players) {
      player.score = 0;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WyrGameScreen(
          players: widget.players,
          deck: finalDeck,
          totalRounds: totalRounds,
        ),
      ),
    );
  }

  Widget _buildRoundSelector() {
    final options = [
      {'label': '10', 'sub': 'Express', 'value': 10},
      {'label': '15', 'sub': 'Standard', 'value': 15},
      {'label': '20', 'sub': 'Intense', 'value': 20},
      {'label': '∞', 'sub': 'Tout', 'value': 0},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, color: Colors.orangeAccent, size: 18),
              SizedBox(width: 8),
              Text(
                "DURÉE DE LA PARTIE",
                style: TextStyle(
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
          children: options.map((opt) {
            final int value = opt['value'] as int;
            final bool isSelected = _selectedRoundCount == value;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  AudioService.instance.playSfx(SoundEffect.click);
                  setState(() => _selectedRoundCount = value);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.orangeAccent.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.orangeAccent
                          : Colors.white24,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.orangeAccent.withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        opt['label'] as String,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isSelected
                              ? Colors.orangeAccent
                              : Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        opt['sub'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.white : Colors.white38,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111122),
      appBar: AppBar(
        title: const Text(
          "TU PRÉFÈRES ?",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          const NeonVolumeControl(),
          IconButton(
            icon: const Icon(
              Icons.help_outline_rounded,
              color: Colors.blueAccent,
              size: 26,
            ),
            tooltip: 'Règles du jeu',
            onPressed: () => GameRulesSheet.show(
              context,
              DefaultGameRules.getRules('wyr'),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const NeonLobbyBanner(
                        imagePath: 'assets/wyr_banner.png',
                        borderColor: Colors.orangeAccent,
                      ),
                      const SizedBox(height: 20),

                      // Sélecteur de nombre de tours
                      _buildRoundSelector(),
                      const SizedBox(height: 20),

                      // Catégories
                      NeonCategorySwitch(
                        title: 'SOFT',
                        color: Colors.greenAccent,
                        value: _isSoftSelected,
                        onChanged: (val) =>
                            setState(() => _isSoftSelected = val),
                      ),
                      NeonCategorySwitch(
                        title: 'GEEK',
                        color: Colors.blueAccent,
                        value: _isGeekSelected,
                        onChanged: (val) =>
                            setState(() => _isGeekSelected = val),
                      ),
                      NeonCategorySwitch(
                        title: 'HARD',
                        color: Colors.orangeAccent,
                        value: _isHardSelected,
                        onChanged: (val) =>
                            setState(() => _isHardSelected = val),
                      ),
                      NeonCategorySwitch(
                        title: 'HOT',
                        color: Colors.redAccent,
                        value: _isHotSelected,
                        onChanged: (val) =>
                            setState(() => _isHotSelected = val),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.orangeAccent.withValues(alpha: 0.15),
                    side: const BorderSide(
                        color: Colors.orangeAccent, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "LANCER LE JEU",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orangeAccent,
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
    );
  }
}
