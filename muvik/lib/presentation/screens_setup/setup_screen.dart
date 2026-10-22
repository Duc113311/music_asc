import 'package:flutter/material.dart';
import '../common_components/app_touchable.dart';
import 'package:get/get.dart';

import '../../controller/setup_controller.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import 'step_permission.dart';
import 'step_result.dart';
import 'step_sources.dart';

/// sc_step_01..03. No bottom navigation and no theme step (spec §1.4).
class SetupScreen extends GetView<SetupController> {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final step = controller.step.value;
      return PopScope(
        canPop: step == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && step > 0 && !controller.scanState.value.isRunning) {
            controller.goTo(step - 1);
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                SetupHeader(
                  step: step,
                  onBack: step > 0 && !controller.scanState.value.isRunning
                      ? () => controller.goTo(step - 1)
                      : null,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppMotion.state,
                    child: switch (step) {
                      0 => const StepPermission(key: ValueKey(0)),
                      1 => const StepSources(key: ValueKey(1)),
                      _ => const StepResult(key: ValueKey(2)),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class SetupHeader extends StatelessWidget {
  const SetupHeader({super.key, required this.step, this.onBack});
  final int step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.screenH,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null)
                AppIconButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'action_back'.tr,
                  color: c.textPrimary,
                  onPressed: onBack,
                )
              else
                const SizedBox(width: AppSpacing.md),
              ShaderMask(
                shaderCallback: (r) =>
                    LinearGradient(colors: c.ctaGradient).createShader(r),
                child: Text(
                  'Muvik',
                  style: AppTypography.headingL.copyWith(color: Colors.white),
                ),
              ),
              const Spacer(),
              Text(
                'setup_step_of'.trParams({
                  'args1': '${step + 1}',
                  'args2': '3',
                }),
                style: AppTypography.bodyM.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: Semantics(
              label: 'setup_step_of'.trParams({
                'args1': '${step + 1}',
                'args2': '3',
              }),
              child: Row(
                children: List.generate(
                  3,
                  (i) => Expanded(
                    child: AnimatedContainer(
                      duration: AppMotion.state,
                      margin: EdgeInsets.only(right: i < 2 ? AppSpacing.xs : 0),
                      height: 6,
                      decoration: BoxDecoration(
                        color: i <= step ? c.primary : c.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared title block for setup steps.
class SetupTitle extends StatelessWidget {
  const SetupTitle({
    super.key,
    required this.title,
    required this.highlight,
    required this.description,
  });
  final String title;
  final String highlight;
  final String description;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$title '),
              TextSpan(
                text: highlight,
                style: TextStyle(color: c.primary),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: AppTypography.headingL.copyWith(color: c.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          description,
          textAlign: TextAlign.center,
          style: AppTypography.bodyL.copyWith(color: c.textSecondary),
        ),
      ],
    );
  }
}
