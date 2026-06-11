// lib/shared/widgets/neon_lobby_banner.dart
import 'package:flutter/material.dart';

class NeonLobbyBanner extends StatelessWidget {
  final String imagePath;
  final Color borderColor;
  final double fixedHeight;

  const NeonLobbyBanner({
    super.key,
    required this.imagePath,
    required this.borderColor,
    this.fixedHeight = 150.0, // Hauteur par défaut (comme dans WYR et Imposter)
  });

  @override
  Widget build(BuildContext context) {
    // Calcul mathématique intégré directement dans le widget
    const double targetImageRatio = 0.45;
    double calculatedCardWidth = fixedHeight / targetImageRatio;

    return Center( 
      child: Container(
        height: fixedHeight, 
        width: calculatedCardWidth, 
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15), 
          border: Border.all(color: borderColor, width: 2.5), 
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.3), 
              blurRadius: 15, 
              spreadRadius: 2
            )
          ], 
          image: DecorationImage(
            image: AssetImage(imagePath), 
            fit: BoxFit.contain // Contain évite que l'image ne soit coupée
          )
        ),
      ),
    );
  }
}