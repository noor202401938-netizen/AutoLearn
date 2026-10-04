import 'package:flutter/material.dart';

/// "Lecture notebook" design language.
///
/// Light mode is a sheet of graph paper written on in fountain-pen ink.
/// Dark mode is a lecture-hall blackboard written on in chalk.
/// Anything that isn't a standard Material role lives in [NotebookColors].
class AppTheme {
  // ── Paper & ink (light) ────────────────────────────────────────────────────
  static const Color paper = Color(0xFFF6F1E3);        // page background
  static const Color sheet = Color(0xFFFFFCF4);        // fresh sheet / cards
  static const Color sheetShade = Color(0xFFEDE6D3);   // tucked-under paper
  static const Color ink = Color(0xFF1D3557);          // blue-black fountain pen
  static const Color inkSoft = Color(0xFFDCE4EF);      // ink wash
  static const Color graphite = Color(0xFF4A4F59);     // pencil
  static const Color redPen = Color(0xFFC8553D);       // margin rule / corrections
  static const Color greenPen = Color(0xFF2E7D4F);     // ticks, correct answers
  static const Color highlighter = Color(0xFFFFE066);  // yellow marker
  static const Color gridLine = Color(0xFFD5E0EA);     // faint blue grid

  // ── Blackboard & chalk (dark) ──────────────────────────────────────────────
  static const Color board = Color(0xFF1F2B26);
  static const Color boardRaised = Color(0xFF26352F);
  static const Color boardShade = Color(0xFF2E3F38);
  static const Color chalk = Color(0xFFEDEAE0);
  static const Color chalkDim = Color(0xFFB4BCB5);
  static const Color chalkYellow = Color(0xFFF2DC7A);
  static const Color chalkPink = Color(0xFFF0A49A);
  static const Color chalkGreen = Color(0xFF9FD8AE);
  static const Color chalkBlue = Color(0xFFA9C8E8);
  static const Color boardGrid = Color(0xFF2C3B35);

  /// Kept for callers that only need the brand colour (window titles etc).
  static const Color primary = ink;

  /// Fonts are bundled (see pubspec.yaml), so this is just the family name.
  static TextStyle font(String family, TextStyle style) => style.copyWith(fontFamily: family);

  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        scheme: const ColorScheme.light(
          primary: ink,
          onPrimary: sheet,
          primaryContainer: inkSoft,
          onPrimaryContainer: ink,
          secondary: graphite,
          onSecondary: sheet,
          secondaryContainer: sheetShade,
          onSecondaryContainer: graphite,
          tertiary: redPen,
          onTertiary: sheet,
          tertiaryContainer: Color(0xFFF6DDD5),
          onTertiaryContainer: Color(0xFF6E2414),
          error: Color(0xFFB3261E),
          onError: Colors.white,
          errorContainer: Color(0xFFF9DEDC),
          onErrorContainer: Color(0xFF410E0B),
          surface: paper,
          onSurface: Color(0xFF1C2230),
          onSurfaceVariant: graphite,
          surfaceContainerLowest: sheet,
          surfaceContainerLow: sheet,
          surfaceContainer: sheet,
          surfaceContainerHigh: Color(0xFFF1EBDB),
          surfaceContainerHighest: sheetShade,
          outline: Color(0xFF8A8F99),
          outlineVariant: Color(0xFFD9D1BC),
        ),
        notebook: const NotebookColors(
          gridLine: gridLine,
          marginLine: redPen,
          highlighter: highlighter,
          annotation: redPen,
          correct: greenPen,
          sheet: sheet,
          stackShadow: Color(0x331D3557),
        ),
      );

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        scheme: const ColorScheme.dark(
          primary: chalk,
          onPrimary: board,
          primaryContainer: boardShade,
          onPrimaryContainer: chalk,
          secondary: chalkBlue,
          onSecondary: board,
          secondaryContainer: boardShade,
          onSecondaryContainer: chalkBlue,
          tertiary: chalkPink,
          onTertiary: board,
          tertiaryContainer: Color(0xFF4A302C),
          onTertiaryContainer: chalkPink,
          error: Color(0xFFFFB4AB),
          onError: Color(0xFF690005),
          errorContainer: Color(0xFF93000A),
          onErrorContainer: Color(0xFFFFDAD6),
          surface: board,
          onSurface: chalk,
          onSurfaceVariant: chalkDim,
          surfaceContainerLowest: board,
          surfaceContainerLow: boardRaised,
          surfaceContainer: boardRaised,
          surfaceContainerHigh: boardShade,
          surfaceContainerHighest: boardShade,
          outline: Color(0xFF7C8A83),
          outlineVariant: Color(0xFF3A4C44),
        ),
        notebook: const NotebookColors(
          gridLine: boardGrid,
          marginLine: chalkPink,
          highlighter: chalkYellow,
          annotation: chalkYellow,
          correct: chalkGreen,
          sheet: boardRaised,
          stackShadow: Color(0x66000000),
        ),
      );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required NotebookColors notebook,
  }) {
    final text = _textTheme(scheme.onSurface, scheme.onSurfaceVariant);
    const radius = BorderRadius.all(Radius.circular(6));
    final inkBorder = BorderSide(color: scheme.onSurface.withValues(alpha: 0.85), width: 1.25);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      extensions: [notebook],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: notebook.sheet,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: text.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: inkBorder,
          shape: const RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: notebook.sheet,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: scheme.outline)),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: scheme.outline)),
        focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: scheme.primary, width: 2)),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
        labelStyle: text.bodyMedium,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: notebook.sheet,
        selectedColor: notebook.highlighter.withValues(alpha: brightness == Brightness.light ? 0.7 : 0.25),
        labelStyle: text.labelMedium?.copyWith(color: scheme.onSurface),
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: notebook.sheet,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: notebook.sheet,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radius, side: inkBorder),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    );
  }

  /// Fraunces (bookish serif) for headings, IBM Plex Sans for reading,
  /// IBM Plex Mono for figures. Handwriting lives in [NotebookColors.hand].
  static TextTheme _textTheme(Color onSurf, Color onSurfVar) {
    TextStyle serif(double size, {double h = 1.2}) => font('Fraunces',
        TextStyle(fontSize: size, fontWeight: FontWeight.w600, color: onSurf, height: h, letterSpacing: -0.3));
    TextStyle sans(double size, FontWeight w, Color c, {double h = 1.5}) =>
        font('IBM Plex Sans', TextStyle(fontSize: size, fontWeight: w, color: c, height: h));

    return TextTheme(
      displayLarge: serif(44, h: 1.1),
      displayMedium: serif(36, h: 1.1),
      displaySmall: serif(30, h: 1.15),
      headlineLarge: serif(28),
      headlineMedium: serif(24),
      headlineSmall: serif(20, h: 1.3),
      titleLarge: sans(18, FontWeight.w600, onSurf, h: 1.35),
      titleMedium: sans(16, FontWeight.w600, onSurf, h: 1.4),
      titleSmall: sans(14, FontWeight.w600, onSurf, h: 1.4),
      bodyLarge: sans(16, FontWeight.w400, onSurf, h: 1.6),
      bodyMedium: sans(14, FontWeight.w400, onSurfVar, h: 1.55),
      bodySmall: sans(12, FontWeight.w400, onSurfVar),
      labelLarge: sans(14, FontWeight.w600, onSurf, h: 1.0),
      labelMedium: sans(12, FontWeight.w600, onSurfVar, h: 1.0),
      labelSmall: sans(11, FontWeight.w600, onSurfVar, h: 1.0).copyWith(letterSpacing: 0.6),
    );
  }
}

/// Notebook-specific colours that Material's [ColorScheme] has no slot for.
/// Read with `NotebookColors.of(context)`.
@immutable
class NotebookColors extends ThemeExtension<NotebookColors> {
  final Color gridLine;
  final Color marginLine;
  final Color highlighter;
  final Color annotation;
  final Color correct;
  final Color sheet;
  final Color stackShadow;

  const NotebookColors({
    required this.gridLine,
    required this.marginLine,
    required this.highlighter,
    required this.annotation,
    required this.correct,
    required this.sheet,
    required this.stackShadow,
  });

  static NotebookColors of(BuildContext context) =>
      Theme.of(context).extension<NotebookColors>()!;

  /// Handwritten margin-note style.
  TextStyle hand({double size = 20, Color? color}) =>
      AppTheme.font('Caveat', TextStyle(fontSize: size, fontWeight: FontWeight.w600, color: color ?? annotation, height: 1.1));

  /// Plain small text for labels and status. It inherits the theme's body font
  /// and colour, so informational text doesn't compete with real content.
  TextStyle note({double size = 13, Color? color}) => TextStyle(fontSize: size, height: 1.3, color: color);

  /// Tabular figures for stats, prices, scores.
  static TextStyle figures({double size = 14, FontWeight weight = FontWeight.w500, Color? color}) =>
      AppTheme.font('IBM Plex Mono', TextStyle(fontSize: size, fontWeight: weight, color: color));

  @override
  NotebookColors copyWith({
    Color? gridLine,
    Color? marginLine,
    Color? highlighter,
    Color? annotation,
    Color? correct,
    Color? sheet,
    Color? stackShadow,
  }) =>
      NotebookColors(
        gridLine: gridLine ?? this.gridLine,
        marginLine: marginLine ?? this.marginLine,
        highlighter: highlighter ?? this.highlighter,
        annotation: annotation ?? this.annotation,
        correct: correct ?? this.correct,
        sheet: sheet ?? this.sheet,
        stackShadow: stackShadow ?? this.stackShadow,
      );

  @override
  NotebookColors lerp(NotebookColors? other, double t) {
    if (other == null) return this;
    return NotebookColors(
      gridLine: Color.lerp(gridLine, other.gridLine, t)!,
      marginLine: Color.lerp(marginLine, other.marginLine, t)!,
      highlighter: Color.lerp(highlighter, other.highlighter, t)!,
      annotation: Color.lerp(annotation, other.annotation, t)!,
      correct: Color.lerp(correct, other.correct, t)!,
      sheet: Color.lerp(sheet, other.sheet, t)!,
      stackShadow: Color.lerp(stackShadow, other.stackShadow, t)!,
    );
  }
}
