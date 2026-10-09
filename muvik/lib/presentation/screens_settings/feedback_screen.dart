import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../configs/app_config.dart';
import '../../controller/feedback_controller.dart';
import '../../services/feedback_service.dart';
import '../../utils/toast_utils.dart';
import '../../values/app_assets.dart';
import '../../values/app_colors.dart';
import '../../values/app_typography.dart';
import '../common_components/state_views.dart';

/// Gửi phản hồi: type, required content, optional reply email over the wave
/// background. "Gửi" opens the email app; the app never claims the mail was
/// sent (P14-16..18).
class FeedbackScreen extends GetView<FeedbackController> {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final f = _FeedbackPalette.of(context);
    return Scaffold(
      backgroundColor: c.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'action_back'.tr,
          icon: Icon(Icons.chevron_left_rounded, size: 34, color: c.primary),
          onPressed: () => Get.back<void>(),
        ),
        title: Text(
          'about_feedback'.tr,
          style: AppTypography.appBarTitle.copyWith(
            fontSize: 20,
            color: c.textPrimary,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              f.dark ? AppAssets.bgDark : AppAssets.bgLight,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              color: f.dark ? const Color(0x59040B22) : null,
              colorBlendMode: f.dark ? BlendMode.srcATop : null,
            ),
          ),
          SafeArea(
            child: Obx(
              () => ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 17, 24),
                children: [
                  const _Hero(),
                  const SizedBox(height: 4),
                  Text(
                    'feedback_title'.trParams({'args1': AppConfig.appName}),
                    textAlign: TextAlign.center,
                    style: AppTypography.headingL.copyWith(
                      fontSize: 23,
                      height: 1.3,
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    'feedback_subtitle'.trParams({'args1': AppConfig.appName}),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyM.copyWith(
                      fontSize: 13.5,
                      color: f.accentText,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _Label('feedback_type'.tr),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final (i, t) in FeedbackType.values.indexed) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _TypeChip(
                            type: t,
                            selected: controller.type.value == t,
                            onTap: () => controller.type.value = t,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  _Label('feedback_content'.tr, required: true),
                  const SizedBox(height: 8),
                  _ContentField(controller: controller),
                  if (controller.contentError.value != null)
                    _ErrorText(controller.contentError.value!),
                  const SizedBox(height: 22),
                  _Label('feedback_email'.tr, suffix: 'feedback_optional'.tr),
                  const SizedBox(height: 8),
                  _EmailField(controller: controller),
                  if (controller.emailError.value != null)
                    _ErrorText(controller.emailError.value!),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const SizedBox(width: 1),
                      Icon(
                        Icons.info_outline_rounded,
                        size: 19,
                        color: f.accentText,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'feedback_network_note'.tr,
                          style: AppTypography.bodyM.copyWith(
                            fontSize: 12.5,
                            color: f.accentText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (controller.noEmailApp.value) ...[
                    const SizedBox(height: 14),
                    InfoBanner(
                      message: 'feedback_no_email_app'.trParams({
                        'args1': AppConfig.supportEmail,
                      }),
                      actionLabel: 'action_copy'.tr,
                      onAction: () async {
                        await FeedbackService.copySupportEmail();
                        ToastUtils.success('toast_copied'.tr);
                      },
                    ),
                  ],
                  if (controller.opened.value) ...[
                    const SizedBox(height: 14),
                    InfoBanner(
                      icon: Icons.mark_email_unread_rounded,
                      color: c.info,
                      message: 'feedback_composer_opened'.tr,
                    ),
                  ],
                  const SizedBox(height: 14),
                  _SendButton(onTap: controller.send),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Navy/indigo colors of the feedback mockup; light theme uses tokens.
class _FeedbackPalette {
  _FeedbackPalette._(this.dark, this._c);
  factory _FeedbackPalette.of(BuildContext context) => _FeedbackPalette._(
    Theme.of(context).brightness == Brightness.dark,
    context.colors,
  );

  final bool dark;
  final AppColors _c;

  Color get field => dark ? const Color(0xE60A194B) : _c.surface;
  Color get fieldBorder => dark ? const Color(0xFF3638B6) : _c.border;
  Color get chip => dark ? const Color(0xE60D1D5A) : _c.surface;
  Color get chipBorder => dark ? const Color(0xFF252A8E) : _c.border;
  Color get accentText => dark ? const Color(0xFF9D9CF6) : _c.primary;
  Color get hint => dark ? const Color(0xFF9294DC) : _c.textMuted;
}

/// Chat-bubble art cropped from the mockup, edges faded into the page.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (r) => RadialGradient(
          radius: 0.5,
          colors: const [Color(0xFF000000), Color(0x00000000)],
          stops: const [0.55, 1],
          transform: _ScaleX(r.width / r.height),
        ).createShader(r),
        child: Image.asset(AppAssets.feedbackHero, width: 190, height: 105),
      ),
    );
  }
}

/// Stretches a radial gradient into an ellipse matching a wide box.
class _ScaleX extends GradientTransform {
  const _ScaleX(this.factor);
  final double factor;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final c = bounds.center;
    return Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(math.max(factor, 1), 1, 1, 1)
      ..translateByDouble(-c.dx, -c.dy, 0, 1);
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.required = false, this.suffix});
  final String text;
  final bool required;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final f = _FeedbackPalette.of(context);
    final base = AppTypography.label.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: c.textPrimary,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: text),
          if (required)
            TextSpan(
              text: '  *',
              style: base.copyWith(color: const Color(0xFFF0506E)),
            ),
          if (suffix != null)
            TextSpan(
              text: ' $suffix',
              style: base.copyWith(
                fontWeight: FontWeight.w400,
                color: f.accentText,
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, left: 4),
    child: Text(
      text,
      style: AppTypography.caption.copyWith(color: context.colors.error),
    ),
  );
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final FeedbackType type;
  final bool selected;
  final VoidCallback onTap;

  static const _icons = {
    FeedbackType.bug: Icons.bug_report_outlined,
    FeedbackType.idea: Icons.lightbulb_outline_rounded,
    FeedbackType.other: Icons.more_horiz_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final f = _FeedbackPalette.of(context);
    final radius = BorderRadius.circular(12);
    final fg = selected ? Colors.white : const Color(0xFFC9CBF5);
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 43.5,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: selected ? null : f.chip,
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF8D43FE), Color(0xFF6A5CFC)],
                )
              : null,
          border: Border.all(
            color: selected ? const Color(0x66FFFFFF) : f.chipBorder,
          ),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x667A4DFD), blurRadius: 14)]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _icons[type],
                  size: 21,
                  color: selected || !f.dark ? fg : c.primary,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    type.labelKey.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: f.dark ? fg : c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _decoration(BuildContext context, String hint) {
  final f = _FeedbackPalette.of(context);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: f.fieldBorder),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTypography.bodyM.copyWith(fontSize: 13.5, color: f.hint),
    filled: true,
    fillColor: f.field,
    counterText: '',
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: BorderSide(color: context.colors.primary, width: 1.5),
    ),
  );
}

class _ContentField extends StatelessWidget {
  const _ContentField({required this.controller});
  final FeedbackController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final f = _FeedbackPalette.of(context);
    return Stack(
      children: [
        TextField(
          controller: controller.content,
          minLines: 4,
          maxLines: 4,
          maxLength: FeedbackController.maxLength,
          onChanged: (_) => controller.contentError.value = null,
          style: AppTypography.bodyM.copyWith(
            fontSize: 13.5,
            color: c.textPrimary,
          ),
          decoration: _decoration(
            context,
            'feedback_content_hint'.tr,
          ).copyWith(contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 30)),
        ),
        Positioned(
          right: 12,
          bottom: 9,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller.content,
            builder: (context, v, _) => Text(
              '${v.text.characters.length}/${FeedbackController.maxLength}',
              style: AppTypography.caption.copyWith(
                fontSize: 12,
                color: f.hint,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller});
  final FeedbackController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final f = _FeedbackPalette.of(context);
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller.email,
        keyboardType: TextInputType.emailAddress,
        onChanged: (_) => controller.emailError.value = null,
        style: AppTypography.bodyM.copyWith(fontSize: 14, color: c.textPrimary),
        decoration: _decoration(context, 'feedback_email_hint'.tr).copyWith(
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 18),
            child: Icon(Icons.mail_outline_rounded, color: f.accentText),
          ),
        ),
      ),
    );
  }
}

/// Purple→cyan gradient CTA with a paper-plane icon.
class _SendButton extends StatelessWidget {
  const _SendButton({required this.onTap});
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Semantics(
      button: true,
      label: 'feedback_send'.tr,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: const LinearGradient(
            colors: [Color(0xFFA848FC), Color(0xFF6A6CFB), Color(0xFF23BFFE)],
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x557A5CFC), blurRadius: 16),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: SizedBox(
              height: 45,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.rotate(
                    angle: -0.5,
                    child: const Icon(
                      Icons.send_outlined,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Text(
                    'feedback_send'.tr,
                    style: AppTypography.label.copyWith(
                      fontSize: 16,
                      color: Colors.white,
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
