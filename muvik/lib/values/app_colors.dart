import 'package:flutter/material.dart';

/// Accent options for "Màu nhấn". Each accent has a dark- and light-theme tone.
enum AccentColor {
  lavender(
    'lavender',
    'accent_lavender',
    Color(0xFF7C5CF4),
    Color(0xFF7C3AED),
    Color(0xFF6A49E8),
    Color(0xFF6D28D9),
  ),
  teal(
    'teal',
    'accent_teal',
    Color(0xFF46D9E5),
    Color(0xFF087F8C),
    Color(0xFF22C3D0),
    Color(0xFF066B76),
  ),
  coral(
    'coral',
    'accent_coral',
    Color(0xFFFB7185),
    Color(0xFFBE123C),
    Color(0xFFF43F5E),
    Color(0xFF9F1239),
  ),
  blue(
    'blue',
    'accent_blue',
    Color(0xFF60A5FA),
    Color(0xFF1D4ED8),
    Color(0xFF3B82F6),
    Color(0xFF1E40AF),
  ),
  amber(
    'amber',
    'accent_amber',
    Color(0xFFFBBF24),
    Color(0xFFA16207),
    Color(0xFFF59E0B),
    Color(0xFF854D0E),
  ),
  green(
    'green',
    'accent_green',
    Color(0xFF4ADE80),
    Color(0xFF15803D),
    Color(0xFF22C55E),
    Color(0xFF166534),
  ),
  pink(
    'pink',
    'accent_pink',
    Color(0xFFF472B6),
    Color(0xFFBE185D),
    Color(0xFFEC4899),
    Color(0xFF9D174D),
  ),
  orange(
    'orange',
    'accent_orange',
    Color(0xFFFB923C),
    Color(0xFFC2410C),
    Color(0xFFF97316),
    Color(0xFF9A3412),
  ),
  fuchsia(
    'fuchsia',
    'accent_fuchsia',
    Color(0xFFD946EF),
    Color(0xFFA21CAF),
    Color(0xFFC026D3),
    Color(0xFF86198F),
  ),
  lime(
    'lime',
    'accent_lime',
    Color(0xFFA3E635),
    Color(0xFF4D7C0F),
    Color(0xFF84CC16),
    Color(0xFF3F6212),
  ),
  indigo(
    'indigo',
    'accent_indigo',
    Color(0xFF6366F1),
    Color(0xFF4338CA),
    Color(0xFF4F46E5),
    Color(0xFF3730A3),
  ),
  ruby(
    'ruby',
    'accent_ruby',
    Color(0xFFFF3B5C),
    Color(0xFFC8102E),
    Color(0xFFE11D48),
    Color(0xFF9F1239),
  );

  const AccentColor(
    this.key,
    this.labelKey,
    this.dark,
    this.light,
    this.darkPressed,
    this.lightPressed,
  );

  final String key;
  final String labelKey;
  final Color dark;
  final Color light;
  final Color darkPressed;
  final Color lightPressed;

  static AccentColor fromKey(String key) => AccentColor.values.firstWhere(
    (a) => a.key == key,
    orElse: () => AccentColor.lavender,
  );
}

/// Design System tokens (Muvik_Design_System.docx §1–2, §11) as a ThemeExtension.
/// Widgets read colors through `context.colors`, never hardcoded hex values.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceInput,
    required this.surfaceSelected,
    required this.border,
    required this.divider,
    required this.scrim,
    required this.primary,
    required this.primaryPressed,
    required this.onPrimary,
    required this.secondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.iconDefault,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.gradientBg,
    required this.ctaGradient,
    required this.cardShadow,
    required this.sheetShadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceInput;
  final Color surfaceSelected;
  final Color border;
  final Color divider;
  final Color scrim;
  final Color primary;
  final Color primaryPressed;

  /// Lighter tone for highlighted text and progress bars (lavender: #9D85FF).
  Color get primaryLight =>
      primary == AccentColor.lavender.dark ? const Color(0xFF9D85FF) : primary;
  final Color onPrimary;
  final Color secondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color iconDefault;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final List<Color> gradientBg;
  final List<Color> ctaGradient;
  final BoxShadow cardShadow;
  final BoxShadow sheetShadow;

  static const Color onDestructive = Color(0xFFFFFFFF);

  /// Chooses readable text on an arbitrary accent (P14-13 contrast rule).
  static Color onColor(Color c) {
    return ThemeData.estimateBrightnessForColor(c) == Brightness.dark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF140D26);
  }

  static AppColors dark(AccentColor accent) => AppColors(
    background: const Color(0xFF090F20),
    surface: const Color(0xFF121A2E),
    surfaceElevated: const Color(0xFF1A2340),
    surfaceInput: const Color(0xFF182139),
    surfaceSelected: const Color(0xFF292044),
    border: const Color(0xFF2B3551),
    divider: const Color(0xFF222C43),
    scrim: const Color(0x99000000),
    primary: accent.dark,
    primaryPressed: accent.darkPressed,
    onPrimary: onColor(accent.dark),
    secondary: const Color(0xFF46D9E5),
    textPrimary: const Color(0xFFF5F6FC),
    textSecondary: const Color(0xFFB2B8CD),
    textMuted: const Color(0xFF8791AC),
    textDisabled: const Color(0xFF59637C),
    iconDefault: const Color(0xFFB2B8CD),
    success: const Color(0xFF4ADE80),
    warning: const Color(0xFFFBBF24),
    error: const Color(0xFFFB7185),
    info: const Color(0xFF60A5FA),
    gradientBg: const [Color(0xFF090F20), Color(0xFF151638), Color(0xFF090F20)],
    ctaGradient: [accent.dark, const Color(0xFF46D9E5)],
    cardShadow: const BoxShadow(
      color: Color(0x29000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
    sheetShadow: const BoxShadow(
      color: Color(0x47000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  );

  static AppColors light(AccentColor accent) => AppColors(
    background: const Color(0xFFF7F8FC),
    surface: const Color(0xFFFFFFFF),
    surfaceElevated: const Color(0xFFFFFFFF),
    surfaceInput: const Color(0xFFEFF1F8),
    surfaceSelected: const Color(0xFFEEE7FF),
    border: const Color(0xFFDDE1EC),
    divider: const Color(0xFFE9ECF3),
    scrim: const Color(0x59090F20),
    primary: accent.light,
    primaryPressed: accent.lightPressed,
    onPrimary: onColor(accent.light),
    secondary: const Color(0xFF087F8C),
    textPrimary: const Color(0xFF182033),
    textSecondary: const Color(0xFF59647A),
    textMuted: const Color(0xFF68738A),
    textDisabled: const Color(0xFFA0A8BA),
    iconDefault: const Color(0xFF59647A),
    success: const Color(0xFF15803D),
    warning: const Color(0xFFA16207),
    error: const Color(0xFFBE123C),
    info: const Color(0xFF1D4ED8),
    gradientBg: const [Color(0xFFF7F8FC), Color(0xFFF0EBFF), Color(0xFFF7F8FC)],
    ctaGradient: [accent.light, const Color(0xFF087F8C)],
    cardShadow: const BoxShadow(
      color: Color(0x0F182033),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
    sheetShadow: const BoxShadow(
      color: Color(0x1F182033),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  );

  @override
  AppColors copyWith({Color? primary, Color? onPrimary}) => AppColors(
    background: background,
    surface: surface,
    surfaceElevated: surfaceElevated,
    surfaceInput: surfaceInput,
    surfaceSelected: surfaceSelected,
    border: border,
    divider: divider,
    scrim: scrim,
    primary: primary ?? this.primary,
    primaryPressed: primaryPressed,
    onPrimary: onPrimary ?? this.onPrimary,
    secondary: secondary,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    textMuted: textMuted,
    textDisabled: textDisabled,
    iconDefault: iconDefault,
    success: success,
    warning: warning,
    error: error,
    info: info,
    gradientBg: gradientBg,
    ctaGradient: ctaGradient,
    cardShadow: cardShadow,
    sheetShadow: sheetShadow,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceElevated: l(surfaceElevated, other.surfaceElevated),
      surfaceInput: l(surfaceInput, other.surfaceInput),
      surfaceSelected: l(surfaceSelected, other.surfaceSelected),
      border: l(border, other.border),
      divider: l(divider, other.divider),
      scrim: l(scrim, other.scrim),
      primary: l(primary, other.primary),
      primaryPressed: l(primaryPressed, other.primaryPressed),
      onPrimary: l(onPrimary, other.onPrimary),
      secondary: l(secondary, other.secondary),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      textDisabled: l(textDisabled, other.textDisabled),
      iconDefault: l(iconDefault, other.iconDefault),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      error: l(error, other.error),
      info: l(info, other.info),
      gradientBg: t < 0.5 ? gradientBg : other.gradientBg,
      ctaGradient: t < 0.5 ? ctaGradient : other.ctaGradient,
      cardShadow: BoxShadow.lerp(cardShadow, other.cardShadow, t)!,
      sheetShadow: BoxShadow.lerp(sheetShadow, other.sheetShadow, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
