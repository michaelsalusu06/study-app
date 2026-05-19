import 'package:flutter/material.dart';

/// App color constants following the design system
/// These are only used within theme definitions.
/// Widgets should use Theme.of(context) instead.
class AppColors {
  AppColors._();

  // ===========================================
  // PRIMARY COLORS
  // ===========================================
  static const Color primary = Color(0xFF1479FF);
  static const Color background = Color(0xFF193B68);
  static const Color card = Color(0xFFFFFFFF);

  // ===========================================
  // ACCENT COLORS
  // ===========================================
  static const Color accent1 = Color(0xFF14D2FF);
  static const Color accent2 = Color(0xFF14A5FF);
  static const Color accent3 = Color(0xFF14EBFF);

  // ===========================================
  // STATUS COLORS
  // ===========================================
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFF4ADE80);
  static const Color successDark = Color(0xFF16A34A);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color successContainerDark = Color(0xFF14532D);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color warningContainerDark = Color(0xFF451A03);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color errorContainerDark = Color(0xFF450A0A);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF2563EB);
  static const Color infoContainer = Color(0xFFDBEAFE);
  static const Color infoContainerDark = Color(0xFF1E3A5F);

  // ===========================================
  // LIGHT THEME COLORS
  // ===========================================
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF4F5F7);
  static const Color surfaceContainerHigh = Color(0xFFECEEF1);

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);
  static const Color textInverse = Color(0xFFFFFFFF);

  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);

  // ===========================================
  // DARK THEME COLORS
  // ===========================================
  static const Color darkBackground = Color(0xFF0D0F14);
  static const Color darkSurface = Color(0xFF161921);
  static const Color darkSurfaceVariant = Color(0xFF1E222A);
  static const Color darkSurfaceContainerHigh = Color(0xFF262A34);

  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFFB3B8C4);
  static const Color darkTextTertiary = Color(0xFF7C8494);
  static const Color darkTextDisabled = Color(0xFF4B5563);
  static const Color darkTextInverse = Color(0xFF1A1D26);

  static const Color darkDivider = Color(0xFF2A2F3A);
  static const Color darkBorder = Color(0xFF2A2F3A);
  static const Color darkBorderLight = Color(0xFF1E222A);

  // ===========================================
  // SEMANTIC UI COLORS
  // ===========================================
  static const Color starGold              = Color(0xFFFFB800);
  static const Color googleBrand           = Color(0xFF4285F4);
  static const Color logoCyanShadow        = Color(0xFF1AE8FF);
  static const Color primaryGradientMid    = Color(0xFF147EFF);
  static const Color primaryGradientEnd    = Color(0xFF149AFF);

  // Dashboard & stats
  static const Color statsStudents         = Color(0xFF6C63FF);
  static const Color statsCourses          = Color(0xFFFF6B6B);
  static const Color statsEarnings         = Color(0xFF4CAF50);
  static const Color dashboardGradientTop  = Color(0xFF1565C0);
  static const Color dashboardGradientBottom = Color(0xFFD6E8FF);
  static const Color sectionLabelDark      = Color(0xFF1A237E);

  // ===========================================
  // GRADIENTS
  // ===========================================
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1479FF), Colors.white],
    stops: [0.0, 0.75],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [accent1, AppColors.accent2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, successLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1D26), Color(0xFF2A2F3A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===========================================
  // SHADOWS
  // ===========================================
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x14000000);
  static const Color shadowDark = Color(0x1F000000);

  static const Color darkShadowLight = Color(0x0AFFFFFF);
  static const Color darkShadowMedium = Color(0x14FFFFFF);

  // ===========================================
  // OVERLAYS
  // ===========================================
  static const Color overlayLight = Color(0x80000000);
  static const Color overlayDark = Color(0x80FFFFFF);
  static const Color scrimLight = Color(0x33000000);
  static const Color scrimDark = Color(0x33FFFFFF);
}

/// Extension on BuildContext for easy theme access
extension ThemeContext on BuildContext {
  /// Get the current theme data
  ThemeData get theme => Theme.of(this);

  /// Get the color scheme
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Get the text theme
  TextTheme get textStyles => Theme.of(this).textTheme;

  /// Check if dark mode is enabled
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Get adaptive color based on theme
  Color adaptiveColor({required Color light, required Color dark}) {
    return isDarkMode ? dark : light;
  }
}

/// Extension on ColorScheme for custom semantic colors
extension ColorSchemeExtension on ColorScheme {
  /// Check if dark mode
  bool get _isDark => brightness == Brightness.dark;

  /// Success color for positive states
  Color get successColor =>
      _isDark ? AppColors.successLight : AppColors.success;

  /// Success container color
  Color get successContainer =>
      _isDark ? AppColors.successContainerDark : AppColors.successContainer;

  /// Warning color for caution states
  Color get warningColor =>
      _isDark ? AppColors.warningLight : AppColors.warning;

  /// Warning container color
  Color get warningContainer =>
      _isDark ? AppColors.warningContainerDark : AppColors.warningContainer;

  /// Info color for informational states
  Color get infoColor => _isDark ? AppColors.infoLight : AppColors.info;

  /// Info container color
  Color get infoContainer =>
      _isDark ? AppColors.infoContainerDark : AppColors.infoContainer;

  /// Tertiary brand color
  Color get tertiaryBrand => AppColors.accent2;

  /// Tertiary container color
  Color get tertiaryBrandContainer => AppColors.accent3;

  /// Surface variant for subtle backgrounds
  Color get surfaceVariantColor =>
      _isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

  /// High emphasis surface
  Color get surfaceHigh => _isDark
      ? AppColors.darkSurfaceContainerHigh
      : AppColors.surfaceContainerHigh;

  /// Border color
  Color get borderColor => _isDark ? AppColors.darkBorder : AppColors.border;

  /// Light border color
  Color get borderLightColor =>
      _isDark ? AppColors.darkBorderLight : AppColors.borderLight;

  /// Divider color
  Color get dividerColor => _isDark ? AppColors.darkDivider : AppColors.divider;

  /// Tertiary text color
  Color get textTertiary =>
      _isDark ? AppColors.darkTextTertiary : AppColors.textTertiary;

  /// Disabled text color
  Color get textDisabledColor =>
      _isDark ? AppColors.darkTextDisabled : AppColors.textDisabled;

  /// Shadow color
  Color get shadowColor =>
      _isDark ? AppColors.darkShadowLight : AppColors.shadowLight;

  /// Medium shadow color
  Color get shadowMediumColor =>
      _isDark ? AppColors.darkShadowMedium : AppColors.shadowMedium;
}
