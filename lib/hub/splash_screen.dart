import 'package:flutter/material.dart';
import 'package:gameflix/hub/gameflix_hub.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(context, PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const GameFlixHub(), // Redirige vers le HUB
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        ));
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF050515), Color(0xFF1A1A40), Color(0xFFE50914)]),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 10)]),
                // Si tu n'as pas encore d'image, ça affichera juste un cercle stylé pour le moment
                child: ClipOval(child: Image.asset('assets/app_icon.png', fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.gamepad, size: 80, color: Colors.white))),
              ),
            ),
            const SizedBox(height: 50),
            const Text("GAMEFLIX", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4, shadows: [Shadow(color: Colors.redAccent, blurRadius: 15)])),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 3),
          ],
        ),
      ),
    );
  }
}