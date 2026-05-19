import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/auth_state.dart';
import '../../../core/services/user_api_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/common/empty_state.dart';
import '../../../core/widgets/common/loading_widget.dart';
import '../../../core/widgets/inputs/search_input.dart';
import '../../../models/tutor_profile.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  static const _gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1565C0), Color(0xFFD6E8FF)],
    stops: [0.0, 0.45],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(gradient: _gradient),
            ),
          ),
          IndexedStack(
            index: _currentIndex,
            children: const [
              _HomeTab(),
              _ScheduleTab(),
              _MyLearningTab(),
              _ProfileTab(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 68,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(0, Icons.home_rounded, AppStrings.home),
          _navItem(1, Icons.calendar_today_rounded, AppStrings.schedule),
          _navItem(2, Icons.play_circle_rounded, AppStrings.myLearning),
          _navItem(3, Icons.person_rounded, AppStrings.profile),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? AppColors.primary : AppColors.textDisabled,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List<TutorProfile>? _tutors;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTutors();
  }

  Future<void> _loadTutors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await UserApiService.instance.getTutors();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _tutors = result.tutors;
      } else {
        _error = result.errorMessage;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildHeader(context),
        const SizedBox(height: AppSizes.sm),
        _buildSectionLabel('Browse by Topic', onTap: () {}),
        _buildTopicsGrid(),
        const SizedBox(height: AppSizes.sm),
        _buildSectionLabel('Top Rated Tutors', onTap: () {}),
        _buildTutorSection(),
        const SizedBox(height: 110),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final displayName = AuthState.instance.displayName;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.lg, AppSizes.lg, AppSizes.lg, AppSizes.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting,',
                        style: AppTypography.subtitle(context)
                            .copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayName,
                        style: AppTypography.headline(context).copyWith(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildAvatarCircle(displayName),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            _buildSearchCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCircle(String displayName) {
    final initials = displayName.isNotEmpty
        ? displayName.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase()
        : '?';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchInput(
            hint: 'Search tutors, topics...',
            onChanged: (value) {},
          ),
          const Divider(height: 28),
          _buildUpcomingRow(context),
        ],
      ),
    );
  }

  Widget _buildUpcomingRow(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.calendar_today_rounded,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upcoming Session',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'No upcoming session',
                style: AppTypography.title(context).copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Book', style: TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.md, AppSizes.lg, AppSizes.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF1A237E),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onTap != null)
            GestureDetector(
              onTap: onTap,
              child: const Text(
                'See all',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopicsGrid() {
    const topics = [
      (Icons.calculate_outlined, 'Math'),
      (Icons.code_rounded, 'Coding'),
      (Icons.language_rounded, 'Language'),
      (Icons.music_note_rounded, 'Music'),
      (Icons.science_outlined, 'Science'),
      (Icons.brush_rounded, 'Art'),
      (Icons.history_edu_rounded, 'History'),
      (Icons.fitness_center_rounded, 'PE'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: topics.length,
      itemBuilder: (_, i) {
        final (icon, label) = topics[i];
        return GestureDetector(
          onTap: () {},
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A237E),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTutorSection() {
    if (_isLoading) {
      return SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          itemCount: 4,
          itemBuilder: (_, __) => _buildTutorSkeleton(),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.wifi_off_rounded, color: AppColors.textSecondary, size: 32),
              const SizedBox(height: 8),
              const Text(
                'Could not load tutors',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: _loadTutors,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_tutors == null || _tutors!.isEmpty) {
      return const EmptyState(message: 'No tutors available');
    }

    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
        itemCount: _tutors!.length,
        itemBuilder: (context, i) {
          final tutor = _tutors![i];
          return _buildTutorCard(tutor);
        },
      ),
    );
  }

  Widget _buildTutorCard(TutorProfile tutor) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tutor.displayName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              tutor.firstSubject.isNotEmpty ? tutor.firstSubject : 'Tutor',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFA726), size: 14),
                const SizedBox(width: 2),
                Text(
                  (tutor.overallRating ?? 0).toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tutor.formattedPrice,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorSkeleton() {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShimmerLoading(
            child: CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.surfaceContainerHigh,
            ),
          ),
          const SizedBox(height: 8),
          ShimmerLoading(
            child: Container(
              height: 12,
              width: 90,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 4),
          ShimmerLoading(
            child: Container(
              height: 10,
              width: 60,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          const SizedBox(height: 4),
          ShimmerLoading(
            child: Container(
              height: 10,
              width: 45,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Schedule Tab ─────────────────────────────────────────────────────────────

class _ScheduleTab extends StatelessWidget {
  const _ScheduleTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Schedule',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    const Text(
                      'No sessions scheduled',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    const Text(
                      'Book a tutor to get started',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── My Learning Tab ──────────────────────────────────────────────────────────

class _MyLearningTab extends StatelessWidget {
  const _MyLearningTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Learning',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_circle_rounded,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    const Text(
                      'No sessions yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    const Text(
                      'Start learning by booking a tutor',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Tab ─────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

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
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            _ProfileMenuItem(
              icon: Icons.person_outline_rounded,
              label: 'Edit Profile',
              onTap: () => Navigator.of(context).pushNamed('/update-profile'),
            ),
            _ProfileMenuItem(
              icon: Icons.bookmark_border_rounded,
              label: 'Saved Tutors',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.card_membership_rounded,
              label: 'Subscription',
              onTap: () => Navigator.of(context).pushNamed('/subscription-plans'),
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
              onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
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
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isDestructive ? Colors.redAccent : AppColors.textDisabled,
          size: 20,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
