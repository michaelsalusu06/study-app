import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/common/avatar_widget.dart';
import '../../../../models/live_class_model.dart';

class PreJoinContent extends StatelessWidget {
  const PreJoinContent({
    super.key,
    required this.liveClass,
    required this.onJoin,
  });

  final LiveClassModel liveClass;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.videocam_off_outlined,
                          size: 40, color: colorScheme.primary),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      "Class hasn't started yet",
                      style: textTheme.titleMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              children: [
                AvatarWidget(
                    name: liveClass.teacher?.name ?? 'Teacher',
                    size: AvatarSize.large),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        liveClass.teacher?.name ?? 'Teacher',
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Expert Instructor',
                        style: textTheme.bodySmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                TextButton(onPressed: () {}, child: const Text('View Profile')),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Text('Class Details',
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSizes.sm),
          _buildInfoRow(context,
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: liveClass.formattedDate),
          _buildInfoRow(context,
              icon: Icons.access_time_outlined,
              label: 'Time',
              value: liveClass.formattedTime),
          _buildInfoRow(context,
              icon: Icons.people_outline,
              label: 'Enrolled',
              value: '${liveClass.viewerCount} students'),
          const SizedBox(height: AppSizes.xl),
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.primaryContainer.withAlpha(77),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Column(
              children: [
                Text('Class starts in',
                    style: textTheme.titleSmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: AppSizes.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCountdownItem(context, '00', 'Hours'),
                    const SizedBox(width: AppSizes.sm),
                    Text(':', style: textTheme.headlineMedium),
                    const SizedBox(width: AppSizes.sm),
                    _buildCountdownItem(context, '15', 'Mins'),
                    const SizedBox(width: AppSizes.sm),
                    Text(':', style: textTheme.headlineMedium),
                    const SizedBox(width: AppSizes.sm),
                    _buildCountdownItem(context, '30', 'Secs'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          PrimaryButton(text: 'Join Class', onPressed: onJoin),
          const SizedBox(height: AppSizes.md),
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: Icon(Icons.notifications_outlined, color: colorScheme.primary),
              label: const Text('Set Reminder'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSizes.sm),
          Text(label,
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant)),
          const Spacer(),
          Text(value,
              style:
                  textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildCountdownItem(BuildContext context, String value, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Center(
            child: Text(
              value,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(label,
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
