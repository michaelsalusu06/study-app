import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/user_api_service.dart';
import '../../../../core/services/booking_api_service.dart';
import '../../../../models/booking_model.dart';

class StudentScheduleTab extends StatefulWidget {
  const StudentScheduleTab({super.key});

  @override
  State<StudentScheduleTab> createState() => _StudentScheduleTabState();
}

class _StudentScheduleTabState extends State<StudentScheduleTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<Booking> _upcoming = [];
  List<Booking> _past = [];
  bool _isLoading = true;
  String? _error;

  static const _tabs = ['Upcoming', 'Completed', 'Cancelled'];

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

    final result = await UserApiService.instance.getStudentBookings();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.success) {
        final all = result.bookings ?? [];
        _upcoming = all
            .where((b) =>
                b.status == BookingStatus.pending ||
                b.status == BookingStatus.confirmed)
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
        _past = all
            .where((b) =>
                b.status == BookingStatus.completed ||
                b.status == BookingStatus.cancelled)
            .toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
      } else {
        _error = result.errorMessage;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.lg, AppSizes.lg, AppSizes.lg, 0),
            child: const Text(
              'My Schedule',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.sectionLabelDark,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // ── Tab bar ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2))
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                dividerColor: Colors.transparent,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // ── Tab views ────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildError()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildList(_upcoming, 'upcoming'),
                          _buildList(
                              _past
                                  .where((b) =>
                                      b.status == BookingStatus.completed)
                                  .toList(),
                              'completed'),
                          _buildList(
                              _past
                                  .where((b) =>
                                      b.status == BookingStatus.cancelled)
                                  .toList(),
                              'cancelled'),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 48, color: AppColors.textTertiary),
          const SizedBox(height: AppSizes.md),
          Text(_error!,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSizes.md),
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Booking> bookings, String type) {
    if (bookings.isEmpty) return _buildEmpty(type);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppSizes.lg, 0, AppSizes.lg, 100),
        itemCount: bookings.length,
        itemBuilder: (context, i) => _BookingCard(
          booking: bookings[i],
          onRefresh: _load,
        ),
      ),
    );
  }

  Widget _buildEmpty(String type) {
    final messages = {
      'upcoming': ('No upcoming sessions', 'Book a tutor to get started'),
      'completed': ('No completed sessions', 'Your finished sessions will appear here'),
      'cancelled': ('No cancelled sessions', 'Hopefully none needed!'),
    };
    final msg = messages[type]!;

    return Center(
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
            child: const Icon(Icons.calendar_today_rounded,
                color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: AppSizes.md),
          Text(msg.$1,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sectionLabelDark)),
          const SizedBox(height: AppSizes.xs),
          Text(msg.$2,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Booking card
// ─────────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onRefresh;
  const _BookingCard({required this.booking, required this.onRefresh});

  Future<void> _handleJoin(BuildContext context) async {
    final result = await UserApiService.instance.getJoinInfo(booking.id);
    if (result.success && result.meetingUrl != null) {
      final uri = Uri.parse(result.meetingUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open meeting URL')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.errorMessage ?? 'Cannot join session yet')));
    }
  }

  Future<void> _handleCancel(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this session? Your coins will be refunded.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Cancel')),
        ],
      ),
    );

    if (confirm == true) {
      final res = await UserApiService.instance.cancelBooking(booking.id);
      if (res.success) {
        onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message ?? 'Failed to cancel.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: tutor name + status ──────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.tutorName,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    Text(
                      booking.title,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  booking.status.label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSizes.sm),

          // ── Date + duration ────────────────────────────
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                _formatDate(booking.startTime),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(width: AppSizes.md),
              const Icon(Icons.access_time_rounded,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                booking.formattedDuration,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const Spacer(),
              if (booking.status == BookingStatus.completed)
                TextButton(
                  onPressed: () => _showReviewDialog(context),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Rate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                )
              else if (booking.status == BookingStatus.confirmed)
                ElevatedButton(
                  onPressed: () => _handleJoin(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Join', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                )
              else if (booking.status == BookingStatus.pending)
                TextButton(
                  onPressed: () => _handleCancel(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.toll_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${_fmtPrice(booking.price)} coins',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context) {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rate your Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.starGold,
                    size: 32,
                  ),
                  onPressed: () => setState(() => rating = index + 1),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Leave a comment (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final success = await BookingApiService.instance.submitReview(
                  booking.id,
                  rating: rating,
                  comment: commentController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Review submitted!' : 'Failed to submit review.'),
                      backgroundColor: success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed: return AppColors.success;
      case BookingStatus.pending:   return AppColors.warning;
      case BookingStatus.completed: return AppColors.info;
      case BookingStatus.cancelled: return AppColors.error;
      case BookingStatus.declined:  return AppColors.error;
    }
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} · $h:$m';
  }

  String _fmtPrice(double price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}jt';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}k';
    return price.toStringAsFixed(0);
  }
}
