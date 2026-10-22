import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_ink_ripple.dart';
import 'app_typography.dart';

/// Light + dark themes built from the same tokens; ThemeMode follows the user
/// choice (system by default). Unlike the base template, dark is not pinned.
class AppTheme {
  AppTheme._();

  static ThemeData dark(AccentColor accent) =>
      _build(AppColors.dark(accent), Brightness.dark);

  static ThemeData light(AccentColor accent) =>
      _build(AppColors.light(accent), Brightness.light);

  static ThemeData _build(AppColors c, Brightness b) {
    final scheme = ColorScheme(
      brightness: b,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.secondary,
      onSecondary: AppColors.onColor(c.secondary),
      error: c.error,
      onError: AppColors.onDestructive,
      surface: c.surface,
      onSurface: c.textPrimary,
      surfaceContainerHighest: c.surfaceInput,
      outline: c.border,
      outlineVariant: c.divider,
      scrim: c.scrim,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: c.background,
      dividerColor: c.divider,
      extensions: [c],
      textTheme: AppTypography.textTheme(c.textPrimary, c.textSecondary),
      iconTheme: IconThemeData(color: c.iconDefault, size: AppSizes.icon),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: AppSizes.appBar,
        foregroundColor: c.textPrimary,
        titleTextStyle: AppTypography.appBarTitle.copyWith(
          color: c.textPrimary,
          fontFamily: AppTypography.fontFamily,
        ),
        systemOverlayStyle: b == Brightness.dark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              ),
      ),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceElevated,
        modalBackgroundColor: c.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: c.scrim,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        barrierColor: c.scrim,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceElevated,
        contentTextStyle: AppTypography.bodyM.copyWith(color: c.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.toast),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: c.primaryLight,
        inactiveTrackColor: c.border,
        thumbColor: c.primaryLight,
        overlayColor: c.primary.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primaryLight,
        linearTrackColor: c.border,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withValues(alpha: 0.3),
        selectionHandleColor: c.primary,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      // Scan-library ripple, slightly faster, for every touchable.
      splashFactory: AppInkRipple.splashFactory,
    );
  }
}
