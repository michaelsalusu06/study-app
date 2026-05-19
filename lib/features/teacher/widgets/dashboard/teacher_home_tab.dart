import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common/avatar_widget.dart';

class TeacherHomeTab extends StatelessWidget {
  const TeacherHomeTab({super.key});

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
    final stats = [
      {'title': 'Total Students', 'value': '1,234', 'icon': Icons.people_rounded, 'color': AppColors.statsStudents},
      {'title': 'Active Courses', 'value': '12', 'icon': Icons.book_rounded, 'color': AppColors.statsCourses},
      {'title': 'Monthly Earnings', 'value': '\$4,560', 'icon': Icons.attach_money_rounded, 'color': AppColors.statsEarnings},
      {'title': 'Average Rating', 'value': '4.9', 'icon': Icons.star_rounded, 'color': AppColors.starGold},
    ];

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        itemCount: stats.length,
        itemBuilder: (context, index) =>
            _buildStatCard(context, stats[index]),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, Map<String, dynamic> stat) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final color = stat['color'] as Color;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: AppSizes.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(stat['icon'] as IconData, size: 20, color: color),
              ),
              const Spacer(),
              Text(
                stat['value'] as String,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                stat['title'] as String,
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingSessions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    const sessions = [
      {'title': 'Advanced Mathematics', 'time': '10:00 AM', 'students': 24, 'status': 'In 30 mins'},
      {'title': 'Physics Fundamentals', 'time': '2:00 PM', 'students': 18, 'status': 'Today'},
      {'title': 'Calculus II', 'time': '4:30 PM', 'students': 32, 'status': 'Today'},
    ];

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
        ...sessions.map((s) => _buildSessionItem(context, s)),
      ],
    );
  }

  Widget _buildSessionItem(BuildContext context, Map<String, dynamic> session) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(Icons.videocam_rounded, color: colorScheme.primary),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session['title'] as String,
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Icon(Icons.schedule_outlined,
                        size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(session['time'] as String,
                        style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant)),
                    const SizedBox(width: AppSizes.sm),
                    Icon(Icons.people_outline,
                        size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${session['students']} students',
                        style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm, vertical: AppSizes.xs),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Text(
                  session['status'] as String,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                    minimumSize: Size.zero),
                child: const Text('Start'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    const activities = [
      {'type': 'enrollment', 'message': 'John Doe enrolled in Advanced Math', 'time': '2 hours ago'},
      {'type': 'review', 'message': 'New 5-star review on Physics Course', 'time': '5 hours ago'},
      {'type': 'message', 'message': 'New message from Alice Smith', 'time': '1 day ago'},
    ];

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
        ...activities.map((a) => _buildActivityItem(context, a)),
      ],
    );
  }

  Widget _buildActivityItem(
      BuildContext context, Map<String, dynamic> activity) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    IconData icon;
    Color iconColor;
    switch (activity['type']) {
      case 'enrollment':
        icon = Icons.person_add_rounded;
        iconColor = colorScheme.primary;
        break;
      case 'review':
        icon = Icons.star_rounded;
        iconColor = AppColors.starGold;
        break;
      case 'message':
        icon = Icons.message_rounded;
        iconColor = colorScheme.secondary;
        break;
      default:
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
                Text(activity['message'] as String,
                    style: textTheme.bodyMedium),
                Text(activity['time'] as String,
                    style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
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
