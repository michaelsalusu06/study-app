import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// 90×90 blue rounded-rectangle logo box with the Lern "L" lettermark.
class LernLogoBox extends StatelessWidget {
  const LernLogoBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(painter: LernLogoPainter()),
      ),
    );
  }
}

/// Draws the Lern "L" lettermark:
/// - Cyan (#1AE8FF) offset shadow ~16px left, 14px down
/// - White letterform on top
class LernLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double sx = size.width / 480;
    final double sy = size.height / 480;

    Path buildL(double offX, double offY) {
      double x(double v) => (v + offX) * sx;
      double y(double v) => (v + offY) * sy;

      final path = Path();
      path.moveTo(x(190), y(80));
      path.cubicTo(x(218), y(76), x(252), y(86), x(252), y(115));
      path.cubicTo(x(252), y(138), x(252), y(150), x(252), y(158));
      path.lineTo(x(241), y(240));
      path.lineTo(x(236), y(282));
      path.cubicTo(x(234), y(300), x(232), y(312), x(230), y(318));
      path.cubicTo(x(235), y(322), x(280), y(322), x(357), y(322));
      path.cubicTo(x(360), y(322), x(360), y(326), x(357), y(358));
      path.cubicTo(x(356), y(363), x(348), y(368), x(308), y(395));
      path.cubicTo(x(298), y(401), x(285), y(401), x(268), y(395));
      path.cubicTo(x(248), y(387), x(237), y(374), x(226), y(364));
      path.cubicTo(x(216), y(354), x(208), y(352), x(207), y(369));
      path.cubicTo(x(203), y(381), x(188), y(392), x(162), y(395));
      path.cubicTo(x(146), y(396), x(130), y(387), x(131), y(358));
      path.lineTo(x(131), y(322));
      path.lineTo(x(165), y(312));
      path.lineTo(x(165), y(158));
      path.cubicTo(x(165), y(140), x(152), y(122), x(128), y(112));
      path.cubicTo(x(118), y(100), x(130), y(78), x(165), y(78));
      path.cubicTo(x(178), y(77), x(186), y(78), x(190), y(80));
      path.close();
      return path;
    }

    canvas.drawPath(
      buildL(-16, 14),
      Paint()
        ..color = AppColors.logoCyanShadow
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
    canvas.drawPath(
      buildL(0, 0),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(LernLogoPainter _) => false;
}
