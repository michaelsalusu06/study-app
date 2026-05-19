import 'package:flutter/material.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_sizes.dart';

class PageIndicatorRow extends StatelessWidget {
  const PageIndicatorRow({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final isActive = currentIndex == index;
          return AnimatedContainer(
            duration: AppAnimations.dotIndicator,
            curve: AppAnimations.dotExpand,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
          );
        }),
      ),
    );
  }
}
