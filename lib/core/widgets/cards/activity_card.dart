import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

enum ActivityType { enrollment, review, message, other }

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.type,
    required this.message,
    required this.time,
  });

  final ActivityType type;
  final String message;
  final String time;

  static ActivityType fromString(String value) {
    switch (value) {
      case 'enrollment': return ActivityType.enrollment;
      case 'review': return ActivityType.review;
      case 'message': return ActivityType.message;
      default: return ActivityType.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final IconData icon;
    final Color iconColor;
    switch (type) {
      case ActivityType.enrollment:
        icon = Icons.person_add_rounded;
        iconColor = colorScheme.primary;
      case ActivityType.review:
        icon = Icons.star_rounded;
        iconColor = AppColors.starGold;
      case ActivityType.message:
        icon = Icons.message_rounded;
        iconColor = colorScheme.secondary;
      case ActivityType.other:
        icon = Icons.notifications_rounded;
        iconColor = colorScheme.onSurfaceVariant;
    }

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.xs),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: iconColor.withAlpha(26), shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: textTheme.bodyMedium),
                Text(time,
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
