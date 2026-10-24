import 'package:flutter/material.dart';

/// Typography scale (Design System §4). Line height expressed as height ratio.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'BeVietnamPro';

  static const TextStyle display = TextStyle(
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle headingL = TextStyle(
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle headingM = TextStyle(
    fontSize: 22,
    height: 30 / 22,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle headingS = TextStyle(
    fontSize: 18,
    height: 26 / 18,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle bodyL = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodyM = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle label = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 18 / 12,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle navigation = TextStyle(
    fontSize: 13.5,
    height: 18 / 13.5,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle songTitle = TextStyle(
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle statNumber = TextStyle(
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w700,
  );

  static TextTheme textTheme(Color primary, Color secondary) => TextTheme(
    displayLarge: display.copyWith(color: primary),
    headlineLarge: headingL.copyWith(color: primary),
    headlineMedium: headingM.copyWith(color: primary),
    headlineSmall: headingS.copyWith(color: primary),
    titleLarge: appBarTitle.copyWith(color: primary),
    titleMedium: songTitle.copyWith(color: primary),
    titleSmall: label.copyWith(color: primary),
    bodyLarge: bodyL.copyWith(color: primary),
    bodyMedium: bodyM.copyWith(color: secondary),
    bodySmall: caption.copyWith(color: secondary),
    labelLarge: label.copyWith(color: primary),
    labelMedium: navigation.copyWith(color: secondary),
    labelSmall: caption.copyWith(color: secondary),
  );
}
