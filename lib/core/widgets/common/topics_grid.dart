import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

class TopicsGrid extends StatelessWidget {
  const TopicsGrid({super.key, this.onTopicTap});

  final void Function(String topic)? onTopicTap;

  static const _topics = [
    (Icons.calculate_outlined, 'Math'),
    (Icons.code_rounded, 'Coding'),
    (Icons.language_rounded, 'Language'),
    (Icons.music_note_rounded, 'Music'),
    (Icons.science_outlined, 'Science'),
    (Icons.brush_rounded, 'Art'),
    (Icons.history_edu_rounded, 'History'),
    (Icons.fitness_center_rounded, 'PE'),
  ];

  @override
  Widget build(BuildContext context) {
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
      itemCount: _topics.length,
      itemBuilder: (_, i) {
        final (icon, label) = _topics[i];
        return GestureDetector(
          onTap: onTopicTap != null ? () => onTopicTap!(label) : null,
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
                        offset: Offset(0, 2)),
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
                  color: AppColors.sectionLabelDark,
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
}
