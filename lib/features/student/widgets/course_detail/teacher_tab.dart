import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/common/avatar_widget.dart';
import '../../../../models/course_model.dart';

class TeacherTab extends StatelessWidget {
  const TeacherTab({super.key, required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Column(
              children: [
                AvatarWidget(
                  name: course.teacher?.name ?? 'Teacher',
                  size: AvatarSize.extraLarge,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  course.teacher?.name ?? 'Teacher',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  'Expert Instructor',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStat(context, '4.9', 'Rating'),
                    const SizedBox(width: AppSizes.lg),
                    _buildStat(context, '1.2K', 'Students'),
                    const SizedBox(width: AppSizes.lg),
                    _buildStat(context, '15', 'Courses'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Text(
            'About',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'An experienced instructor with over 10 years of teaching experience. '
            'Passionate about helping students achieve their learning goals through '
            'practical, hands-on instruction.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
          ),
          const SizedBox(height: AppSizes.lg),
          PrimaryButton(
            text: 'Subscribe to Teacher',
            onPressed: () {},
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value,
            style:
                textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        Text(label,
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
