// lib/games/imposter/imp_lobby.dart
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/games/imposter/imp_game.dart';
import 'package:gameflix/l10n/app_strings.dart';
import 'package:gameflix/l10n/strings_imp_code.dart';
import 'package:gameflix/shared/widgets/neon_category_switch.dart';
import 'package:gameflix/shared/widgets/neon_lobby_banner.dart';
import 'package:gameflix/shared/widgets/global_settings_button.dart';
import 'package:gameflix/services/pack_loader_service.dart';

// --- MODÈLE ---
class ImpCard {
  final String category;
  final String word;
  final String imposterWord;
  final String? imagePath;

  ImpCard({
    required this.category,
    required this.word,
    required this.imposterWord,
    this.imagePath,
  });

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
  static const List<(String, Color)> _categories = [
    ('Animaux', Colors.greenAccent),
    ('Sport', Colors.orangeAccent),
    ('Lieu', Colors.blueAccent),
    ('Personnage Animé', Colors.pinkAccent),
    ('Film', Colors.amberAccent),
    ('Célébrités', Colors.cyanAccent),
    ('Musique', Colors.purpleAccent),
    ('Nourriture', Colors.limeAccent),
    ('Soirée', Colors.redAccent),
  ];

  List<ImpCard> _allCards = [];
  final Map<String, bool> _selectedCategories = {
    for (final (cat, _) in _categories) cat: true,
  };
  bool _isMisterWhiteMode = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await PackLoaderService.instance.loadCardsForGame<ImpCard>(
      'imp',
      ImpCard.fromJson,
    );
    if (!mounted) return;
    setState(() => _allCards = cards);
  }

  void _startGame() {
    final List<ImpCard> deck = _allCards
        .where((c) => _selectedCategories[c.category] ?? false)
        .toList();

    if (deck.isEmpty) {
      final strings = AppStrings.read(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.impSelectCategoryError),
          backgroundColor: Colors.redAccent,
        ),
      );
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
      for (int i = 1; i < badGuysCount; i++) {
        rolesToAssign.add("IMPOSTER");
      }
    } else {
      for (int i = 0; i < badGuysCount; i++) {
        rolesToAssign.add("IMPOSTER");
      }
    }

    while (rolesToAssign.length < totalPlayers) {
      rolesToAssign.add("CIVIL");
    }

    rolesToAssign.shuffle(random);

    Map<String, String> assignedRoles = {};
    for (int i = 0; i < totalPlayers; i++) {
      assignedRoles[widget.players[i].name] = rolesToAssign[i];
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ImpDistributionScreen(
          players: widget.players,
          selectedCard: selectedCard,
          playerRoles: assignedRoles,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: buildUnifiedLobbyAppBar(
        context: context,
        gameId: 'imp',
        accentColor: Colors.orangeAccent,
      ),
      body: Container(
        decoration: kLobbyBackgroundDecoration,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const NeonLobbyBanner(
                  imagePath: 'assets/banners/fr/imp_banner.webp',
                  borderColor: Colors.purpleAccent,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.purpleAccent, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.impMisterWhiteModeTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.purpleAccent,
                              ),
                            ),
                            Text(
                              strings.impMisterWhiteModeSubtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isMisterWhiteMode,
                        activeTrackColor: Colors.purpleAccent,
                        activeThumbColor: Colors.white,
                        onChanged: (val) =>
                            setState(() => _isMisterWhiteMode = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final (cat, color) in _categories)
                          NeonCategorySwitch(
                            title: strings.impCategoryTitle(cat),
                            color: color,
                            value: _selectedCategories[cat] ?? true,
                            onChanged: (val) =>
                                setState(() => _selectedCategories[cat] = val),
                          ),
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
                      backgroundColor: Colors.purpleAccent.withValues(alpha: 0.1),
                      side: const BorderSide(color: Colors.purpleAccent, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      strings.impDealRolesButton,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purpleAccent,
                        letterSpacing: 1.5,
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
