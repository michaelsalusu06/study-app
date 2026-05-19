import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common/avatar_widget.dart';
import '../../../../models/course_model.dart';

class ReviewsTab extends StatelessWidget {
  const ReviewsTab({super.key, required this.course});

  final CourseModel course;

  static const _reviews = [
    {
      'name': 'Alice Johnson',
      'rating': 5,
      'comment': 'Excellent course! The instructor explains everything clearly.',
      'date': '2 days ago',
    },
    {
      'name': 'Bob Smith',
      'rating': 4,
      'comment': 'Great content, but could use more practical examples.',
      'date': '1 week ago',
    },
    {
      'name': 'Carol White',
      'rating': 5,
      'comment': "Best course I've taken on this platform!",
      'date': '2 weeks ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      course.rating.toStringAsFixed(1),
                      style: textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: index < course.rating.floor()
                              ? AppColors.starGold
                              : colorScheme.outline,
                        );
                      }),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      '${course.totalStudents} reviews',
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(width: AppSizes.lg),
                Expanded(
                  child: Column(
                    children: [5, 4, 3, 2, 1].map((stars) {
                      final percent = stars == 5
                          ? 0.7
                          : stars == 4
                              ? 0.2
                              : stars == 3
                                  ? 0.08
                                  : 0.02;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.xs),
                        child: Row(
                          children: [
                            Text('$stars', style: textTheme.bodySmall),
                            const SizedBox(width: AppSizes.xs),
                            Icon(Icons.star_rounded,
                                size: 12, color: AppColors.starGold),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    AppSizes.radiusFull),
                                child: LinearProgressIndicator(
                                  value: percent,
                                  backgroundColor: colorScheme.outlineVariant,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.starGold),
                                  minHeight: 4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          ..._reviews.map((review) => _buildReviewItem(context, review)),
        ],
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, Map<String, dynamic> review) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(
                  name: review['name'] as String, size: AvatarSize.small),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['name'] as String,
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: index < (review['rating'] as int)
                                ? AppColors.starGold
                                : colorScheme.outline,
                          );
                        }),
                        const SizedBox(width: AppSizes.sm),
                        Text(
                          review['date'] as String,
                          style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            review['comment'] as String,
            style: textTheme.bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
