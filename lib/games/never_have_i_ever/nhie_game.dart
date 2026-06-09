import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/hub/gameflix_hub.dart';


// --- MODÈLE ---
class NhieCard {
  final String difficulty;
  final String content;
  NhieCard({required this.difficulty, required this.content});
  factory NhieCard.fromJson(Map<String, dynamic> json) => NhieCard(difficulty: json['difficulty'], content: json['content']);
}

// --- ÉCRAN 1 : LE LOBBY (CHOIX DES CATÉGORIES) ---
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
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    // CORRECTION DU NOM DU FICHIER ICI
    final String response = await rootBundle.loadString('assets/data/nhie_cards.json');
    final List<dynamic> data = json.decode(response);
    setState(() => _allCards = data.map((j) => NhieCard.fromJson(j)).toList());
  }

  void _startGame() {
    // On crée la liste directement à partir de ce que les booléens disent au moment T
    List<NhieCard> deck = [];
    
    if (_isSoftSelected) {
      deck.addAll(_allCards.where((c) => c.difficulty == 'SOFT'));
    }
    if (_isGeekSelected) {
      deck.addAll(_allCards.where((c) => c.difficulty == 'GEEK'));
    }
    if (_isHotSelected) {
      deck.addAll(_allCards.where((c) => c.difficulty == 'HOT'));
    }

    if (deck.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sélectionne au moins une catégorie !"), backgroundColor: Colors.redAccent)
      );
      return;
    }
    
    deck.shuffle();
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => NhieRaceScreen(players: widget.players, deck: deck))
    );
  }

  Widget _buildCategorySwitch(String title, Color color, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFF050515), borderRadius: BorderRadius.circular(15), border: Border.all(color: value ? color : Colors.white10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: value ? Colors.white : Colors.white38)),
          Switch(
            value: value, 
            activeTrackColor: color,    // Le rail devient coloré quand c'est activé
            activeThumbColor: Colors.white, // Le petit bouton devient blanc
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- MISE À JOUR : On récupère les mêmes dimensions que le Hub ---
    const double fixedRenderHeight = 170.0; 
    const double targetImageRatio = 0.45;
    double calculatedCardWidth = fixedRenderHeight / targetImageRatio;

    return Scaffold(
      backgroundColor: const Color(0xFF111122),
      appBar: AppBar(title: const Text("JE N'AI JAMAIS", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            
            // --- MISE À JOUR DE LA BANNIÈRE ---
            Center( 
              child: Container(
                height: fixedRenderHeight-20, 
                width: calculatedCardWidth, 
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15), // Le petit border radius
                  border: Border.all(color: Colors.purpleAccent, width: 2.5), // La bordure violette
                  boxShadow: [
                    // L'ombre lumineuse passe en violet pour s'accorder à la bordure
                    BoxShadow(color: Colors.purpleAccent.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2)
                  ], 
                  image: const DecorationImage(
                    image: AssetImage('assets/nhie_banner.png'), 
                    fit: BoxFit.contain, 
                  )
                ),
              ),
            ),
            // -----------------------------------
            
            const SizedBox(height: 30),
            _buildCategorySwitch('SOFT', Colors.greenAccent, _isSoftSelected, (val) => setState(() => _isSoftSelected = val)),
            _buildCategorySwitch('GEEK', Colors.orangeAccent, _isGeekSelected, (val) => setState(() => _isGeekSelected = val)),
            _buildCategorySwitch('HOT', Colors.redAccent, _isHotSelected, (val) => setState(() => _isHotSelected = val)),
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

// --- ÉCRAN 2 : LA COURSE DE CHEVAUX (LE JEU) ---
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

 // --- MISE À JOUR : Ajout du paramètre "index" ---
  Widget _buildRaceTrack(Player player, int index) {
    bool isSelected = _currentTurnSelections[player.name] ?? false;
    int visualScore = player.score + (isSelected ? 1 : 0);
    double progress = min(visualScore / 10.0, 1.0); 

    // 1. La liste de tes 5 couleurs dans l'ordre demandé
    final List<Color> playerColors = [
      Colors.redAccent,
      Colors.lightBlueAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.greenAccent,
    ];
    
    // 2. On attribue la couleur en fonction de la position du joueur
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
                decoration: BoxDecoration(
                  color: Colors.black45, 
                  borderRadius: BorderRadius.circular(25), 
                  // 3. La bordure s'allume avec la couleur du joueur !
                  border: Border.all(color: isSelected ? trackColor : Colors.white10, width: 2)
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double avatarSize = 35.0; 
                    double maxTop = constraints.maxHeight - avatarSize; 

                    return Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 500), curve: Curves.easeOutBack,
                          top: maxTop * (1.0 - progress),
                          child: Container(
                            width: avatarSize, height: avatarSize,
                            margin: const EdgeInsets.symmetric(vertical: 2), 
                            // 4. Le fond du pion prend la couleur du joueur quand il est sélectionné
                            decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? trackColor : Colors.white24),
                            child: Center(
                              child: visualScore >= 10 
                                  ? const Icon(Icons.emoji_events, color: Colors.amber, size: 18)
                                  : const FaIcon(FontAwesomeIcons.horse, color: Colors.white, size: 18),
                            ),
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
            // 5. Le score s'affiche en permanence dans la couleur du joueur !
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
            // 1. LA CARTE EN HAUT
            Container(
              padding: const EdgeInsets.all(25), margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(color: const Color(0xFF111122), borderRadius: BorderRadius.circular(20), border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 2), boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("JE N'AI JAMAIS", style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18)),
                  const SizedBox(height: 20),
                  

                  SizedBox(
                    height: 120, // Hauteur maximum allouée au texte
                    child: Center(
                      child: AutoSizeText(
                        card.content, 
                        textAlign: TextAlign.center, 
                        maxLines: 5, // Autorise 5 lignes maximum
                        minFontSize: 12, // Rétrécit jusqu'à la taille 12 si besoin
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3),
                      ),
                    ),
                  ),
                  // -----------------------------------------------------
                  
                ],
              ),
            ),
            
            const Text("Appuyez sur votre ligne si vous l'avez fait 👇", style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: widget.players.asMap().entries.map((entry) {
                    int index = entry.key; // 0, 1, 2...
                    Player p = entry.value; // Le joueur
                    return Expanded(child: _buildRaceTrack(p, index));
                  }).toList(),
                  // ------------------------------------------------------------------
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

// --- ÉCRAN 3 : LE GAGNANT (SCOREBOARD) ---
class NhieScoreboardScreen extends StatelessWidget {
  final List<Player> players;
  const NhieScoreboardScreen({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    List<Player> sortedPlayers = List.from(players)..sort((a, b) => b.score.compareTo(a.score));
    
    return Scaffold(
      backgroundColor: const Color(0xFF050515),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("🏁 LA COURSE EST FINIE ! 🏁", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
              const SizedBox(height: 30),
              const Text("Le pire joueur de la soirée est...", style: TextStyle(color: Colors.white70, fontSize: 18)),
              const SizedBox(height: 10),
              Text(sortedPlayers.first.name.toUpperCase(), style: const TextStyle(fontSize: 50, fontWeight: FontWeight.w900, color: Colors.redAccent, shadows: [Shadow(color: Colors.red, blurRadius: 20)])),
              const SizedBox(height: 40),
              ...sortedPlayers.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text("${p.name} : ${p.score} points", style: const TextStyle(fontSize: 20, color: Colors.white)),
              )),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const GameFlixHub()), (route) => false),
                icon: const Icon(Icons.home, color: Colors.black), label: const Text("RETOUR AU MENU", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
              )
            ],
          ),
        ),
      ),
    );
  }
}