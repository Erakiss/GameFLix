// lib/shared/widgets/neon_volume_control.dart
import 'package:flutter/material.dart';
import 'package:gameflix/l10n/app_strings.dart';
import 'package:gameflix/services/audio_service.dart';

/// Contrôle de volume néon compact destiné aux AppBar des mini-jeux :
/// affiche l'état du son et ouvre au tap un mini-popover néon contenant
/// le Slider de volume maître et les 2 toggles BGM / SFX reliés à [AudioService].
class NeonVolumeControl extends StatelessWidget {
  const NeonVolumeControl({super.key});

  void _openVolumePopover(BuildContext context) {
    AudioService.instance.playSfx(SoundEffect.click);
    showDialog<void>(
      context: context,
      builder: (_) => const NeonVolumePopoverDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = AudioService.instance;

    return AnimatedBuilder(
      animation: audio,
      builder: (context, _) {
        final bool isMuted = audio.isMuted;
        final int activeBars = isMuted ? 0 : audio.volumeLevel;

        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _openVolumePopover(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A30).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isMuted
                      ? Colors.white24
                      : Colors.cyanAccent.withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: isMuted
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.25),
                          blurRadius: 8,
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Icône haut-parleur néon
                  Icon(
                    isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: isMuted ? Colors.white38 : Colors.cyanAccent,
                    size: 20,
                    shadows: isMuted
                        ? null
                        : const [
                            Shadow(color: Colors.cyanAccent, blurRadius: 8),
                          ],
                  ),
                  const SizedBox(width: 6),

                  // 2. Indicateur visuel des 5 barres verticales
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(5, (index) {
                      final int barLevel = index + 1;
                      final bool isActive = !isMuted && barLevel <= activeBars;
                      final double barHeight = 5.0 + (index * 2.5);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.2),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 3.0,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.cyanAccent : Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Mini-popover / Dialog néon permettant de régler en temps réel :
/// 1. Le Slider de volume maître global.
/// 2. Le toggle On/Off de la musique (BGM).
/// 3. Le toggle On/Off des effets sonores (SFX).
class NeonVolumePopoverDialog extends StatelessWidget {
  const NeonVolumePopoverDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = AudioService.instance;
    final strings = AppStrings.of(context);

    return Dialog(
      backgroundColor: const Color(0xFF141428),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Colors.cyanAccent, width: 1.8),
      ),
      child: AnimatedBuilder(
        animation: audio,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. En-tête du mini-panneau
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.equalizer_rounded, color: Colors.cyanAccent, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          strings.volumeSectionTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Slider du Volume Maître
                Row(
                  children: [
                    Icon(
                      audio.volume <= 0.0 ? Icons.volume_mute_rounded : Icons.volume_up_rounded,
                      color: Colors.cyanAccent,
                      size: 22,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.cyanAccent,
                          inactiveTrackColor: Colors.white12,
                          thumbColor: Colors.pinkAccent,
                          overlayColor: Colors.pinkAccent.withValues(alpha: 0.2),
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
                      width: 42,
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
                const SizedBox(height: 10),

                // 3. Toggle Musique (BGM)
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  dense: true,
                  activeThumbColor: Colors.cyanAccent,
                  activeTrackColor: Colors.cyanAccent.withValues(alpha: 0.35),
                  secondary: Icon(
                    audio.isBgmEnabled ? Icons.music_note_rounded : Icons.music_off_rounded,
                    color: audio.isBgmEnabled ? Colors.cyanAccent : Colors.white38,
                  ),
                  title: Text(
                    strings.bgmToggleLabel,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  value: audio.isBgmEnabled,
                  onChanged: (enabled) => audio.setBgmMuted(!enabled),
                ),

                // 4. Toggle Effets Sonores (SFX)
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  dense: true,
                  activeThumbColor: Colors.pinkAccent,
                  activeTrackColor: Colors.pinkAccent.withValues(alpha: 0.35),
                  secondary: Icon(
                    audio.isSfxEnabled ? Icons.campaign_rounded : Icons.volume_off_rounded,
                    color: audio.isSfxEnabled ? Colors.pinkAccent : Colors.white38,
                  ),
                  title: Text(
                    strings.sfxToggleLabel,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  value: audio.isSfxEnabled,
                  onChanged: (enabled) => audio.setSfxMuted(!enabled),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
