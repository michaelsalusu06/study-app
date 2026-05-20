import 'package:flutter/material.dart';

import '../../constants/app_sizes.dart';

/// Social auth button used for Google / Apple sign-in.
///
/// The [icon] parameter lets you pass any widget (e.g. SVG, image).
/// Social auth button used for Google / Apple sign-in.
/// the [icon] will be look like this
/// ```
/// icon: const Icon(Icons.apple),
/// ```
class SocialAuthButton extends StatelessWidget {
  
  const SocialAuthButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.isLoading = false,
    VoidCallback? onApplePressed,
    VoidCallback? onGooglePressed,
    String? googleButtonText,
    String? appleButtonText,
  });

  final String label;
  final Widget? icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveBackgroundColor = backgroundColor ?? colorScheme.surface;
    final effectiveBorderColor = borderColor ?? colorScheme.outline;
    final effectiveTextColor = textColor ?? colorScheme.onSurface;

    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          foregroundColor: effectiveTextColor,
          side: BorderSide(
            color: effectiveBorderColor,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: AppSizes.iconMd,
                height: AppSizes.iconMd,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: AppSizes.iconLg,
                    height: AppSizes.iconLg,
                    child: Center(child: icon),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: effectiveTextColor,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
