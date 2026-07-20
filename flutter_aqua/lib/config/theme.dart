import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Octavia Design System — Color Tokens
/// Use light-mode constants only; for dark, resolve via [OctaviaColors.resolve].
class OctaviaColors {
  // Primary
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryLight = Color(0xFF93C5FD);
  static const Color primaryDark = Color(0xFF60A5FA);

  // Accent
  static const Color accentPink = Color(0xFFF472B6);
  static const Color accentGreen = Color(0xFF4ADE80);
  static const Color accentYellow = Color(0xFFFDE68A);

  // Background — light
  static const Color bgBase = Color(0xFFF5F7FA);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgNav = Color(0xFFFFFFFF);
  static const Color navActive = Color(0xFFEFF6FF);
  static const Color premiumBg = Color(0xFF1E2A4A);

  // Background — dark
  static const Color darkBgBase = Color(0xFF0B1120);
  static const Color darkBgCard = Color(0xFF162032);
  static const Color darkBgNav = Color(0xFF0F1729);
  static const Color darkNavActive = Color(0xFF1E3A5F);

  // Text — light
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Text — dark
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Badge
  static const Color badgePro = Color(0xFF6366F1);
  static const Color badgeMsg = Color(0xFF3B82F6);

  /// Resolve the right token for the current brightness.
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBgBase : bgBase;
  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBgCard : bgCard;
  static Color txtPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : textPrimary;
  static Color txtSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : textSecondary;
  static Color txtMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextMuted : textMuted;
}

class AppTheme {
  // ── Border Radius ──
  static const double radiusCard = 16.0;
  static const double radiusButton = 10.0;
  static const double radiusNav = 12.0;
  static const double radiusPill = 8.0;

  // ── Shadows ──
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get popupShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Light palette
    const bgBase = OctaviaColors.bgBase;
    const bgCard = OctaviaColors.bgCard;
    const textPrimary = OctaviaColors.textPrimary;
    const textSecondary = OctaviaColors.textSecondary;
    const textMuted = OctaviaColors.textMuted;

    // Dark palette — deeper, more contrast
    const darkBg = OctaviaColors.darkBgBase;
    const darkCard = OctaviaColors.darkBgCard;
    const darkTextPrimary = OctaviaColors.darkTextPrimary;
    const darkTextSecondary = OctaviaColors.darkTextSecondary;
    const darkTextMuted = OctaviaColors.darkTextMuted;

    final scaffoldBg = isDark ? darkBg : bgBase;
    final cardColor = isDark ? darkCard : bgCard;
    final txtPrimary = isDark ? darkTextPrimary : textPrimary;
    final txtSecondary = isDark ? darkTextSecondary : textSecondary;
    final txtMuted = isDark ? darkTextMuted : textMuted;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: isDark ? OctaviaColors.primaryDark : OctaviaColors.primary,
        onPrimary: Colors.white,
        primaryContainer: isDark ? const Color(0xFF172554) : const Color(0xFFEFF6FF),
        onPrimaryContainer: isDark ? OctaviaColors.primaryLight : OctaviaColors.primary,
        secondary: OctaviaColors.accentPink,
        onSecondary: Colors.white,
        secondaryContainer: isDark ? const Color(0xFF2D1A2A) : const Color(0xFFFCE7F3),
        onSecondaryContainer: isDark ? OctaviaColors.accentPink : const Color(0xFF9D174D),
        tertiary: OctaviaColors.accentGreen,
        onTertiary: Colors.white,
        tertiaryContainer: isDark ? const Color(0xFF0C2218) : const Color(0xFFECFDF5),
        onTertiaryContainer: isDark ? OctaviaColors.accentGreen : const Color(0xFF065F46),
        error: const Color(0xFFEF4444),
        onError: Colors.white,
        errorContainer: isDark ? const Color(0xFF3B1111) : const Color(0xFFFEF2F2),
        onErrorContainer: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
        surface: scaffoldBg,
        onSurface: txtPrimary,
        surfaceContainerLow: cardColor,
        surfaceContainer: isDark ? const Color(0xFF1A2744) : const Color(0xFFF1F5F9),
        surfaceContainerHighest: isDark ? const Color(0xFF253552) : const Color(0xFFE2E8F0),
        onSurfaceVariant: txtSecondary,
        outline: txtMuted,
        outlineVariant: isDark ? const Color(0xFF253552) : const Color(0xFFE2E8F0),
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        // Display / Heading — Poppins
        headlineLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: txtPrimary,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: txtPrimary,
          height: 1.3,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: txtPrimary,
          height: 1.3,
        ),
        // Section heading
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: txtPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: txtPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: txtPrimary,
        ),
        // Body
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: txtPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: txtSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: txtMuted,
        ),
        // Label
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: txtPrimary,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: txtSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: txtMuted,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusButton),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusButton),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF253552) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusButton),
          borderSide: BorderSide(
            color: isDark ? OctaviaColors.primaryDark : OctaviaColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusButton),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: txtMuted,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: txtMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scaffoldBg,
        foregroundColor: txtPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: txtPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: isDark ? OctaviaColors.primaryDark : OctaviaColors.primary,
        unselectedItemColor: txtMuted,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        indicatorColor: isDark ? OctaviaColors.darkNavActive : OctaviaColors.navActive,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? (isDark ? OctaviaColors.primaryDark : OctaviaColors.primary)
                : txtMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: isSelected
                ? (isDark ? OctaviaColors.primaryDark : OctaviaColors.primary)
                : txtMuted,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: OctaviaColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: OctaviaColors.primary,
          side: const BorderSide(color: OctaviaColors.primary, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF1A2744) : const Color(0xFFF1F5F9),
        selectedColor: isDark ? OctaviaColors.darkNavActive : OctaviaColors.navActive,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: txtSecondary,
        ),
        side: BorderSide(
          color: isDark ? const Color(0xFF253552) : const Color(0xFFE2E8F0),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF253552) : const Color(0xFFE2E8F0),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1A2744) : OctaviaColors.textPrimary,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 13,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusButton),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF162032) : cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: txtPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 13,
          color: txtSecondary,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return txtMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? OctaviaColors.primaryDark : OctaviaColors.primary;
          }
          return isDark ? const Color(0xFF253552) : const Color(0xFFE2E8F0);
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: isDark ? OctaviaColors.primaryDark : OctaviaColors.primary,
        unselectedLabelColor: txtMuted,
        indicatorColor: isDark ? OctaviaColors.primaryDark : OctaviaColors.primary,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
        dividerColor: isDark ? const Color(0xFF253552) : const Color(0xFFE2E8F0),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: isDark ? const Color(0xFF162032) : Colors.transparent,
        collapsedBackgroundColor: cardColor,
        iconColor: txtSecondary,
        collapsedIconColor: txtMuted,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF162032) : bgCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? OctaviaColors.primaryDark : OctaviaColors.primary,
      ),
    );
  }

  static ThemeData light() => _buildTheme(Brightness.light);
  static ThemeData dark() => _buildTheme(Brightness.dark);
}
