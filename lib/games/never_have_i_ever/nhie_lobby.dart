// lib/games/never_have_i_ever/nhie_lobby.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/games/never_have_i_ever/nhie_game.dart';
import 'package:gameflix/shared/widgets/neon_category_switch.dart';
import 'package:gameflix/shared/widgets/neon_lobby_banner.dart';
import 'package:gameflix/shared/widgets/game_rules_sheet.dart';
import 'package:gameflix/shared/widgets/unlock_pack_sheet.dart';
import 'package:gameflix/services/pack_loader_service.dart';
import 'package:gameflix/state/access_control_provider.dart';

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
    final cards = await PackLoaderService.instance.loadCardsForGame<NhieCard>(
      'nhie',
      NhieCard.fromJson,
    );
    if (!mounted) return;
    setState(() => _allCards = cards);
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
    final access = context.watch<AccessControlProvider>();
    final bool canAccessHot = access.canAccess('nhie_hot', isPremium: true);

    return Scaffold(
      backgroundColor: const Color(0xFF111122),
      appBar: AppBar(
        title: const Text("JE N'AI JAMAIS", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.cyanAccent, size: 26),
            tooltip: 'Règles du jeu',
            onPressed: () => GameRulesSheet.show(context, DefaultGameRules.getRules('nhie')),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            NeonLobbyBanner(imagePath: 'assets/nhie_banner.png', borderColor: Colors.purpleAccent,),
            const SizedBox(height: 30),
            NeonCategorySwitch(title: 'SOFT', color: Colors.greenAccent, value: _isSoftSelected, onChanged: (val) => setState(() => _isSoftSelected = val)),
            NeonCategorySwitch(title: 'GEEK', color: Colors.orangeAccent, value: _isGeekSelected, onChanged: (val) => setState(() => _isGeekSelected = val)),
            NeonCategorySwitch(
              title: 'HOT',
              color: Colors.redAccent,
              value: _isHotSelected,
              isLocked: !canAccessHot,
              onLockedTap: () {
                UnlockPackSheet.show(
                  context,
                  packId: 'nhie_hot',
                  packTitle: 'Pack Hot & Piquant',
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
                    packTitle: 'Pack Hot & Piquant',
                    onUnlocked: () {
                      setState(() => _isHotSelected = true);
                    },
                  );
                } else {
                  setState(() => _isHotSelected = val);
                }
              },
            ),
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