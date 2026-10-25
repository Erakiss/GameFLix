// lib/shared/widgets/neon_volume_control.dart
import 'package:flutter/material.dart';
import 'package:gameflix/services/audio_service.dart';

/// Contrôle de volume néon compact intégré dans l'AppBar :
/// icône haut-parleur pour Mute/Unmute + 5 barres verticales de volume.
class NeonVolumeControl extends StatelessWidget {
  const NeonVolumeControl({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = AudioService.instance;

    return AnimatedBuilder(
      animation: audio,
      builder: (context, _) {
        final bool isMuted = audio.isMuted;
        final int activeBars = isMuted ? 0 : audio.volumeLevel;

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Bouton Mute / Unmute (icône haut-parleur)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                isMuted ? Icons.volume_off : Icons.volume_up,
                color: isMuted ? Colors.white38 : Colors.cyanAccent,
                size: 22,
                shadows: isMuted
                    ? null
                    : const [
                        Shadow(color: Colors.cyanAccent, blurRadius: 8),
                      ],
              ),
              tooltip: isMuted ? 'Activer le son' : 'Couper le son',
              onPressed: () => audio.toggleMute(),
            ),
            const SizedBox(width: 6),

            // 2. Les 5 barres verticales de l'égaliseur (de hauteur croissante)
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(5, (index) {
                final int barLevel = index + 1;
                final bool isActive = !isMuted && barLevel <= activeBars;
                final double barHeight = 6.0 + (index * 3.0); // 6px, 9px, 12px, 15px, 18px

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => audio.setVolumeLevel(barLevel),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 3.5,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.cyanAccent : Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.cyanAccent.withValues(alpha: 0.6),
                                  blurRadius: 4,
                                  spreadRadius: 0.5,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }
}
