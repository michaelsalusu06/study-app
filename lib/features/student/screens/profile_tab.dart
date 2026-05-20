import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/auth_state.dart';
import '../../../core/theme/app_typography.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const _ProfileHeader(),
        const SizedBox(height: AppSizes.lg),
        _buildSectionCard(
          children: [
            _ProfileMenuItem(
              icon: Icons.person_outline_rounded,
              label: 'Edit Profile',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.lock_outline_rounded,
              label: 'Change Password',
              disabled: true,
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              disabled: true,
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        _buildSectionCard(
          children: [
            _ProfileMenuItem(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              disabled: true,
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              disabled: true,
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.info_outline_rounded,
              label: 'About',
              disabled: true,
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        _buildSectionCard(
          children: [
            _ProfileMenuItem(
              icon: Icons.logout_rounded,
              label: 'Log Out',
              iconColor: Colors.redAccent,
              labelColor: Colors.redAccent,
              showDivider: false,
              onTap: () {
                AuthState.instance.clear();
                // TODO: navigate to login — e.g. context.go('/login')
              },
            ),
          ],
        ),
        const SizedBox(height: 110),
      ],
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final auth = AuthState.instance;
    final displayName = auth.displayName;
    final email = auth.email ?? '';
    final avatarUrl = auth.avatarUrl;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.lg, AppSizes.lg, AppSizes.lg, AppSizes.md,
        ),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6)),
                ],
                image: avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: avatarUrl == null
                  ? const Icon(Icons.person_rounded, size: 52, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 14),
            Text(
              displayName,
              style: AppTypography.headline(context).copyWith(color: Colors.white),
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                email,
                style: AppTypography.subtitle(context).copyWith(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 16),
            // Coin badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monetization_on_rounded,
                      color: Color(0xFFFFD700), size: 22),
                  SizedBox(width: 8),
                  Text(
                    '0', // TODO: wire ke coin balance dari API
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'coins',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Menu Item ───────────────────────────────────────────────────────────────

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;
  final bool showDivider;
  final bool disabled;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
    this.showDivider = true,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = disabled
        ? Colors.grey.shade400
        : (iconColor ?? AppColors.primary);
    final effectiveLabelColor = disabled
        ? Colors.grey.shade400
        : (labelColor ?? AppColors.textPrimary);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: effectiveIconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: effectiveLabelColor,
                    ),
                  ),
                ),
                if (disabled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Soon',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textDisabled,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 74, endIndent: 20),
      ],
    );
  }
}