// lib/shared/widgets/procedural_neon_background.dart
import 'package:flutter/material.dart';

/// Arrière-plan procédural haute performance remplaçant les images bitmap lourdes.
///
/// Dessine un mesh gradient cyber-néon fluide et sombre composé de dégradés radiaux
/// superposés (Cyan, Magenta, Violet profond) avec un vignettage périphérique.
/// Rendu matériel accéléré fluide à 60/120 FPS sur tous les formats d'écran.
class ProceduralNeonBackground extends StatelessWidget {
  final Widget child;

  const ProceduralNeonBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _NeonMeshPainter(),
      child: child,
    );
  }
}

class _NeonMeshPainter extends CustomPainter {
  const _NeonMeshPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Fond sombre dégradé de base (Midnight Dark to Deep Indigo/Aubergine)
    final baseGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF050510),
        Color(0xFF0B0A1E),
        Color(0xFF130924),
      ],
      stops: [0.0, 0.5, 1.0],
    ).createShader(rect);

    final basePaint = Paint()..shader = baseGradient;
    canvas.drawRect(rect, basePaint);

    // 2. Halo lumineux Cyan néon (en haut à droite)
    final cyanCenter = Offset(size.width * 0.85, size.height * 0.15);
    final cyanRadius = size.width * 0.7;
    final cyanPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: 0.16),
          const Color(0xFF00E5FF).withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: cyanCenter, radius: cyanRadius));
    canvas.drawCircle(cyanCenter, cyanRadius, cyanPaint);

    // 3. Halo lumineux Magenta / Hot Pink néon (en bas à gauche)
    final magentaCenter = Offset(size.width * 0.15, size.height * 0.82);
    final magentaRadius = size.width * 0.75;
    final magentaPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF1493).withValues(alpha: 0.15),
          const Color(0xFFFF1493).withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: magentaCenter, radius: magentaRadius));
    canvas.drawCircle(magentaCenter, magentaRadius, magentaPaint);

    // 4. Halo d'ambiance Violet profond (au centre-gauche)
    final violetCenter = Offset(size.width * 0.35, size.height * 0.45);
    final violetRadius = size.width * 0.65;
    final violetPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF8A2BE2).withValues(alpha: 0.12),
          const Color(0xFF8A2BE2).withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: violetCenter, radius: violetRadius));
    canvas.drawCircle(violetCenter, violetRadius, violetPaint);

    // 5. Vignettage périphérique subtil pour maximiser le contraste des cartes et textes
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.1,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.25),
          Colors.black.withValues(alpha: 0.75),
        ],
        stops: const [0.4, 0.8, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignettePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
