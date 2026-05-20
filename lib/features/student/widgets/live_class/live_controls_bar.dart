import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';

class LiveControlsBar extends StatelessWidget {
  const LiveControlsBar({super.key, required this.onLeave});

  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(context,
              icon: Icons.mic_off_outlined, label: 'Mute', onTap: () {}),
          _buildControlButton(context,
              icon: Icons.videocam_off_outlined,
              label: 'Camera',
              onTap: () {}),
          _buildControlButton(context,
              icon: Icons.handshake_outlined,
              label: 'Raise Hand',
              onTap: () {}),
          _buildControlButton(context,
              icon: Icons.emoji_emotions_outlined, label: 'React', onTap: () {}),
          _buildControlButton(context,
              icon: Icons.call_end_rounded,
              label: 'Leave',
              onTap: onLeave,
              isDestructive: true),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDestructive
                  ? colorScheme.errorContainer
                  : colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: isDestructive
                    ? colorScheme.error
                    : colorScheme.onSurface),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: isDestructive
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
