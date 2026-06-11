// lib/games/would_you_rather/wyr_game.dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:gameflix/games/would_you_rather/wyr_lobby.dart'; // Import pour le modèle WyrCard

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
    _swipeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  void _nextCard() {
    if (_swipeController.isAnimating) return;

    _swipeController.forward().then((_) {
      if (_currentIndex < widget.deck.length - 1) {
        setState(() => _currentIndex++);
        _swipeController.reset();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fin des cartes ! Retour au menu.")));
        Navigator.pop(context); 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.deck.isEmpty) return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text("Aucune carte", style: TextStyle(color: Colors.white))));

    return Scaffold(
      backgroundColor: Colors.black,
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
        horizontalOffset = -animValue * size.width; 
        rotation = animValue * (pi / 3); 
        opacity = 1.0 - (animValue * 0.5); 
      } else if (i == 1) {
        scale = 0.9 + (0.1 * animValue);
        verticalOffset = 30.0 - (30.0 * animValue);
        opacity = 0.5 + (0.5 * animValue);
      } else if (i == 2) {
        scale = 0.8 + (0.1 * animValue);
        verticalOffset = 60.0 - (30.0 * animValue);
        opacity = 0.2 + (0.3 * animValue);
      }

      cards.add(
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) 
            ..multiply(Matrix4.translationValues(horizontalOffset, verticalOffset, 0.0))
            ..multiply(Matrix4.diagonal3Values(scale, scale, 1.0))
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

class WyrPlayingCard extends StatelessWidget {
  final WyrCard card;
  final bool isTopCard;
  final VoidCallback onTap;

  const WyrPlayingCard({super.key, required this.card, required this.isTopCard, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color accentColor;
    switch (card.category) {
      case 'Soft': accentColor = Colors.greenAccent; break;
      case 'Geek': accentColor = Colors.blueAccent; break;
      case 'Hard': accentColor = Colors.orangeAccent; break;
      case 'Hot': accentColor = Colors.redAccent; break;
      default: accentColor = Colors.purpleAccent;
    }

    return Container(
      width: 320, height: 500,
      decoration: BoxDecoration(
        color: const Color(0xFF111122),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 2),
        boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            Column(
              children: [
                ChoiceZone(text: card.choice1, baseColor: Colors.pinkAccent, onTap: isTopCard ? onTap : () {}),
                ChoiceZone(text: card.choice2, baseColor: Colors.cyanAccent, onTap: isTopCard ? onTap : () {}),
              ],
            ),
            Center(
              child: IgnorePointer(
                child: Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(color: const Color(0xFF111122), shape: BoxShape.circle, border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 3), boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2)]),
                  child: const Center(child: Text("OU", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChoiceZone extends StatefulWidget {
  final String text; final Color baseColor; final VoidCallback onTap;
  const ChoiceZone({super.key, required this.text, required this.baseColor, required this.onTap});
  @override State<ChoiceZone> createState() => _ChoiceZoneState();
}

class _ChoiceZoneState extends State<ChoiceZone> {
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Listener(
        onPointerDown: (_) => setState(() => _isPressed = true),
        onPointerUp: (_) { if (_isPressed) widget.onTap(); setState(() => _isPressed = false); },
        onPointerCancel: (_) => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100), width: double.infinity,
          decoration: BoxDecoration(color: _isPressed ? widget.baseColor.withValues(alpha: 0.5) : widget.baseColor.withValues(alpha: 0.15), boxShadow: _isPressed ? [BoxShadow(color: widget.baseColor.withValues(alpha: 0.8), blurRadius: 40, spreadRadius: 5)] : []),
          transform: _isPressed ? Matrix4.diagonal3Values(0.95, 0.95, 1.0) : Matrix4.identity(), transformAlignment: Alignment.center,
          child: Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 15.0), child: AutoSizeText(widget.text, textAlign: TextAlign.center, maxLines: 5, minFontSize: 16, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _isPressed ? Colors.white : widget.baseColor, height: 1.3)))),
        ),
      ),
    );
  }
}