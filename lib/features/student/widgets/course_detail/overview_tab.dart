import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common/avatar_widget.dart';
import '../../../../models/course_model.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key, required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              AvatarWidget(
                name: course.teacher?.name ?? 'Teacher',
                size: AvatarSize.small,
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                course.teacher?.name ?? 'Teacher',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          _buildStatsRow(context),
          const SizedBox(height: AppSizes.lg),
          Text(
            'About this course',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            course.description,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Text(
            "What you'll learn",
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSizes.sm),
          ..._buildLearningPoints(context),
          const SizedBox(height: AppSizes.lg),
          Text(
            'Requirements',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSizes.sm),
          ..._buildRequirements(context),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context,
              icon: Icons.star_rounded,
              label: 'Rating',
              value: course.rating.toStringAsFixed(1),
              color: AppColors.starGold),
          _buildStatItem(context,
              icon: Icons.people_outline,
              label: 'Students',
              value: '${course.totalStudents}'),
          _buildStatItem(context,
              icon: Icons.schedule_outlined,
              label: 'Duration',
              value: course.formattedDuration),
          _buildStatItem(context,
              icon: Icons.update_outlined, label: 'Updated', value: 'Recently'),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Icon(icon, size: 20, color: color ?? colorScheme.primary),
        const SizedBox(height: AppSizes.xs),
        Text(value,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        Text(label,
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant)),
      ],
    );
  }

  List<Widget> _buildLearningPoints(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const points = [
      'Understand the fundamentals of the subject',
      'Apply concepts to real-world scenarios',
      'Build practical projects from scratch',
      'Master advanced techniques',
    ];
    return points
        .map((point) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 20, color: colorScheme.primary),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(point,
                        style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant)),
                  ),
                ],
              ),
            ))
        .toList();
  }

  List<Widget> _buildRequirements(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const requirements = [
      'No prior experience required',
      'A computer with internet access',
      'Willingness to learn',
    ];
    return requirements
        .map((req) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_right_rounded,
                      size: 20, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: AppSizes.xs),
                  Expanded(
                    child: Text(req,
                        style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant)),
                  ),
                ],
              ),
            ))
        .toList();
  }
}
