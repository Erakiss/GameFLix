import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';

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

  Widget _buildCategorySwitch(String title, Color color, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFF050515), borderRadius: BorderRadius.circular(15), border: Border.all(color: value ? color : Colors.white10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: value ? Colors.white : Colors.white38)),
          Switch(value: value, activeTrackColor: color, activeThumbColor: Colors.white, onChanged: onChanged),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double fixedRenderHeight = 150.0; 
    const double targetImageRatio = 0.45;
    double calculatedCardWidth = fixedRenderHeight / targetImageRatio;

    return Scaffold(
      backgroundColor: const Color(0xFF111122),
      appBar: AppBar(title: const Text("TU PRÉFÈRES ?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Bannière
              Center( 
                child: Container(
                  height: fixedRenderHeight, 
                  width: calculatedCardWidth, 
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15), 
                    border: Border.all(color: Colors.orangeAccent, width: 2.5), 
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orangeAccent.withValues(alpha: 0.3), 
                        blurRadius: 15, 
                        spreadRadius: 2
                      )
                    ], 
                    image: const DecorationImage(
                      image: AssetImage('assets/wyr_banner.png'), 
                      fit: BoxFit.cover, // Remplit proprement la carte
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              _buildCategorySwitch('SOFT', Colors.greenAccent, _isSoftSelected, (val) => setState(() => _isSoftSelected = val)),
              _buildCategorySwitch('GEEK', Colors.blueAccent, _isGeekSelected, (val) => setState(() => _isGeekSelected = val)),
              _buildCategorySwitch('HARD', Colors.orangeAccent, _isHardSelected, (val) => setState(() => _isHardSelected = val)),
              _buildCategorySwitch('HOT', Colors.redAccent, _isHotSelected, (val) => setState(() => _isHotSelected = val)),
              
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

// --- ÉCRAN 2 : LE JEU (ÉCRAN SCINDÉ) ---
class WyrGameScreen extends StatefulWidget {
  final List<WyrCard> deck;
  const WyrGameScreen({super.key, required this.deck});

  @override
  State<WyrGameScreen> createState() => _WyrGameScreenState();
}

class _WyrGameScreenState extends State<WyrGameScreen> {
  int _currentIndex = 0;

  void _nextCard() {
    setState(() {
      if (_currentIndex < widget.deck.length - 1) {
        _currentIndex++;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fin des cartes ! Retour au menu."))
        );
        Navigator.pop(context); // Retourne au lobby quand le deck est vide
      }
    });
  }


 @override
  Widget build(BuildContext context) {
    if (widget.deck.isEmpty) return const Scaffold(body: Center(child: Text("Aucune carte")));

    WyrCard currentCard = widget.deck[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // L'ANIMATION DE REMPLACEMENT DE CARTE
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            // Une courbe un peu élastique pour donner du peps à l'arrivée
            switchInCurve: Curves.easeOutCubic, 
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              // Effet : Apparaît en fondu ET glisse légèrement vers le haut
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.15), // Arrive d'un peu plus bas
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            // Le bloc Column est la "Carte" qui sera remplacée. 
            // La ValueKey est OBLIGATOIRE pour que Flutter comprenne qu'il doit animer.
            child: Column(
              key: ValueKey<int>(_currentIndex), 
              children: [
                ChoiceZone(text: currentCard.choice1, baseColor: Colors.pinkAccent, onTap: _nextCard),
                ChoiceZone(text: currentCard.choice2, baseColor: Colors.cyanAccent, onTap: _nextCard),
              ],
            ),
          ),

          // LE BADGE "OU" AU CENTRE (Fixe, par-dessus l'animation)
          Center(
            // J'ai ajouté IgnorePointer pour éviter qu'il ne bloque les clics au centre de l'écran
            child: IgnorePointer(
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF111122),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15, spreadRadius: 5)]
                ),
                child: const Center(
                  child: Text("OU", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                ),
              ),
            ),
          ),

          // Bouton quitter
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ChoiceZone extends StatefulWidget {
  final String text;
  final Color baseColor;
  final VoidCallback onTap;

  const ChoiceZone({super.key, required this.text, required this.baseColor, required this.onTap});

  @override
  State<ChoiceZone> createState() => _ChoiceZoneState();
}

class _ChoiceZoneState extends State<ChoiceZone> {
  bool _isPressed = false;

  void _handleTapDown(Offset localPosition) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp() {
    if (_isPressed) {
      widget.onTap(); 
    }
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Listener(
        onPointerDown: (event) => _handleTapDown(event.localPosition),
        onPointerUp: (event) => _handleTapUp(),
        onPointerCancel: (event) => _handleTapCancel(),
        onPointerMove: (event) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final bool isInside = box.paintBounds.contains(event.localPosition);
          if (!isInside) _handleTapCancel();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100), // Très rapide pour l'impact
          width: double.infinity,
          decoration: BoxDecoration(
            // Le fond devient beaucoup plus opaque au clic
            color: _isPressed 
                ? widget.baseColor.withValues(alpha: 0.5) 
                : widget.baseColor.withValues(alpha: 0.15),
            // L'effet NEON / ILLUMINATION !
            boxShadow: _isPressed 
                ? [BoxShadow(color: widget.baseColor.withValues(alpha: 0.8), blurRadius: 40, spreadRadius: 5)] 
                : [],
            border: const Border(bottom: BorderSide(color: Colors.white10)),
          ),
          // Effet d'enfoncement (réduit à 95% de sa taille)
          transform: _isPressed ? Matrix4.diagonal3Values(0.95, 0.95, 1.0) : Matrix4.identity(),          transformAlignment: Alignment.center,
          child: Center(
            child: AutoSizeText(
              widget.text, 
              textAlign: TextAlign.center, 
              maxLines: 5,
              minFontSize: 16,
              style: TextStyle(
                fontSize: 32, 
                fontWeight: FontWeight.bold, 
                // Le texte passe en blanc pur au clic pour accentuer le flash
                color: _isPressed ? Colors.white : widget.baseColor,
                height: 1.3
              ),
            ),
          ),
        ),
      ),
    );
  }
}