import 'package:flutter/material.dart';

class TeacherProfileTab extends StatelessWidget {
  const TeacherProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We removed the solid backgroundColor here
      body: Container(
        // Applied the requested 3-color linear gradient to the entire screen
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3B82F6), // Vivid blue at top
              Color(0xFF93C5FD), // Light blue in middle
              Color(0xFFFFFFFF), // White at bottom
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _TeacherProfileHeader(),
            const SizedBox(height: 24),
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
                  showDivider: false, 
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                  showDivider: false,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              children: [
                _ProfileMenuItem(
                  icon: Icons.logout_rounded,
                  label: 'Log Out',
                  iconColor: Colors.redAccent,
                  labelColor: Colors.redAccent,
                  showDivider: false,
                  onTap: () {
                    // TODO: Handle logout logic
                  },
                ),
              ],
            ),
            const SizedBox(height: 110), 
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06), // Slightly increased shadow for contrast against white
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _TeacherProfileHeader extends StatelessWidget {
  const _TeacherProfileHeader();

  @override
  Widget build(BuildContext context) {
    // Removed the separate background decoration so it blends seamlessly into the screen gradient
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 16),
        child: Column(
          children: [
            // Avatar Profile Picture
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
              ),
              child: const Icon(Icons.person_rounded, size: 52, color: Colors.white),
            ),
            const SizedBox(height: 14),
            // Profile Name
            const Text(
              'Dr. Amba Rusdi, S.Kom., M.SI.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            // Profile Role / Subtitle
            const Text(
              'Teacher',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            // Earnings Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFFFD700), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Rp 5,432,000',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'total earnings',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
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
        : (iconColor ?? const Color(0xFF6366F1)); 
    final effectiveLabelColor = disabled
        ? Colors.grey.shade400
        : (labelColor ?? const Color(0xFF1E293B)); 

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
                // Icon Box
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
                // Label Text
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
                // Trailing Widget ("Soon" badge or Chevron)
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
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
        // Bottom Divider
        if (showDivider)
          const Divider(
            height: 1, 
            indent: 74, 
            endIndent: 20, 
            color: Color(0xFFF1F5F9), 
          ),
      ],
    );
  }
}