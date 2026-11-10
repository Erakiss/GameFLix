// lib/shared/widgets/neon_table_mat.dart
import 'package:flutter/material.dart';

/// Tapis de jeu procédural/vectoriel cyber-néon pour les jeux de cartes.
///
/// Remplace les images bitmap fixes et garantit que les liserés et halos
/// lumineux ne sont jamais tronqués ni déformés, quel que soit le ratio d'écran.
class NeonTableMat extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget? child;
  final EdgeInsetsGeometry padding;

  const NeonTableMat({
    super.key,
    this.width,
    this.height,
    this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        // Dégradé feutrine sombre cyber
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF09081C),
            Color(0xFF060614),
            Color(0xFF0B0920),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.5,
        ),
        boxShadow: [
          // Halo néon Magenta / Violet à gauche
          BoxShadow(
            color: const Color(0xFFFF2A85).withValues(alpha: 0.35),
            blurRadius: 22,
            spreadRadius: 1,
            offset: const Offset(-4, 0),
          ),
          // Halo néon Cyan électrique à droite
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
            blurRadius: 22,
            spreadRadius: 1,
            offset: const Offset(4, 0),
          ),
          // Ombre de profondeur sombre sous le tapis
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 25,
            spreadRadius: 4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Décoration / filigrane vectoriel feutré au centre du tapis
            CustomPaint(
              size: Size.infinite,
              painter: const _TableMatTexturePainter(),
            ),
            ?child,
          ],
        ),
      ),
    );
  }
}

class _TableMatTexturePainter extends CustomPainter {
  const _TableMatTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);

    // 1. Double liseré néon interne le long des bords (Magenta à gauche -> Cyan à droite)
    final innerRect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = const LinearGradient(
        colors: [
          Color(0x66FF2A85),
          Color(0x228A2BE2),
          Color(0x6600E5FF),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(innerRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(14)),
      borderPaint,
    );

    // 2. Halo subtil au centre pour mettre en valeur les cartes
    final centerGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF8A2BE2).withValues(alpha: 0.08),
          const Color(0xFF00E5FF).withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.45));

    canvas.drawCircle(center, size.width * 0.45, centerGlowPaint);

    // 3. Filigrane de table de jeu : losange / losanges concentriques élégants
    final diamondPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.035);

    final double dW = size.width * 0.22;
    final double dH = size.height * 0.38;

    final path = Path()
      ..moveTo(center.dx, center.dy - dH)
      ..lineTo(center.dx + dW, center.dy)
      ..lineTo(center.dx, center.dy + dH)
      ..lineTo(center.dx - dW, center.dy)
      ..close();

    canvas.drawPath(path, diamondPaint);

    final innerPath = Path()
      ..moveTo(center.dx, center.dy - dH * 0.6)
      ..lineTo(center.dx + dW * 0.6, center.dy)
      ..lineTo(center.dx, center.dy + dH * 0.6)
      ..lineTo(center.dx - dW * 0.6, center.dy)
      ..close();

    canvas.drawPath(innerPath, diamondPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
