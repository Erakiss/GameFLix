import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/models/game_card.dart';
import 'package:gameflix/games/truth_or_dare/tod_game.dart';
import 'package:gameflix/shared/widgets/global_settings_button.dart';
import 'package:gameflix/shared/widgets/unlock_pack_sheet.dart';
import 'package:gameflix/shared/widgets/neon_table_mat.dart';
import 'package:gameflix/services/pack_loader_service.dart';
import 'package:gameflix/state/access_control_provider.dart';
import 'package:gameflix/l10n/app_strings.dart';
import 'package:gameflix/l10n/strings_tod_nhie.dart';

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
    final baseCards = await PackLoaderService.instance.loadCardsForGame<GameCard>(
      'tod',
      GameCard.fromJson,
    );
    _baseDeck.addAll(baseCards);

    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString('saved_cards');
    if (saved != null) {
      final List<dynamic> decoded = jsonDecode(saved);
      _customCards.addAll(decoded.map((c) => GameCard.fromJson(c)));
    }

    if (!mounted) return;
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppStrings.read(context).todCardAddedSnackbar)),
              );
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
    final bool canAccessHot =
        AccessControlProvider.instance.canAccess('tod_hot', isPremium: true);
    List<GameCard> finalDeck = [];
    if (_useSoft) finalDeck.addAll(_baseDeck.where((c) => c.difficulty == 'SOFT'));
    if (_useFun) finalDeck.addAll(_baseDeck.where((c) => c.difficulty == 'FUN'));
    if (_useHot && canAccessHot) finalDeck.addAll(_baseDeck.where((c) => c.difficulty == 'HOT'));
    if (_useCustom) finalDeck.addAll(_customCards);

    if (finalDeck.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.read(context).todSelectDeckError),
          backgroundColor: Colors.redAccent,
        ),
      );
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

    final s = AppStrings.of(context);
    final access = context.watch<AccessControlProvider>();
    final bool canAccessHot = access.canAccess('tod_hot', isPremium: true);

    return Scaffold(
      appBar: buildUnifiedLobbyAppBar(
        context: context,
        gameId: 'tod',
        accentColor: Colors.purpleAccent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: kLobbyBackgroundDecoration,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(s.todActiveDecksTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 15),
                
                // --- LES NOUVEAUX MINI-BOUTONS ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMiniToggle("SOFT", Colors.greenAccent, _useSoft, () => _toggleDeck('SOFT', _useSoft)),
                    _buildMiniToggle("FUN", Colors.orangeAccent, _useFun, () => _toggleDeck('FUN', _useFun)),
                    _buildMiniToggle(
                      "HOT",
                      Colors.redAccent,
                      _useHot,
                      () {
                        if (!canAccessHot) {
                          UnlockPackSheet.show(
                            context,
                            packId: 'tod_hot',
                            packTitle: s.todHotPackTitle,
                            onUnlocked: () {
                              _toggleDeck('HOT', false);
                            },
                          );
                        } else {
                          _toggleDeck('HOT', _useHot);
                        }
                      },
                      isLocked: !canAccessHot,
                    ),
                    _buildMiniToggle("CUSTOM", Colors.purpleAccent, _useCustom, () => _toggleDeck('CUSTOM', _useCustom)),
                  ],
                ),
                
                const SizedBox(height: 25),
                
                // --- LE TAPIS ANIMÉ ---
                _buildTapisPreview(),
                
                const SizedBox(height: 15),
                Center(child: TextButton.icon(onPressed: _openCardManager, icon: const Icon(Icons.add_box, color: Colors.purpleAccent), label: Text(s.todManageCustomCards(_customCards.length), style: const TextStyle(color: Colors.purpleAccent)))),
                
                const Spacer(),
                Text(s.todGameLengthTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10), padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
                  child: Column(
                    children: [
                      Text(s.todTurnsCount(_selectedTurns.toInt()), style: const TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.w900)),
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
                    child: Text(
                      s.todStartGameButton, 
                      style: const TextStyle(
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
  Widget _buildMiniToggle(
    String label,
    Color color,
    bool isActive,
    VoidCallback onTap, {
    bool isLocked = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.2) : Colors.black45,
          border: Border.all(
            color: isLocked ? Colors.redAccent.withValues(alpha: 0.7) : (isActive ? color : Colors.white24),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: isActive ? color : Colors.white54, fontWeight: FontWeight.bold, fontSize: 13)),
            if (isLocked) ...[
              const SizedBox(width: 4),
              const Icon(Icons.lock_rounded, size: 12, color: Colors.redAccent),
            ],
          ],
        ),
      ),
    );
  }

  // Composant : Le Tapis Animé
  // Composant : Le Tapis Animé
  Widget _buildTapisPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        double height = width / 2.5; 
        
        double cardWidth = 55; 
        double cardHeight = 85;

        List<String> activeDecks = [];
        if (_useSoft) activeDecks.add('SOFT');
        if (_useFun) activeDecks.add('FUN');
        if (_useHot) activeDecks.add('HOT');
        if (_useCustom) activeDecks.add('CUSTOM');

        return Hero(
          tag: 'tapis_hero', 
          child: Material(
            color: Colors.transparent,
            child: NeonTableMat(
              width: width,
              height: height,
              child: Stack(
                children: ['SOFT', 'FUN', 'HOT', 'CUSTOM'].map((deck) {
                  bool isActive = activeDecks.contains(deck);
                  int activeIndex = activeDecks.indexOf(deck);
                  
                  double leftPos = isActive 
                    ? ((width / (activeDecks.length + 1)) * (activeIndex + 1)) - (cardWidth / 2)
                    : (width / 2) - (cardWidth / 2); 
                  
                  double activeTopPos = (height - cardHeight) / 2;
                  double inactiveTopPos = height + 50.0;
                  
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
    final s = AppStrings.of(context);
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
                
              Text(_isCreating ? s.todNewCardTitle : s.todYourCustomCardsTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
              
              const SizedBox(width: 48), // Spacer pour centrer le titre
            ],
          ),
          const SizedBox(height: 20),
          
          // Le contenu change selon l'état _isCreating
          Expanded(
            child: _isCreating ? _buildCreateForm(s) : _buildCardsList(s),
          ),
        ],
      ),
    );
  }

  // --- VUE 1 : LA LISTE DES CARTES ---
  Widget _buildCardsList(AppStrings s) {
    if (widget.customCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.style, size: 60, color: Colors.white24),
            const SizedBox(height: 15),
            Text(s.todEmptyCustomCards, style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 30),
            _buildAddButton(s),
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
                  subtitle: Text(s.todCardTypeDisplay(card.type), style: const TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold)),
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
        _buildAddButton(s),
      ],
    );
  }

  Widget _buildAddButton(AppStrings s) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: Text(s.todCreateNewCardButton, style: const TextStyle(fontWeight: FontWeight.bold)),
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
  Widget _buildCreateForm(AppStrings s) {
    return Column(
      children: [
        TextField(
          controller: _contentController, 
          decoration: InputDecoration(
            labelText: s.todCustomContentLabel, 
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
            labelText: s.todCardTypeFieldLabel,
            filled: true, 
            fillColor: Colors.black45,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: [
            DropdownMenuItem(value: 'ACTION', child: Text(s.todActionLabel)), 
            DropdownMenuItem(value: 'VERITE', child: Text(s.todTruthLabel))
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
            child: Text(s.todSaveCardButton, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
          )
        )
      ],
    );
  }
}