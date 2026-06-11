// lib/shared/widgets/neon_confetti.dart
import 'package:flutter/material.dart';
import 'dart:math';

class NeonConfettiWidget extends StatefulWidget {
  const NeonConfettiWidget({super.key});

  @override
  State<NeonConfettiWidget> createState() => _NeonConfettiWidgetState();
}

class _NeonConfettiWidgetState extends State<NeonConfettiWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    List<Color> colors = [Colors.pinkAccent, Colors.cyanAccent, Colors.purpleAccent, Colors.greenAccent, Colors.amberAccent];
    
    for (int i = 0; i < 80; i++) {
      _particles.add(_ConfettiParticle(
        x: _random.nextDouble() * 400, 
        y: _random.nextDouble() * -600,
        size: _random.nextDouble() * 6 + 4, 
        speed: _random.nextDouble() * 3 + 2,
        color: colors[_random.nextInt(colors.length)], 
        rotationSpeed: _random.nextDouble() * 0.05,
        rotation: _random.nextDouble() * pi * 2, 
      ));
    }
  }

  @override 
  void dispose() { 
    _controller.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final size = MediaQuery.of(context).size;
        for (var p in _particles) {
          p.y += p.speed;
          p.x += sin(p.y / 30) * 0.5; 
          p.rotation += p.rotationSpeed;
          if (p.y > size.height) { p.y = -20; p.x = _random.nextDouble() * size.width; }
        }
        return CustomPaint(size: Size.infinite, painter: _ConfettiPainter(particles: _particles));
      },
    );
  }
}

class _ConfettiParticle {
  double x, y, size, speed, rotation, rotationSpeed; Color color;
  _ConfettiParticle({required this.x, required this.y, required this.size, required this.speed, required this.color, required this.rotationSpeed, this.rotation = 0});
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()..color = p.color..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(p.x.clamp(0, size.width), p.y);
      canvas.rotate(p.rotation);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size * 1.5, height: p.size), paint);
      canvas.restore();
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}