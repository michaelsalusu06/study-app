import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Application theme configuration
/// Modern, clean design with proper light/dark mode support
class AppTheme {
  AppTheme._();

  // ============================================
  // LIGHT THEME
  // ============================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Manrope',
      // Color Scheme
      colorScheme: ColorScheme.light(
        // Primary colors
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.accent1,
        onPrimaryContainer: AppColors.primary,
        // Secondary colors
        secondary: AppColors.accent2,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.accent2,
        onSecondaryContainer: AppColors.accent2,
        // Tertiary colors
        tertiary: AppColors.accent3,
        onTertiary: Colors.white,
        tertiaryContainer: AppColors.accent3,
        onTertiaryContainer: AppColors.accent3,
        // Error colors
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.errorDark,

        // Surface colors
        surface: AppColors.surface,
        onSurface: const Color(0xFF1479FF),
        surfaceContainerHighest: AppColors.surfaceContainerHigh,

        // Background
        surfaceTint: AppColors.primary.withAlpha(12),

        // Outline
        outline: AppColors.border,
        outlineVariant: AppColors.borderLight,

        // Inverse
        inverseSurface: AppColors.textPrimary,
        onInverseSurface: Colors.white,
        inversePrimary: AppColors.accent1,
        // Shadow & scrim
        shadow: AppColors.shadowMedium,
        scrim: AppColors.scrimLight,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.background,

      // AppBar Theme - Clean and minimal
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        titleSpacing: AppSizes.md,
        titleTextStyle: GoogleFonts.manrope(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),

      // Text Theme - Modern typography
      textTheme: _buildLightTextTheme(),

      // Elevated Button Theme - Modern filled buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      // Filled Button Theme (Material 3)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(64, AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      // Input Decoration Theme - Clean inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        labelStyle: GoogleFonts.manrope(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.manrope(
          color: AppColors.textTertiary,
          fontSize: 14,
        ),
        errorStyle: GoogleFonts.manrope(
          color: AppColors.error,
          fontSize: 12,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),
      // Card Theme - Subtle elevation
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent1,
        elevation: 0,
        height: AppSizes.bottomNavHeight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            );
          }
          return GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.primary,
              size: 24,
            );
          }
          return const IconThemeData(
            color: AppColors.textTertiary,
            size: 24,
          );
        }),
      ),
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 2,
        shape: CircleBorder(),
      ),
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.accent1,
        disabledColor: AppColors.surfaceVariant,
        labelStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        secondaryLabelStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm, vertical: AppSizes.xs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        side: BorderSide.none,
      ),
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
        ),
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
      ),
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        elevation: 3,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.manrope(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.manrope(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 3,
      ),
      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        dividerColor: AppColors.divider,
      ),
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceVariant,
        circularTrackColor: AppColors.surfaceVariant,
      ),
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent1;
          }
          return AppColors.border;
        }),
      ),
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
      ),
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textTertiary;
        }),
      ),
      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),
      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: AppColors.primary,
        size: 24,
      ),
    );
  }

  // ============================================
  // DARK THEME
  // ============================================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Manrope',
      // Color Scheme
      colorScheme: ColorScheme.dark(
        // Primary colors
        primary: AppColors.accent1,
        onPrimary: AppColors.textPrimary,
        primaryContainer: AppColors.accent1,
        onPrimaryContainer: AppColors.accent1,
        // Secondary colors
        secondary: AppColors.accent2,
        onSecondary: AppColors.textPrimary,
        secondaryContainer: AppColors.accent2,
        onSecondaryContainer: AppColors.accent2,
        // Tertiary colors
        tertiary: AppColors.accent3,
        onTertiary: AppColors.textPrimary,
        tertiaryContainer: AppColors.accent3,
        onTertiaryContainer: AppColors.accent3,
        // Error colors
        error: AppColors.errorLight,
        onError: AppColors.textPrimary,
        errorContainer: AppColors.errorContainerDark,
        onErrorContainer: AppColors.errorLight,
        // Surface colors
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        surfaceContainerHighest: AppColors.darkSurfaceContainerHigh,

        // Background
        surfaceTint: AppColors.accent1.withAlpha(12),

        // Outline
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkBorderLight,

        // Inverse
        inverseSurface: AppColors.darkTextPrimary,
        onInverseSurface: AppColors.darkBackground,
        inversePrimary: AppColors.primary,
        // Shadow & scrim
        shadow: Colors.black45,
        scrim: AppColors.scrimDark,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.background,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        centerTitle: false,
        titleSpacing: AppSizes.md,
        titleTextStyle: GoogleFonts.manrope(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.darkTextPrimary,
          size: 24,
        ),
      ),

      // Text Theme
      textTheme: _buildDarkTextTheme(),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent1,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(64, AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      // Filled Button Theme (Material 3)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent1,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(64, AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent1,
          minimumSize: const Size(64, AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          side: const BorderSide(color: AppColors.accent1, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent1,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.accent1, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.errorLight),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.errorLight, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.darkBorderLight),
        ),
        labelStyle: GoogleFonts.manrope(
          color: AppColors.darkTextSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.manrope(
          color: AppColors.darkTextTertiary,
          fontSize: 14,
        ),
        errorStyle: GoogleFonts.manrope(
          color: AppColors.errorLight,
          fontSize: 12,
        ),
        prefixIconColor: AppColors.darkTextSecondary,
        suffixIconColor: AppColors.darkTextSecondary,
      ),
      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.accent1,
        unselectedItemColor: AppColors.darkTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.accent1,
        elevation: 0,
        height: AppSizes.bottomNavHeight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.accent1,
            );
          }
          return GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.darkTextTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.accent1,
              size: 24,
            );
          }
          return const IconThemeData(
            color: AppColors.darkTextTertiary,
            size: 24,
          );
        }),
      ),
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent1,
        foregroundColor: AppColors.textPrimary,
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 2,
        shape: CircleBorder(),
      ),
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        selectedColor: AppColors.accent1,
        disabledColor: AppColors.darkSurfaceVariant,
        labelStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextPrimary,
        ),
        secondaryLabelStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextPrimary,
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm, vertical: AppSizes.xs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        side: BorderSide.none,
      ),
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
        ),
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: AppColors.darkBorder,
      ),
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        elevation: 3,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        contentTextStyle: GoogleFonts.manrope(
          fontSize: 14,
          color: AppColors.darkTextSecondary,
        ),
      ),
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceContainerHigh,
        contentTextStyle: GoogleFonts.manrope(
          color: AppColors.darkTextPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 3,
      ),
      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.accent1,
        unselectedLabelColor: AppColors.darkTextSecondary,
        labelStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.accent1, width: 2),
        ),
        dividerColor: AppColors.darkDivider,
      ),
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent1,
        linearTrackColor: AppColors.darkSurfaceVariant,
        circularTrackColor: AppColors.darkSurfaceVariant,
      ),
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent1;
          }
          return AppColors.darkTextTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.darkBorder;
        }),
      ),
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent1;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
      ),
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent1;
          }
          return AppColors.darkTextTertiary;
        }),
      ),
      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.darkTextPrimary,
        size: 24,
      ),
      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: AppColors.accent1,
        size: 24,
      ),
    );
  }

  // ============================================
  // TEXT THEMES
  // ============================================
  /// Build text theme for light mode
  static TextTheme _buildLightTextTheme() {
    final baseTheme = GoogleFonts.manropeTextTheme();
    return baseTheme.copyWith(
      // Display - Large headlines
      displayLarge: baseTheme.displayLarge?.copyWith(
        color: AppColors.textPrimary,
        letterSpacing: -1,
        height: 1.2,
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.25,
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.3,
      ),
      // Headlines
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.3,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
        height: 1.35,
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
        height: 1.4,
      ),
      // Titles
      titleLarge: baseTheme.titleLarge?.copyWith(
        color: AppColors.textPrimary,
        letterSpacing: 0,
        height: 1.4,
      ),
      titleMedium: baseTheme.titleMedium?.copyWith(
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      titleSmall: baseTheme.titleSmall?.copyWith(
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
        height: 1.4,
      ),
      // Body
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        color: AppColors.textPrimary,
        letterSpacing: 0,
        height: 1.5,
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
        height: 1.5,
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
        height: 1.5,
      ),
      // Labels
      labelLarge: baseTheme.labelLarge?.copyWith(
        color: AppColors.textPrimary,
        letterSpacing: 0.3,
        height: 1.4,
      ),
      labelMedium: baseTheme.labelMedium?.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
        height: 1.4,
      ),
      labelSmall: baseTheme.labelSmall?.copyWith(
        color: AppColors.textTertiary,
        letterSpacing: 0.4,
        height: 1.4,
      ),
    );
  }

  /// Build text theme for dark mode
  static TextTheme _buildDarkTextTheme() {
    final baseTheme = GoogleFonts.manropeTextTheme();
    return baseTheme.copyWith(
      // Display - Large headlines
      displayLarge: baseTheme.displayLarge?.copyWith(
        color: AppColors.darkTextPrimary,
        letterSpacing: -1,
        height: 1.2,
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        color: AppColors.darkTextPrimary,
        letterSpacing: -0.5,
        height: 1.25,
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        color: AppColors.darkTextPrimary,
        letterSpacing: -0.5,
        height: 1.3,
      ),
      // Headlines
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        color: AppColors.darkTextPrimary,
        letterSpacing: -0.5,
        height: 1.3,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        color: AppColors.darkTextPrimary,
        letterSpacing: -0.3,
        height: 1.35,
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        color: AppColors.darkTextPrimary,
        letterSpacing: -0.2,
        height: 1.4,
      ),
      // Titles
      titleLarge: baseTheme.titleLarge?.copyWith(
        color: AppColors.darkTextPrimary,
        letterSpacing: 0,
        height: 1.4,
      ),
      titleMedium: baseTheme.titleMedium?.copyWith(
        color: AppColors.darkTextPrimary,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      titleSmall: baseTheme.titleSmall?.copyWith(
        color: AppColors.darkTextPrimary,
        letterSpacing: 0.2,
        height: 1.4,
      ),
      // Body
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        color: AppColors.darkTextPrimary,
        letterSpacing: 0,
        height: 1.5,
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        color: AppColors.darkTextPrimary,
        letterSpacing: 0.1,
        height: 1.5,
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        color: AppColors.darkTextSecondary,
        letterSpacing: 0.2,
        height: 1.5,
      ),
      // Labels
      labelLarge: baseTheme.labelLarge?.copyWith(
        color: AppColors.darkTextPrimary,
        letterSpacing: 0.3,
        height: 1.4,
      ),
      labelMedium: baseTheme.labelMedium?.copyWith(
        color: AppColors.darkTextSecondary,
        letterSpacing: 0.3,
        height: 1.4,
      ),
      labelSmall: baseTheme.labelSmall?.copyWith(
        color: AppColors.darkTextTertiary,
        letterSpacing: 0.4,
        height: 1.4,
      ),
    );
  }
}
