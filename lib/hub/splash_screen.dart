import 'package:flutter/material.dart';
import 'package:gameflix/hub/gameflix_hub.dart';
import 'package:gameflix/l10n/app_strings.dart';
import 'package:gameflix/models/game_config.dart';
import 'package:gameflix/services/ad_manager.dart';
import 'package:gameflix/shared/navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  bool _bannersPrecached = false;

  @override
  void initState() {
    super.initState();
    AdManager.instance.init();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(context, PageRouteBuilder(
          settings: const RouteSettings(name: kHubRouteName),
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, _, _) => const GameFlixHub(), // Redirige vers le HUB
          transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
        ));
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_bannersPrecached) {
      _bannersPrecached = true;
      final strings = AppStrings.read(context);
      final double dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 3.0);
      final int cacheWidth = ((170.0 / 0.45) * dpr).round();
      for (final game in GameRegistry.games) {
        final String? path = strings.gameBannerPath(game.id, game.bannerPath);
        if (path != null) {
          precacheImage(
            ResizeImage.resizeIfNeeded(cacheWidth, null, AssetImage(path)),
            context,
          );
        }
      }
    }
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050510),
              Color(0xFF120924),
              Color(0xFF1F0E3A),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(42),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF2E7E).withValues(alpha: 0.28),
                      blurRadius: 36,
                      spreadRadius: 4,
                      offset: const Offset(-6, -4),
                    ),
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                      blurRadius: 36,
                      spreadRadius: 4,
                      offset: const Offset(6, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/app_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.gamepad_outlined, size: 80, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 44),
            const GameFlixTextLogo(fontSize: 38),
            const SizedBox(height: 28),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: Color(0xFF00E5FF),
                strokeWidth: 2.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}