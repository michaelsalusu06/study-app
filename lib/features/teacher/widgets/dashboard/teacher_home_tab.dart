import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/cards/activity_card.dart';
import '../../../../core/widgets/cards/session_card.dart';
import '../../../../core/widgets/cards/stat_card.dart';
import '../../../../core/widgets/common/avatar_widget.dart';

class TeacherHomeTab extends StatelessWidget {
  const TeacherHomeTab({super.key});

  static const _stats = [
    {'title': 'Total Students', 'value': '1,234', 'icon': Icons.people_rounded, 'color': AppColors.statsStudents},
    {'title': 'Active Courses', 'value': '12', 'icon': Icons.book_rounded, 'color': AppColors.statsCourses},
    {'title': 'Monthly Earnings', 'value': '\$4,560', 'icon': Icons.attach_money_rounded, 'color': AppColors.statsEarnings},
    {'title': 'Average Rating', 'value': '4.9', 'icon': Icons.star_rounded, 'color': AppColors.starGold},
  ];

  static const _sessions = [
    {'title': 'Advanced Mathematics', 'time': '10:00 AM', 'students': 24, 'status': 'In 30 mins'},
    {'title': 'Physics Fundamentals', 'time': '2:00 PM', 'students': 18, 'status': 'Today'},
    {'title': 'Calculus II', 'time': '4:30 PM', 'students': 32, 'status': 'Today'},
  ];

  static const _activities = [
    {'type': 'enrollment', 'message': 'John Doe enrolled in Advanced Math', 'time': '2 hours ago'},
    {'type': 'review', 'message': 'New 5-star review on Physics Course', 'time': '5 hours ago'},
    {'type': 'message', 'message': 'New message from Alice Smith', 'time': '1 day ago'},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSizes.md),
            _buildQuickStats(context),
            const SizedBox(height: AppSizes.lg),
            _buildUpcomingSessions(context),
            const SizedBox(height: AppSizes.lg),
            _buildRecentActivity(context),
            const SizedBox(height: AppSizes.lg),
            _buildQuickActions(context),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning! 👋',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                Text(
                  'Dr. Sarah Wilson',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              AvatarWidget(
                  name: 'Sarah Wilson',
                  size: AvatarSize.medium,
                  onTap: () {}),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        itemCount: _stats.length,
        itemExtent: 176, // 160 card + 16 margin — skip per-item measurement
        itemBuilder: (context, index) {
          final s = _stats[index];
          return StatCard(
            title: s['title'] as String,
            value: s['value'] as String,
            icon: s['icon'] as IconData,
            color: s['color'] as Color,
          );
        },
      ),
    );
  }

  Widget _buildUpcomingSessions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Sessions',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text('View All',
                    style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        ..._sessions.map((s) => SessionCard(
              title: s['title'] as String,
              time: s['time'] as String,
              studentCount: s['students'] as int,
              status: s['status'] as String,
            )),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Text(
            'Recent Activity',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        ..._activities.map((a) => ActivityCard(
              type: ActivityCard.fromString(a['type'] as String),
              message: a['message'] as String,
              time: a['time'] as String,
            )),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final actions = [
      {'icon': Icons.add_circle_outline, 'label': 'Create Course', 'color': colorScheme.primary},
      {'icon': Icons.schedule_outlined, 'label': 'Schedule Class', 'color': colorScheme.secondary},
      {'icon': Icons.analytics_outlined, 'label': 'View Analytics', 'color': AppColors.statsEarnings},
      {'icon': Icons.help_outline, 'label': 'Help & Support', 'color': colorScheme.onSurfaceVariant},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Text(
            'Quick Actions',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: actions
                .map((action) => _buildActionButton(context, action))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      BuildContext context, Map<String, dynamic> action) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: (action['color'] as Color).withAlpha(26),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(action['icon'] as IconData,
                color: action['color'] as Color),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            action['label'] as String,
            style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
