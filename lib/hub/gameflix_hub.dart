// lib/hub/gameflix_hub.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/games/truth_or_dare/tod_lobby.dart';
import 'package:gameflix/games/never_have_i_ever/nhie_lobby.dart';
import 'package:gameflix/games/would_you_rather/wyr_lobby.dart';
import 'package:gameflix/games/imposter/imp_lobby.dart';
import 'package:gameflix/games/drinking_board/board_game.dart';

class GameFlixHub extends StatefulWidget {
  const GameFlixHub({super.key});
  @override
  State<GameFlixHub> createState() => _GameFlixHubState();
}

class _GameFlixHubState extends State<GameFlixHub> {
  final List<Player> _globalPlayers = [];

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString('saved_players');
    if (saved != null) {
      final List<dynamic> decoded = jsonDecode(saved);
      setState(() {
        _globalPlayers.clear();
        _globalPlayers.addAll(decoded.map((p) => Player.fromJson(p)));
      });
    }
  }

  Future<void> _savePlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(_globalPlayers.map((p) => p.toJson()).toList());
    prefs.setString('saved_players', encodedData);
  }

  void _openPlayerManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A30),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.70, // Prend 70% de l'écran
          child: PlayerManagerSheet(
            players: _globalPlayers,
            onPlayersUpdated: () {
              setState(() {}); 
              _savePlayers(); 
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100, 
        leading: Row(
          children: [
            const SizedBox(width: 10), 
            // 1. Le drapeau
            GestureDetector(
              onTap: () { /* Logique langue */ },
              child: const Text("🇫🇷", style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 10), // L'écart ultra-réduit que tu voulais
            // 2. Le bouton joueurs
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.people_alt, color: Colors.cyanAccent, size: 26),
                  if (_globalPlayers.isNotEmpty)
                    Positioned(
                      right: -5, top: -5,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                        child: Text('${_globalPlayers.length}', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    )
                ],
              ),
              onPressed: _openPlayerManager,
            ),
          ],
        ),
        // Le titre est maintenant tout seul au centre
        title: const Text(
          "GAMEFLIX",
          style: TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.w900, 
            color: Colors.white, 
            letterSpacing: 2, 
            shadows: [Shadow(color: Colors.redAccent, blurRadius: 10)]
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.settings, color: Colors.white70, size: 26),
            color: const Color(0xFF1A1A30),
            onSelected: (value) { /* ... */ },
            itemBuilder: (BuildContext context) => [
              _buildPopupMenuItem('volume', 'Volume', Icons.volume_up),
              _buildPopupMenuItem('sub', 'Manage Subscription', Icons.card_membership),
              _buildPopupMenuItem('restore', 'Restore Purchase', Icons.restore),
              _buildPopupMenuItem('contact', 'Contact Us', Icons.mail_outline),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF050515), Color(0xFF111122), Color(0xFF2B003B)]),
        ),
        child: SafeArea(
          child: _buildCatalogue(),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value, String text, IconData icon) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 20),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildCatalogue() {
    
    // 1. On garde ton empreinte verticale fixe de 170px qui t'allait bien.
    const double fixedRenderHeight = 170.0; 

    // 2. Ton image fait 1000x450, soit un ratio hauteur/largeur de 0.45.
    // Pour calculer la largeur parfaite pour que l'image tienne, on fait : Hauteur / Ratio.
    // Largeur = 170.0 / 0.45 = ~377.78px.
    const double targetImageRatio = 0.45; // Height is 0.45 of Width
    double calculatedCardWidth = fixedRenderHeight / targetImageRatio; // Target width based on target height.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 20, bottom: 10),
          child: Text("SÉLECTIONNE UN JEU", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 2)),
        ),
        Expanded(
          child: ListWheelScrollView(
            // itemExtent reste sur la hauteur, c'est l'empreinte verticale dans la roue.
            itemExtent: fixedRenderHeight + 30, // repeatable vertical spacing.
            physics: const BouncingScrollPhysics(), 
            perspective: 0.005, 
            diameterRatio: 2.0, 
            squeeze: 1.05, 
            children: [
              // 1. TRUTH OR DARE
              _buildWheelCard(
                subtitle: "Action ou Vérité revisité",
                imagePath: 'assets/tod_banner.png', 
                cardRenderHeight: fixedRenderHeight, // Empreinte verticale
                cardRenderWidth: calculatedCardWidth, // Largeur calculée pour l'image
                onTap: () {
                  if (_globalPlayers.length < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Ajoute au moins 2 joueurs !"), backgroundColor: Colors.redAccent));
                    _openPlayerManager();
                    return;
                  }
                  Navigator.push(context, MaterialPageRoute(builder: (context) => TodLobbyScreen(players: _globalPlayers)));
                }
              ),

              // 2. Never Have I Ever
              _buildWheelCard(
                subtitle: "Je n'ai jamais... mais en course !",
                imagePath: 'assets/nhie_banner.png', 
                cardRenderHeight: fixedRenderHeight,
                cardRenderWidth: calculatedCardWidth,
                isNew: true,
                onTap: () {
                  // --- MISE À JOUR : Limite entre 2 et 5 joueurs ---
                  if (_globalPlayers.length < 2 || _globalPlayers.length > 5) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("⚠️ Il faut entre 2 et 5 joueurs pour ce jeu !"), 
                        backgroundColor: Colors.redAccent
                      )
                    );
                    _openPlayerManager();
                    return;
                  }
                  // ------------------------------------------------
                  Navigator.push(context, MaterialPageRoute(builder: (context) => NhieLobbyScreen(players: _globalPlayers)));
                }
              ),

              // 3. Imposter
              _buildWheelCard(
                subtitle: "Imposteur ou Mister White ?",
                imagePath: 'assets/imp_banner.png', 
                cardRenderHeight: fixedRenderHeight,
                cardRenderWidth: calculatedCardWidth,
                isNew: true,
                onTap: () {
                  if (_globalPlayers.length < 3) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("⚠️ Il faut au moins 3 joueurs pour ce jeu !"), 
                        backgroundColor: Colors.redAccent
                      )
                    );
                    _openPlayerManager();
                    return;
                  }
                  // ------------------------------------------------
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ImpLobbyScreen(players: _globalPlayers)));
                }
              ),

              _buildWheelCard(
                subtitle: "Le choix impossible",
                imagePath: 'assets/wyr_banner.png', // Si tu en as une
                isNew: true,
                cardRenderHeight: fixedRenderHeight,
                cardRenderWidth: calculatedCardWidth,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const WyrLobbyScreen()));
                }
              ),

              // 5. LE JEU DE PLATEAU (PROTOTYPE)
              _buildWheelCard(
                subtitle: "Le plateau de l'enfer",
                imagePath: 'assets/board_banner.png',
                isNew: true,
                cardRenderHeight: fixedRenderHeight,
                cardRenderWidth: calculatedCardWidth,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BoardGameScreen(players: _globalPlayers))),
              ),

              // 6. UN JEU EN PRÉPARATION (On passe les mêmes dimensions pour la cohérence visuelle)
              _buildWheelCard(
                subtitle: "Le code chauffe...",
                imagePath: null, 
                isLocked: true,
                cardRenderHeight: fixedRenderHeight,
                cardRenderWidth: calculatedCardWidth,
                onTap: () {}
              ),

            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWheelCard({
    required String subtitle,
    String? imagePath,           // Restauré : Nullable
    bool isLocked = false,       // Restauré : Par défaut false
    bool isNew = false,          // Le nouveau badge
    required double cardRenderHeight,
    required double cardRenderWidth,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      // Si la carte est verrouillée, on désactive le clic
      onTap: isLocked ? null : onTap, 
      child: Stack(
        clipBehavior: Clip.none, // Permet au badge NEW de dépasser légèrement
        children: [
          // 1. La carte de base
          Container(
            height: cardRenderHeight,
            width: cardRenderWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFF111122),
              border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.5), width: 2),
              boxShadow: [
                BoxShadow(color: Colors.purpleAccent.withValues(alpha: 0.3),blurRadius: 15,spreadRadius: 2,),],
              image: imagePath != null 
                ? DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                    colorFilter: isLocked ? ColorFilter.mode(Colors.black.withValues(alpha: 0.7), BlendMode.darken) : null,
                  )
                : null,
            ),
            child: Stack(
              children: [
                // --- LE TEXTE : TITRE ET SOUS-TITRE ---
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      // Un dégradé noir pour que le texte ressorte bien sur l'image
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                // --- LE CADENAS SI VERROUILLÉ ---
                if (isLocked)
                  const Center(child: Icon(Icons.lock_outline, color: Colors.white54, size: 50)),
              ],
            ),
          ),
          
          // 2. Le badge "NEW" superposé
          if (isNew && !isLocked)
            Positioned(
              top: -5,
              right: -5,
              child: Transform.rotate(
                angle: 0.1, 
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 2)
                    ],
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Text(
                    "NEW",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Player Manager Pop-up ---
class PlayerManagerSheet extends StatefulWidget {
  final List<Player> players;
  final VoidCallback onPlayersUpdated;

  const PlayerManagerSheet({super.key, required this.players, required this.onPlayersUpdated});

  @override
  State<PlayerManagerSheet> createState() => _PlayerManagerSheetState();
}

class _PlayerManagerSheetState extends State<PlayerManagerSheet> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedGender = 'M';

  void _addPlayer() {
    if (_nameController.text.trim().isNotEmpty) {
      setState(() {
        widget.players.add(Player(name: _nameController.text.trim(), gender: _selectedGender));
        _nameController.clear();
      });
      widget.onPlayersUpdated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Text("LES JOUEURS", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.cyanAccent, letterSpacing: 2)),
          const SizedBox(height: 20),
          
          Row(children: [
            Expanded(child: GestureDetector(onTap: () => setState(() => _selectedGender = 'M'), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _selectedGender == 'M' ? Colors.blueAccent.withValues(alpha: 0.3) : Colors.white10, border: Border.all(color: _selectedGender == 'M' ? Colors.blueAccent : Colors.transparent), borderRadius: BorderRadius.circular(10)), child: Center(child: Text('♂ Garçon', style: TextStyle(color: _selectedGender == 'M' ? Colors.blueAccent : Colors.white54, fontWeight: FontWeight.bold)))))),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(onTap: () => setState(() => _selectedGender = 'F'), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _selectedGender == 'F' ? Colors.pinkAccent.withValues(alpha: 0.3) : Colors.white10, border: Border.all(color: _selectedGender == 'F' ? Colors.pinkAccent : Colors.transparent), borderRadius: BorderRadius.circular(10)), child: Center(child: Text('♀ Fille', style: TextStyle(color: _selectedGender == 'F' ? Colors.pinkAccent : Colors.white54, fontWeight: FontWeight.bold)))))),
          ]),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: TextField(controller: _nameController, onSubmitted: (_) => _addPlayer(), decoration: InputDecoration(hintText: 'Prénom...', filled: true, fillColor: Colors.black45, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
            const SizedBox(width: 10),
            IconButton(onPressed: _addPlayer, icon: const Icon(Icons.add_circle, size: 45, color: Colors.cyanAccent)),
          ]),
          const SizedBox(height: 20),
          
          Expanded(
            child: widget.players.isEmpty 
              ? const Center(child: Text("Aucun joueur pour le moment.\nAjoute tes potes pour commencer !", textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic)))
              : ListView.builder(
                  itemCount: widget.players.length,
                  itemBuilder: (context, i) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
                    child: Row(
                      children: [
                        Text(widget.players[i].gender == 'M' ? '♂' : '♀', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: widget.players[i].gender == 'M' ? Colors.blueAccent : Colors.pinkAccent)),
                        const SizedBox(width: 15),
                        Text(widget.players[i].name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent), 
                          onPressed: () {
                            setState(() => widget.players.removeAt(i)); 
                            widget.onPlayersUpdated();
                          }
                        ),
                      ],
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}