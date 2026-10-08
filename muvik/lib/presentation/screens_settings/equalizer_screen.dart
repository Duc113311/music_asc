import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../values/app_dimensions.dart';
import '../common_components/cards.dart';
import '../common_components/equalizer_panel.dart';
import '../common_components/primary_button.dart';
import '../dialogs/app_dialogs.dart';

/// sc_bo_chinh_am — same data as the player EQ sheet.
class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DetailAppBar(title: 'settings_equalizer'.tr),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          children: [
            const EqualizerPanel(),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'eq_reset'.tr,
              icon: Icons.restart_alt_rounded,
              variant: ButtonVariant.secondary,
              onPressed: confirmResetEqualizer,
            ),
          ],
        ),
      ),
    );
  }
}
