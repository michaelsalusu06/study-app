import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../models/course_model.dart';

class CurriculumTab extends StatelessWidget {
  const CurriculumTab({super.key, required this.course});

  final CourseModel course;

  static const _sections = [
    {
      'title': 'Introduction',
      'lessons': [
        {'title': 'Welcome to the course', 'duration': '5:00', 'preview': true},
        {'title': 'What you will learn', 'duration': '3:00', 'preview': true},
      ],
    },
    {
      'title': 'Getting Started',
      'lessons': [
        {'title': 'Setting up your environment', 'duration': '10:00', 'preview': false},
        {'title': 'Basic concepts', 'duration': '15:00', 'preview': false},
        {'title': 'Your first project', 'duration': '20:00', 'preview': false},
      ],
    },
    {
      'title': 'Advanced Topics',
      'lessons': [
        {'title': 'Advanced techniques', 'duration': '25:00', 'preview': false},
        {'title': 'Best practices', 'duration': '15:00', 'preview': false},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final totalLessons = _sections.fold<int>(
        0, (sum, s) => sum + (s['lessons'] as List).length);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('${_sections.length} Sections', style: textTheme.titleSmall),
                Text('$totalLessons Lessons', style: textTheme.titleSmall),
                Text('2h 30m', style: textTheme.titleSmall),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          ..._sections.asMap().entries.map((entry) {
            final section = entry.value;
            return _buildSection(
              context,
              sectionNumber: entry.key + 1,
              title: section['title'] as String,
              lessons: section['lessons'] as List<Map<String, dynamic>>,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required int sectionNumber,
    required String title,
    required List<Map<String, dynamic>> lessons,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Center(
                  child: Text(
                    '$sectionNumber',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(title,
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Text(
                '${lessons.length} lessons',
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        ...lessons.map((lesson) => _buildLessonItem(context, lesson)),
        const SizedBox(height: AppSizes.md),
      ],
    );
  }

  Widget _buildLessonItem(BuildContext context, Map<String, dynamic> lesson) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isPreview = lesson['preview'] == true;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.sm),
      child: Row(
        children: [
          Icon(
            isPreview ? Icons.play_circle_outline : Icons.lock_outline,
            size: 20,
            color: isPreview ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              lesson['title'] as String,
              style: textTheme.bodyMedium?.copyWith(
                color: isPreview
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (isPreview)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm, vertical: AppSizes.xs),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Text(
                'Preview',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(width: AppSizes.sm),
          Text(
            lesson['duration'] as String,
            style:
                textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
