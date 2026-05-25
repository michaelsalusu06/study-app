import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/auth_state.dart';
import '../../../../core/services/coin_service.dart';
import '../../../../core/services/user_api_service.dart';
import '../../../../core/services/student_profile_service.dart';
import '../../../../core/services/tutor_browse_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/cards/tutor_card.dart';
import '../../../../core/widgets/common/empty_state.dart';
import '../../../../core/widgets/common/section_header.dart';
import '../../../../core/widgets/common/topics_grid.dart';
import '../../../../core/widgets/inputs/search_input.dart';
import '../../../../models/tutor_profile.dart';
import '../../../../models/booking_model.dart';
import '../../screens/notifications_screen.dart';
import '../../screens/tutor_detail_screen.dart';
import '../../screens/coin_history_screen.dart';

class StudentHomeTab extends StatefulWidget {
  const StudentHomeTab({super.key});

  @override
  State<StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends State<StudentHomeTab> {
  List<TutorProfile>? _tutors;
  Booking? _nextSession;
  bool _isLoading = true;
  String? _error;
  int _unseenNotifs = 0;
  String? _searchQuery;
  String? _selectedTopic;
  double? _maxCoins;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _loadNotifCount();
    _refreshProfile();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    // Also refresh profile to get latest coins/notif count
    _loadNotifCount();
    _refreshProfile();
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Load Tutors (with normalized filters)
      final tutorResult = await TutorBrowseService.instance.getTutors(
        search: _searchQuery,
        subject: _selectedTopic?.toLowerCase(), 
        maxPrice: _maxCoins,
      );

      // 2. Load Bookings to find the next upcoming one
      final bookingResult = await UserApiService.instance.getStudentBookings();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (tutorResult.success) {
          _tutors = tutorResult.tutors?.map((t) => TutorProfile.fromJson(t)).toList();
        } else {
          _error = tutorResult.errorMessage;
        }

        if (bookingResult.success) {
          final upcoming = (bookingResult.bookings ?? [])
              .where((b) => b.status == BookingStatus.confirmed && b.startTime.isAfter(DateTime.now()))
              .toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
          
          if (upcoming.isNotEmpty) {
            _nextSession = upcoming.first;
          } else {
            _nextSession = null;
          }
        }
      });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = 'An error occurred'; });
    }
  }

  Future<void> _loadNotifCount() async {
    final count = await StudentProfileService.instance.getUnseenCount();
    if (mounted) setState(() => _unseenNotifs = count);
  }

  Future<void> _refreshProfile() async {
    await StudentProfileService.instance.getMyProfile();
    // getMyProfile doesn't return coins_balance; call balance endpoint separately.
    await CoinService.instance.getCoinBalance();
    if (mounted) setState(() {});
  }

  void _onSearch(String query) {
    setState(() { _searchQuery = query.isEmpty ? null : query; });
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), _loadAll);
  }

  void _onTopicTap(String topic) {
    setState(() {
      _selectedTopic = (_selectedTopic == topic) ? null : topic;
    });
    _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final isFiltering = _searchQuery != null || _selectedTopic != null || _maxCoins != null;

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: AppColors.primary,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(context),
          const SizedBox(height: AppSizes.sm),
          SectionHeader(
            title: 'Browse by Topic', 
            onSeeAll: () => setState(() { _selectedTopic = null; _loadAll(); }),
          ),
          TopicsGrid(onTopicTap: _onTopicTap),
          const SizedBox(height: AppSizes.sm),
          
          // Filter Indicator
          if (isFiltering)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.xs),
              child: Row(
                children: [
                  const Text('Active Filter: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
                  if (_selectedTopic != null)
                    _buildFilterChip(_selectedTopic!, () => setState(() { _selectedTopic = null; _loadAll(); })),
                  if (_searchQuery != null)
                    _buildFilterChip('"${_searchQuery!}"', () => setState(() { _searchQuery = null; _loadAll(); })),
                  if (_maxCoins != null)
                    _buildFilterChip('< ${_maxCoins!.round()} coins', () => setState(() { _maxCoins = null; _loadAll(); })),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() { _selectedTopic = null; _searchQuery = null; _maxCoins = null; _loadAll(); }),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: const Text('Clear All', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),

          SectionHeader(
            title: isFiltering ? 'Search Results' : 'Top Rated Tutors', 
            onSeeAll: _loadAll,
          ),
          _buildTutorSection(),
          const SizedBox(height: 110),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDeleted,
            child: const Icon(Icons.close, size: 12, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final displayName = AuthState.instance.displayName;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.lg, AppSizes.lg, AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$greeting,', style: AppTypography.subtitle(context).copyWith(color: Colors.white70)),
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
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoinHistoryScreen())),
                  child: ListenableBuilder(
                    listenable: AuthState.instance,
                    builder: (context, _) => _buildCoinChip(AuthState.instance.coinsBalance),
                  ),
                ),
                const SizedBox(width: 12),
                _buildNotifBell(),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            _buildSearchCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinChip(int coins) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.toll_rounded, color: Colors.amber, size: 16),
          const SizedBox(width: 6),
          Text('$coins', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildNotifBell() {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
        _loadNotifCount();
      },
      child: Stack(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
          ),
          if (_unseenNotifs > 0)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text('$_unseenNotifs', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
              ),
            ),
        ],
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
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchInput(hint: 'Search tutors, topics...', onChanged: _onSearch),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.toll_rounded, size: 16, color: Colors.amber),
              const SizedBox(width: 8),
              const Text('Max Coins:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Expanded(
                child: Slider(
                  value: _maxCoins ?? 1000,
                  min: 0,
                  max: 1000,
                  divisions: 20,
                  label: _maxCoins?.round().toString() ?? 'Any',
                  onChanged: (val) => setState(() => _maxCoins = val == 1000 ? null : val),
                  onChangeEnd: (_) => _loadAll(),
                ),
              ),
              Text(_maxCoins == null ? 'Any' : _maxCoins!.round().toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
          const Divider(height: 20),
          _buildUpcomingRow(context),
        ],
      ),
    );
  }

  Widget _buildUpcomingRow(BuildContext context) {
    final hasSession = _nextSession != null;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (hasSession ? AppColors.success : AppColors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            hasSession ? Icons.videocam_rounded : Icons.calendar_today_rounded,
            size: 18, 
            color: hasSession ? AppColors.success : AppColors.primary
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasSession ? 'Next Session' : 'Upcoming Session',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: hasSession ? AppColors.success : AppColors.primary),
              ),
              Text(
                hasSession 
                  ? '${_nextSession!.tutorName} · ${DateFormat('HH:mm').format(_nextSession!.startTime)}'
                  : 'No upcoming session',
                style: AppTypography.title(context).copyWith(fontSize: 13, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: () {
              if (hasSession) {
                // Navigate to schedule or call
              } else {
                _loadAll();
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              backgroundColor: hasSession ? AppColors.success : AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(hasSession ? 'Join' : 'Refresh', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
          itemExtent: 152,
          itemBuilder: (_, __) => const TutorCardSkeleton(),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_tutors == null || _tutors!.isEmpty) {
      return const EmptyState(message: 'No tutors found match your search');
    }

    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
        itemCount: _tutors!.length,
        itemExtent: 152,
        itemBuilder: (context, i) {
          final tutor = _tutors![i];
          return TutorCard(
            tutor: tutor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TutorDetailScreen(tutorId: tutor.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.textSecondary, size: 32),
            const SizedBox(height: 8),
            const Text('Could not load tutors', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            TextButton.icon(onPressed: _loadAll, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
