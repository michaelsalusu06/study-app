import 'dart:math';
import 'package:flutter/material.dart';

class ParticleData {
  final double x, y, radius, speed, opacity, drift, phase;
  const ParticleData({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.drift,
    required this.phase,
  });
}

class ParticleBackground extends StatelessWidget {
  const ParticleBackground({
    super.key,
    required this.controller,
    required this.particles,
  });

  final AnimationController controller;
  final List<ParticleData> particles;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) => CustomPaint(
          painter: _ParticlePainter(particles: particles, t: controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.particles, required this.t});
  final List<ParticleData> particles;
  final double t;

  // Single Paint reused every frame — avoids allocation on every 60fps tick
  static final _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final progress = (t * p.speed * 10) % 1.0;
      final x = (p.x * size.width + sin(p.phase + t * 2 * pi) * 20 * p.drift)
          .clamp(0.0, size.width);
      final y = ((p.y - progress * 0.1) % 1.0) * size.height;
      final opacity =
          (p.opacity * (0.5 + 0.5 * sin(p.phase + progress * 2 * pi)))
              .clamp(0.0, 1.0);
      _paint.color = Color.fromRGBO(255, 255, 255, opacity);
      canvas.drawCircle(Offset(x, y), p.radius, _paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}
