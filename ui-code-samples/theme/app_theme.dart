import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// PDF Pro – Scan & OCR design tokens.
///
/// Red is the brand and the primary action colour (scan, CTAs, premium). Navy carries
/// headings and the dark theme. Blue is for document/secondary actions and links,
/// green for success, orange for warnings and purple (sparingly) for OCR / smart tools.
class AppColors {
  AppColors._();

  // Brand palette.
  static const Color red = Color(0xFFFF3B30);
  static const Color redDark = Color(0xFFFF453A); // iOS dark-mode red, better contrast on navy
  static const Color navy = Color(0xFF0F172A);
  static const Color blue = Color(0xFF007AFF);
  static const Color green = Color(0xFF34C759);
  static const Color orange = Color(0xFFFF9500);
  static const Color purple = Color(0xFF7C3AED);
  static const Color slate = Color(0xFF64748B);

  /// Destructive actions and errors (rose, so it reads differently from the brand red).
  static const Color danger = Color(0xFFE11D48);

  // Semantic aliases used across the app.
  static const Color brand = red;
  static const Color brandDark = redDark;
  static const Color accent = green;
  static const Color warning = orange;

  // Light surfaces.
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh = Color(0xFFF1F5F9);
  static const Color lightOutline = Color(0xFFE2E8F0);
  static const Color lightText = navy;
  static const Color lightMuted = Color(0xFF64748B);

  // Dark surfaces (navy foundation, not inverted colours).
  static const Color darkBg = Color(0xFF0B1222);
  static const Color darkSurface = Color(0xFF162033);
  static const Color darkSurfaceHigh = Color(0xFF1E2A40);
  static const Color darkOutline = Color(0xFF2A3850);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkMuted = Color(0xFF94A3B8);

  /// Palette offered in colour pickers (annotations, text, watermark).
  static const List<Color> palette = [
    Color(0xFF111111),
    Color(0xFFFFFFFF),
    Color(0xFFFF3B30),
    Color(0xFF007AFF),
    Color(0xFF34C759),
    Color(0xFFFF9500),
    Color(0xFFFFCC00),
    Color(0xFF7C3AED),
    Color(0xFF0F172A),
    Color(0xFF94A3B8),
  ];

  static const List<Color> highlighterPalette = [
    Color(0xFFFFEB3B),
    Color(0xFF76FF03),
    Color(0xFF18FFFF),
    Color(0xFFFF80AB),
    Color(0xFFFFAB40),
  ];

  /// Soft card shadow used instead of borders in light mode.
  static List<BoxShadow> softShadow(Brightness b) => b == Brightness.dark
      ? const []
      : const [
          BoxShadow(color: Color(0x0F0F172A), blurRadius: 18, offset: Offset(0, 6)),
          BoxShadow(color: Color(0x080F172A), blurRadius: 3, offset: Offset(0, 1)),
        ];
}

class Gaps {
  Gaps._();
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Cards and tool tiles.
  static const double radius = 18;

  /// Buttons, fields, small containers.
  static const double radiusS = 14;

  /// Sheets and hero cards.
  static const double radiusL = 26;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    final primary = isDark ? AppColors.redDark : AppColors.red;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final high = isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh;
    final outlineVariant = isDark ? AppColors.darkOutline : AppColors.lightOutline;

    final scheme = ColorScheme.fromSeed(seedColor: AppColors.red, brightness: b).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primary.withValues(alpha: isDark ? 0.22 : 0.10),
      onPrimaryContainer: isDark ? const Color(0xFFFFB4AE) : const Color(0xFFB3261E),
      secondary: isDark ? const Color(0xFF0A84FF) : AppColors.blue,
      onSecondary: Colors.white,
      tertiary: AppColors.purple,
      onTertiary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: muted,
      surfaceContainerLowest: bg,
      surfaceContainerLow: isDark ? const Color(0xFF111A2C) : const Color(0xFFFBFCFE),
      surfaceContainer: surface,
      surfaceContainerHigh: high,
      surfaceContainerHighest: isDark ? const Color(0xFF26344D) : const Color(0xFFE2E8F0),
      outline: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
      outlineVariant: outlineVariant,
      inverseSurface: isDark ? AppColors.darkText : AppColors.navy,
      onInverseSurface: isDark ? AppColors.navy : Colors.white,
      shadow: AppColors.navy,
    );

    final base = ThemeData(
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
    );

    // iOS-style type scale: bold large titles, semibold section titles, regular body.
    final t = base.textTheme;
    final textTheme = t
        .copyWith(
          displaySmall: t.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.0),
          headlineLarge: t.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.9),
          headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.7, fontSize: 30),
          headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
          titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
          titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.1),
          titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          bodyLarge: t.bodyLarge?.copyWith(height: 1.35),
          bodyMedium: t.bodyMedium?.copyWith(height: 1.35),
          labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
          labelMedium: t.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        )
        .apply(bodyColor: text, displayColor: text);

    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Gaps.radiusS));

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: outlineVariant,
        centerTitle: true,
        foregroundColor: text,
        titleTextStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 17, color: text),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 1.5,
        shadowColor: AppColors.navy.withValues(alpha: 0.10),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Gaps.radius),
          side: isDark ? BorderSide(color: outlineVariant.withValues(alpha: 0.6)) : BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: buttonShape,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: buttonShape,
          foregroundColor: text,
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
          padding: const EdgeInsets.symmetric(horizontal: 22),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: buttonShape,
          foregroundColor: scheme.secondary,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(44, 44),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(shape: buttonShape, minimumSize: const Size(44, 44)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 3,
        highlightElevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        extendedTextStyle: textTheme.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: isDark ? high : surface,
        hintStyle: TextStyle(color: muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Gaps.radiusS), borderSide: BorderSide(color: outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Gaps.radiusS), borderSide: BorderSide(color: outlineVariant)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Gaps.radiusS),
          borderSide: BorderSide(color: scheme.secondary, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? primary : muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(size: 25, color: states.contains(WidgetState.selected) ? primary : muted),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Gaps.radiusL))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Gaps.radiusL)),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 19),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: AppColors.navy.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Gaps.radiusS)),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        color: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? (isDark ? AppColors.darkText : AppColors.navy) : high,
        ),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
          color: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected) ? (isDark ? AppColors.navy : Colors.white) : text,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(buttonShape),
          side: WidgetStatePropertyAll(BorderSide(color: outlineVariant)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? primary.withValues(alpha: isDark ? 0.25 : 0.10) : surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? primary : text,
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.green : null,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.transparent : null,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: high,
        circularTrackColor: high,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkSurfaceHigh : AppColors.navy,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        actionTextColor: isDark ? const Color(0xFF64B5FF) : const Color(0xFF7CC0FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Gaps.radiusS)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Gaps.radiusS)),
        iconColor: muted,
        minVerticalPadding: 10,
      ),
      dividerTheme: DividerThemeData(color: outlineVariant, thickness: 1, space: 1),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: AppColors.navy.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12.5),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
