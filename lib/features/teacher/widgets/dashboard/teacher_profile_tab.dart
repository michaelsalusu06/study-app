import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common/avatar_widget.dart';

class TeacherProfileTab extends StatelessWidget {
  const TeacherProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            Center(
              child: Column(
                children: [
                  AvatarWidget(
                      name: 'Sarah Wilson', size: AvatarSize.extraLarge),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'Dr. Sarah Wilson',
                    style: textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Mathematics Expert',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            ..._buildMenuItems(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    const items = [
      {'icon': Icons.person_outline, 'label': 'Edit Profile', 'isDestructive': false},
      {'icon': Icons.settings_outlined, 'label': 'Settings', 'isDestructive': false},
      {'icon': Icons.help_outline, 'label': 'Help & Support', 'isDestructive': false},
      {'icon': Icons.logout, 'label': 'Logout', 'isDestructive': true},
    ];

    return items.map((item) {
      final isDestructive = item['isDestructive'] as bool;
      return Container(
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        child: ListTile(
          leading: Icon(
            item['icon'] as IconData,
            color: isDestructive
                ? colorScheme.error
                : colorScheme.onSurfaceVariant,
          ),
          title: Text(
            item['label'] as String,
            style: textTheme.bodyLarge?.copyWith(
              color: isDestructive ? colorScheme.error : colorScheme.onSurface,
            ),
          ),
          trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          onTap: () {},
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        ),
      );
    }).toList();
  }
}
