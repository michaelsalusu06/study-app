import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

class SocialAuthRow extends StatelessWidget {
  const SocialAuthRow({
    super.key,
    required this.onGoogleTap,
    required this.onAppleTap,
  });

  final VoidCallback onGoogleTap;
  final VoidCallback onAppleTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SocialIconButton(
          onPressed: onGoogleTap,
          child: const GoogleLogo(),
        ),
        const SizedBox(width: AppSizes.md),
        SocialIconButton(
          onPressed: onAppleTap,
          child: const AppleLogo(),
        ),
      ],
    );
  }
}

class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const FaIcon(
      FontAwesomeIcons.google,
      size: 26,
      color: AppColors.googleBrand,
    );
  }
}

class AppleLogo extends StatelessWidget {
  const AppleLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const FaIcon(FontAwesomeIcons.apple, size: 28, color: Colors.black);
  }
}

class SocialIconButton extends StatelessWidget {
  const SocialIconButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          border: Border.all(color: AppColors.info, width: 1.5),
        ),
        child: Center(child: child),
      ),
    );
  }
}
