import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/models/game_card.dart';
import 'package:gameflix/games/truth_or_dare/tod_game.dart';

class TodLobbyScreen extends StatefulWidget {
  final List<Player> players;
  const TodLobbyScreen({super.key, required this.players});

  @override
  State<TodLobbyScreen> createState() => _TodLobbyScreenState();
}

class _TodLobbyScreenState extends State<TodLobbyScreen> {
  final List<GameCard> _baseDeck = [];
  final List<GameCard> _customCards = [];
  
  bool _useSoft = true;
  bool _useFun = true;
  bool _useHot = false;
  bool _useCustom = true;
  
  bool _isAnimating = false; // Le fameux "Lock" d'animation
  double _selectedTurns = 20;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllCards();
  }

  Future<void> _loadAllCards() async {
    try {
      final String response = await rootBundle.loadString('assets/data/cards.json');
      final List<dynamic> data = jsonDecode(response);
      _baseDeck.addAll(data.map((c) => GameCard.fromJson(c)));
    } catch (e) {
      debugPrint("Erreur JSON: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString('saved_cards');
    if (saved != null) {
      final List<dynamic> decoded = jsonDecode(saved);
      _customCards.addAll(decoded.map((c) => GameCard.fromJson(c)));
    }

    setState(() => _isLoading = false);
  }

  // Fonction pour verrouiller les clics pendant l'animation des cartes
  void _toggleDeck(String deck, bool currentValue) async {
    if (_isAnimating) return;
    setState(() {
      _isAnimating = true;
      if (deck == 'SOFT') _useSoft = !currentValue;
      if (deck == 'FUN') _useFun = !currentValue;
      if (deck == 'HOT') _useHot = !currentValue;
      if (deck == 'CUSTOM') _useCustom = !currentValue;
    });
    // On attend 400ms (la durée du SlideTransition) avant de déverrouiller
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _isAnimating = false);
  }

  // --- NOUVEAU : Fonction utilitaire de sauvegarde ---
  Future<void> _saveCustomCards() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('saved_cards', jsonEncode(_customCards.map((c) => c.toJson()).toList()));
  }

  // --- MISE À JOUR : Le gestionnaire s'ouvre en grand (70% de l'écran) ---
  void _openCardManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A30),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75, // Prend 75% de l'écran pour la liste
          child: ManageCustomCardsSheet(
            customCards: _customCards,
            onCardCreated: (newCard) {
              setState(() => _customCards.add(newCard));
              _saveCustomCards();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Carte ajoutée ! 🃏")));
            },
            onCardDeleted: (cardToDelete) {
              setState(() => _customCards.remove(cardToDelete));
              _saveCustomCards();
            },
          ),
        ),
      )
    );
  }

  void _startGame() {
    List<GameCard> finalDeck = [];
    if (_useSoft) finalDeck.addAll(_baseDeck.where((c) => c.difficulty == 'SOFT'));
    if (_useFun) finalDeck.addAll(_baseDeck.where((c) => c.difficulty == 'FUN'));
    if (_useHot) finalDeck.addAll(_baseDeck.where((c) => c.difficulty == 'HOT'));
    if (_useCustom) finalDeck.addAll(_customCards);

    if (finalDeck.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Sélectionne au moins un paquet !"), backgroundColor: Colors.redAccent));
      return;
    }

    for (var player in widget.players) { player.score = 0; }

    Navigator.pushReplacement(context, PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 800),
      pageBuilder: (_, _, _) => TodGameScreen(players: widget.players, deck: finalDeck, maxTurns: _selectedTurns.toInt()),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("Configuration", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)), backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF050515), Color(0xFF111122), Color(0xFF2B003B)])),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text("Paquets actifs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 15),
                
                // --- LES NOUVEAUX MINI-BOUTONS ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMiniToggle("SOFT", Colors.greenAccent, _useSoft, () => _toggleDeck('SOFT', _useSoft)),
                    _buildMiniToggle("FUN", Colors.orangeAccent, _useFun, () => _toggleDeck('FUN', _useFun)),
                    _buildMiniToggle("HOT", Colors.redAccent, _useHot, () => _toggleDeck('HOT', _useHot)),
                    _buildMiniToggle("CUSTOM", Colors.purpleAccent, _useCustom, () => _toggleDeck('CUSTOM', _useCustom)),
                  ],
                ),
                
                const SizedBox(height: 25),
                
                // --- LE TAPIS ANIMÉ ---
                _buildTapisPreview(),
                
                const SizedBox(height: 15),
                Center(child: TextButton.icon(onPressed: _openCardManager, icon: const Icon(Icons.add_box, color: Colors.purpleAccent), label: Text("Gérer les ${_customCards.length} cartes Custom", style: const TextStyle(color: Colors.purpleAccent)))),
                
                const Spacer(),
                const Text("Durée de la partie", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10), padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
                  child: Column(
                    children: [
                      Text("${_selectedTurns.toInt()} tours", style: const TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.w900)),
                      Slider(value: _selectedTurns, min: 5, max: 50, divisions: 9, activeColor: Colors.cyanAccent, inactiveColor: Colors.white24, onChanged: (val) => setState(() => _selectedTurns = val)),
                    ],
                  ),
                ),
                
                SizedBox(
                  width: double.infinity, height: 60,
                  child: ElevatedButton(
                    onPressed: _startGame, // Vérifie que c'est bien le nom de ta fonction
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent.withValues(alpha: 0.1), 
                      side: const BorderSide(color: Colors.pinkAccent, width: 2), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    child: const Text(
                      "LANCER LA PARTIE", 
                      style: TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.pinkAccent, 
                        letterSpacing: 2
                      )
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Composant : Les petits boutons Néon
  Widget _buildMiniToggle(String label, Color color, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.2) : Colors.black45,
          border: Border.all(color: isActive ? color : Colors.white24, width: 2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)] : [],
        ),
        child: Text(label, style: TextStyle(color: isActive ? color : Colors.white54, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  // Composant : Le Tapis Animé
  // Composant : Le Tapis Animé
  Widget _buildTapisPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        // --- NOUVEAU : On calcule la hauteur pour forcer le ratio 1000x400 (soit 2.5) ---
        double height = width / 2.5; 
        
        double cardWidth = 55; 
        double cardHeight = 85;

        // On crée la liste des decks actifs pour calculer les positions
        List<String> activeDecks = [];
        if (_useSoft) activeDecks.add('SOFT');
        if (_useFun) activeDecks.add('FUN');
        if (_useHot) activeDecks.add('HOT');
        if (_useCustom) activeDecks.add('CUSTOM');

        return Hero(
          tag: 'tapis_hero', 
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: height, // Utilise la hauteur mathématique parfaite
              width: width,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white24, width: 2),
                // --- NOUVEAU : Ton image dédiée au lobby ---
                image: const DecorationImage(image: AssetImage('assets/tapis_lobby.png'), fit: BoxFit.cover),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 5))]
              ),
              child: Stack(
                children: ['SOFT', 'FUN', 'HOT', 'CUSTOM'].map((deck) {
                  bool isActive = activeDecks.contains(deck);
                  int activeIndex = activeDecks.indexOf(deck);
                  
                  // Calcul de la position X
                  double leftPos = isActive 
                    ? ((width / (activeDecks.length + 1)) * (activeIndex + 1)) - (cardWidth / 2)
                    : (width / 2) - (cardWidth / 2); 
                  
                  // --- NOUVEAU : Centrage vertical parfait selon la nouvelle hauteur ---
                  double activeTopPos = (height - cardHeight) / 2;
                  double inactiveTopPos = height + 50.0; // Sort par le bas
                  
                  double topPos = isActive ? activeTopPos : inactiveTopPos;

                  String img = 'assets/Soft_Card.png';
                  if (deck == 'FUN') img = 'assets/Fun_Card.png';
                  if (deck == 'HOT') img = 'assets/Hot_Card.png';
                  if (deck == 'CUSTOM') img = 'assets/Custom_Card.png';

                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutBack, 
                    left: leftPos,
                    top: topPos,
                    child: Container(
                      width: cardWidth, height: cardHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        image: DecorationImage(image: AssetImage(img), fit: BoxFit.cover),
                        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))]
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      }
    );
  }
}

// Le menu Custom (inchangé)
// --- LE NOUVEAU GESTIONNAIRE DE CARTES CUSTOM ---
class ManageCustomCardsSheet extends StatefulWidget {
  final List<GameCard> customCards;
  final Function(GameCard) onCardCreated;
  final Function(GameCard) onCardDeleted;

  const ManageCustomCardsSheet({
    super.key, 
    required this.customCards, 
    required this.onCardCreated, 
    required this.onCardDeleted
  });

  @override
  State<ManageCustomCardsSheet> createState() => _ManageCustomCardsSheetState();
}

class _ManageCustomCardsSheetState extends State<ManageCustomCardsSheet> {
  bool _isCreating = false; // Permet de basculer entre la liste et le formulaire
  final _contentController = TextEditingController();
  String _type = 'ACTION';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Header avec le titre et le bouton retour (si on est en mode création)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_isCreating)
                IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white70), onPressed: () => setState(() => _isCreating = false))
              else
                const SizedBox(width: 48), // Spacer pour centrer le titre
                
              Text(_isCreating ? "Nouvelle Carte" : "Tes Cartes Custom", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
              
              const SizedBox(width: 48), // Spacer pour centrer le titre
            ],
          ),
          const SizedBox(height: 20),
          
          // Le contenu change selon l'état _isCreating
          Expanded(
            child: _isCreating ? _buildCreateForm() : _buildCardsList(),
          ),
        ],
      ),
    );
  }

  // --- VUE 1 : LA LISTE DES CARTES ---
  Widget _buildCardsList() {
    if (widget.customCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.style, size: 60, color: Colors.white24),
            const SizedBox(height: 15),
            const Text("Aucune carte custom pour l'instant.", style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 30),
            _buildAddButton(),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: widget.customCards.length,
            itemBuilder: (context, index) {
              final card = widget.customCards[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  title: Text(card.content, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(card.type, style: const TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      widget.onCardDeleted(card);
                      setState(() {}); 
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('CRÉER UNE NOUVELLE CARTE', style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        onPressed: () {
          setState(() {
            _contentController.clear();
            _isCreating = true;
          });
        },
      ),
    );
  }

  // --- VUE 2 : LE FORMULAIRE DE CRÉATION ---
  Widget _buildCreateForm() {
    return Column(
      children: [
        TextField(
          controller: _contentController, 
          decoration: InputDecoration(
            labelText: 'Contenu (utilise {TARGET} pour cibler un joueur)', 
            filled: true, 
            fillColor: Colors.black45,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ), 
          maxLines: 3,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: _type, 
          decoration: InputDecoration(
            labelText: 'Type de carte',
            filled: true, 
            fillColor: Colors.black45,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: const [
            DropdownMenuItem(value: 'ACTION', child: Text('ACTION')), 
            DropdownMenuItem(value: 'VERITE', child: Text('VERITE'))
          ], 
          onChanged: (v) => setState(() => _type = v!)
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity, 
          child: ElevatedButton(
            onPressed: () { 
              if (_contentController.text.trim().isNotEmpty) { 
                widget.onCardCreated(GameCard(type: _type, difficulty: 'CUSTOM', content: _contentController.text.trim())); 
                setState(() => _isCreating = false); // Retourne à la liste après création
              } 
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
            child: const Text('VALIDER LA CARTE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
          )
        )
      ],
    );
  }
}