import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common/gradient_text.dart';
import 'lern_logo_box.dart';
import 'onboarding_models.dart';

/// Renders a single onboarding page — animated or static.
/// Pass animation .value fields for live pages; pass 1.0 for static/inactive pages.
class OnboardingPageContent extends StatelessWidget {
  const OnboardingPageContent({
    super.key,
    required this.page,
    required this.isHero,
    required this.iconScaleVal,
    required this.iconFadeVal,
    required this.titleSlideTVal,
    required this.titleFadeVal,
    required this.subtitleSlideTVal,
    required this.subtitleFadeVal,
    required this.pageDirection,
  });

  final OnboardingPage page;
  final bool isHero;
  final double iconScaleVal;
  final double iconFadeVal;
  final double titleSlideTVal;
  final double titleFadeVal;
  final double subtitleSlideTVal;
  final double subtitleFadeVal;
  final int pageDirection;

  static const _titleGradient = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryGradientMid, AppColors.primaryGradientEnd],
    stops: [0.0, 0.28, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    return isHero ? _buildHeroContent(context) : _buildRegularContent(context);
  }

  Widget _buildHeroContent(BuildContext context) {
    final titleFade = titleFadeVal.clamp(0.0, 1.0);
    final titleOffset = Offset((1.0 - titleSlideTVal) * 80 * pageDirection, 0);
    final subtitleFade = subtitleFadeVal.clamp(0.0, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Opacity(
          opacity: iconFadeVal.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: iconScaleVal.clamp(0.0, 1.3),
            child: const LernLogoBox(),
          ),
        ),
        const SizedBox(height: 40),
        // Color alpha on Text avoids compositing layer
        Transform.translate(
          offset: titleOffset,
          child: Text(
            'Hi, Welcome to',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85 * titleFade),
              fontSize: 18,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        // GradientText uses a shader — must keep Opacity here
        Opacity(
          opacity: titleFade,
          child: Transform.translate(
            offset: titleOffset,
            child: const GradientText(
              'Lern',
              gradient: _titleGradient,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 80,
                letterSpacing: -3,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Transform.translate(
          offset: Offset((1.0 - subtitleSlideTVal) * 60 * pageDirection, 0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              page.subtitle,
              style: TextStyle(
                color: AppColors.primary.withOpacity(subtitleFade),
                height: 1.6,
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegularContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final titleFade = titleFadeVal.clamp(0.0, 1.0);
    final subtitleFade = subtitleFadeVal.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: iconFadeVal.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: iconScaleVal.clamp(0.0, 1.3),
              child: _buildIconContainer(page),
            ),
          ),
          const SizedBox(height: AppSizes.xxl),
          // GradientText uses shader — keep Opacity
          Opacity(
            opacity: titleFade,
            child: Transform.translate(
              offset: Offset((1.0 - titleSlideTVal) * 80 * pageDirection, 0),
              child: _buildTitleText(page, theme),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          // Color alpha on Text avoids compositing layer
          Transform.translate(
            offset: Offset((1.0 - subtitleSlideTVal) * 60 * pageDirection, 0),
            child: Text(
              page.subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(subtitleFade),
                height: 1.6,
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleText(OnboardingPage page, ThemeData theme) {
    return GradientText(
      page.title,
      gradient: _titleGradient,
      style: theme.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 40,
        letterSpacing: -1,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildIconContainer(OnboardingPage page) {
    const configs = [
      IconConfig(Icons.school_rounded,
          [AppColors.primary, AppColors.accent2]),
      IconConfig(Icons.person_search_rounded,
          [AppColors.primary, AppColors.accent2]),
      IconConfig(Icons.verified_rounded,
          [AppColors.primary, AppColors.accent2]),
      IconConfig(Icons.auto_stories_rounded,
          [AppColors.primary, AppColors.accent2]),
    ];
    // Find config by icon match
    final cfg = configs.firstWhere(
      (c) => c.icon == page.icon,
      orElse: () => configs[0],
    );

    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: cfg.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: cfg.colors.first.withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Icon(cfg.icon, size: 58, color: cfg.colors.first),
        ],
      ),
    );
  }
}
