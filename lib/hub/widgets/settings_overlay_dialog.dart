// lib/hub/widgets/settings_overlay_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:gameflix/l10n/app_strings.dart';
import 'package:gameflix/l10n/locale_controller.dart';
import 'package:gameflix/models/game_config.dart';
import 'package:gameflix/services/audio_service.dart';
import 'package:gameflix/shared/widgets/unlock_pack_sheet.dart';
import 'package:gameflix/state/access_control_provider.dart';

// --- CONSTANTE SUPPORT CENTRALISÉE ---

/// Adresse email officielle de support et de suggestions (facilement modifiable).
const String kSupportEmail = 'contact@gameflix.app';

/// Overlay de réglages plein écran (100% de l'écran) centré au milieu,
/// avec bouton de fermeture `✕` en haut à gauche et 5 sections :
/// 1. Volume Control (Slider maître + 2 toggles BGM / SFX)
/// 2. Language (Sélecteur FR / EN / ES)
/// 3. Manage My Subscription (Statut + Paywall + Restore Purchases)
/// 4. Suggest a Question (Modale de proposition d'idée de carte/gage)
/// 5. Contact Us (Copie/ouverture vers [kSupportEmail])
class SettingsOverlayDialog extends StatefulWidget {
  const SettingsOverlayDialog({super.key});

  /// Affiche l'overlay Réglages en plein écran (100% de la surface).
  static Future<void> show(BuildContext context) {
    AudioService.instance.playSfx(SoundEffect.click);
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Settings',
      barrierColor: Colors.black.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) => const SettingsOverlayDialog(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<SettingsOverlayDialog> createState() => _SettingsOverlayDialogState();
}

class _SettingsOverlayDialogState extends State<SettingsOverlayDialog> {
  final TextEditingController _promoCodeController = TextEditingController();

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleRedeemPromoCode(AppStrings strings) async {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) return;

    AudioService.instance.playSfx(SoundEffect.click);
    final success = await AccessControlProvider.instance.redeemPromoCode(code);
    if (!mounted) return;

    if (success) {
      AudioService.instance.playSfx(SoundEffect.victory);
      _promoCodeController.clear();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(strings.giftCodeSuccessMessage),
            backgroundColor: Colors.pinkAccent,
          ),
        );
    } else {
      AudioService.instance.playSfx(SoundEffect.buzzer);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(strings.giftCodeErrorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
    }
  }

  Future<void> _handleRestorePurchases(BuildContext context, AppStrings strings) async {
    AudioService.instance.playSfx(SoundEffect.click);
    final restored = await AccessControlProvider.instance.restorePurchases();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            restored ? strings.restoreSuccessMessage : strings.restoreEmptyMessage,
          ),
          backgroundColor: restored ? Colors.pinkAccent : Colors.orangeAccent,
        ),
      );
  }

  Future<void> _handleContactUs(BuildContext context, AppStrings strings) async {
    AudioService.instance.playSfx(SoundEffect.click);

    // 1. Copie de l'adresse de support dans le presse-papier
    await Clipboard.setData(const ClipboardData(text: kSupportEmail));
    if (!context.mounted) return;

    // 2. Notification visuelle claire à l'utilisateur
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(strings.contactCopiedMessage(kSupportEmail)),
          backgroundColor: Colors.cyanAccent.shade700,
        ),
      );
  }

  void _openSuggestQuestionDialog(BuildContext context) {
    AudioService.instance.playSfx(SoundEffect.click);
    showDialog<void>(
      context: context,
      builder: (_) => const SuggestQuestionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final localeCtrl = context.watch<LocaleController>();
    final accessCtrl = context.watch<AccessControlProvider>();
    final audio = AudioService.instance;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E20).withValues(alpha: 0.97),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Contenu principal centré au milieu de l'écran
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Titre principal
                      Text(
                        strings.settingsTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(color: Colors.cyanAccent, blurRadius: 14),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- SECTION 1 : VOLUME CONTROL ---
                      _buildSectionCard(
                        title: strings.volumeSectionTitle,
                        icon: Icons.volume_up_rounded,
                        accentColor: Colors.cyanAccent,
                        child: AnimatedBuilder(
                          animation: audio,
                          builder: (context, _) {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      strings.masterVolumeLabel,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Expanded(
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor: Colors.cyanAccent,
                                          inactiveTrackColor: Colors.white12,
                                          thumbColor: Colors.pinkAccent,
                                        ),
                                        child: Slider(
                                          value: audio.volume,
                                          min: 0.0,
                                          max: 1.0,
                                          onChanged: (val) => audio.setVolume(val),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        '${(audio.volume * 100).round()}%',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: Colors.cyanAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildAudioToggleChip(
                                        label: strings.bgmToggleLabel,
                                        icon: audio.isBgmEnabled
                                            ? Icons.music_note_rounded
                                            : Icons.music_off_rounded,
                                        isActive: audio.isBgmEnabled,
                                        activeColor: Colors.cyanAccent,
                                        onTap: () => audio.toggleBgmMute(),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildAudioToggleChip(
                                        label: strings.sfxToggleLabel,
                                        icon: audio.isSfxEnabled
                                            ? Icons.campaign_rounded
                                            : Icons.volume_off_rounded,
                                        isActive: audio.isSfxEnabled,
                                        activeColor: Colors.pinkAccent,
                                        onTap: () => audio.toggleSfxMute(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      // --- SECTION 2 : LANGUAGE (FR / EN / ES) ---
                      _buildSectionCard(
                        title: strings.languageSectionTitle,
                        icon: Icons.language_rounded,
                        accentColor: Colors.purpleAccent,
                        child: Row(
                          children: AppLocale.values.map((loc) {
                            final bool isSelected = localeCtrl.currentLocale == loc;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    AudioService.instance.playSfx(SoundEffect.click);
                                    localeCtrl.setLocale(loc);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.purpleAccent.withValues(alpha: 0.25)
                                          : Colors.white10,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.purpleAccent
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(loc.flag, style: const TextStyle(fontSize: 22)),
                                        const SizedBox(height: 4),
                                        Text(
                                          loc.label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : Colors.white60,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // --- SECTION 3 : MANAGE MY SUBSCRIPTION ---
                      _buildSectionCard(
                        title: strings.subscriptionSectionTitle,
                        icon: Icons.workspace_premium_rounded,
                        accentColor: Colors.pinkAccent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              accessCtrl.isSubscribed
                                  ? strings.subStatusActive
                                  : strings.subStatusFree,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: accessCtrl.isSubscribed
                                    ? Colors.amberAccent
                                    : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (!accessCtrl.isSubscribed) ...[
                              ElevatedButton.icon(
                                onPressed: () {
                                  UnlockPackSheet.show(
                                    context,
                                    packId: 'vip_all',
                                    packTitle: 'PASS PRO / SPICY',
                                    onUnlocked: () {},
                                  );
                                },
                                icon: const Icon(Icons.local_fire_department_rounded, color: Colors.white),
                                label: Text(
                                  strings.unlockProButton,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pinkAccent,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // --- ESPACE CADEAU SOUS PASSER EN PRO ---
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.amberAccent.withValues(alpha: 0.5),
                                    width: 1.2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.card_giftcard_rounded, color: Colors.amberAccent, size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          strings.giftCodeTitle,
                                          style: const TextStyle(
                                            color: Colors.amberAccent,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            key: const Key('gift_code_input'),
                                            controller: _promoCodeController,
                                            textCapitalization: TextCapitalization.characters,
                                            onSubmitted: (_) => _handleRedeemPromoCode(strings),
                                            decoration: InputDecoration(
                                              hintText: strings.giftCodeHint,
                                              hintStyle: const TextStyle(fontSize: 13, color: Colors.white38),
                                              filled: true,
                                              fillColor: const Color(0xFF131326),
                                              isDense: true,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          key: const Key('gift_code_button'),
                                          onPressed: () => _handleRedeemPromoCode(strings),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.amberAccent,
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Text(
                                            strings.giftCodeValidateButton,
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            OutlinedButton.icon(
                              onPressed: () => _handleRestorePurchases(context, strings),
                              icon: const Icon(Icons.restore_rounded, color: Colors.cyanAccent, size: 18),
                              label: Text(
                                strings.restorePurchasesButton,
                                style: const TextStyle(color: Colors.cyanAccent),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.cyanAccent),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // --- SECTION 4 : SUGGEST A QUESTION ---
                      _buildSectionCard(
                        title: strings.suggestQuestionSectionTitle,
                        icon: Icons.lightbulb_outline_rounded,
                        accentColor: Colors.amberAccent,
                        child: OutlinedButton.icon(
                          onPressed: () => _openSuggestQuestionDialog(context),
                          icon: const Icon(Icons.add_comment_rounded, color: Colors.amberAccent),
                          label: Text(
                            strings.suggestQuestionButton,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.amberAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // --- SECTION 5 : CONTACT US ---
                      _buildSectionCard(
                        title: strings.contactSectionTitle,
                        icon: Icons.mail_outline_rounded,
                        accentColor: Colors.greenAccent,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleContactUs(context, strings),
                          icon: const Icon(Icons.send_rounded, color: Colors.greenAccent),
                          label: Text(
                            '${strings.contactButton} ($kSupportEmail)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.greenAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Bouton croix (✕) en haut à gauche pour fermer l'overlay
            Positioned(
              top: 12,
              left: 16,
              child: IconButton(
                key: const Key('settings_close_button'),
                onPressed: () {
                  AudioService.instance.playSfx(SoundEffect.click);
                  Navigator.of(context).pop();
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white10,
                  side: const BorderSide(color: Colors.cyanAccent, width: 1.5),
                ),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.cyanAccent,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171730),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.45), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildAudioToggleChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? activeColor : Colors.white24,
            width: 1.3,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? activeColor : Colors.white38, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Boîte de dialogue néon permettant à un joueur de proposer une idée de question/gage.
class SuggestQuestionDialog extends StatefulWidget {
  const SuggestQuestionDialog({super.key});

  @override
  State<SuggestQuestionDialog> createState() => _SuggestQuestionDialogState();
}

class _SuggestQuestionDialogState extends State<SuggestQuestionDialog> {
  final TextEditingController _ideaController = TextEditingController();
  String _selectedGameId = 'tod';

  @override
  void dispose() {
    _ideaController.dispose();
    super.dispose();
  }

  Future<void> _submitSuggestion() async {
    final text = _ideaController.text.trim();
    if (text.isEmpty) return;

    final strings = AppStrings.read(context);
    final formattedMail =
        'To: $kSupportEmail\nSubject: [SUGGESTION GAMEFLIX] ($_selectedGameId)\n\n$text';

    // 1. Copie de la suggestion formatée dans le presse-papier
    await Clipboard.setData(ClipboardData(text: formattedMail));
    if (!mounted) return;

    // 2. Fermeture de la boîte de dialogue et confirmation SnackBar
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(strings.suggestionSentMessage),
          backgroundColor: Colors.amber.shade800,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final availableGames = GameRegistry.games.where((g) => !g.isLocked).toList();

    return Dialog(
      backgroundColor: const Color(0xFF16162E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.amberAccent, width: 1.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.suggestDialogTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.amberAccent,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            // 1. Sélecteur du jeu concerné
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGameId,
                  dropdownColor: const Color(0xFF1A1A30),
                  items: availableGames.map((g) {
                    return DropdownMenuItem<String>(
                      value: g.id,
                      child: Text(
                        strings.gameTitle(g.id, g.title),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedGameId = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Champ texte de la question / gage
            TextField(
              controller: _ideaController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: strings.suggestInputHint,
                filled: true,
                fillColor: Colors.black45,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Boutons Annuler / Envoyer
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    strings.cancelButton,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitSuggestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    strings.sendButton,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
