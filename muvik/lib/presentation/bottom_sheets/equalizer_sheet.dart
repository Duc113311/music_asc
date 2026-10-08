import 'package:get/get.dart';

import '../../values/route_name.dart';
import '../common_components/equalizer_panel.dart';
import '../common_components/primary_bottom_sheet.dart';
import '../common_components/primary_button.dart';

/// Quick EQ from the player; "Chi tiết" opens sc_bo_chinh_am (P12-09).
Future<void> showEqualizerSheet() => showAppSheet<void>(
  builder: (context) {
    return SheetScaffold(
      title: 'settings_equalizer'.tr,
      footer: PrimaryButton(
        label: 'action_details'.tr,
        variant: ButtonVariant.secondary,
        onPressed: () async {
          Get.back<void>();
          await Get.toNamed(RouteName.equalizer);
        },
      ),
      child: const EqualizerPanel(compact: true),
    );
  },
);
