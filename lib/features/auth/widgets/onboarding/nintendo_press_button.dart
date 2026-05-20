import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/widgets/buttons/primary_button.dart';

class NintendoPressButton extends StatefulWidget {
  const NintendoPressButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  final String text;
  final VoidCallback onPressed;

  @override
  State<NintendoPressButton> createState() => _NintendoPressButtonState();
}

class _NintendoPressButtonState extends State<NintendoPressButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleX;
  late final Animation<double> _scaleY;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppAnimations.buttonPress,
      reverseDuration: AppAnimations.buttonRelease,
    );
    _scaleX = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _ctrl, curve: AppAnimations.buttonScale),
    );
    _scaleY = Tween<double>(begin: 1.0, end: 0.91).animate(
      CurvedAnimation(parent: _ctrl, curve: AppAnimations.buttonScale),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    HapticFeedback.lightImpact();
    _ctrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _ctrl.reverse();
    widget.onPressed();
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform(
          alignment: Alignment.center,
          transform:
              Matrix4.diagonal3Values(_scaleX.value, _scaleY.value, 1.0),
          child: child,
        ),
        child: AbsorbPointer(
          child: PrimaryButton(
            text: widget.text,
            onPressed: widget.onPressed,
            width: 340,
            height: 70,
            radius: 90,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
