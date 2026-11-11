// lib/hub/gameflix_hub.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gameflix/hub/widgets/settings_overlay_dialog.dart';
import 'package:gameflix/l10n/app_strings.dart';
import 'package:gameflix/l10n/locale_controller.dart';
import 'package:gameflix/l10n/strings_shared.dart';
import 'package:gameflix/models/player.dart';
import 'package:gameflix/models/game_config.dart';
import 'package:gameflix/services/audio_service.dart';
import 'package:gameflix/services/ad_manager.dart';
import 'package:gameflix/shared/widgets/hub_banner_ad.dart';
import 'package:gameflix/shared/widgets/hub_in_wheel_ad_card.dart';
import 'package:gameflix/shared/widgets/pass_1h_countdown_badge.dart';
import 'package:gameflix/shared/widgets/procedural_neon_background.dart';
import 'package:gameflix/shared/widgets/unlock_pack_sheet.dart';
import 'package:gameflix/state/players_controller.dart';
import 'package:gameflix/state/access_control_provider.dart';

class GameFlixHub extends StatefulWidget {
  const GameFlixHub({super.key});
  @override
  State<GameFlixHub> createState() => _GameFlixHubState();
}

class _GameFlixHubState extends State<GameFlixHub> {
  @override
  void initState() {
    super.initState();
    AudioService.instance.init().then((_) {
      if (mounted) {
        AudioService.instance.playBgm();
      }
    });
    AdManager.instance.init();
    AccessControlProvider.instance.resetTemporaryUnlocks();
  }

  void _openPlayerManager() {
    AudioService.instance.playSfx(SoundEffect.click);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A30),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75, // Prend 75% de l'écran
          child: const PlayerManagerSheet(),
        ),
      ),
    );
  }

  void _openProPaywall() {
    AudioService.instance.playSfx(SoundEffect.click);
    UnlockPackSheet.show(
      context,
      packId: 'vip_all',
      packTitle: AppStrings.read(context).proSpicyPackTitle,
      onUnlocked: () {},
    );
  }

  /// Point d'entrée unique pour lancer un jeu :
  /// vérifie le nombre de joueurs puis passe des copies "session" au jeu.
  void _launchGame({
    int minPlayers = 0,
    int? maxPlayers,
    required Widget Function(List<Player> sessionPlayers) builder,
  }) {
    final controller = context.read<PlayersController>();
    final strings = AppStrings.read(context);
    final int count = controller.count;
    final bool tooFew = count < minPlayers;
    final bool tooMany = maxPlayers != null && count > maxPlayers;

    if (tooFew || tooMany) {
      final String message = maxPlayers == null
          ? strings.minPlayersError(minPlayers)
          : strings.minMaxPlayersError(minPlayers, maxPlayers);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      _openPlayerManager();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => builder(controller.sessionPlayers())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int playerCount = context.watch<PlayersController>().count;
    final localeCtrl = context.watch<LocaleController>();
    final bool isSubscribed = context.watch<AccessControlProvider>().isSubscribed;
    final strings = AppStrings.of(context);
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isWideScreen = screenWidth >= 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        toolbarHeight: 62,
        flexibleSpace: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF050510).withValues(alpha: 0.68),
                  const Color(0xFF050510).withValues(alpha: 0.22),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.65, 1.0],
              ),
            ),
          ),
        ),
        leadingWidth: 108,
        leading: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 14),
              // 1. Le sélecteur de langue (Drapeau FR / EN / ES)
              PopupMenuButton<AppLocale>(
                key: const Key('hub_language_selector'),
                padding: EdgeInsets.zero,
                tooltip: strings.languageSectionTitle,
                color: const Color(0xFF1A1A30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Colors.cyanAccent, width: 1.2),
                ),
                onSelected: (locale) {
                  AudioService.instance.playSfx(SoundEffect.click);
                  localeCtrl.setLocale(locale);
                },
                itemBuilder: (_) => AppLocale.values.map((loc) {
                  final bool selected = loc == localeCtrl.currentLocale;
                  return PopupMenuItem<AppLocale>(
                    value: loc,
                    child: Row(
                      children: [
                        Text(loc.flag, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Text(
                          loc.label,
                          style: TextStyle(
                            color: selected ? Colors.cyanAccent : Colors.white,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Text(
                    localeCtrl.flag,
                    style: const TextStyle(fontSize: 21),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 2. Le bouton joueurs (style lignes fines sans boîte + micro-halo)
              IconButton(
                key: const Key('hub_players_button'),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.all(4),
                ),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      color: Colors.cyanAccent,
                      size: 25,
                      shadows: [
                        Shadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.45),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    if (playerCount > 0)
                      Positioned(
                        right: -6,
                        top: -5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E0E24),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFF2E7E),
                              width: 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF2E7E).withValues(alpha: 0.45),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Text(
                            '$playerCount',
                            style: const TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: _openPlayerManager,
              ),
            ],
          ),
        ),
        // 3. Responsive Header : Icône "G" détourée sur mobile (< 600px), titre textuel "gameflix" sur grand écran (>= 600px)
        title: isWideScreen
            ? const FittedBox(
                fit: BoxFit.scaleDown,
                child: GameFlixTextLogo(
                  key: Key('hub_header_title_text'),
                  fontSize: 24,
                ),
              )
            : Container(
                key: const Key('hub_header_logo'),
                height: 36,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF2E7E).withValues(alpha: 0.18),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/header_logo.png',
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const GameFlixTextLogo(fontSize: 20),
                ),
              ),
        centerTitle: true,
        actions: [
          // Badge néon compte à rebours si le Pass Soirée 1H est actif
          const Center(
            child: Pass1hCountdownBadge(),
          ),
          const SizedBox(width: 6),

          // 4. Élément Pro / Pro-actif ultra-minimaliste : Couronne à lignes fines sans texte ni boîte
          Center(
            child: GestureDetector(
              key: const Key('hub_pro_badge'),
              behavior: HitTestBehavior.opaque,
              onTap: _openProPaywall,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: ProCrownIcon(
                  isSubscribed: isSubscribed,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 5. Bouton Réglages (icône engrenage à lignes fines sans boîte + micro-halo)
          Center(
            child: GestureDetector(
              key: const Key('hub_settings_button'),
              behavior: HitTestBehavior.opaque,
              onTap: () => SettingsOverlayDialog.show(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Icon(
                  Icons.settings_outlined,
                  color: Colors.cyanAccent,
                  size: 23,
                  shadows: [
                    Shadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.45),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: ProceduralNeonBackground(
        child: SafeArea(
          child: _buildCatalogue(strings),
        ),
      ),
    );
  }

  Widget _buildCatalogue(AppStrings strings) {
    final accessCtrl = context.watch<AccessControlProvider>();
    final bool showInWheelAd = !accessCtrl.isSubscribed && !accessCtrl.isPass1hActive;

    // 1. On garde ton empreinte verticale fixe de 170px qui t'allait bien.
    const double fixedRenderHeight = 170.0;

    // 2. Ton image fait 1000x450, soit un ratio hauteur/largeur de 0.45.
    // Pour calculer la largeur parfaite pour que l'image tienne, on fait : Hauteur / Ratio.
    // Largeur = 170.0 / 0.45 = ~377.78px.
    const double targetImageRatio = 0.45; // Height is 0.45 of Width
    double calculatedCardWidth = fixedRenderHeight / targetImageRatio; // Target width based on target height.

    final List<Widget> wheelItems = [];
    for (int i = 0; i < GameRegistry.games.length; i++) {
      final game = GameRegistry.games[i];
      wheelItems.add(
        _buildWheelCard(
          subtitle: strings.gameSubtitle(game.id, game.subtitle),
          newBadgeLabel: strings.newBadge,
          imagePath: strings.gameBannerPath(game.id, game.bannerPath),
          isNew: game.isNew,
          isLocked: game.isLocked,
          cardRenderHeight: fixedRenderHeight,
          cardRenderWidth: calculatedCardWidth,
          onTap: () => _launchGame(
            minPlayers: game.minPlayers,
            maxPlayers: game.maxPlayers,
            builder: game.builder,
          ),
        ),
      );

      // Insertion de la carte sponsorisée juste après le 4e jeu (index 3)
      if (showInWheelAd && i == 3) {
        wheelItems.add(
          HubInWheelAdCard(
            cardRenderHeight: fixedRenderHeight,
            cardRenderWidth: calculatedCardWidth,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 20, bottom: 10),
          child: Text(
            strings.selectGame,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: ListWheelScrollView(
            // itemExtent reste sur la hauteur, c'est l'empreinte verticale dans la roue.
            itemExtent: fixedRenderHeight + 30, // repeatable vertical spacing.
            physics: const BouncingScrollPhysics(),
            perspective: 0.005,
            diameterRatio: 2.0,
            squeeze: 1.05,
            children: wheelItems,
          ),
        ),
        const HubBannerAd(),
      ],
    );
  }

  Widget _buildWheelCard({
    required String subtitle,
    required String newBadgeLabel,
    String? imagePath, // Restauré : Nullable
    bool isLocked = false, // Restauré : Par défaut false
    bool isNew = false, // Le nouveau badge
    required double cardRenderHeight,
    required double cardRenderWidth,
    required VoidCallback onTap,
  }) {
    final double dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 3.0);
    final int cacheWidth = (cardRenderWidth * dpr).round();

    return RepaintBoundary(
      child: GestureDetector(
        // Si la carte est verrouillée, on désactive le clic
        onTap: isLocked
            ? null
            : () {
                AudioService.instance.playSfx(SoundEffect.click);
                onTap();
              },
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
                border: Border.all(
                  color: Colors.purpleAccent.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
                image: imagePath != null
                    ? DecorationImage(
                        image: ResizeImage.resizeIfNeeded(
                          cacheWidth,
                          null,
                          AssetImage(imagePath),
                        ),
                        fit: BoxFit.cover,
                        colorFilter: isLocked
                            ? ColorFilter.mode(
                                Colors.black.withValues(alpha: 0.7),
                                BlendMode.darken,
                              )
                            : null,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  // --- LE TEXTE : TITRE ET SOUS-TITRE ---
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
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
                          colors: [
                            Colors.black.withValues(alpha: 0.9),
                            Colors.transparent,
                          ],
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
                    const Center(
                      child: Icon(Icons.lock_outline, color: Colors.white54, size: 50),
                    ),
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
                        BoxShadow(
                          color: Colors.pinkAccent.withValues(alpha: 0.6),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      newBadgeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
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

// --- Player Manager Pop-up ---
// Lit et modifie le roster uniquement via PlayersController.
class PlayerManagerSheet extends StatefulWidget {
  const PlayerManagerSheet({super.key});

  @override
  State<PlayerManagerSheet> createState() => _PlayerManagerSheetState();
}

class _PlayerManagerSheetState extends State<PlayerManagerSheet> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedGender = 'M';
  Set<String> _selectedTargets = {'F'}; // Par défaut : M -> F

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Sélectionne le genre du joueur et pré-coche automatiquement le genre opposé en cible.
  void _selectGender(String gender) {
    setState(() {
      _selectedGender = gender;
      _selectedTargets = Set<String>.from(Player.defaultTargetsForGender(gender));
    });
  }

  /// Active/désactive une cible ('M' ou 'F') en garantissant qu'au moins une cible reste cochée.
  void _toggleTarget(String targetGender) {
    setState(() {
      if (_selectedTargets.contains(targetGender)) {
        if (_selectedTargets.length > 1) {
          _selectedTargets.remove(targetGender);
        }
      } else {
        _selectedTargets.add(targetGender);
      }
    });
  }

  void _addPlayer() {
    final strings = AppStrings.read(context);
    final result = context.read<PlayersController>().add(
          _nameController.text,
          _selectedGender,
          attractedTo: Set<String>.from(_selectedTargets),
        );

    switch (result) {
      case AddPlayerResult.added:
        _nameController.clear(); // On vide le champ pour taper le pote suivant direct
      case AddPlayerResult.duplicate:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.duplicateNameError),
            backgroundColor: Colors.redAccent,
          ),
        );
      case AddPlayerResult.emptyName:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayersController>();
    final strings = AppStrings.of(context);
    final players = controller.players;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Text(
            strings.playersTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),

          // 1. Choix du genre du joueur (Garçon / Fille)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectGender('M'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedGender == 'M'
                          ? Colors.blueAccent.withValues(alpha: 0.3)
                          : Colors.white10,
                      border: Border.all(
                        color: _selectedGender == 'M'
                            ? Colors.blueAccent
                            : Colors.transparent,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        strings.boyLabel,
                        style: TextStyle(
                          color: _selectedGender == 'M'
                              ? Colors.blueAccent
                              : Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectGender('F'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedGender == 'F'
                          ? Colors.pinkAccent.withValues(alpha: 0.3)
                          : Colors.white10,
                      border: Border.all(
                        color: _selectedGender == 'F'
                            ? Colors.pinkAccent
                            : Colors.transparent,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        strings.girlLabel,
                        style: TextStyle(
                          color: _selectedGender == 'F'
                              ? Colors.pinkAccent
                              : Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. Sélecteur cumulable des cibles acceptées pour les gages rapprochés
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  strings.targetsPrompt,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  key: const Key('target_toggle_M'),
                  onTap: () => _toggleTarget('M'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedTargets.contains('M')
                          ? Colors.blueAccent.withValues(alpha: 0.25)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedTargets.contains('M')
                            ? Colors.blueAccent
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        strings.targetBoys,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _selectedTargets.contains('M')
                              ? Colors.blueAccent
                              : Colors.white38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  key: const Key('target_toggle_F'),
                  onTap: () => _toggleTarget('F'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedTargets.contains('F')
                          ? Colors.pinkAccent.withValues(alpha: 0.25)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedTargets.contains('F')
                            ? Colors.pinkAccent
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        strings.targetGirls,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _selectedTargets.contains('F')
                              ? Colors.pinkAccent
                              : Colors.white38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Saisie du prénom + bouton Ajouter
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  onSubmitted: (_) => _addPlayer(),
                  decoration: InputDecoration(
                    hintText: strings.firstNameHint,
                    filled: true,
                    fillColor: Colors.black45,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: _addPlayer,
                icon: const Icon(Icons.add_circle, size: 45, color: Colors.cyanAccent),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. Liste des joueurs avec badge de cible cliquable à la volée
          Expanded(
            child: players.isEmpty
                ? Center(
                    child: Text(
                      strings.emptyPlayersMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, i) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Text(
                            players[i].gender == 'M' ? '♂' : '♀',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: players[i].gender == 'M'
                                  ? Colors.blueAccent
                                  : Colors.pinkAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              players[i].name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // Badge discret cliquable pour basculer les cibles à la volée
                          GestureDetector(
                            key: Key('player_target_badge_$i'),
                            onTap: () => controller.cyclePlayerTargets(i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purpleAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.purpleAccent.withValues(alpha: 0.6),
                                ),
                              ),
                              child: Text(
                                players[i].targetBadgeLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyanAccent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => controller.removeAt(i),
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

/// Titre textuel de la nouvelle identité visuelle : "game" en blanc pur et "flix"
/// en dégradé néon (Rose -> Violet -> Cyan) avec la police géométrique étendue Orbitron.
class GameFlixTextLogo extends StatelessWidget {
  final double fontSize;

  const GameFlixTextLogo({
    super.key,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontFamily: 'Orbitron',
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: fontSize * 0.06,
      height: 1.0,
    );

    return Transform.scale(
      scaleX: 1.08,
      scaleY: 1.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            'game',
            style: baseStyle.copyWith(
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.white.withValues(alpha: 0.18),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                Color(0xFFFF2E7E),
                Color(0xFFC850FF),
                Color(0xFF00E5FF),
              ],
              stops: [0.0, 0.52, 1.0],
            ).createShader(bounds),
            child: Text(
              'flix',
              style: baseStyle.copyWith(
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: const Color(0xFFC850FF).withValues(alpha: 0.35),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icône minimaliste "Pro / Pro-actif" dessinée exclusivement en lignes fines,
/// sans texte ni conteneur-pilule.
///
/// - Non-abonné ([isSubscribed] == false) : contour fin blanc/rose discret.
/// - Abonné ([isSubscribed] == true) : contour fin en dégradé néon lumineux avec
///   micro-halo et éclat supérieur.
class ProCrownIcon extends StatelessWidget {
  final bool isSubscribed;
  final double size;

  const ProCrownIcon({
    super.key,
    required this.isSubscribed,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FineLineCrownPainter(isSubscribed: isSubscribed),
      ),
    );
  }
}

class _FineLineCrownPainter extends CustomPainter {
  final bool isSubscribed;

  const _FineLineCrownPainter({required this.isSubscribed});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // Tracés géométriques de la couronne minimaliste à lignes fines
    final crownPath = Path()
      ..moveTo(w * 0.16, h * 0.74)
      ..lineTo(w * 0.10, h * 0.36)
      ..lineTo(w * 0.33, h * 0.54)
      ..lineTo(w * 0.50, h * 0.22)
      ..lineTo(w * 0.67, h * 0.54)
      ..lineTo(w * 0.90, h * 0.36)
      ..lineTo(w * 0.84, h * 0.74)
      ..close();

    // Ligne de base fine détachée sous la couronne
    final baseLinePath = Path()
      ..moveTo(w * 0.19, h * 0.86)
      ..lineTo(w * 0.81, h * 0.86);

    final shader = isSubscribed
        ? const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              Color(0xFFFF2E7E),
              Color(0xFFFFD54F),
              Color(0xFF00E5FF),
            ],
            stops: [0.0, 0.5, 1.0],
          ).createShader(rect)
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.88),
              const Color(0xFFFF6EC7).withValues(alpha: 0.82),
            ],
          ).createShader(rect);

    // 1. Micro-halo lumineux
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSubscribed ? 2.6 : 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = shader
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        isSubscribed ? 4.5 : 2.0,
      );

    canvas.drawPath(crownPath, glowPaint);
    canvas.drawPath(baseLinePath, glowPaint);

    // 2. Trait fin principal
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSubscribed ? 1.75 : 1.55
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = shader;

    canvas.drawPath(crownPath, strokePaint);
    canvas.drawPath(baseLinePath, strokePaint);

    // 3. Si Pro Actif : petit éclat minimaliste à 4 branches au sommet central
    if (isSubscribed) {
      final cx = w * 0.50;
      final cy = h * 0.10;
      final r = w * 0.065;
      final sparklePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF00E5FF);

      canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), sparklePaint);
      canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy + r), sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FineLineCrownPainter oldDelegate) {
    return oldDelegate.isSubscribed != isSubscribed;
  }
}
