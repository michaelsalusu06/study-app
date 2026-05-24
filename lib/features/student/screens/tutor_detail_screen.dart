import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/user_api_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/tutor_profile.dart';
import 'booking_screen.dart';

class TutorDetailScreen extends StatefulWidget {
  final String tutorId;
  const TutorDetailScreen({super.key, required this.tutorId});

  @override
  State<TutorDetailScreen> createState() => _TutorDetailScreenState();
}

class _TutorDetailScreenState extends State<TutorDetailScreen> {
  Map<String, dynamic>? _tutorRaw;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    final result = await UserApiService.instance.getTutorDetail(widget.tutorId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _tutorRaw = result.tutor;
      } else {
        _error = result.errorMessage;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  // ── Error state ────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: AppSizes.md),
          Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
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

  // ── Main content ───────────────────────────────────────────
  Widget _buildContent() {
    final tutor = _tutorRaw!;
    final name = tutor['full_name'] as String? ?? tutor['username'] as String? ?? 'Tutor';
    final username = tutor['username'] as String?;
    final bio = tutor['bio'] as String?;
    final avatarUrl = tutor['avatar_url'] as String?;
    
    // Safely parse numbers from dynamic API response
    final rating = double.tryParse(tutor['overall_rating']?.toString() ?? '0') ?? 0.0;
    final ratingCount = int.tryParse(tutor['rating_count']?.toString() ?? '0') ?? 0;
    
    final subjects = (tutor['subjects'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final offers = (tutor['tutor_offers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    
    // Robust initials generation to avoid RangeError
    final nameParts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    final initials = nameParts.isNotEmpty 
        ? nameParts.map((e) => e[0]).take(2).join().toUpperCase()
        : '?';

    return CustomScrollView(
      slivers: [
        // ── App bar with avatar ──────────────────────────────
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: AppColors.primary,
          leading: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary, Color(0xFF0D5FCC)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: ClipOval(
                      child: avatarUrl != null && avatarUrl.isNotEmpty
                          ? Image.network(avatarUrl, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _initialsWidget(initials, 28))
                          : _initialsWidget(initials, 28),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  if (username != null)
                    Text('@$username',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ],
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Stats row ──────────────────────────────
                _buildStatsRow(rating, ratingCount, subjects.length),
                const SizedBox(height: AppSizes.lg),

                // ── Subjects ───────────────────────────────
                if (subjects.isNotEmpty) ...[
                  _sectionTitle('Subjects'),
                  const SizedBox(height: AppSizes.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: subjects.map((s) => _SubjectChip(label: s)).toList(),
                  ),
                  const SizedBox(height: AppSizes.lg),
                ],

                // ── Bio ────────────────────────────────────
                if (bio != null && bio.isNotEmpty) ...[
                  _sectionTitle('About'),
                  const SizedBox(height: AppSizes.sm),
                  Text(bio,
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.6)),
                  const SizedBox(height: AppSizes.lg),
                ],

                // ── Offers ─────────────────────────────────
                _sectionTitle('Available Sessions'),
                const SizedBox(height: AppSizes.sm),
                if (offers.isEmpty)
                  const _EmptyOffers()
                else
                  ...offers.map((o) => _OfferCard(
                        offer: o,
                        tutorId: widget.tutorId,
                        tutorName: name,
                      )),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(double rating, int ratingCount, int subjectCount) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            icon: Icons.star_rounded,
            iconColor: AppColors.starGold,
            value: rating.toStringAsFixed(1),
            label: '$ratingCount reviews',
          ),
          _divider(),
          _StatItem(
            icon: Icons.menu_book_rounded,
            iconColor: AppColors.primary,
            value: '$subjectCount',
            label: 'subjects',
          ),
          _divider(),
          _StatItem(
            icon: Icons.verified_rounded,
            iconColor: AppColors.success,
            value: 'Verified',
            label: 'tutor',
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: AppColors.divider);

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.sectionLabelDark),
      );

  Widget _initialsWidget(String initials, double fontSize) => Center(
        child: Text(initials,
            style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w800)),
      );
}

// ─────────────────────────────────────────────────────────────
// Offer card
// ─────────────────────────────────────────────────────────────
class _OfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  final String tutorId;
  final String tutorName;

  const _OfferCard({
    required this.offer,
    required this.tutorId,
    required this.tutorName,
  });

  @override
  Widget build(BuildContext context) {
    final title = offer['title'] as String? ?? 'Session';
    final summary = offer['summary'] as String?;
    
    // Safely parse numbers from dynamic API response
    final coinsPerHour = int.tryParse(offer['coins_per_hour']?.toString() ?? '0') ?? 0;
    final duration = int.tryParse(offer['duration_minutes']?.toString() ?? '60') ?? 60;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          // Duration badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$duration',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
                const Text('min',
                    style: TextStyle(fontSize: 9, color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.md),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                if (summary != null && summary.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.toll_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '$coinsPerHour coins/hr',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Book button
          const SizedBox(width: AppSizes.sm),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(
                      tutorId: tutorId,
                      tutorName: tutorName,
                      offer: offer,
                    ),
                  ),
                );
              },
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _SubjectChip extends StatelessWidget {
  final String label;
  const _SubjectChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary)),
    );
  }
}

class _EmptyOffers extends StatelessWidget {
  const _EmptyOffers();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: const Center(
        child: Text('No offers available yet',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      ),
    );
  }
}
