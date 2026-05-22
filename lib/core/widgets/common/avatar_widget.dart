import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';

/// Modern avatar widget with theme-aware styling
class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AvatarSize.medium,
    this.backgroundColor,
    this.textColor,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
    this.badge,
    this.badgeColor,
    this.radius,
  });

  final String? imageUrl;
  final String? name;
  final AvatarSize size;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;
  final String? badge;
  final Color? badgeColor;
  final int? radius;

  double get _avatarSize {
    switch (size) {
      case AvatarSize.small:
        return AppSizes.avatarSm;
      case AvatarSize.medium:
        return AppSizes.avatarMd;
      case AvatarSize.large:
        return AppSizes.avatarLg;
      case AvatarSize.extraLarge:
        return AppSizes.avatarXl;
    }
  }

  double get _fontSize {
    switch (size) {
      case AvatarSize.small:
        return 12;
      case AvatarSize.medium:
        return 16;
      case AvatarSize.large:
        return 20;
      case AvatarSize.extraLarge:
        return 28;
    }
  }

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveBackgroundColor =
        backgroundColor ?? colorScheme.primaryContainer;
    final effectiveTextColor = textColor ?? colorScheme.onPrimaryContainer;
    final effectiveBorderColor =
        borderColor ?? colorScheme.primary.withOpacity(0.3);

    Widget avatar = Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveBackgroundColor,
        border: showBorder
            ? Border.all(
                color: effectiveBorderColor,
                width: 2,
              )
            : null,
        image: imageUrl != null && imageUrl!.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
                onError: (_, __) {},
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: imageUrl == null || imageUrl!.isEmpty
          ? Center(
              child: Text(
                _initials,
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.w600,
                  color: effectiveTextColor,
                ),
              ),
            )
          : null,
    );

    // Wrap with badge if provided
    if (badge != null) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: badgeColor ?? colorScheme.error,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                border: Border.all(
                  color: colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onError,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Wrap with gesture detector if onTap provided
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }
}

enum AvatarSize { small, medium, large, extraLarge }
