import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../services/feedback_service.dart';

enum FeedbackType {
  bug('feedback_type_bug'),
  idea('feedback_type_idea'),
  other('feedback_type_other');

  const FeedbackType(this.labelKey);
  final String labelKey;
}

/// sc_feedback: type, required content, optional reply email. "Gửi" opens
/// the email app; the app never claims the mail was sent (P14-16..18).
class FeedbackController extends GetxController {
  static const int minLength = 10;
  static const int maxLength = 2000;

  final TextEditingController content = TextEditingController();
  final TextEditingController email = TextEditingController();
  final Rx<FeedbackType> type = FeedbackType.idea.obs;
  final RxnString contentError = RxnString();
  final RxnString emailError = RxnString();
  final RxBool noEmailApp = false.obs;
  final RxBool opened = false.obs;

  static final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void onClose() {
    content.dispose();
    email.dispose();
    super.onClose();
  }

  bool validate() {
    final text = content.text.trim();
    contentError.value = text.isEmpty
        ? 'feedback_content_required'.tr
        : (text.length < minLength ? 'feedback_content_short'.tr : null);
    final mail = email.text.trim();
    emailError.value = mail.isNotEmpty && !_emailRe.hasMatch(mail)
        ? 'feedback_email_invalid'.tr
        : null;
    return contentError.value == null && emailError.value == null;
  }

  Future<void> send() async {
    if (!validate()) return;
    final ok = await FeedbackService.composeEmail(
      subject: '[Muvik] ${type.value.labelKey.tr}',
      body: content.text.trim(),
      replyTo: email.text.trim(),
    );
    noEmailApp.value = !ok;
    opened.value = ok;
  }
}
