import 'package:get/get.dart';

import '../models/ui_models/app_error.dart';
import '../services/application/auth_service.dart';
import '../utils/toast_utils.dart';

/// Observes the optional Google account (P15-02). Never gates local music.
class AuthController extends GetxController {
  static AuthController get to => Get.isRegistered<AuthController>()
      ? Get.find()
      : Get.put(AuthController(), permanent: true);

  final AuthService _service = Get.find();
  final Rxn<AuthUser> user = Rxn<AuthUser>();
  final RxBool busy = false.obs;
  final Rxn<AppErrorCode> lastError = Rxn<AppErrorCode>();

  @override
  void onInit() {
    super.onInit();
    _service.user.addListener(_sync);
    _sync();
  }

  @override
  void onClose() {
    _service.user.removeListener(_sync);
    super.onClose();
  }

  void _sync() => user.value = _service.user.value;

  bool get isLoggedIn => user.value != null;

  Future<void> signIn() async {
    if (busy.value) return; // double tap guard (P15-03)
    busy.value = true;
    lastError.value = null;
    try {
      await _service.signIn();
      ToastUtils.success('toast_signed_in'.tr);
    } on AppError catch (e) {
      // Cancel is silent; other errors are typed and retryable (P15-05).
      if (e.code != AppErrorCode.authCancelled) {
        lastError.value = e.code;
        ToastUtils.error(e.code.messageKey.tr);
      }
    } catch (_) {
      lastError.value = AppErrorCode.authFailed;
      ToastUtils.error(AppErrorCode.authFailed.messageKey.tr);
    } finally {
      busy.value = false;
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    ToastUtils.success('toast_signed_out'.tr);
  }
}
