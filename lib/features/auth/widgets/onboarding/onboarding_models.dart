import 'package:flutter/material.dart';

class OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  const OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class IconConfig {
  final IconData icon;
  final List<Color> colors;
  const IconConfig(this.icon, this.colors);
}

/// Classic Nintendo pop: fast rise → overshoot → settle
class NintendoBounce extends Curve {
  const NintendoBounce();
  @override
  double transformInternal(double t) {
    if (t < 0.55) return (t / 0.55) * 1.20;
    if (t < 0.75) return 1.20 - ((t - 0.55) / 0.20) * 0.28;
    return 0.92 + ((t - 0.75) / 0.25) * 0.08;
  }
}
