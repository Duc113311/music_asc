import 'package:get/get.dart';

import '../configs/legal_config.dart';
import '../services/feedback_service.dart';
import 'toast_utils.dart';

/// Opens the hosted privacy policy.
class LegalUtils {
  const LegalUtils._();

  /// Sends the user to the policy page in their browser. The policy lives on
  /// the web only, so when no browser can take the URL the user is told
  /// instead of getting a tap that appears to do nothing.
  static Future<void> openPrivacyPolicy() async {
    final opened = await FeedbackService.openUrl(LegalConfig.privacyPolicyUrl);
    if (!opened) {
      ToastUtils.show('about_privacy_unavailable'.tr, type: ToastType.warning);
    }
  }
}
