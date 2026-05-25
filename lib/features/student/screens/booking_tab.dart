import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/common/empty_state.dart';
import '../../../core/widgets/common/loading_widget.dart';
import '../../../core/services/user_api_service.dart';
import '../../../models/booking_model.dart';

Future<List<Booking>> _fetchStudentBookings() =>
    UserApiService.instance.getStudentBookings().then(
      (r) => r.bookings ?? [],
    );

class BookingTab extends StatefulWidget {
  const BookingTab({super.key});

  @override
  State<BookingTab> createState() => _BookingTabState();
}

class _BookingTabState extends State<BookingTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Booking>? _bookings;
  bool _isLoading = true;
  String? _error;

  static const _tabs = [
    BookingStatus.pending,
    BookingStatus.confirmed,
    BookingStatus.completed,
    BookingStatus.cancelled,
    BookingStatus.declined,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _fetchStudentBookings();
      if (!mounted) return;
      setState(() { _bookings = data; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<Booking> _filtered(BookingStatus status) =>
      (_bookings ?? []).where((b) => b.status == status).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeader(context),
          _buildTabBar(),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.lg, AppSizes.lg, AppSizes.lg, AppSizes.md,
        ),
        child: Text(
          'My Courses',
          style: AppTypography.headline(context).copyWith(color: Colors.white),
        ),
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.white,
        tabs: _tabs.map((s) => Tab(text: s.label)).toList(),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return TabBarView(
      controller: _tabController,
      children: _tabs.map((status) {
        if (_isLoading) {
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.lg, AppSizes.md, AppSizes.lg, 110),
            itemCount: 4,
            itemBuilder: (_, __) => const _CourseCardSkeleton(),
          );
        }

        if (_error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Could not load courses',
                  style: TextStyle(color: Color(0xFF1A237E), fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final items = _filtered(status);
        if (items.isEmpty) {
          return const EmptyState(
            message: 'You have not taken any courses yet',
          );
        }

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.lg, AppSizes.md, AppSizes.lg, 110),
            itemCount: items.length,
            itemBuilder: (_, i) => _CourseCard(
              booking: items[i],
              onJoin: items[i].status == BookingStatus.confirmed
                  ? () => _joinCall(items[i].id)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _joinCall(String bookingId) async {
    final result = await UserApiService.instance.getJoinInfo(bookingId);
    if (!mounted) return;
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Cannot join call.')),
      );
      return;
    }
    final uri = Uri.parse(result.meetingUrl!);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Jitsi Meet.')),
        );
      }
    }
  }
}

// ─── Course Card ──────────────────────────────────────────────────────────────

class _CourseCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onJoin;

  const _CourseCard({required this.booking, this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top: tutor + status badge ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: booking.tutorAvatarUrl != null
                      ? NetworkImage(booking.tutorAvatarUrl!)
                      : null,
                  child: booking.tutorAvatarUrl == null
                      ? const Icon(Icons.person_rounded,
                          color: AppColors.primary, size: 20)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    booking.tutorName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _StatusBadge(status: booking.status),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // ── Konten ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul
                Text(
                  booking.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                // Deskripsi
                if (booking.description != null &&
                    booking.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    booking.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                // ── Info chips grid ──────────────────────────────────────
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today_rounded,
                      label: booking.dayOfWeek,
                    ),
                    _InfoChip(
                      icon: Icons.access_time_rounded,
                      label: booking.defaultStartTime,
                    ),
                    _InfoChip(
                      icon: Icons.timelapse_rounded,
                      label: booking.formattedDuration,
                    ),
                    _InfoChip(
                      icon: Icons.monetization_on_rounded,
                      label: booking.formattedCoins,
                      iconColor: const Color(0xFFFFD700),
                    ),
                  ],
                ),
                if (onJoin != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onJoin,
                      icon: const Icon(Icons.videocam_rounded, size: 18),
                      label: const Text('Join Call'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final BookingStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      BookingStatus.pending   => (const Color(0xFFF57C00), const Color(0xFFFFF3E0)),
      BookingStatus.confirmed => (const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
      BookingStatus.completed => (const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
      BookingStatus.cancelled => (Colors.redAccent,        const Color(0xFFFFEBEE)),
      BookingStatus.declined  => (const Color(0xFF6A1B9A), const Color(0xFFF3E5F5)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ─── Info Chip ────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor ?? AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _CourseCardSkeleton extends StatelessWidget {
  const _CourseCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerLoading(
                child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.surfaceContainerHigh),
              ),
              const SizedBox(width: 10),
              ShimmerLoading(
                child: Container(
                  height: 12, width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ShimmerLoading(
            child: Container(
              height: 14, width: 180,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ShimmerLoading(
            child: Container(
              height: 10, width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          const SizedBox(height: 6),
          ShimmerLoading(
            child: Container(
              height: 10, width: 220,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ShimmerLoading(
                child: Container(
                  height: 28, width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }
}