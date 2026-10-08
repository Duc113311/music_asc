import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/library_controller.dart';
import '../../models/ui_models/library_groups.dart';
import '../common_components/app_controls.dart';
import '../common_components/primary_bottom_sheet.dart';
import '../common_components/primary_button.dart';

/// "Sắp xếp bài hát": the choice is a draft until "Áp dụng"; changing the
/// order never resets the current song (spec §9.2).
Future<void> showSortSheet() =>
    showAppSheet<void>(builder: (_) => const _SortSheet());

class _SortSheet extends StatefulWidget {
  const _SortSheet();
  @override
  State<_SortSheet> createState() => _SortSheetState();
}

class _SortSheetState extends State<_SortSheet> {
  late SongSort _draft = LibraryController.to.sort.value;

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: 'sort_title'.tr,
      padding: EdgeInsets.zero,
      footer: PrimaryButton(
        label: 'action_apply'.tr,
        onPressed: () async {
          await LibraryController.to.setSort(_draft);
          Get.back<void>();
        },
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in SongSort.values)
            SelectableOptionTile(
              title: s.labelKey.tr,
              selected: s == _draft,
              onTap: () => setState(() => _draft = s),
            ),
        ],
      ),
    );
  }
}
