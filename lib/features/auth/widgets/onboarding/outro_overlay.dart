import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'lern_logo_box.dart';

class OutroOverlay extends StatelessWidget {
  const OutroOverlay({
    super.key,
    required this.controller,
    required this.expand,
    required this.logoOpacity,
    required this.logoScale,
    required this.line1Opacity,
    required this.line1Slide,
    required this.line2Opacity,
    required this.line2Slide,
    required this.line3Opacity,
    required this.line3Slide,
    required this.checkScale,
    required this.checkOpacity,
  });

  final AnimationController controller;
  final Animation<double> expand;
  final Animation<double> logoOpacity;
  final Animation<double> logoScale;
  final Animation<double> line1Opacity;
  final Animation<Offset> line1Slide;
  final Animation<double> line2Opacity;
  final Animation<Offset> line2Slide;
  final Animation<double> line3Opacity;
  final Animation<Offset> line3Slide;
  final Animation<double> checkScale;
  final Animation<double> checkOpacity;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        if (controller.value == 0.0) return const SizedBox.shrink();
        final size = MediaQuery.of(context).size;
        final maxR =
            sqrt(size.width * size.width + size.height * size.height);
        final radius = expand.value.clamp(0.0, 1.0) * maxR;
        final logoOp = logoOpacity.value.clamp(0.0, 1.0);
        final logoSc = logoScale.value.clamp(0.0, 1.5);

        return Stack(
          children: [
            CustomPaint(
              painter: _CircleExpandPainter(radius: radius),
              size: Size.infinite,
            ),
            if (logoOp > 0)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: logoOp,
                      child: Transform.scale(
                        scale: logoSc,
                        child: const LernLogoBox(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Opacity(
                      opacity: logoOp,
                      child: const Text(
                        'Lern',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Opacity(
                      opacity: line1Opacity.value.clamp(0.0, 1.0),
                      child: SlideTransition(
                        position: line1Slide,
                        child: const Text(
                          'Welcome aboard! 🎉',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: line2Opacity.value.clamp(0.0, 1.0),
                      child: SlideTransition(
                        position: line2Slide,
                        child: Text(
                          'Your learning journey starts now.',
                          style: TextStyle(
                            color: AppColors.primary.withOpacity(0.65),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: line3Opacity.value.clamp(0.0, 1.0),
                      child: SlideTransition(
                        position: line3Slide,
                        child: Text(
                          "Good luck — you've got this. 💪",
                          style: TextStyle(
                            color: AppColors.primary.withOpacity(0.45),
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Opacity(
                      opacity: checkOpacity.value.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: checkScale.value.clamp(0.0, 1.5),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.10),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CircleExpandPainter extends CustomPainter {
  const _CircleExpandPainter({required this.radius});
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_CircleExpandPainter old) => old.radius != radius;
}
