import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized theme tokens and Material theme configuration.
class AppTheme {
  // BUITEMS Brand Colors
  // Primary brand color used for headers, buttons, and accents.
  static const Color primary = Color(0xFF004F8C);
  // Accent color for highlights and secondary actions.
  static const Color accent = Color.fromARGB(255, 255, 111, 0);
  // Background color for the main app canvas.
  static const Color background = Color(0xFFF8FAFC);
  // Surface color for cards and panels.
  static const Color surface = Color(0xFFFFFFFF);
  // Error color for validation and failure states.
  static const Color error = Color(0xFFDC2626);
  // Success color for positive feedback.
  static const Color success = Color(0xFF10B981);
  // Warning color for caution states.
  static const Color warning = Color(0xFFF59E0B);
  // Info color for neutral informational states.
  static const Color info = Color(0xFF3B82F6);
  // Secondary/Purple color for additional UI elements.
  static const Color secondary = Color(0xFF9C27B0);
  // Tertiary/Cyan color for alternative highlights.
  static const Color tertiary = Color(0xFF00BCD4);
  // Dark primary color for gradients and overlays.
  static const Color primaryDark = Color(0xFF003D6E);

  // Text Colors
  // Main text color for titles and body copy.
  static const Color textPrimary = Color(0xFF1E293B);
  // Secondary text color for hints and subtitles.
  static const Color textSecondary = Color(0xFF64748B);
  // Disabled text color for unavailable controls.
  static const Color textDisabled = Color(0xFFCBD5E1);

  // Border & Divider
  // Border color for outlined fields and cards.
  static const Color border = Color(0xFFE2E8F0);
  // Divider color for section separators.
  static const Color divider = Color(0xFFF1F5F9);

  /// Builds the shared light theme used by the app.
  static ThemeData get lightTheme {
    return ThemeData(
      // Enables the Material 3 look and feel.
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      // Overall scaffold background color.
      scaffoldBackgroundColor: background,
      // Global font family used across the app.
      fontFamily: GoogleFonts.poppins().fontFamily,
      appBarTheme: AppBarTheme(
        // Keep app bars flat and clean.
        elevation: 0,
        // Center titles for a balanced layout.
        centerTitle: true,
        // Default app bar background.
        backgroundColor: Colors.white,
        // Default app bar content color.
        foregroundColor: textPrimary,
        // Remove surface tint to preserve the chosen white background.
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          // Primary button fill.
          backgroundColor: primary,
          // Button text/icon color.
          foregroundColor: Colors.white,
          // Flat button look.
          elevation: 0,
          // Comfortable hit area.
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          // Outlined buttons use the primary color for emphasis.
          foregroundColor: primary,
          // Match the brand color for the outline.
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        // Filled input fields are easier to scan and tap.
        filled: true,
        // Use white so fields stand out on the light background.
        fillColor: Colors.white,
        // Internal spacing inside text fields.
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(
          color: textSecondary,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.poppins(
          color: textSecondary,
          fontSize: 14,
        ),
      ),
      cardTheme: const CardThemeData(
        // Keep cards flat and consistent.
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        // Subtle divider lines between sections.
        color: divider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        // Use the primary text color as the snackbar background.
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Text Styles
  // Large page title style.
  static TextStyle get h1 => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      );

  // Section heading style.
  static TextStyle get h2 => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      );

  // Subheading style.
  static TextStyle get h3 => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  // Standard body text for longer content.
  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 16,
        color: textPrimary,
      );

  // Default body text for forms and labels.
  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: 14,
        color: textPrimary,
      );

  // Smaller supporting text.
  static TextStyle get bodySmall => GoogleFonts.poppins(
        fontSize: 12,
        color: textSecondary,
      );

  // Dashboard section heading style.
  static TextStyle get dashboardSectionTitle => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      );

  // Dashboard stat card value style.
  static TextStyle dashboardStatValue(Color color) => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
      );

  // Dashboard stat card label style.
  static TextStyle get dashboardStatLabel => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      );

  // Dashboard action label style.
  static TextStyle dashboardActionLabel(Color color) => GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.2,
      );

  // Dashboard welcome text on dark headers.
  static TextStyle get dashboardWelcomeGreeting => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white70,
      );

  // Dashboard welcome title on dark headers.
  static TextStyle get dashboardWelcomeName => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );

  // Dashboard welcome subtitle on dark headers.
  static TextStyle get dashboardWelcomeSubtitle => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Colors.white70,
      );

  // Drawer header name style on dark backgrounds.
  static TextStyle get dashboardDrawerName => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );

  // Drawer header email style on dark backgrounds.
  static TextStyle get dashboardDrawerEmail => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Colors.white70,
      );

  // Caption text for the smallest supporting labels.
  static TextStyle get caption => GoogleFonts.poppins(
        fontSize: 12,
        color: textSecondary,
      );
}
