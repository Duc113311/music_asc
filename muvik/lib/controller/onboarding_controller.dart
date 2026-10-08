import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../configs/pref_const.dart';
import '../services/storage/pref_store.dart';
import '../values/route_name.dart';

/// Three intro pages; finishing or skipping records completion and always
/// continues to Setup, never past permissions/sources (P06-07).
class OnboardingController extends GetxController {
  static const int pageCount = 3;

  final PageController pageController = PageController();
  final RxInt page = 0.obs;

  void onPageChanged(int i) => page.value = i;

  void next() {
    if (page.value >= pageCount - 1) {
      finish();
      return;
    }
    pageController.nextPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  void back() {
    if (page.value == 0) return;
    pageController.previousPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  Future<void> finish() async {
    await PrefStore.setBool(PrefConst.onboardingCompleted, true);
    Get.offAllNamed(RouteName.setup);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
