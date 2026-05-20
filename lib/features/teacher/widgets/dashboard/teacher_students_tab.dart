import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common/avatar_widget.dart';
import '../../../../core/widgets/inputs/search_input.dart';

class TeacherStudentsTab extends StatelessWidget {
  const TeacherStudentsTab({super.key});

  static const _names = [
    'Alice Johnson',
    'Bob Smith',
    'Carol White',
    'David Brown',
    'Eva Green',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Students',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                const SearchInput(
                    hint: 'Search students...', size: SearchInputSize.small),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.md),
              itemCount: 10,
              itemBuilder: (context, index) =>
                  _buildStudentItem(context, index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentItem(BuildContext context, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final name = _names[index % _names.length];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          AvatarWidget(name: name, size: AvatarSize.medium),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text('3 courses enrolled',
                    style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('75%',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  )),
              Text('progress',
                  style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}
