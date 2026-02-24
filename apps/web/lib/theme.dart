import 'package:flutter/material.dart';

// ──────────────────────────────────────────────
//  NOTON Design Tokens
// ──────────────────────────────────────────────

class NotonColors {
  NotonColors._();

  // Brand
  static const primary = Color(0xFF5C6BC0);      // indigo-400
  static const primaryDark = Color(0xFF3949AB);  // indigo-600

  // Neutral (Notion-inspired warm grays)
  static const bg = Color(0xFFFFFFFF);
  static const bgSecondary = Color(0xFFF7F6F3);  // sidebar bg
  static const bgHover = Color(0xFFEFEEEB);
  static const bgActive = Color(0xFFE8E7E4);

  static const border = Color(0xFFE9E9E7);
  static const borderLight = Color(0xFFF1F0ED);

  static const textPrimary = Color(0xFF1A1A19);
  static const textSecondary = Color(0xFF787774);
  static const textTertiary = Color(0xFFAFADAA);
  static const textLink = Color(0xFF5C6BC0);

  // Status
  static const error = Color(0xFFEB5757);
  static const success = Color(0xFF0F7B6C);
  static const warning = Color(0xFFFFA344);

  // Chat (Slack-inspired)
  static const chatBg = Color(0xFFFFFFFF);
  static const chatSidebar = Color(0xFF1A1D21);   // Slack dark sidebar
  static const chatSidebarText = Color(0xFFCDD0D7);
  static const chatSidebarActive = Color(0xFF1164A3);
  static const chatSidebarHover = Color(0xFF27292C);
}

// ──────────────────────────────────────────────
//  Theme
// ──────────────────────────────────────────────

ThemeData buildNotonTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: NotonColors.primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFE8EAF6),
    onPrimaryContainer: Color(0xFF1A237E),
    secondary: Color(0xFF8C93C8),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFE8EAF6),
    onSecondaryContainer: Color(0xFF3949AB),
    surface: NotonColors.bg,
    onSurface: NotonColors.textPrimary,
    surfaceContainerHighest: NotonColors.bgSecondary,
    onSurfaceVariant: NotonColors.textSecondary,
    outline: NotonColors.border,
    outlineVariant: NotonColors.borderLight,
    error: NotonColors.error,
    onError: Colors.white,
    errorContainer: Color(0xFFFDEBEB),
    onErrorContainer: Color(0xFF8B0000),
    inverseSurface: Color(0xFF1A1A19),
    onInverseSurface: Colors.white,
    inversePrimary: Color(0xFFB3BCF5),
    shadow: Color(0x0A000000),
    scrim: Color(0x33000000),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: NotonColors.bg,

    // ── Typography ──
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: NotonColors.textPrimary, letterSpacing: -1.5),
      displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: NotonColors.textPrimary, letterSpacing: -1),
      displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: NotonColors.textPrimary, letterSpacing: -0.5),
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: NotonColors.textPrimary),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: NotonColors.textPrimary),
      headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: NotonColors.textPrimary),
      titleLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: NotonColors.textPrimary),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: NotonColors.textPrimary),
      titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: NotonColors.textSecondary),
      bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: NotonColors.textPrimary, height: 1.6),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: NotonColors.textPrimary, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: NotonColors.textSecondary),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: NotonColors.textPrimary),
      labelMedium: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: NotonColors.textSecondary, letterSpacing: 0.5),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: NotonColors.textTertiary, letterSpacing: 0.5),
    ),

    // ── AppBar ──
    appBarTheme: const AppBarTheme(
      backgroundColor: NotonColors.bg,
      foregroundColor: NotonColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: NotonColors.textPrimary,
      ),
      iconTheme: IconThemeData(color: NotonColors.textSecondary, size: 20),
    ),

    // ── InputDecoration ──
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NotonColors.bgSecondary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: NotonColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: NotonColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: NotonColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: NotonColors.error),
      ),
      hintStyle: const TextStyle(color: NotonColors.textTertiary, fontSize: 14),
      labelStyle: const TextStyle(color: NotonColors.textSecondary, fontSize: 13),
    ),

    // ── Buttons ──
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: NotonColors.textPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(40),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: NotonColors.textPrimary,
        minimumSize: const Size.fromHeight(40),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        side: const BorderSide(color: NotonColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: NotonColors.textSecondary,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    ),

    // ── Divider ──
    dividerTheme: const DividerThemeData(
      color: NotonColors.border,
      thickness: 1,
      space: 1,
    ),

    // ── Card ──
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: NotonColors.border),
      ),
      color: NotonColors.bg,
      margin: EdgeInsets.zero,
    ),

    // ── ListTile ──
    listTileTheme: const ListTileThemeData(
      minLeadingWidth: 0,
      contentPadding: EdgeInsets.symmetric(horizontal: 8),
      dense: true,
      visualDensity: VisualDensity.compact,
    ),

    // ── Tooltip ──
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A19),
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      waitDuration: const Duration(milliseconds: 600),
    ),

    // ── SnackBar ──
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1A1A19),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),

    // ── Dialog ──
    dialogTheme: DialogThemeData(
      backgroundColor: NotonColors.bg,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: const TextStyle(
        fontSize: 16, fontWeight: FontWeight.w600, color: NotonColors.textPrimary,
      ),
    ),
  );
}
