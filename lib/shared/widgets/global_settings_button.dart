// lib/shared/widgets/global_settings_button.dart
import 'package:flutter/material.dart';
import 'package:gameflix/hub/widgets/settings_overlay_dialog.dart';
import 'package:gameflix/shared/widgets/game_rules_sheet.dart';

/// Décoration de fond standardisée (dégradé violet profond) pour tous les Lobbies.
const BoxDecoration kLobbyBackgroundDecoration = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF050515),
      Color(0xFF111122),
      Color(0xFF2B003B),
    ],
  ),
);

/// Bouton global de paramètres ("roue crantée" néon) ouvrant [SettingsOverlayDialog].
///
/// Utilisé de manière uniforme dans le Hub, tous les Lobbies, tous les Écrans de jeu
/// et tous les Scoreboards.
class GlobalSettingsButton extends StatelessWidget {
  final Color color;
  final double size;

  const GlobalSettingsButton({
    super.key,
    this.color = Colors.cyanAccent,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => SettingsOverlayDialog.show(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Icon(
            Icons.settings_outlined,
            color: color,
            size: size,
            shadows: [
              Shadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Construit l'AppBar standardisée pour tous les Lobbies :
/// - Titre "LOBBY" centré en majuscules avec la police Orbitron et lueur néon.
/// - Icônes uniformisées `[ ?, ⚙️ ]` en haut à droite.
PreferredSizeWidget buildUnifiedLobbyAppBar({
  required BuildContext context,
  required String gameId,
  Color accentColor = Colors.purpleAccent,
}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    elevation: 0,
    centerTitle: true,
    iconTheme: const IconThemeData(color: Colors.white),
    title: Text(
      'LOBBY',
      style: TextStyle(
        fontFamily: 'Orbitron',
        fontWeight: FontWeight.w900,
        fontSize: 22,
        color: Colors.white,
        letterSpacing: 3,
        shadows: [
          Shadow(
            color: accentColor.withValues(alpha: 0.65),
            blurRadius: 12,
          ),
        ],
      ),
    ),
    actions: [
      IconButton(
        icon: Icon(
          Icons.help_outline_rounded,
          color: accentColor,
          size: 25,
          shadows: [
            Shadow(
              color: accentColor.withValues(alpha: 0.45),
              blurRadius: 10,
            ),
          ],
        ),
        tooltip: 'Règles du jeu',
        onPressed: () => GameRulesSheet.show(
          context,
          DefaultGameRules.getRules(gameId),
        ),
      ),
      const GlobalSettingsButton(),
      const SizedBox(width: 8),
    ],
  );
}
