import 'package:flutter/material.dart';

import '../../controller/settings_controller.dart';
import '../../models/ui_models/scan_state.dart';
import '../../values/app_colors.dart';
import '../../values/app_dimensions.dart';
import '../../values/app_typography.dart';
import '../common_components/app_controls.dart';
import '../common_components/app_inputs.dart';
import '../common_components/app_touchable.dart';
import '../common_components/cards.dart';
import '../common_components/primary_button.dart';
import '../common_components/primary_dialog.dart';
import '../common_components/source_widgets.dart';
import '../common_components/state_views.dart';
import '../../utils/toast_utils.dart';

/// Debug-only gallery of components in the current theme and text scale
/// (P03-17). Not registered in release builds.
class ComponentPreviewScreen extends StatefulWidget {
  const ComponentPreviewScreen({super.key});

  @override
  State<ComponentPreviewScreen> createState() => _ComponentPreviewScreenState();
}

class _ComponentPreviewScreenState extends State<ComponentPreviewScreen> {
  final _text = TextEditingController(text: 'Muvik');
  bool _switch = true;
  bool? _check = true;
  int _radio = 0;
  int _tab = 0;
  double _scale = 1;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = SettingsController.to;
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(_scale)),
      child: Scaffold(
        appBar: DetailAppBar(
          title: 'Components',
          actions: [
            IconButton(
              tooltip: 'theme',
              icon: const Icon(Icons.brightness_6_rounded),
              onPressed: () => s.setThemeMode(
                Theme.of(context).brightness == Brightness.dark
                    ? ThemeMode.light
                    : ThemeMode.dark,
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          children: [
            Text(
              'Text scale ${_scale.toStringAsFixed(1)}',
              style: AppTypography.label.copyWith(color: c.textPrimary),
            ),
            Slider(
              value: _scale,
              min: 1,
              max: 2,
              onChanged: (v) => setState(() => _scale = v),
            ),
            Text(
              'Display',
              style: AppTypography.display.copyWith(color: c.textPrimary),
            ),
            Text(
              'Heading L',
              style: AppTypography.headingL.copyWith(color: c.textPrimary),
            ),
            Text(
              'Body M',
              style: AppTypography.bodyM.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Primary',
              onPressed: () => Future.delayed(const Duration(seconds: 1)),
            ),
            const SizedBox(height: AppSpacing.xs),
            const PrimaryButton(label: 'Disabled'),
            const SizedBox(height: AppSpacing.xs),
            PrimaryButton(
              label: 'Gradient',
              variant: ButtonVariant.gradient,
              onPressed: () async {},
            ),
            const SizedBox(height: AppSpacing.xs),
            PrimaryButton(
              label: 'Secondary',
              variant: ButtonVariant.secondary,
              onPressed: () async {},
            ),
            PrimaryButton(
              label: 'Tertiary',
              variant: ButtonVariant.tertiary,
              onPressed: () async {},
            ),
            PrimaryButton(
              label: 'Destructive',
              variant: ButtonVariant.destructive,
              onPressed: () async {},
            ),
            const PrimaryButton(label: 'Loading', loading: true),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                AppSwitch(
                  value: _switch,
                  onChanged: (v) => setState(() => _switch = v),
                ),
                const AppSwitch(value: true),
                GestureDetector(
                  onTap: () => setState(
                    () => _check = _check == true
                        ? null
                        : (_check == null ? false : true),
                  ),
                  child: AppCheckbox(value: _check),
                ),
                const SizedBox(width: 12),
                for (var i = 0; i < 2; i++)
                  GestureDetector(
                    onTap: () => setState(() => _radio = i),
                    child: AppRadio(selected: _radio == i),
                  ),
                AppIconButton(
                  icon: Icons.favorite_rounded,
                  tooltip: 'icon',
                  active: true,
                  onPressed: () {},
                ),
                PlayPauseButton(
                  playing: _switch,
                  onPressed: () => setState(() => _switch = !_switch),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                const AppChip(label: 'Chip', selected: true),
                AppChip(label: 'Chip', icon: Icons.bolt_rounded, onTap: () {}),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedTabs(
              labels: const ['A', 'B', 'C'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(controller: _text, label: 'Input', hint: 'Hint'),
            const SizedBox(height: AppSpacing.xs),
            AppTextField(
              controller: TextEditingController(),
              label: 'Error',
              error: 'Error message',
            ),
            const SizedBox(height: AppSpacing.xs),
            AppSearchField(controller: TextEditingController(), hint: 'Search'),
            const SizedBox(height: AppSpacing.md),
            const ScanProgressCard(
              state: ScanState(
                status: ScanStatus.scanning,
                processed: 42,
                total: 120,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const EmptyState(
              title: 'Empty',
              message: 'Message',
              illustration: true,
            ),
            ErrorState(message: 'Something failed', onRetry: () async {}),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Dialog',
              variant: ButtonVariant.secondary,
              onPressed: () => showConfirmDialog(
                title: 'Title',
                message: 'Message',
                confirmLabel: 'OK',
                icon: Icons.info_rounded,
              ),
            ),
            PrimaryButton(
              label: 'Toast',
              variant: ButtonVariant.tertiary,
              onPressed: () async => ToastUtils.show(
                'Toast ${DateTime.now().second}',
                actionLabel: 'Undo',
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}
