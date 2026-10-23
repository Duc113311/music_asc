# Muvik – Check list rà soát toàn bộ app

Ngày rà soát: 2026-10-23 · Nguồn: đọc code nhánh `main` (commit `175f5a2`), `flutter analyze`, đối chiếu `Muvik_Bug_Fix_Notes.md`.
Chưa chạy lại trên máy thật (điện thoại đang mất kết nối), nên mục nào ghi "xác nhận trên máy" cần test tay.

Quy ước: `[ ]` chưa làm · `[~]` làm một phần / cần xác nhận · `[x]` xong.
Độ ưu tiên: **P0** chặn phát hành / sai luồng, **P1** nên làm sớm, **P2** cải tiến. Cột "Giao cho" để mai điền.

---

## 0. LỖI NGHIÊM TRỌNG – lần mở app đầu tiên bị màn trắng, không vào được (P0)

**Hiện tượng (bạn báo):** bấm vào app lần đầu (sau khi cài) chỉ thấy màn trắng, đợi mãi không vào. Vuốt tắt app rồi mở lại thì vào bình thường.
**Trạng thái:** chưa tái hiện được (điện thoại mất kết nối) nên **chưa xác định được nguyên nhân chắc chắn**. Dưới đây là kết quả đọc code và các nghi phạm xếp theo khả năng.

**Màn trắng này là gì:** đó là màn khởi động native của Android (`LaunchTheme` → `launch_background.xml` chỉ có nền trắng). Nó hiện cho tới khi Flutter vẽ được khung hình đầu tiên, tức là cho tới khi `runApp()` chạy. Màn Splash của app (logo Muvik) chỉ xuất hiện **sau** `runApp()`. Vậy lỗi nằm ở đoạn khởi động **trước `runApp()`** (hoặc engine không khởi động), không nằm ở `BootstrapService` của màn Splash (phần đó có màn Thử lại và timeout 15 s).

**Đoạn code chạy trước `runApp()` trên `main` hiện tại** (`commRunApp` của `dsp_base` 1.1.3 + `main.dart`), tất cả tuần tự và chặn việc hiện giao diện:
`PrefAssist.init` → nạp chuỗi của base → `CommFigs.classifyDevice` (plugin `system_info_plus`, không có timeout) → `SystemChrome` ×2 → `SystemUiChannel.hideNavigationBar` (không có timeout) → `Firebase.initializeApp` (timeout 5 s) → `initializeDateFormatting` → `AppLocalize.ensureConfigured/loadTranslations` → `MixedUtils.currentVersionCode` → (alpha/dev) lấy Android ID cho thiết bị test AdMob (không có timeout) → cài Crashlytics.

| # | Nghi phạm | Vì sao đáng nghi | Cách kiểm tra |
|---|---|---|---|
| CL-45 | **Một `await` trước `runApp()` không bao giờ trả về** | Chỉ cần 1 plugin/channel không trả lời lần đầu (`system_info_plus` đã cũ 0.0.7, `hideNavigationBar`, Android ID) là app treo ở màn trắng vĩnh viễn. Lần 2 vào được vì tiến trình/engine đã ấm và kết quả khác. | Chạy `flutter run --flavor dev` trên máy **vừa gỡ app** và `flutter logs`; thêm log mốc thời gian trước/sau từng bước ở `commRunApp`/`_onBindingInitialized` xem dừng ở bước nào. |
| CL-46 | **Khởi động lạnh lần đầu quá chậm** (không treo thật) | Bản debug/JIT và lần chạy đầu sau khi cài (ART chưa biên dịch, Firebase + Play Services khởi tạo lần đầu, Firebase tối đa 5 s) có thể kéo dài 10–30 s trong khi người dùng chỉ thấy màn trắng nên tưởng là treo. | So thời gian với **bản release** (`flutter build apk --flavor dev --release`): nếu release vào ngay thì chủ yếu do bản debug. `adb shell am start -W -n com.asctechsoft.muvik/.MainActivity` cho `TotalTime`. |
| CL-47 | **Mở app từ trình cài đặt / lúc cấp quyền** | Mở bằng nút "Mở" của trình cài đặt hoặc ngay lúc hệ thống đang hiện hộp thoại có thể tạo activity thứ hai song song (manifest có `launchMode=singleTop`, `taskAffinity=""`), activity đầu đứng im. Vuốt tắt xong mở lại chỉ còn một. | Thử 2 cách: mở từ nút "Mở" của trình cài đặt và mở từ icon launcher; xem có khác nhau không. |
| CL-48 | **Chưa rõ bản build đang test** | Bản debug cài bằng `flutter run` rồi mở lại bằng tay từ launcher khi máy tính không còn kết nối đôi khi cũng kẹt màn trắng. | Ghi rõ lần lỗi là flavor nào (alpha/dev/product), debug hay release, cài bằng `flutter run` hay `.apk`. |

**Hướng sửa đề xuất (làm theo thứ tự):**
- [ ] **CL-49 – Hiện giao diện sớm, đưa việc nặng vào Splash.** `main()` chỉ giữ những gì bắt buộc rồi gọi `runApp()` ngay: prefs + locale (đọc nhanh). Firebase/Crashlytics, `classifyDevice`, AdMob, Remote Config khởi động **sau** khi Splash đã hiện (nền, có timeout, thất bại thì bỏ qua). Màn Splash đã có sẵn trạng thái Thử lại, tái sử dụng được.
- [ ] **CL-50 – Mọi bước trước `runApp()` phải có timeout** (3–5 s) và bắt lỗi: `SystemUiChannel.hideNavigationBar`, `classifyDevice`, lấy Android ID, `SystemChrome`. Một bước hỏng chỉ được bỏ qua, không được làm treo cả app.
- [ ] **CL-51 – Thay màn trắng native bằng màn thương hiệu.** `launch_background.xml` (và `values-night`) đang nền trắng; đổi sang màu nền Muvik + logo, và dùng Android 12 SplashScreen API (`windowSplashScreen*`). Người dùng sẽ không thấy "trắng" nữa, và khi có lỗi cũng phân biệt được "đang tải" với "treo".
- [ ] **CL-52 – Watchdog khởi động.** Ghi mốc thời gian từng bước (`AppLog.info` + breadcrumb Crashlytics). Nếu sau ~8 s vẫn chưa tới `runApp()` thì ghi một báo cáo không-nghiêm-trọng để biết lỗi xảy ra ở bước nào trên máy người dùng.
- [ ] **CL-53 – Kiểm tra lại sau khi merge nhánh `feature/asc-base-alignment`.** Nhánh này đã bỏ `classifyDevice`/AdMob Android ID khỏi đường khởi động (đổi sang `DspBase.start`, có timeout 6 s, không ném lỗi) nên có thể giảm nguy cơ; **chưa kiểm chứng trên máy**, và vẫn cần CL-49…CL-51.
- [ ] **CL-54 – Kịch bản test bắt buộc trước khi phát hành:** gỡ app → cài mới → mở lần đầu (đo thời gian đến Splash) → lặp 5 lần trên ít nhất 2 máy (một máy yếu), cả flavor `dev` release và `product` release, cả mở từ trình cài đặt và từ launcher.

---

## 1. Luồng khởi động mới (bạn yêu cầu)

Hiện tại: `Splash → Onboarding → Setup (quyền → chọn nguồn → quét → kết quả) → Home` (`splash_screen.dart` `nextRoute()`).
Chưa có màn chọn ngôn ngữ, và Cài đặt cũng chưa có mục đổi ngôn ngữ.

| # | Việc | Chi tiết | Ưu tiên | Giao cho |
|---|---|---|---|---|
| CL-01 | **Thêm màn chọn ngôn ngữ giữa Splash và Onboarding** | Luồng mới: `Splash → Chọn ngôn ngữ → Onboarding → Setup → Home`. Route mới `RouteName.language` (+ `AppPages`), pref mới `languageChosen`. `SplashScreen.nextRoute()`: chưa chọn ngôn ngữ → language; rồi onboarding; rồi setup; rồi home. Mặc định tô sáng ngôn ngữ máy (`AppLocalize.resolve`). Chọn xong áp dụng ngay bằng `AscLocale.setAppLocale` (không dựng lại app), lưu `PrefConst.language` và tắt `followSystemLanguage`. Chỉ liệt kê ngôn ngữ đã có bản dịch thật (EN, VI – `AppLocaleConfig.supportedLocales`); thêm ngôn ngữ mới = thêm `Locale` + dịch folder `values-xx`. Thiết kế màn theo figma nếu có (chưa có key `sc_...` trong `screen_map.md`). | P0 | |
| CL-02 | Mục **Ngôn ngữ** trong Cài đặt | Dùng lại đúng màn/list của CL-01, để người dùng đổi sau. Cần thêm key chuỗi vào `tool/strings_src.py`. | P1 | |
| CL-03 | Test luồng điều hướng | Cập nhật test cho `nextRoute()` (hiện chưa có test): 4 trạng thái pref → 4 route. Test cài lại app, tắt app giữa chừng ở màn ngôn ngữ/onboarding/setup. | P1 | |
| CL-04 | Analytics cho các bước | `RouteAnalytics` đã log `screen_view` theo route; kiểm tra tên route mới xuất hiện trong Firebase. | P2 | |

## 2. Quét thư viện nhạc tự động (bạn yêu cầu)

Hiện tại: sau khi cấp quyền, người dùng phải tự **chọn nguồn → bấm Quét** (`setup_controller.dart` `startScan`). Vào app lần sau chỉ có `refreshOnResume()` (kiểm tra quyền/nguồn, **không** phát hiện bài mới), muốn cập nhật phải vào Cài đặt → Quét thư viện.

| # | Việc | Chi tiết | Ưu tiên | Giao cho |
|---|---|---|---|---|
| CL-05 | **Tự quét ngay sau khi cấp quyền (setup)** | Cấp quyền xong → tự chọn mọi nguồn truy cập được (`selectableSources`) và chạy `scan()` luôn, hiện tiến độ ngay trong step, xong sang kết quả. Bỏ bước "chọn nguồn" khỏi luồng mặc định; giữ "Thêm thư mục khác" và "Quét lại" ở màn kết quả. Máy không có nhạc (0 bài) → màn kết quả hiện đúng trạng thái trống như `P06-14`. | P0 | |
| CL-06 | **Tự kiểm tra bài mới mỗi lần vào app, rồi báo** | Khi mở app (sau splash/home) và khi quay lại foreground: so sánh nhanh MediaStore với DB (số bài / `MediaStore.getGeneration` / `date_modified` lớn nhất, **không** quét đầy đủ). Có thay đổi → hiện banner/snackbar "Tìm thấy N bài mới" kèm nút **Quét** (hoặc quét nền tự động rồi báo "Đã thêm N bài"). Không đổi → im lặng. Chạy nền, không chặn UI, chặn chạy trùng khi đang quét (`state.value.isRunning`). | P0 | |
| CL-07 | Tuỳ chọn trong Cài đặt: "Tự quét khi có nhạc mới" | Bật = quét nền tự động rồi báo kết quả; tắt = chỉ báo và để người dùng bấm. Mặc định đề xuất: báo + nút Quét (an toàn pin/dữ liệu). | P1 | |
| CL-08 | Phát hiện thay đổi khi app đang mở | Đăng ký `ContentObserver` trên `MediaStore.Audio` phía Kotlin (`MediaLibraryHandler`) → đẩy sự kiện lên Dart để chạy CL-06. Throttle (vd. 5 s) vì tải file nhạc về sẽ bắn nhiều sự kiện. | P2 | |
| CL-09 | Xử lý bài bị xoá khỏi máy | Phần quét hiện đã có `missingIds`; kiểm tra bài đang phát/trong playlist bị xoá file thì UI báo gọn và bỏ khỏi hàng đợi (liên quan `P07-16`). Test với SD tháo/lắp. | P1 | |
| CL-10 | Kiểm tra quét trên máy thật | `P05-01…P05-15` trong `Muvik_TODO_Implementation.md` toàn ghi "chờ QA, chưa có thiết bị". Cần chạy: 0 bài, hàng nghìn bài, tên Unicode, nguồn trùng, quyền bị thu hồi, hủy giữa chừng. | P0 | |

## 3. Đối chiếu danh sách fix cũ (`Muvik_Bug_Fix_Notes.md`) với code hiện tại

| Mục cũ | Trạng thái trong code | Việc còn lại |
|---|---|---|
| Giảm font 2px | `[x]` `SmallerTextScaler` ở `main.dart` | Chạy `layout_overflow_test`, xem tay các màn nhiều chữ (thống kê, onboarding) |
| Bỏ header Khám phá (Melo + logo) | `[~]` `explore_tab.dart` không còn `MeloLogo` | Xác nhận trên máy |
| Padding top/bottom +2px cho option Cài đặt | `[~]` chưa xác minh được từ code | Xem tay `settings_tab.dart` / các tile |
| Ẩn thanh điều hướng của máy | `[x]` `SystemUiChannel.hideNavigationBar` + gọi lại khi resume | Test vuốt cạnh dưới, xoay, đa nhiệm |
| Hiệu ứng chạm toàn app | `[~]` đã đặt ripple ở theme (`AppInkRipple`, `app_theme.dart:121`) | Còn `GestureDetector` không ripple: `app_controls.dart`, `now_playing_screen.dart`, `player_widgets.dart` → đổi sang `AppTouchable`/`InkWell`. Test Phát qua tai nghe, Chủ đề, Bộ chỉnh âm |
| Rate app: sao sáng lần lượt khi mở | `[ ]` `rate_app_dialog.dart` chỉ có hiệu ứng phóng khi bấm, **chưa** có animation tự chạy khi mở | Làm animation stagger 1→5 sao khi dialog mở (~120 ms/sao, tôn trọng `disableAnimations`) |
| Màu nhấn: 8 màu, 2 hàng | `[~]` Comment ghi "8 accents on 2 rows of 4" nhưng `AccentColor` có **12** màu (`app_colors.dart`) → đang thành 3 hàng | Chốt 8 hay 12; sửa enum hoặc lưới + comment cho khớp (cả `accent_sheet.dart` và `theme_screen.dart`) |
| Login Google | `[ ]` **Đã bị gỡ khỏi code**: không còn `google_sign_in` trong `pubspec.yaml`, đã xoá `auth_controller.dart`/`auth_service.dart`. `bootstrap_service.dart` vẫn ghi chú "Auth runs detached" (lỗi thời) | Quyết định: làm lại hay bỏ hẳn. Nếu làm lại: thêm package, OAuth client + SHA-1 debug/release trong Firebase, `AppConfig.googleServerClientId` |
| Bỏ bottom sheet thứ tự phát / lặp lại | `[x]` Player không còn `showModalBottomSheet` | Thêm toast/haptic báo chế độ mới (xem CL-24) |
| Ảnh "Playlist dành cho bạn" nhỏ lại | `[~]` `_cardWidth = 170` (`dashboard_tab.dart:666`) | Xác nhận kích thước mong muốn; nếu còn to, giảm ~140 |
| Loudness Boost (nghe to như TikTok) | `[~]` Đã có `_LoudnessSlider` + `eq_loudness_gain_db` | Test trên máy: méo tiếng, mức an toàn, cảnh báo khi kéo cao, lưu lại sau khi thoát app |

## 4. Lỗi / rủi ro kỹ thuật

| # | Việc | Chi tiết | Ưu tiên | Giao cho |
|---|---|---|---|---|
| CL-11 | **Chưa chạy thử trên máy thật sau khi chuyển base** | Nhánh `feature/asc-base-alignment` (worktree `D:\app-music-asc`, commit `62f01cd`) đã đổi `dsp_base`→v2 + `asc_common`, viết lại `main.dart`, thêm `AppLifecycleService`. Mới qua analyze/test/build APK. Cần merge vào `main` (xung đột `pubspec.yaml`, `pubspec.lock`, vài file lib vì `main` đã có thêm commit `175f5a2`), rồi chạy máy thật: khởi động, đổi ngôn ngữ, tắt/mở màn hình, quay lại từ nền. | P0 | |
| CL-12 | Chưa chạy `python build.py` | Script mới chỉ kiểm tra cú pháp. Chạy thử `python build.py dev release` trên Windows (cần `python` trong PATH – máy này `py` có, `python` đang trỏ về Microsoft Store). | P1 | |
| CL-13 | Bí mật trong smart_drink | `build.py` (mật khẩu Gmail app, đã commit), `dsp_base/build_helper.py` (Telegram bot token, đang staged – **đừng commit/push**), `debug.jks` + `android/debug_keystore.properties` đã commit. Đổi mật khẩu/token, chuyển sang biến môi trường như bản muvik. | P0 | |
| CL-14 | `catch (_) {}` nuốt lỗi | 4 chỗ: `setup_controller.dart:118`, `headphones_screen.dart:170`, `audio_effects_channel.dart:100`, `system_ui_channel.dart:20`. Ít nhất 2 chỗ đầu nên `AppLog.info`/`AppLog.error`. | P2 | |
| CL-15 | API deprecated | `onReorder` → `onReorderItem` ở `queue_sheet.dart`, `playlist_detail_screen.dart` (Flutter 3.47). | P2 | |
| CL-16 | `AudioDeviceType` experimental | `audio_handler.dart` ~dòng 715-720 (6 warning) – bọc 1 chỗ + ghi lý do ignore. | P2 | |
| CL-17 | Toolchain Android sắp hết hỗ trợ | Gradle 8.14 → ≥ 9.1, AGP 8.11.1 → ≥ 9.0.1, Kotlin 2.2.20 → ≥ 2.3.20 (Flutter 3.47 đã cảnh báo). | P2 | |
| CL-18 | Bản release chưa thử | Chưa build `--flavor product --release` (R8/shrink có thể cắt `just_audio`/`audio_service`; app chưa có `proguard-rules.pro`); chưa cấu hình ký bản store (`android/key.properties`). | P0 trước khi lên store | |
| CL-19 | Chính sách riêng tư trống | `AppConfig.privacyPolicyUrl = ''` (ghi chú `P20-06`). Bắt buộc trước khi phát hành, nhất là khi có Firebase. | P0 trước khi lên store | |
| CL-20 | Quyền và sao lưu | Manifest còn `INTERNET` (Firebase cần, giữ), `RECEIVE_BOOT_COMPLETED`, `FOREGROUND_SERVICE_SPECIAL_USE`: kiểm tra từng quyền có dùng thật không (Play Console sẽ hỏi). Chưa đặt `android:allowBackup`/`dataExtractionRules` → DB nghe nhạc có thể bị sao lưu lên Drive; chốt có muốn không. | P1 | |
| CL-21 | Đặc tả còn lỗi thời | `APP_BASE_STRUCTURE.md` vẫn mô tả `commRunApp`/`CommLocalize`/`PrefAssist`. Cập nhật theo `muvik/docs/base_packages.md`. | P2 | |

## 5. Điểm chạm & animation

| # | Việc | Chi tiết | Ưu tiên | Giao cho |
|---|---|---|---|---|
| CL-22 | Đồng bộ widget chạm | Dùng 1 widget chung (`AppTouchable` trong `common_components`, hoặc bản của `asc_common`) cho mọi nơi; thay 3 `GestureDetector` còn lại. Vùng chạm tối thiểu 48dp. | P1 | |
| CL-23 | Phản hồi khi bấm nút play/next/prev | Hiệu ứng nhấn xuống (scale ~0.94, 120 ms – `AppMotion.press`) + haptic nhẹ cho play/pause, yêu thích, lặp lại, ngẫu nhiên. | P1 | |
| CL-24 | Báo chế độ khi đổi lặp lại / ngẫu nhiên | Bỏ bottom sheet rồi nên có toast ngắn ("Lặp lại: một bài", "Ngẫu nhiên: bật") + đổi icon có animation chuyển (`AnimatedSwitcher`). | P1 | |
| CL-25 | Chuyển màn | `app_pages.dart` đang trộn `fadeIn`, `downToUp`, `noTransition`. Chốt quy tắc: vào chi tiết = trượt ngang, Now Playing = từ dưới lên, tab = không chuyển. | P2 | |
| CL-26 | Player | Ảnh bìa: hiệu ứng chuyển bài (cross-fade/slide), `Hero` từ mini player lên Now Playing, đĩa/tonearm (đã có asset `ic_dia`, `ic_tonearm`) quay khi đang phát và dừng khi pause. | P2 | |
| CL-27 | Trạng thái chờ | Danh sách đang tải dùng skeleton/shimmer thay vì trống; `AnimatedSwitcher` giữa loading → nội dung. | P2 | |
| CL-28 | Rate app + màn khác | Ngoài mục sao sáng lần lượt: hiệu ứng xuất hiện cho dialog (scale+fade), nút "Gửi" bật sáng khi chọn sao. | P1 | |
| CL-29 | Onboarding | Hiệu ứng vào cho từng trang (stagger chữ/hình), chấm trang chuyển mượt; có `reduce motion` thì tắt. | P2 | |
| CL-30 | Tôn trọng "Giảm chuyển động" | Splash đã xử lý `disableAnimations`; làm tương tự cho mọi animation mới. | P1 | |

## 6. Tính năng & trải nghiệm

| # | Việc | Chi tiết | Ưu tiên | Giao cho |
|---|---|---|---|---|
| CL-31 | Màn trống/lỗi có hành động | 0 bài, mất quyền, file lỗi: empty state có nút (Quét lại, Mở cài đặt, Thêm thư mục). | P1 | |
| CL-32 | Accessibility | Tooltip/Semantics có ở ~40 file; rà icon button, slider (EQ, seek) có nhãn và giá trị đọc được bằng TalkBack. | P1 | |
| CL-33 | Chữ cứng / màu cứng | Không còn `Text('...')` cứng (tốt). Nhưng 156 chỗ `Color(0x...)` trong `presentation` (onboarding 51, explore 27, melo_logo 26, feedback 15) → chuyển vào `AppColors` để theme sáng/tối và đổi accent đúng. | P2 | |
| CL-34 | Đa ngôn ngữ | App có 16 folder `values-*` nhưng chỉ EN/VI là bản dịch thật, 14 folder còn lại là tiếng Anh. Quyết định có dịch thêm không; trong lúc đó danh sách ngôn ngữ (CL-01) chỉ hiện EN/VI. | P2 | |
| CL-35 | Phát nhạc nâng cao | Tốc độ phát, crossfade/gapless, hẹn giờ tắt (đã có), bỏ qua khoảng lặng, ReplayGain/chuẩn hoá âm lượng. Chọn mục phù hợp roadmap. | P2 | |
| CL-36 | Quản lý bài hát | Đặt làm nhạc chuông, chia sẻ file, xoá file khỏi máy (có xác nhận), sửa tag, ẩn thư mục (đã có "loại trừ" – kiểm tra UI). | P2 | |
| CL-37 | Lời bài hát | Đã có `lyrics_service`/`lyrics_view` đọc LRC. Kiểm tra: bài không có lời, lệch thời gian, cuộn theo dòng, bật/tắt nhanh. | P1 | |
| CL-38 | Notification/khoá màn hình | Đã làm notification tuỳ biến (`OngoingNotification`). Test Android 13/14/15, Samsung One UI, tai nghe Bluetooth, xe (metadata, ảnh bìa). | P1 | |
| CL-39 | Widget màn hình chính | Chưa có; cân nhắc widget play/pause + bài hiện tại. | P2 | |
| CL-40 | Tìm kiếm | Lịch sử tìm kiếm, gợi ý, tìm theo lời/thư mục, bỏ dấu tiếng Việt (tìm "nhac" ra "Nhạc"). Kiểm tra bỏ dấu hiện đã có chưa. | P1 | |

## 7. Hiệu năng (đo bằng DevTools trên máy thật)

| # | Việc | Chi tiết | Ưu tiên |
|---|---|---|---|
| CL-41 | Khởi động | Đo thời gian đến Home; splash cố định 1200 ms (`splash_screen.dart`) → chỉ giữ tối thiểu cần cho logo, còn lại chờ bootstrap thật. `DspBase` bị cắt sau 6 s nếu mạng chậm. | P1 |
| CL-42 | Cuộn thư viện lớn | Thử vài nghìn bài: jank, RAM artwork. Chỉ 2 chỗ dùng `cacheWidth`; kiểm tra `song_artwork.dart`, ảnh bìa trong list/grid có `cacheWidth` hợp lý. | P1 |
| CL-43 | Phạm vi rebuild | 44 `Obx`, 65 `setState` trong `presentation`; kiểm tra màn Player/Statistics (file lớn nhất: `onboarding_screen.dart` 991 dòng, `statistics_screen.dart` 855 dòng) có rebuild cả màn mỗi giây khi cập nhật vị trí phát. Cân nhắc tách file lớn. | P2 |
| CL-44 | `shrinkWrap: true` | 3 chỗ trong `presentation`; chắc chắn không nằm trong danh sách dài. | P2 |

## 8. Kiểm thử

- [ ] Test mới: `nextRoute()` (CL-03), phát hiện bài mới (CL-06), tự quét sau cấp quyền (CL-05).
- [ ] Widget test Player: đổi lặp lại/ngẫu nhiên đổi icon, không bật bottom sheet.
- [ ] Chạy `flutter test` sau khi giảm font + đổi màu nhấn; hiện test có `layout_overflow_test`, `lyrics_test`, `bug_fix_rules_test`… nhưng chưa test `audio_handler`.
- [ ] Checklist QA tay trên máy thật (mai chạy theo thứ tự): cài mới → ngôn ngữ → onboarding → cấp quyền → quét tự động → phát nhạc → tắt màn hình → thông báo → tai nghe → xoay/đa nhiệm → gỡ quyền → quay lại.

---

### Gợi ý chia việc cho ngày mai

0. **Làm trước nhất – lỗi màn trắng lần đầu (1 người, cần máy thật):** CL-45…CL-54 (`main.dart`, `launch_background.xml`, `splash_screen.dart`). Nên chốt nguyên nhân trước rồi mới làm phần 1, vì cả hai cùng sửa luồng khởi động.
1. **Luồng đầu tiên (1 người):** CL-01, CL-02, CL-03, CL-05 (thay đổi chung `splash_screen`, `app_pages`, `setup_controller`).
2. **Quét tự động (1 người):** CL-06, CL-07, CL-08, CL-09, CL-10 (`library_scan_service`, Kotlin `MediaLibraryHandler`).
3. **UI/animation (1 người):** mục 3 (rate app, màu nhấn), 5 (CL-22…CL-30).
4. **Hạ tầng/phát hành:** CL-11, CL-12, CL-13, CL-17, CL-18, CL-19, CL-20.
