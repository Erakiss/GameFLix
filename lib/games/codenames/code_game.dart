// lib/games/codenames/code_game.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'dart:math'; 
import 'package:auto_size_text/auto_size_text.dart';

import 'package:gameflix/models/player.dart';
import 'package:gameflix/games/codenames/code_lobby.dart'; 
import 'package:gameflix/games/codenames/code_scoreboard.dart';

class CodeGameScreen extends StatefulWidget {
  final List<BoardWord> board;
  final List<Player> redTeam;
  final List<Player> blueTeam;
  final String startingTeam;
  final bool isExpress;

  const CodeGameScreen({super.key, required this.board, required this.redTeam, required this.blueTeam, required this.startingTeam, required this.isExpress});

  @override
  State<CodeGameScreen> createState() => _CodeGameScreenState();
}

class _CodeGameScreenState extends State<CodeGameScreen> {
  late String _currentTurn;
  int _redRemaining = 0;
  int _blueRemaining = 0;

  bool _isSpyTurn = true;          
  bool _spyGridRevealed = false;   
  bool _isTransitioning = false;   

  String _overlayMessage = "";   
  Color _overlayColor = Colors.transparent;

  final Color _bgDark = const Color(0xFF050515);
  final Color _cardDark = const Color(0xFF111122);
  final Color _neonRed = Colors.redAccent;
  final Color _neonBlue = Colors.cyanAccent; 

  @override
  void initState() {
    super.initState();
    _currentTurn = widget.startingTeam;
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    for (var word in widget.board) {
      if (word.teamColor == "RED") _redRemaining++;
      if (word.teamColor == "BLUE") _blueRemaining++;
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _endTurn() {
    setState(() {
      _currentTurn = _currentTurn == "RED" ? "BLUE" : "RED";
      _isSpyTurn = true; 
      _spyGridRevealed = false;
    });
  }

  void _revealWord(BoardWord word) {
    if (word.isRevealed || _isTransitioning) return;

    setState(() {
      word.isRevealed = true; 

      if (word.teamColor == "RED") _redRemaining--;
      if (word.teamColor == "BLUE") _blueRemaining--;
    });

    if (word.teamColor == "ASSASSIN") {
      setState(() {
        _isTransitioning = true; 
        _overlayMessage = "SYSTÈME COMPROMIS\nÉCHEC CRITIQUE";
        _overlayColor = Colors.redAccent;
      });
      Future.delayed(const Duration(seconds: 2), () { 
        if (!mounted) return;
        String winner = _currentTurn == "RED" ? "BLUE" : "RED";
        _goToScoreboard(winner, "L'ASSASSIN A ÉTÉ TROUVÉ !");
      });
      return;
    }

    if (_redRemaining == 0) {
      _isTransitioning = true;
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        _goToScoreboard("RED", "TOUS LES MOTS ROUGES ONT ÉTÉ TROUVÉS !");
      });
      return;
    }
    if (_blueRemaining == 0) {
      _isTransitioning = true;
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        _goToScoreboard("BLUE", "TOUS LES MOTS CYBER-BLEUS ONT ÉTÉ TROUVÉS !");
      });
      return;
    }

    if (word.teamColor != _currentTurn) {
      setState(() {
        _isTransitioning = true; 
        if (word.teamColor == "NEUTRAL") {
          _overlayMessage = "CIBLE NEUTRE\nFIN DE TRANSMISSION";
          _overlayColor = Colors.white;
        } else {
          _overlayMessage = "FIREWALL ENNEMI\nACCÈS REFUSÉ";
          _overlayColor = word.teamColor == "RED" ? _neonRed : _neonBlue;
        }
      });
      
      Future.delayed(const Duration(seconds: 2), () { 
        if (!mounted) return;
        setState(() {
          _isTransitioning = false; 
          _overlayMessage = ""; 
        });
        _endTurn(); 
      });
    }
  }

  void _goToScoreboard(String winner, String reason) {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => CodeScoreboardScreen(winner: winner, reason: reason, redTeam: widget.redTeam, blueTeam: widget.blueTeam))
    );
  }

  Color _getColorForTeam(String teamColor) {
    switch (teamColor) {
      case "RED": return _neonRed;
      case "BLUE": return _neonBlue;
      case "ASSASSIN": return Colors.red; 
      default: return Colors.white54; 
    }
  }

  Widget _buildLockScreen({required String title, required String subtitle, required String btnText, required VoidCallback onConfirm}) {
    Color activeColor = _currentTurn == "RED" ? _neonRed : _neonBlue;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: activeColor.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 5)]
              ),
              child: Icon(Icons.fingerprint, size: 70, color: activeColor), 
            ),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: activeColor, letterSpacing: 3)),
            const SizedBox(height: 5),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.white70, fontStyle: FontStyle.italic)),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: activeColor.withValues(alpha: 0.1), 
                side: BorderSide(color: activeColor, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              child: Text(btnText, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: activeColor, letterSpacing: 1.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid({required bool isSpyView}) {
    final int columns = widget.isExpress ? 4 : 5;
    final int rows = widget.isExpress ? 4 : 5;
    const double spacing = 10.0; 

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cellWidth = (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
        final double cellHeight = (constraints.maxHeight - ((rows - 1) * spacing)) / rows;
        final double dynamicAspectRatio = cellWidth / cellHeight;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: dynamicAspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: widget.board.length,
          itemBuilder: (context, index) {
            final word = widget.board[index];
            bool showColor = isSpyView || word.isRevealed;
            Color teamBaseColor = _getColorForTeam(word.teamColor);

            return TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: showColor ? pi : 0),
              duration: const Duration(milliseconds: 600), 
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                bool isFront = value < (pi / 2);
                
                Widget faceHidden = Container(
                  decoration: BoxDecoration(
                    color: _cardDark, 
                    borderRadius: BorderRadius.circular(12), 
                    border: Border.all(color: Colors.white10, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 5, offset: const Offset(0, 4))]
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: AutoSizeText(word.word, textAlign: TextAlign.center, maxLines: 1, minFontSize: 6, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white70)),
                    ),
                  ),
                );

                Widget faceRevealed = Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi), 
                  child: Container(
                    decoration: BoxDecoration(
                      color: word.teamColor == "ASSASSIN" ? Colors.black : teamBaseColor.withValues(alpha: 0.15), 
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: teamBaseColor, width: word.teamColor == "ASSASSIN" ? 3 : 2),
                      boxShadow: (word.teamColor != "NEUTRAL") ? [BoxShadow(color: teamBaseColor.withValues(alpha: 0.4), blurRadius: 15, spreadRadius: 2)] : [],
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: word.teamColor == "ASSASSIN"
                          ? Column( 
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                                Flexible(
                                  child: AutoSizeText(word.word, textAlign: TextAlign.center, maxLines: 1, minFontSize: 6, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.redAccent, letterSpacing: 2)),
                                ),
                              ],
                            )
                          : AutoSizeText(
                              word.word,
                              textAlign: TextAlign.center, maxLines: 1, minFontSize: 6,
                              style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2,
                                color: word.teamColor == "NEUTRAL" ? Colors.white54 : teamBaseColor,
                                decoration: word.isRevealed && isSpyView ? TextDecoration.lineThrough : null, 
                              ),
                            ),
                      ),
                    ),
                  ),
                );

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(value),
                  child: GestureDetector(
                    onTap: () {
                      if (!isSpyView && !word.isRevealed && !_isTransitioning) {
                        _revealWord(word);
                      }
                    },
                    child: isFront ? faceHidden : faceRevealed,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentSpyName = _currentTurn == "RED" ? widget.redTeam.first.name : widget.blueTeam.first.name;
    Color turnColor = _currentTurn == "RED" ? _neonRed : _neonBlue;
    String teamText = _currentTurn == "RED" ? "ROUGE" : "BLEU";

    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: () {
          if (_isSpyTurn) {
            if (!_spyGridRevealed) {
              return _buildLockScreen(
                title: "TOUR ESPION $teamText",
                subtitle: "Autorisation requise pour $currentSpyName. Sécurisez le périmètre.",
                btnText: "DÉVERROUILLER",
                onConfirm: () => setState(() => _spyGridRevealed = true),
              );
            } 
            else {
              return Padding(
                padding: const EdgeInsets.all(15), 
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.radar, color: turnColor),
                            const SizedBox(width: 10),
                            Text("RÉSEAU ESPION $teamText", style: TextStyle(color: turnColor, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _isSpyTurn = false), 
                          icon: const Icon(Icons.wifi_tethering_off, color: Colors.white, size: 18),
                          label: const Text("TRANSMETTRE", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
                          style: ElevatedButton.styleFrom(backgroundColor: turnColor, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Expanded(child: Center(child: _buildGrid(isSpyView: true))),
                  ],
                ),
              );
            }
          } 
          else {
            return Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(color: _cardDark, borderRadius: BorderRadius.circular(10), border: Border.all(color: _neonRed, width: 2), boxShadow: [BoxShadow(color: _neonRed.withValues(alpha: 0.2), blurRadius: 10)]),
                        child: Text("CIBLES ROUGE : $_redRemaining", style: TextStyle(color: _neonRed, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
                      ),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                        decoration: BoxDecoration(
                          color: turnColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: turnColor, width: 2),
                          boxShadow: [BoxShadow(color: turnColor.withValues(alpha: 0.5), blurRadius: 15)]
                        ),
                        child: Text("PIRATAGE $teamText", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2, shadows: [Shadow(color: turnColor, blurRadius: 5)])),
                      ),
                      
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                            decoration: BoxDecoration(color: _cardDark, borderRadius: BorderRadius.circular(10), border: Border.all(color: _neonBlue, width: 2), boxShadow: [BoxShadow(color: _neonBlue.withValues(alpha: 0.2), blurRadius: 10)]),
                            child: Text("CIBLES BLEU : $_blueRemaining", style: TextStyle(color: _neonBlue, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
                          ),
                          const SizedBox(width: 15),
                          
                          // MODIFICATION ICI : Flèche droite intuitive au lieu du bouton Power !
                          Container(
                            decoration: BoxDecoration(shape: BoxShape.circle, color: _cardDark, border: Border.all(color: Colors.white38)),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_forward, color: Colors.white),
                              tooltip: "Fin de transmission",
                              onPressed: _isTransitioning ? null : _endTurn, 
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(child: _buildGrid(isSpyView: false)),
                        
                        if (_isTransitioning && _overlayMessage.isNotEmpty)
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0.5, end: 1.0),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                  decoration: BoxDecoration(
                                    color: _bgDark.withValues(alpha: 0.9), 
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _overlayColor, width: 3),
                                    boxShadow: [BoxShadow(color: _overlayColor.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 10)]
                                  ),
                                  child: Text(
                                    _overlayMessage,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: _overlayColor,
                                      letterSpacing: 3,
                                      height: 1.3,
                                      shadows: [Shadow(color: _overlayColor, blurRadius: 10)]
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        }()
      ),
    );
  }
}