import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../common/loading_widget.dart';
import '../../../models/tutor_profile.dart';

class TutorCard extends StatelessWidget {
  const TutorCard({
    super.key,
    required this.tutor,
    this.onTap,
  });

  final TutorProfile tutor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              tutor.displayName,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              tutor.firstSubject.isNotEmpty ? tutor.firstSubject : 'Tutor',
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: AppColors.starGold, size: 14),
                const SizedBox(width: 2),
                Text(
                  (tutor.overallRating ?? 0).toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tutor.formattedPrice,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class TutorCardSkeleton extends StatelessWidget {
  const TutorCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
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
                  backgroundColor: AppColors.surfaceContainerHigh)),
          const SizedBox(height: 8),
          ShimmerLoading(
              child: Container(
                  height: 12,
                  width: 90,
                  decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6)))),
          const SizedBox(height: 4),
          ShimmerLoading(
              child: Container(
                  height: 10,
                  width: 60,
                  decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(5)))),
          const SizedBox(height: 4),
          ShimmerLoading(
              child: Container(
                  height: 10,
                  width: 45,
                  decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(5)))),
        ],
      ),
    );
  }
}
