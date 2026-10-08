import 'package:flutter/animation.dart';

/// Spacing scale (Design System §5).
class AppSpacing {
  AppSpacing._();
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;

  static const double screenH = 20;
  static const double groupGap = 24;
  static const double cardPadding = 16;
  static const double dialogPadding = 24;
}

class AppRadius {
  AppRadius._();
  static const double imageSm = 8;
  static const double input = 16;
  static const double button = 16;
  static const double card = 20;
  static const double dialog = 24;
  static const double sheet = 24;
  static const double toast = 12;
  static const double tabs = 14;
  static const double full = 999;
}

class AppSizes {
  AppSizes._();
  static const double iconSm = 20;
  static const double icon = 24;
  static const double iconLg = 32;
  static const double touch = 48;
  static const double buttonPrimary = 52;
  static const double buttonSecondary = 48;
  static const double playLarge = 80;
  static const double playMini = 48;
  static const double appBar = 56;
  static const double navBar = 72;
  static const double miniPlayer = 80;
  static const double miniPlayerArt = 48;
  static const double songTile = 80;
  static const double songArt = 56;
  static const double settingsTile = 64;
  static const double playlistCard = 160;
  static const double inputHeight = 52;
  static const double textAreaHeight = 144;
  static const double chipHeight = 36;
  static const double dialogMaxWidth = 360;
  static const double sheetHandleW = 36;
  static const double sheetHandleH = 4;
}

class AppMotion {
  AppMotion._();
  static const Duration press = Duration(milliseconds: 120);
  static const Duration state = Duration(milliseconds: 180);
  static const Duration overlay = Duration(milliseconds: 240);
  static const Curve curve = Curves.easeOut;
}
