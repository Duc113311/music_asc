import 'package:flutter/material.dart';

import '../../values/app_typography.dart';

/// One rounded bar of the Melo wave mark. Sizes are in logical px at
/// `scale == 1`; [gap] is the space before this bar.
class MeloBar {
  const MeloBar(
    this.width,
    this.height,
    this.colors, {
    this.gap = 0,
    this.knob,
  });

  final double width;
  final double height;
  final List<Color> colors;
  final double gap;

  /// Optional glowing dot drawn over the middle of the bar.
  final Color? knob;
}

/// Melo wordmark: wave bars + "Melo". The presets mirror sc_onBrg_01..03.
class MeloLogo extends StatelessWidget {
  const MeloLogo({
    super.key,
    required this.bars,
    required this.fontSize,
    required this.textGap,
    this.textColors = const [Color(0xFFFFFFFF)],
    this.scale = 1,
  });

  /// sc_onBrg_01: five blue/violet bars, white text.
  const MeloLogo.cool({super.key, this.scale = 1})
    : bars = const [
        MeloBar(5.5, 12.3, [Color(0xFF7C54FB), Color(0xFF7A58F7)]),
        MeloBar(5.5, 24.7, [Color(0xFF8265F7), Color(0xFF5F5BF8)], gap: 4.5),
        MeloBar(2.3, 11.4, [Color(0xFF6C81EF), Color(0xFF5B84EF)], gap: 2.8),
        MeloBar(5.9, 39.3, [Color(0xFF7CB5F6), Color(0xFF449CF3)], gap: 1.8),
        MeloBar(5.5, 12.3, [Color(0xFF57D3F5), Color(0xFF4BCEF4)], gap: 4.2),
      ],
      fontSize = 29.5,
      textGap = 12.2,
      textColors = const [Color(0xFFFFFFFF)];

  /// sc_onBrg_02: three bars, white text.
  const MeloLogo.compact({super.key, this.scale = 1})
    : bars = const [
        MeloBar(4.1, 10.7, [Color(0xFF7C58F6), Color(0xFF7A52F9)]),
        MeloBar(4.3, 20.6, [
          Color(0xFF7C58F0),
          Color(0xFF6865F7),
          Color(0xFF3A79EE),
        ], gap: 3.2),
        MeloBar(4.3, 10.5, [Color(0xFF4DA8EB), Color(0xFF4DA1EC)], gap: 3.3),
      ],
      fontSize = 23.5,
      textGap = 8.4,
      textColors = const [Color(0xFFFFFFFF)];

  /// sc_onBrg_03: violet/blue/coral bars, gradient text.
  const MeloLogo.vivid({super.key, this.scale = 1})
    : bars = const [
        MeloBar(4.1, 9.9, [Color(0xFF824CF7), Color(0xFF884FF7)]),
        MeloBar(4.2, 22, [Color(0xFF8645F8), Color(0xFF7A45F8)], gap: 4.3),
        MeloBar(
          5.9,
          36.1,
          [
            Color(0xFFA579F7),
            Color(0xFF9B82FB),
            Color(0xFF6FCFF9),
            Color(0xFF41A6F1),
          ],
          gap: 3.1,
          knob: Color(0xFF8BE3FC),
        ),
        MeloBar(4.1, 20.1, [Color(0xFFFD7866), Color(0xFFFC8161)], gap: 3.7),
        MeloBar(4.1, 9.2, [Color(0xFFF79B7F), Color(0xFFF6A083)], gap: 4.6),
      ],
      fontSize = 36,
      textGap = 9.6,
      textColors = const [
        Color(0xFF915CFE),
        Color(0xFF7A97FD),
        Color(0xFF71C4F6),
        Color(0xFF5DE8DC),
      ];

  final List<MeloBar> bars;
  final double fontSize;
  final double textGap;
  final List<Color> textColors;
  final double scale;

  @override
  Widget build(BuildContext context) {
    Widget text = Text(
      'Melo',
      maxLines: 1,
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: fontSize * scale,
        height: 1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * fontSize * scale,
        color: textColors.first,
      ),
    );
    if (textColors.length > 1) {
      text = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (r) =>
            LinearGradient(colors: textColors).createShader(r),
        child: text,
      );
    }
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final b in bars) ...[
            SizedBox(width: b.gap * scale),
            _Bar(bar: b, scale: scale),
          ],
          SizedBox(width: textGap * scale),
          text,
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.bar, required this.scale});
  final MeloBar bar;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final w = bar.width * scale;
    final h = bar.height * scale;
    final body = Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(w / 2),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: bar.colors.length == 1
              ? [bar.colors.first, bar.colors.first]
              : bar.colors,
        ),
        boxShadow: [
          BoxShadow(
            color: bar.colors.last.withValues(alpha: 0.45),
            blurRadius: 6 * scale,
          ),
        ],
      ),
    );
    final knob = bar.knob;
    if (knob == null) return body;
    final d = w * 1.25;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          body,
          Positioned(
            top: h * 0.52 - d / 2,
            child: Container(
              width: d,
              height: d,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: knob,
                boxShadow: [
                  BoxShadow(
                    color: knob.withValues(alpha: 0.7),
                    blurRadius: 6 * scale,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
