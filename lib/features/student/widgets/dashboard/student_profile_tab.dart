import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/auth_state.dart';
import '../../../../core/services/coin_service.dart';
import '../../../../core/widgets/common/api_error_snackbar.dart';

class StudentProfileTab extends StatefulWidget {
  const StudentProfileTab({super.key});

  @override
  State<StudentProfileTab> createState() => _StudentProfileTabState();
}

class _StudentProfileTabState extends State<StudentProfileTab> {
  @override
  void initState() {
    super.initState();
    _refreshBalance();
  }

  Future<void> _refreshBalance() async {
    final result = await CoinService.instance.getCoinBalance();
    if (!mounted) return;
    if (!result.success) {
      ApiErrorSnackbar.show(
          context, result.errorMessage ?? 'Could not refresh coin balance');
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = AuthState.instance.displayName;
    final email = AuthState.instance.email ?? '';
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase()
        : '?';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          children: [
            const SizedBox(height: AppSizes.md),
            CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.sectionLabelDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSizes.xl),
            _ProfileMenuItem(
              icon: Icons.person_outline_rounded,
              label: 'Edit Profile',
              onTap: () =>
                  Navigator.of(context).pushNamed('/update-profile'),
            ),
            _ProfileMenuItem(
              icon: Icons.bookmark_border_rounded,
              label: 'Saved Tutors',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.card_membership_rounded,
              label: 'Subscription',
              onTap: () => Navigator.of(context)
                  .pushNamed('/subscription-plans'),
            ),
            _ProfileMenuItem(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              onTap: () {},
            ),
            const SizedBox(height: AppSizes.md),
            _ProfileMenuItem(
              icon: Icons.logout_rounded,
              label: 'Log Out',
              onTap: () => Navigator.of(context)
                  .pushReplacementNamed('/login'),
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent : AppColors.textPrimary;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          label,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: color),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isDestructive ? Colors.redAccent : AppColors.textDisabled,
          size: 20,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
