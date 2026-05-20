import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/inputs/search_input.dart';
import '../../../../data/dummy_data.dart';

class TeacherCoursesTab extends StatelessWidget {
  const TeacherCoursesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final courses = DummyData.courses.take(5).toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Courses',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                const SearchInput(
                    hint: 'Search courses...', size: SearchInputSize.small),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.md),
              itemCount: courses.length,
              itemBuilder: (context, index) =>
                  _buildCourseItem(context, courses[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseItem(BuildContext context, dynamic course) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(Icons.book_rounded, color: colorScheme.primary),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.xs),
                Row(
                  children: [
                    Icon(Icons.people_outline,
                        size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${course.totalStudents} students',
                        style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant)),
                    const SizedBox(width: AppSizes.sm),
                    Icon(Icons.star_rounded,
                        size: 14, color: AppColors.starGold),
                    const SizedBox(width: 4),
                    Text(course.rating.toStringAsFixed(1),
                        style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {},
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'analytics', child: Text('Analytics')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}
