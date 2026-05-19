import 'package:flutter/material.dart';
import '../../../../core/constants/app_animations.dart';

class OnboardingNavRow extends StatelessWidget {
  const OnboardingNavRow({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onBack,
    required this.onSkip,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AnimatedOpacity(
          opacity: currentPage > 0 ? 1.0 : 0.0,
          duration: AppAnimations.navFade,
          child: TextButton(
            onPressed: currentPage > 0 ? onBack : null,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text(
              '< Back',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: currentPage < totalPages - 1 ? 1.0 : 0.0,
          duration: AppAnimations.navFade,
          child: TextButton(
            onPressed: currentPage < totalPages - 1 ? onSkip : null,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text(
              'Skip',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }
}
