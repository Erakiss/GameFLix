import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async'; 

import 'package:gameflix/models/player.dart';
import 'package:gameflix/games/imposter/imp_scoreboard.dart';
// --- MODÈLE ---
class ImpCard {
  final String category;
  final String word;
  final String imposterWord;
  final String? imagePath; // Prêt pour ta future mise à jour des images !

  ImpCard({required this.category, required this.word, required this.imposterWord, this.imagePath});

  factory ImpCard.fromJson(Map<String, dynamic> json) {
    return ImpCard(
      category: json['category'] ?? '',
      word: json['word'] ?? '',
      imposterWord: json['imposter_word'] ?? '',
      imagePath: json['imagePath'], // Sera null si non renseigné
    );
  }
}

// --- ÉCRAN 1 : LE LOBBY ---
class ImpLobbyScreen extends StatefulWidget {
  final List<Player> players;
  const ImpLobbyScreen({super.key, required this.players});

  @override
  State<ImpLobbyScreen> createState() => _ImpLobbyScreenState();
}

class _ImpLobbyScreenState extends State<ImpLobbyScreen> {
  List<ImpCard> _allCards = [];
  
  // Toggles des catégories
  bool _isAnimaux = true;
  bool _isSport = true;
  bool _isLieu = true;
  bool _isPerso = true;
  bool _isFilm = true;

  // Toggle du mode de jeu
  bool _isMisterWhiteMode = false; // False = Undercover classique (mot similaire), True = Mister White (aucun mot)

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

    // Sélection de la carte
    final random = Random();
    ImpCard selectedCard = deck[random.nextInt(deck.length)];

    // --- NOUVELLE LOGIQUE : Calcul dynamique des rôles ---
    int totalPlayers = widget.players.length;
    int badGuysCount = 1;
    if (totalPlayers >= 5 && totalPlayers <= 7) badGuysCount = 2;
    if (totalPlayers >= 8) badGuysCount = 3;

    List<String> rolesToAssign = [];
    
    // Ajout des méchants
    if (_isMisterWhiteMode) {
      rolesToAssign.add("MISTER_WHITE"); // Le premier méchant est toujours Mister White
      for (int i = 1; i < badGuysCount; i++) {
        rolesToAssign.add("IMPOSTER"); // Les autres méchants éventuels sont des imposteurs normaux
      }
    } else {
      for (int i = 0; i < badGuysCount; i++) {
        rolesToAssign.add("IMPOSTER"); // Tout le monde est imposteur classique
      }
    }

    // Ajout des civils pour combler le reste
    while (rolesToAssign.length < totalPlayers) {
      rolesToAssign.add("CIVIL");
    }

    // On mélange bien les rôles
    rolesToAssign.shuffle(random);

    // On associe chaque joueur à son rôle
    Map<String, String> assignedRoles = {};
    for (int i = 0; i < totalPlayers; i++) {
      assignedRoles[widget.players[i].name] = rolesToAssign[i];
    }
    // -----------------------------------------------------

    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => ImpDistributionScreen(
        players: widget.players, 
        selectedCard: selectedCard, 
        playerRoles: assignedRoles, // On passe la map des rôles au lieu d'un seul joueur
      ))
    );
  }

  Widget _buildCategorySwitch(String title, Color color, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFF050515), borderRadius: BorderRadius.circular(15), border: Border.all(color: value ? color : Colors.white10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: value ? Colors.white : Colors.white38)),
          Switch(value: value, activeTrackColor: color, activeThumbColor: Colors.white, onChanged: onChanged),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double fixedRenderHeight = 150.0; // Un peu plus petit pour laisser la place aux options
    const double targetImageRatio = 0.45;
    double calculatedCardWidth = fixedRenderHeight / targetImageRatio;

    return Scaffold(
      backgroundColor: const Color(0xFF111122),
      appBar: AppBar(title: const Text("L'IMPOSTEUR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Center( 
                child: Container(
                  height: fixedRenderHeight, width: calculatedCardWidth, 
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15), 
                    border: Border.all(color: Colors.purpleAccent, width: 2.5), 
                    boxShadow: [BoxShadow(color: Colors.purpleAccent.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2)], 
                    image: const DecorationImage(image: AssetImage('assets/imp_banner.png'), fit: BoxFit.contain)
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Mode de jeu (Le switch principal)
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

              // Liste scrollable des catégories pour éviter l'overflow
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCategorySwitch('Animaux', Colors.greenAccent, _isAnimaux, (val) => setState(() => _isAnimaux = val)),
                      _buildCategorySwitch('Sport', Colors.orangeAccent, _isSport, (val) => setState(() => _isSport = val)),
                      _buildCategorySwitch('Lieu', Colors.blueAccent, _isLieu, (val) => setState(() => _isLieu = val)),
                      _buildCategorySwitch('Personnage Animé', Colors.pinkAccent, _isPerso, (val) => setState(() => _isPerso = val)),
                      _buildCategorySwitch('Film', Colors.amberAccent, _isFilm, (val) => setState(() => _isFilm = val)),
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

// --- ÉCRAN 2 : LA DISTRIBUTION (PASS & PLAY) ---
class ImpDistributionScreen extends StatefulWidget {
  final List<Player> players;
  final ImpCard selectedCard;
  final Map<String, String> playerRoles; // La nouvelle Map des rôles

  const ImpDistributionScreen({super.key, required this.players, required this.selectedCard, required this.playerRoles});

  @override
  State<ImpDistributionScreen> createState() => _ImpDistributionScreenState();
}

class _ImpDistributionScreenState extends State<ImpDistributionScreen> {
  int _currentPlayerIndex = 0;
  bool _isRevealed = false; 

  void _toggleReveal() {
    setState(() {
      _isRevealed = !_isRevealed;
      if (!_isRevealed) {
        _currentPlayerIndex++;
        if (_currentPlayerIndex >= widget.players.length) {
          // --- MISE À JOUR : Lancement de l'écran de Débat ---
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => ImpDebateScreen(
              players: widget.players,
              playerRoles: widget.playerRoles,
              selectedCard: widget.selectedCard,
            ))
          );
          // ---------------------------------------------------
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPlayerIndex >= widget.players.length) return const SizedBox.shrink();

    Player currentPlayer = widget.players[_currentPlayerIndex];
    String playerRole = widget.playerRoles[currentPlayer.name]!; 
    
    String secretWord = "";
    String roleSubtext = "";
    bool isMisterWhite = false;

    // --- CORRECTION : L'IMPOSTEUR NE SAIT PAS QU'IL EST L'IMPOSTEUR ---
    if (playerRole == "MISTER_WHITE") {
      secretWord = "TU ES MISTER WHITE";
      roleSubtext = "Tu n'as aucun mot. Écoute les autres pour le deviner !";
      isMisterWhite = true;
    } else if (playerRole == "IMPOSTER") {
      secretWord = widget.selectedCard.imposterWord;
      // Même phrase que les civils pour qu'il ne se doute de rien
      roleSubtext = "Mémorise ce mot et garde-le secret.";
    } else {
      secretWord = widget.selectedCard.word;
      // Même phrase que l'imposteur
      roleSubtext = "Mémorise ce mot et garde-le secret.";
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050515),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: !_isRevealed 
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.screen_lock_portrait, size: 80, color: Colors.white54),
                  const SizedBox(height: 30),
                  const Text("Passez le téléphone à", style: TextStyle(fontSize: 20, color: Colors.white70)),
                  const SizedBox(height: 10),
                  Text(currentPlayer.name.toUpperCase(), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.purpleAccent, letterSpacing: 2)),
                  const SizedBox(height: 50),
                  ElevatedButton(
                    onPressed: _toggleReveal,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: const Text("VOIR MON RÔLE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  const Text("Assurez-vous que personne ne regarde votre écran !", textAlign: TextAlign.center, style: TextStyle(color: Colors.redAccent, fontStyle: FontStyle.italic)),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(currentPlayer.name, style: const TextStyle(fontSize: 20, color: Colors.white54)),
                  const SizedBox(height: 10),
                  Text(isMisterWhite ? "ATTENTION :" : "TON MOT SECRET EST :", style: const TextStyle(fontSize: 16, color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  Container(
                    width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(color: const Color(0xFF111122), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.purpleAccent, width: 2), boxShadow: [BoxShadow(color: Colors.purpleAccent.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)]),
                    child: Column(
                      children: [
                        Text(secretWord, textAlign: TextAlign.center, style: TextStyle(fontSize: secretWord.length > 15 ? 24 : 36, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 15),
                        Text(roleSubtext, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.white70, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),
                  ElevatedButton.icon(
                    onPressed: _toggleReveal,
                    icon: const Icon(Icons.visibility_off, color: Colors.white),
                    label: Text(_currentPlayerIndex == widget.players.length - 1 ? "CACHER ET COMMENCER" : "CACHER ET PASSER", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, side: const BorderSide(color: Colors.white54, width: 2), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  ),
                ],
              ),
          ),
        ),
      ),
    );
  }
}

// --- ÉCRAN 3 : LE DÉBAT ET LE CHRONOMÈTRE ---
class ImpDebateScreen extends StatefulWidget {
  final List<Player> players;
  final Map<String, String> playerRoles;
  final ImpCard selectedCard;

  const ImpDebateScreen({super.key, required this.players, required this.playerRoles, required this.selectedCard});

  @override
  State<ImpDebateScreen> createState() => _ImpDebateScreenState();
}

class _ImpDebateScreenState extends State<ImpDebateScreen> {
  late int _timeLeft; 
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.players.length * 60; // 60 secondes par joueur
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goToReveal() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => ImpScoreboardScreen( // <-- Changement ici
        players: widget.players,
        playerRoles: widget.playerRoles,
        selectedCard: widget.selectedCard,
      ))
    );
  }

  // --- NOUVELLE MÉTHODE : Menu pour choisir le joueur distrait ---
  void _showForgetMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111122),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.purpleAccent, width: 2)),
        title: const Text("Qui a oublié son mot ?", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.players.map((p) => ListTile(
            title: Text(p.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.purpleAccent, fontSize: 18, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context); // Ferme la liste
              _showPlayerSecret(p);   // Ouvre l'écran sécurisé pour ce joueur
            },
          )).toList(),
        ),
      ),
    );
  }

  // --- NOUVELLE MÉTHODE : Affichage du mot avec "Maintenir pour voir" ---
  void _showPlayerSecret(Player player) {
    String role = widget.playerRoles[player.name]!;
    String secretWord = "";
    
    // On retrouve le mot exact du joueur
    if (role == "MISTER_WHITE") {
      secretWord = "TU ES MISTER WHITE";
    } else if (role == "IMPOSTER") {
      secretWord = widget.selectedCard.imposterWord;
    } else {
      secretWord = widget.selectedCard.word;
    }

    showDialog(
      context: context,
      builder: (context) {
        bool isRevealed = false; // Par défaut, le mot est caché
        
        // StatefulBuilder permet de rafraîchir uniquement ce petit popup
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF050515),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.purpleAccent, width: 2)),
              title: Text(player.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Cache l'écran aux autres !", style: TextStyle(color: Colors.redAccent, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 20),
                  
                  // Zone d'affichage (Cadenas ou Mot secret)
                  Container(
                    height: 100,
                    alignment: Alignment.center,
                    child: isRevealed
                        ? Text(secretWord, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white))
                        : const Icon(Icons.visibility_off, size: 50, color: Colors.white54),
                  ),
                ],
              ),
              actions: [
                Center(
                  // GestureDetector capte le moment où le doigt se pose et se lève
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => isRevealed = true), // Doigt posé
                    onTapUp: (_) => setState(() => isRevealed = false),  // Doigt levé
                    onTapCancel: () => setState(() => isRevealed = false), // Si le doigt glisse hors du bouton
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      decoration: BoxDecoration(color: Colors.purpleAccent, borderRadius: BorderRadius.circular(15)),
                      child: const Text("MAINTENIR POUR VOIR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    int minutes = _timeLeft ~/ 60;
    int seconds = _timeLeft % 60;
    String timeString = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: const Color(0xFF050515),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("TEMPS DE DÉBAT", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purpleAccent, letterSpacing: 2)),
              const SizedBox(height: 20),
              const Text("Posez-vous des questions pour\ndémasquer les menteurs !", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 50),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.black, 
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _timeLeft <= 30 ? Colors.redAccent : Colors.purpleAccent, width: 3),
                  boxShadow: [BoxShadow(color: (_timeLeft <= 30 ? Colors.redAccent : Colors.purpleAccent).withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 5)]
                ),
                child: Text(
                  timeString, 
                  style: TextStyle(fontSize: 70, fontWeight: FontWeight.w900, color: _timeLeft <= 30 ? Colors.redAccent : Colors.white)
                ),
              ),

              const SizedBox(height: 60),
              ElevatedButton.icon(
                onPressed: _goToReveal,
                icon: const Icon(Icons.how_to_vote, color: Colors.white),
                label: const Text("PASSER AU VOTE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent, 
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
              ),

              const SizedBox(height: 30),
              
              // --- LE NOUVEAU BOUTON D'AIDE ---
              TextButton.icon(
                onPressed: _showForgetMenu,
                icon: const Icon(Icons.help_outline, color: Colors.white54),
                label: const Text("J'ai oublié mon mot", style: TextStyle(color: Colors.white54, decoration: TextDecoration.underline, fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

