import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_typography.dart';

class ScheduleTab extends StatelessWidget {
  const ScheduleTab({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Column(
      children: [
        // Header
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSizes.lg, topPadding + AppSizes.lg, AppSizes.lg, AppSizes.md,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'My Schedule',
              style: AppTypography.headline(context).copyWith(color: Colors.white),
            ),
          ),
        ),
        // Coming soon content
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Coming Soon',
                  style: AppTypography.headline(context).copyWith(
                    color: Colors.white,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Schedule feature is under development.\nCheck back soon!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}