import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/auth_state.dart';
import '../../../../core/services/user_api_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/cards/tutor_card.dart';
import '../../../../core/widgets/common/empty_state.dart';
import '../../../../core/widgets/common/section_header.dart';
import '../../../../core/widgets/common/topics_grid.dart';
import '../../../../core/widgets/inputs/search_input.dart';
import '../../../../models/tutor_profile.dart';

class StudentHomeTab extends StatefulWidget {
  const StudentHomeTab({super.key});

  @override
  State<StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends State<StudentHomeTab> {
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
        SectionHeader(title: 'Browse by Topic', onSeeAll: () {}),
        TopicsGrid(onTopicTap: (_) {}),
        const SizedBox(height: AppSizes.sm),
        SectionHeader(title: 'Top Rated Tutors', onSeeAll: () {}),
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
            AppSizes.lg, AppSizes.lg, AppSizes.lg, AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$greeting,',
                          style: AppTypography.subtitle(context)
                              .copyWith(color: Colors.white70)),
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
        ? displayName
            .trim()
            .split(' ')
            .map((p) => p[0])
            .take(2)
            .join()
            .toUpperCase()
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
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
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
          SearchInput(hint: 'Search tutors, topics...', onChanged: (value) {}),
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
          child: const Icon(Icons.calendar_today_rounded,
              size: 18, color: AppColors.primary),
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
                    color: AppColors.primary),
              ),
              Text(
                'No upcoming session',
                style: AppTypography.title(context)
                    .copyWith(fontSize: 13, color: AppColors.textSecondary),
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
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Book', style: TextStyle(fontSize: 13)),
          ),
        ),
      ],
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
          itemExtent: 152, // 140 card + 12 margin — skip per-item measurement
          itemBuilder: (_, __) => const TutorCardSkeleton(),
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
              borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: AppColors.textSecondary, size: 32),
              const SizedBox(height: 8),
              const Text('Could not load tutors',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
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
        itemExtent: 152, // 140 card + 12 margin — skip per-item measurement
        itemBuilder: (context, i) => TutorCard(tutor: _tutors![i]),
      ),
    );
  }

}
