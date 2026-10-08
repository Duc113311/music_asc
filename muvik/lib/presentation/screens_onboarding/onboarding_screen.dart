import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controller/onboarding_controller.dart';
import '../../values/app_assets.dart';
import '../../values/app_typography.dart';
import '../common_components/melo_logo.dart';

/// sc_onBrg_01..03 in one route so the page index is kept; no navbar.
///
/// Each page is laid out on the 390×844 design frame: elements above the
/// buttons keep their design distance from the bottom edge, top elements keep
/// theirs from the top, and the background is cover-fitted from the top.
/// Screens shorter than the design ratio get the whole frame scaled down.
class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _bgColor,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            if (controller.page.value > 0) {
              controller.back();
            } else {
              Get.back<void>();
            }
          }
        },
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.15,
          child: Scaffold(
            backgroundColor: _bgColor,
            body: PageView(
              controller: controller.pageController,
              onPageChanged: controller.onPageChanged,
              children: const [
                _FitShort(
                  background: _Background(AppAssets.onboarding1, _grade1),
                  child: _Page1(),
                ),
                _FitShort(
                  background: _Background(AppAssets.onboarding2, _grade2),
                  child: _Page2(),
                ),
                _FitShort(
                  background: _Background(AppAssets.onboarding3, _grade3),
                  child: _Page3(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _bgColor = Color(0xFF090F20);
const _designW = 390.0;
const _designH = 844.0;

/// BeVietnamPro vertical metrics (em units), used to place text by baseline.
const _ascent = 1.0;
const _descent = 0.27;

/// Maps design coordinates onto the current screen.
class _Frame {
  _Frame(BoxConstraints box, EdgeInsets pad, double designBottomGap)
    : w = box.maxWidth,
      h = box.maxHeight,
      // Design buttons sit above a 34pt home indicator.
      bottomGap = math.max(designBottomGap, pad.bottom + designBottomGap - 34),
      topInset = pad.top {
    _shift = (h - bottomGap) - (_designH - designBottomGap);
  }

  final double w;
  final double h;
  final double bottomGap;
  final double topInset;
  late final double _shift;

  /// Bottom-anchored design y.
  double y(double v) => v + _shift;

  /// Top-anchored design y, kept clear of the status bar.
  double top(double v) => math.max(v, topInset + 6);
}

/// On screens shorter than 390×844 (e.g. 16:9) the art and the copy cannot
/// both fit at full width, so the page is scaled to fit the height and the
/// side bands show the blurred background.
class _FitShort extends StatelessWidget {
  const _FitShort({required this.background, required this.child});
  final Widget background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        if (h / w >= _designH / _designW) return child;
        final k = h / _designH;
        final mq = MediaQuery.of(context);
        return Stack(
          children: [
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Stack(children: [background]),
              ),
            ),
            Center(
              child: SizedBox(
                width: _designW * k,
                height: h,
                child: FittedBox(
                  child: SizedBox(
                    width: _designW,
                    height: _designH,
                    child: MediaQuery(
                      data: mq.copyWith(
                        padding: mq.padding / k,
                        viewPadding: mq.viewPadding / k,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Top of a text box whose first baseline should land on [baseline].
double _boxTop(double baseline, double size, double height) =>
    baseline - ((height - _ascent - _descent) / 2 + _ascent) * size;

/// Full-bleed background. [grade] is the color matrix that reproduces the
/// mockup's tone from the raw asset (fitted per page against sc_onBrg_0x).
class _Background extends StatelessWidget {
  const _Background(this.asset, this.grade);
  final String asset;
  final List<double> grade;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix(grade),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

const _grade1 = <double>[
  0.840, -0.074, -0.015, 0, 11.3, //
  0.027, 0.656, 0.037, 0, 11.5, //
  0.041, 0.120, 0.646, 0, 12.5, //
  0, 0, 0, 1, 0,
];
const _grade2 = <double>[
  0.814, 0.128, -0.021, 0, 4.9, //
  0.024, 0.887, -0.013, 0, 4.4, //
  0.037, 0.072, 0.789, 0, 5.3, //
  0, 0, 0, 1, 0,
];
const _grade3 = <double>[
  0.862, 0.143, -0.120, 0, 11.8, //
  0.031, 0.803, -0.020, 0, 10.2, //
  0.055, 0.072, 0.757, 0, 6.2, //
  0, 0, 0, 1, 0,
];

/// Title (white) + highlight (gradient) + description, placed by baselines.
class _Copy extends StatelessWidget {
  const _Copy({
    required this.f,
    required this.title,
    required this.highlight,
    required this.desc,
    required this.highlightColors,
    required this.titleBaseline,
    required this.titleSize,
    required this.titleHeight,
    required this.descBaseline,
    required this.descSize,
    required this.descHeight,
    required this.descColor,
    required this.descMaxWidth,
    this.highlightStops,
    this.titleColor = const Color(0xFFFFFFFF),
  });

  final _Frame f;
  final String title;
  final String highlight;
  final String desc;
  final List<Color> highlightColors;
  final List<double>? highlightStops;
  final Color titleColor;
  final double titleBaseline;
  final double titleSize;
  final double titleHeight;
  final double descBaseline;
  final double descSize;
  final double descHeight;
  final Color descColor;
  final double descMaxWidth;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: titleSize,
      height: titleHeight,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.01 * titleSize,
      color: titleColor,
    );
    return Stack(
      children: [
        Positioned(
          left: 12,
          right: 12,
          top: f.y(_boxTop(titleBaseline, titleSize, titleHeight)),
          child: Column(
            children: [
              Text(title, textAlign: TextAlign.center, style: titleStyle),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (r) => LinearGradient(
                  colors: highlightColors,
                  stops: highlightStops,
                ).createShader(r),
                child: Text(
                  highlight,
                  textAlign: TextAlign.center,
                  style: titleStyle,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: f.y(_boxTop(descBaseline, descSize, descHeight)),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.min(descMaxWidth, f.w - 40),
              ),
              child: Text(
                desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: descSize,
                  height: descHeight,
                  fontWeight: FontWeight.w400,
                  color: descColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.active,
    required this.size,
    required this.pitch,
    required this.activeColor,
    required this.inactiveColors,
  });

  final int active;
  final double size;
  final double pitch;
  final Color activeColor;
  final List<Color> inactiveColors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < OnboardingController.pageCount; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : pitch - size),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == active
                    ? activeColor
                    : inactiveColors[i % inactiveColors.length],
                boxShadow: i == active
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.6),
                          blurRadius: size,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

/// Dots centered on [dotsY] and an optional "n / 3" counter on [counterBaseline].
class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.f,
    required this.dots,
    required this.dotsY,
    this.counter,
    this.counterBaseline = 0,
    this.counterColor = const Color(0xFF989EB9),
  });

  final _Frame f;
  final _Dots dots;
  final double dotsY;
  final String? counter;
  final double counterBaseline;
  final Color counterColor;

  @override
  Widget build(BuildContext context) {
    const counterSize = 11.5;
    const counterHeight = 1.3;
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: f.y(dotsY) - dots.size / 2,
          child: Center(child: dots),
        ),
        if (counter != null)
          Positioned(
            left: 0,
            right: 0,
            top: f.y(_boxTop(counterBaseline, counterSize, counterHeight)),
            child: Text(
              counter!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: counterSize,
                height: counterHeight,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
                color: counterColor,
              ),
            ),
          ),
      ],
    );
  }
}

/// Fully rounded button with gradient fill, glow and ripple.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.onTap,
    required this.child,
    this.gradient,
    this.border,
    this.glow = const [],
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;
  final Gradient? gradient;
  final BoxBorder? border;
  final List<BoxShadow> glow;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: radius, boxShadow: glow),
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: gradient,
              border: border,
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              splashColor: Colors.white24,
              highlightColor: Colors.white10,
              child: SizedBox.expand(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _buttonText(double size, {Color color = Colors.white}) => TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: size,
  height: 1.2,
  fontWeight: FontWeight.w600,
  color: color,
);

/// Positions a design rect (left/right edges, top/bottom y) bottom-anchored.
Positioned _place(
  _Frame f, {
  required double left,
  required double right,
  required double top,
  required double bottom,
  required Widget child,
}) {
  final scaleX = f.w / _designW;
  return Positioned(
    left: left * scaleX,
    width: (right - left) * scaleX,
    top: f.y(top),
    height: bottom - top,
    child: child,
  );
}

// ---------------------------------------------------------------- page 1

class _Page1 extends GetView<OnboardingController> {
  const _Page1();

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.viewPaddingOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final f = _Frame(box, pad, 40);
        return Stack(
          children: [
            const _Background(AppAssets.onboarding1, _grade1),
            Positioned(
              left: 0,
              right: 0,
              top: f.y(493.7) - 39.3 / 2,
              height: 39.3,
              child: const Center(child: MeloLogo.cool()),
            ),
            Positioned.fill(
              child: _Copy(
                f: f,
                title: 'onb1_title'.tr,
                highlight: 'onb1_highlight'.tr,
                desc: 'onb1_desc'.tr,
                highlightColors: const [
                  Color(0xFF54E0FC),
                  Color(0xFF66B3FC),
                  Color(0xFFA686FC),
                  Color(0xFFBE79FB),
                ],
                highlightStops: const [0, 0.4, 0.72, 1],
                titleBaseline: 557.8,
                titleSize: 30,
                titleHeight: 1.19,
                descBaseline: 630,
                descSize: 14.5,
                descHeight: 1.58,
                descColor: const Color(0xFF9097B3),
                descMaxWidth: 236,
              ),
            ),
            Positioned.fill(
              child: _Indicator(
                f: f,
                dotsY: 697.4,
                dots: const _Dots(
                  active: 0,
                  size: 9,
                  pitch: 21.3,
                  activeColor: Color(0xFF9C62FC),
                  inactiveColors: [Color(0xFF2A304B)],
                ),
                counter: '1 / ${OnboardingController.pageCount}',
                counterBaseline: 723.3,
              ),
            ),
            // "Bỏ qua" text button, vertically centered on the CTA.
            Positioned(
              left: f.w * 20 / _designW,
              top: f.y(753.1),
              height: 51,
              child: Semantics(
                button: true,
                label: 'action_skip'.tr,
                excludeSemantics: true,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: controller.finish,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 23),
                      child: Center(
                        child: Text(
                          'action_skip'.tr,
                          style: _buttonText(
                            15,
                            color: const Color(0xFF9A88F8),
                          ).copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _place(
              f,
              left: 175.6,
              right: 371.3,
              top: 753.1,
              bottom: 804,
              child: _Pill(
                label: 'action_continue'.tr,
                onTap: controller.next,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFA470FC),
                    Color(0xFF9562FB),
                    Color(0xFF6F4FFA),
                  ],
                  stops: [0, 0.45, 1],
                ),
                border: Border.all(color: const Color(0x40FFFFFF), width: 0.8),
                glow: const [
                  BoxShadow(color: Color(0x598F6BFF), blurRadius: 24),
                ],
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Text(
                        'action_continue'.tr,
                        maxLines: 1,
                        style: _buttonText(15.5),
                      ),
                    ),
                    const Positioned(
                      right: 20,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------- page 2

class _Page2 extends GetView<OnboardingController> {
  const _Page2();

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.viewPaddingOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final f = _Frame(box, pad, 43.8);
        return Stack(
          children: [
            const _Background(AppAssets.onboarding2, _grade2),
            Positioned(
              left: 37.3,
              top: f.top(44.6 - 20.6 / 2) - 1,
              height: 22.6,
              child: const MeloLogo.compact(),
            ),
            Positioned.fill(
              child: _Copy(
                f: f,
                title: 'onb2_title'.tr,
                highlight: 'onb2_highlight'.tr,
                desc: 'onb2_desc'.tr,
                highlightColors: const [
                  Color(0xFF4BEFEC),
                  Color(0xFF58EBF4),
                  Color(0xFF69C7F9),
                  Color(0xFF8A84F8),
                ],
                highlightStops: const [0, 0.55, 0.82, 1],
                titleBaseline: 595.3,
                titleSize: 27,
                titleHeight: 1.255,
                descBaseline: 662.4,
                descSize: 13.7,
                descHeight: 1.54,
                descColor: const Color(0xFF9BA1B9),
                descMaxWidth: 232,
              ),
            ),
            Positioned.fill(
              child: _Indicator(
                f: f,
                dotsY: 718.1,
                dots: const _Dots(
                  active: 1,
                  size: 7.4,
                  pitch: 18.2,
                  activeColor: Color(0xFF3AE5E7),
                  inactiveColors: [
                    Color(0xFF29304E),
                    Color(0xFF29304E),
                    Color(0xFF2B275A),
                  ],
                ),
                counter: '2 / ${OnboardingController.pageCount}',
                counterBaseline: 738.2,
                counterColor: const Color(0xFF9696CA),
              ),
            ),
            _place(
              f,
              left: 20.6,
              right: 186.1,
              top: 756.3,
              bottom: 800.2,
              child: _Pill(
                label: 'action_back'.tr,
                onTap: controller.back,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0F1428),
                    Color(0xFF141832),
                    Color(0xFF1C1D46),
                  ],
                  stops: [0, 0.55, 1],
                ),
                border: Border.all(color: const Color(0xFF2E3060)),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF181C30),
                          ),
                          child: const Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'action_back'.tr,
                      maxLines: 1,
                      style: _buttonText(
                        13.5,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            _place(
              f,
              left: 203.5,
              right: 369.5,
              top: 756.3,
              bottom: 800.2,
              child: _Pill(
                label: 'action_continue'.tr,
                onTap: controller.next,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF976FFB),
                    Color(0xFF8763FB),
                    Color(0xFF7254FA),
                  ],
                ),
                glow: const [
                  BoxShadow(color: Color(0x4D8F6BFF), blurRadius: 22),
                ],
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          'action_continue'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _buttonText(
                            13.5,
                          ).copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------- page 3

/// Label printed on one of the tilted playlist cards of bg_on_03, in the
/// background image's own 390-wide coordinate space.
class _CardLabel {
  const _CardLabel(
    this.key,
    this.count,
    this.left,
    this.top,
    this.degrees,
    this.titleSize, {
    this.splitFirstWord = false,
  });

  final String key;
  final int count;
  final double left;
  final double top;
  final double degrees;
  final double titleSize;
  final bool splitFirstWord;
}

class _Page3 extends GetView<OnboardingController> {
  const _Page3();

  /// bg_on_03.png source size.
  static const _imgW = 853.0;
  static const _imgH = 1843.0;

  static const _labels = [
    _CardLabel(
      'onb3_card_favorites',
      32,
      46.7,
      191.2,
      -19.7,
      10.45,
      splitFirstWord: true,
    ),
    _CardLabel('onb3_card_evening', 18, 269.4, 253.1, 11.8, 9.2),
    _CardLabel('onb3_card_relax', 25, 70.5, 453.7, -17.2, 10.2),
    _CardLabel('onb3_card_focus', 40, 262.8, 410.4, -8.6, 9.15),
  ];

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.viewPaddingOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final f = _Frame(box, pad, 48);
        // Same cover/topCenter math as the background image.
        final s = math.max(f.w / _imgW, f.h / _imgH);
        final imgScale = _imgW * s / _designW;
        final imgDx = (f.w - _imgW * s) / 2;
        return Stack(
          children: [
            const _Background(AppAssets.onboarding3, _grade3),
            for (final l in _labels)
              Positioned(
                left: imgDx + l.left * imgScale,
                top: l.top * imgScale,
                child: Transform.rotate(
                  angle: l.degrees * math.pi / 180,
                  alignment: Alignment.topLeft,
                  child: _CardText(label: l, scale: imgScale),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              top: f.top(52.6 - 36.1 / 2),
              height: 36.1,
              child: const Center(child: MeloLogo.vivid()),
            ),
            Positioned.fill(
              child: _Copy(
                f: f,
                title: 'onb3_title'.tr,
                highlight: 'onb3_highlight'.tr,
                desc: 'onb3_desc'.tr,
                highlightColors: const [
                  Color(0xFFF8826C),
                  Color(0xFFFBB3C4),
                  Color(0xFFF9A0B4),
                  Color(0xFFF97D6F),
                ],
                highlightStops: const [0.08, 0.42, 0.68, 1],
                titleColor: const Color(0xFFF7F0FD),
                titleBaseline: 606.7,
                titleSize: 30.5,
                titleHeight: 1.22,
                descBaseline: 676.2,
                descSize: 13.8,
                descHeight: 1.5,
                descColor: const Color(0xFFC1CAED),
                descMaxWidth: 340,
              ),
            ),
            Positioned.fill(
              child: _Indicator(
                f: f,
                dotsY: 715.4,
                dots: const _Dots(
                  active: 2,
                  size: 7.7,
                  pitch: 16.4,
                  activeColor: Color(0xFF985AFD),
                  inactiveColors: [Color(0xFF676E9A)],
                ),
              ),
            ),
            _place(
              f,
              left: 33.4,
              right: 357.1,
              top: 744.4,
              bottom: 796,
              child: _Pill(
                label: 'action_get_started'.tr,
                onTap: controller.finish,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFD857A),
                    Color(0xFFF86C92),
                    Color(0xFFD353D4),
                    Color(0xFF9B55FA),
                  ],
                  stops: [0, 0.35, 0.66, 1],
                ),
                border: Border.all(color: const Color(0x33FFFFFF), width: 0.8),
                glow: const [
                  BoxShadow(color: Color(0x4DE064B4), blurRadius: 24),
                ],
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'action_get_started'.tr,
                      maxLines: 1,
                      style: _buttonText(16.5),
                    ),
                    const Positioned(
                      right: 18,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CardText extends StatelessWidget {
  const _CardText({required this.label, required this.scale});
  final _CardLabel label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    var title = label.key.tr;
    if (label.splitFirstWord) {
      final i = title.indexOf(' ');
      if (i > 0) title = '${title.substring(0, i)}\n${title.substring(i + 1)}';
    }
    final size = label.titleSize * scale;
    return ExcludeSemantics(
      child: MediaQuery.withNoTextScaling(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: size,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFEFEFE),
              ),
            ),
            SizedBox(height: 4.4 * scale),
            Text(
              'count_songs_n'.trParams({'args1': '${label.count}'}),
              maxLines: 1,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 7.6 * scale,
                height: 1.25,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFBCC8EB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
