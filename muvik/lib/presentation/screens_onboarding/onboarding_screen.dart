import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controller/onboarding_controller.dart';
import '../../values/app_assets.dart';
import '../../values/app_typography.dart';

/// sc_onBrg_01..03 in one route so the page index is kept; no navbar.
///
/// Layout (same on the three pages): the picture fills the screen from the top
/// and fades into the dark background; the copy and the call to action are
/// stacked from the bottom edge up: title, highlighted title line, description,
/// page dots, full-width button. "Bỏ qua" sits top right, a back arrow top left
/// on pages 2 and 3. On entering a page every element fades in and rises in
/// turn (title, highlight, description, dots, button, top buttons); with
/// "remove animations" on in the system settings they appear at once.
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
                _OnboardingPage(spec: _page1),
                _OnboardingPage(spec: _page2),
                _OnboardingPage(spec: _page3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _bgColor = Color(0xFF090F20);
const _skipColor = Color(0xFF9A88F8);

/// Everything that differs between the three pages.
class _PageSpec {
  const _PageSpec({
    required this.index,
    required this.background,
    required this.titleKey,
    required this.highlightKey,
    required this.descKey,
    required this.highlightColors,
    required this.highlightStops,
    required this.ctaKey,
    required this.ctaGradient,
    required this.ctaGlow,
    this.titleColor = Colors.white,
    this.descColor = const Color(0xFF9097B3),
    this.dotInactive = const Color(0xFF2A304B),
    this.skipOpacity = 1,
  });

  final int index;
  final String background;
  final String titleKey;
  final String highlightKey;
  final String descKey;
  final List<Color> highlightColors;
  final List<double> highlightStops;
  final String ctaKey;
  final Gradient ctaGradient;
  final Color ctaGlow;
  final Color titleColor;
  final Color descColor;
  final Color dotInactive;
  final double skipOpacity;

  bool get isFirst => index == 0;
  bool get isLast => index == OnboardingController.pageCount - 1;
}

const _purpleCta = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFA470FC), Color(0xFF9562FB), Color(0xFF6F4FFA)],
  stops: [0, 0.45, 1],
);

const _page1 = _PageSpec(
  index: 0,
  background: AppAssets.onboarding1,
  titleKey: 'onb1_title',
  highlightKey: 'onb1_highlight',
  descKey: 'onb1_desc',
  highlightColors: [
    Color(0xFF54E0FC),
    Color(0xFF66B3FC),
    Color(0xFFA686FC),
    Color(0xFFBE79FB),
  ],
  highlightStops: [0, 0.4, 0.72, 1],
  ctaKey: 'action_continue',
  ctaGradient: _purpleCta,
  ctaGlow: Color(0x598F6BFF),
);

const _page2 = _PageSpec(
  index: 1,
  background: AppAssets.onboarding2,
  titleKey: 'onb2_title',
  highlightKey: 'onb2_highlight',
  descKey: 'onb2_desc',
  highlightColors: [
    Color(0xFF4BEFEC),
    Color(0xFF58EBF4),
    Color(0xFF69C7F9),
    Color(0xFF8A84F8),
  ],
  highlightStops: [0, 0.35, 0.7, 1],
  ctaKey: 'action_continue',
  ctaGradient: _purpleCta,
  ctaGlow: Color(0x598F6BFF),
  descColor: Color(0xFF9BA1B9),
);

const _page3 = _PageSpec(
  index: 2,
  background: AppAssets.onboarding3,
  titleKey: 'onb3_title',
  highlightKey: 'onb3_highlight',
  descKey: 'onb3_desc',
  highlightColors: [
    Color(0xFFF8826C),
    Color(0xFFFBB3C4),
    Color(0xFFF9A0B4),
    Color(0xFFF97D6F),
  ],
  highlightStops: [0.08, 0.42, 0.68, 1],
  ctaKey: 'action_get_started',
  ctaGradient: LinearGradient(
    colors: [
      Color(0xFFFD857A),
      Color(0xFFF86C92),
      Color(0xFFD353D4),
      Color(0xFF9B55FA),
    ],
    stops: [0, 0.35, 0.66, 1],
  ),
  ctaGlow: Color(0x4DE064B4),
  titleColor: Color(0xFFF7F0FD),
  descColor: Color(0xFFC1CAED),
  dotInactive: Color(0xFF676E9A),
  skipOpacity: 0.6,
);

/// Delay (ms) at which each element starts to appear; every element then takes
/// [_revealMs]. Together they play over ~1.3 s.
const _revealMs = 520;
const _delayTitle = 120;
const _delayHighlight = 260;
const _delayDesc = 400;
const _delayDots = 540;
const _delayCta = 660;
const _delayTop = 760;
const _totalMs = _delayTop + _revealMs;

class _OnboardingPage extends StatefulWidget {
  const _OnboardingPage({required this.spec});
  final _PageSpec spec;

  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _totalMs),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Animation that runs from [delayMs] for [_revealMs] of the whole timeline.
  Animation<double> _at(int delayMs) => CurvedAnimation(
    parent: _c,
    curve: Interval(
      delayMs / _totalMs,
      (delayMs + _revealMs) / _totalMs,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final controller = Get.find<OnboardingController>();
    final pad = MediaQuery.viewPaddingOf(context);
    final h = MediaQuery.sizeOf(context).height;
    // The design leaves ~9% of the height under the button.
    final bottomGap = (h * 0.085).clamp(40.0, 84.0) + pad.bottom * 0.5;

    final titleStyle = TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: 28,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.28,
      color: spec.titleColor,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        _Background(spec.background),
        // Title, highlight, description, dots, button: bottom-up stack.
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomGap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Reveal(
                  animation: _at(_delayTitle),
                  child: Text(
                    spec.titleKey.tr,
                    textAlign: TextAlign.center,
                    style: titleStyle,
                  ),
                ),
                _Reveal(
                  animation: _at(_delayHighlight),
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (r) => LinearGradient(
                      colors: spec.highlightColors,
                      stops: spec.highlightStops,
                    ).createShader(r),
                    child: Text(
                      spec.highlightKey.tr,
                      textAlign: TextAlign.center,
                      style: titleStyle,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _Reveal(
                  animation: _at(_delayDesc),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 270),
                    child: Text(
                      spec.descKey.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        height: 1.55,
                        fontWeight: FontWeight.w400,
                        color: spec.descColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                _Reveal(
                  animation: _at(_delayDots),
                  dy: 8,
                  child: _Dots(active: spec.index, inactive: spec.dotInactive),
                ),
                const SizedBox(height: 28),
                _Reveal(
                  animation: _at(_delayCta),
                  dy: 26,
                  // A Column hands its children loose width, so without this
                  // the pill shrinks to the label ("Tiếp tục" came out short).
                  child: SizedBox(
                    width: double.infinity,
                    child: _CtaButton(
                      spec: spec,
                      onTap: spec.isLast ? controller.finish : controller.next,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Back arrow (pages 2 and 3), top left.
        if (!spec.isFirst)
          Positioned(
            left: 8,
            top: pad.top + 6,
            child: _Reveal(
              animation: _at(_delayTop),
              dy: 0,
              child: Semantics(
                button: true,
                label: 'action_back'.tr,
                excludeSemantics: true,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkResponse(
                    onTap: controller.back,
                    customBorder: const CircleBorder(),
                    containedInkWell: true,
                    highlightShape: BoxShape.circle,
                    child: const SizedBox.square(
                      dimension: 48,
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        // "Bỏ qua", top right.
        Positioned(
          right: 12,
          top: pad.top + 6,
          child: _Reveal(
            animation: _at(_delayTop),
            dy: 0,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: Text(
                      'action_skip'.tr,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        color: _skipColor.withValues(alpha: spec.skipOpacity),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Fade + rise driven by one slice of the page timeline.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.animation, required this.child, this.dy = 16});

  final Animation<double> animation;
  final Widget child;

  /// How far (logical px) the child starts below its final place.
  final double dy;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, (1 - animation.value) * dy),
          child: child,
        ),
      ),
    );
  }
}

/// Full-bleed picture from the top, fading into the dark background under the
/// copy so the text stays readable.
class _Background extends StatelessWidget {
  const _Background(this.asset);
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // The art sits in the upper part of a tall canvas that already fades to
        // the dark background; top aligned so the copy sits on the dark area.
        Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          filterQuality: FilterQuality.medium,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00090F20), Color(0x00090F20), _bgColor],
              stops: [0, 0.5, 0.7],
            ),
          ),
        ),
      ],
    );
  }
}

/// Page dots: the current page is a longer glowing pill.
class _Dots extends StatelessWidget {
  const _Dots({required this.active, required this.inactive});
  final int active;
  final Color inactive;

  static const _activeColor = Color(0xFF9C62FC);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < OnboardingController.pageCount; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
            width: i == active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: i == active ? _activeColor : inactive,
              boxShadow: i == active
                  ? [
                      BoxShadow(
                        color: _activeColor.withValues(alpha: 0.6),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
          ),
      ],
    );
  }
}

/// Full-width pill: gradient fill, glow, ripple, label centered with an arrow
/// on the right.
class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.spec, required this.onTap});
  final _PageSpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    final label = spec.ctaKey.tr;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [BoxShadow(color: spec.ctaGlow, blurRadius: 24)],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            height: 54,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: spec.ctaGradient,
              border: Border.all(color: const Color(0x40FFFFFF), width: 0.8),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              splashColor: Colors.white24,
              highlightColor: Colors.white10,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 56),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 22,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
