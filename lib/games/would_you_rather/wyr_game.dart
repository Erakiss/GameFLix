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

// --- ÉCRAN 1 : LE LOBBY (Inchangé) ---
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
              Center( 
                child: Container(
                  height: fixedRenderHeight, width: calculatedCardWidth, 
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.orangeAccent, width: 2.5), 
                    boxShadow: [BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2)], 
                    image: const DecorationImage(image: AssetImage('assets/wyr_banner.png'), fit: BoxFit.cover),
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

// --- ÉCRAN 2 : LE JEU (PAQUET 3D) ---
class WyrGameScreen extends StatefulWidget {
  final List<WyrCard> deck;
  const WyrGameScreen({super.key, required this.deck});

  @override
  State<WyrGameScreen> createState() => _WyrGameScreenState();
}

class _WyrGameScreenState extends State<WyrGameScreen> with SingleTickerProviderStateMixin {
  late AnimationController _swipeController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Vitesse de l'éjection très nerveuse
    _swipeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  void _nextCard() {
    if (_swipeController.isAnimating) return; // Sécurité anti-spam clic

    // Lancement de l'éjection de la carte
    _swipeController.forward().then((_) {
      if (_currentIndex < widget.deck.length - 1) {
        // On passe à la carte suivante invisiblement et on reset l'animation
        setState(() => _currentIndex++);
        _swipeController.reset();
      } else {
        // C'était la dernière carte !
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fin des cartes ! Retour au menu.")));
        Navigator.pop(context); 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.deck.isEmpty) return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text("Aucune carte", style: TextStyle(color: Colors.white))));

    return Scaffold(
      backgroundColor: Colors.black, // Fond du plateau
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white54),
        actions: [
           Padding(
             padding: const EdgeInsets.only(right: 20, top: 15),
             child: Text("${_currentIndex + 1} / ${widget.deck.length}", style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
           )
        ],
      ),
      body: Center(
        child: AnimatedBuilder(
          animation: _swipeController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              // Génération de la pile de 3 cartes
              children: _buildCardStack(),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildCardStack() {
    List<Widget> cards = [];
    int remainingCards = widget.deck.length - _currentIndex;
    int displayCount = min(3, remainingCards); 
    final size = MediaQuery.of(context).size;

    // On boucle à l'envers pour que la carte d'index 0 (la courante) soit dessinée en dernier (donc au-dessus)
    for (int i = displayCount - 1; i >= 0; i--) {
      int cardIndexInDeck = _currentIndex + i;
      WyrCard cardData = widget.deck[cardIndexInDeck];

      double scale = 1.0;
      double verticalOffset = 0.0;
      double horizontalOffset = 0.0;
      double rotation = 0.0;
      double opacity = 1.0;
      double animValue = _swipeController.value;

      if (i == 0) {
        // CARTE ACTIVE : Elle part sur la gauche en pivotant
        horizontalOffset = -animValue * size.width; 
        rotation = animValue * (pi / 3); 
        opacity = 1.0 - (animValue * 0.5); 
      } else if (i == 1) {
        // CARTE DU DESSOUS : Grandit et prend la place de l'active
        scale = 0.9 + (0.1 * animValue);
        verticalOffset = 30.0 - (30.0 * animValue);
        opacity = 0.5 + (0.5 * animValue);
      } else if (i == 2) {
        // 3ÈME CARTE : Grandit légèrement pour prendre la place de la carte 2
        scale = 0.8 + (0.1 * animValue);
        verticalOffset = 60.0 - (30.0 * animValue);
        opacity = 0.2 + (0.3 * animValue);
      }

      cards.add(
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective 3D pour le flip
            ..multiply(Matrix4.translationValues(horizontalOffset, verticalOffset, 0.0)) // Remplacement de translate
            ..multiply(Matrix4.diagonal3Values(scale, scale, 1.0)) // Remplacement de scale
            ..rotateY(rotation),
          child: Opacity(
            opacity: opacity,
            child: WyrPlayingCard(
              card: cardData,
              isTopCard: i == 0,
              onTap: _nextCard,
            ),
          ),
        ),
      );
    }
    return cards;
  }
}

// --- LE WIDGET DE LA CARTE PHYSIQUE ---
class WyrPlayingCard extends StatelessWidget {
  final WyrCard card;
  final bool isTopCard;
  final VoidCallback onTap;

  const WyrPlayingCard({super.key, required this.card, required this.isTopCard, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320, height: 500, // Taille fixe pour l'illusion d'un vrai paquet
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white24, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5, offset: Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23), // Masque les débordements des ChoiceZones aux coins
        child: Stack(
          children: [
            // LES DEUX CHOIX (Tes zones néons)
            Column(
              children: [
                ChoiceZone(
                  text: card.choice1, 
                  baseColor: Colors.pinkAccent, 
                  onTap: isTopCard ? onTap : () {}, // Seule la carte du dessus écoute les clics
                ),
                ChoiceZone(
                  text: card.choice2, 
                  baseColor: Colors.cyanAccent, 
                  onTap: isTopCard ? onTap : () {},
                ),
              ],
            ),
            
            // LE BADGE "OU" (Superposé au centre de la carte)
            Center(
              child: IgnorePointer(
                child: Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111122),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 3),
                    boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 10, spreadRadius: 2)]
                  ),
                  child: const Center(
                    child: Text("OU", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- TES ZONES DE SÉLECTION NÉONS (Inchangées, juste réutilisées) ---
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
          duration: const Duration(milliseconds: 100), 
          width: double.infinity,
          decoration: BoxDecoration(
            color: _isPressed 
                ? widget.baseColor.withValues(alpha: 0.5) 
                : widget.baseColor.withValues(alpha: 0.15),
            boxShadow: _isPressed 
                ? [BoxShadow(color: widget.baseColor.withValues(alpha: 0.8), blurRadius: 40, spreadRadius: 5)] 
                : [],
          ),
          transform: _isPressed ? Matrix4.diagonal3Values(0.95, 0.95, 1.0) : Matrix4.identity(),          
          transformAlignment: Alignment.center,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0), // Marge pour pas coller au bord
              child: AutoSizeText(
                widget.text, 
                textAlign: TextAlign.center, 
                maxLines: 5,
                minFontSize: 16,
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold, 
                  color: _isPressed ? Colors.white : widget.baseColor,
                  height: 1.3
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}