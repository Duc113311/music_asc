# Muvik – Danh sách bug / chỉnh sửa cần fix

Ngày ghi: 2026-10-10 · Trạng thái: `[ ]` chưa làm, `[x]` xong

## Giao diện chung
- [x] Giảm font chữ toàn app xuống 2px. → `SmallerTextScaler` trong `main.dart` (trừ 2px mọi cỡ chữ, không xuống dưới 8px, vẫn theo cỡ chữ hệ thống).
- [x] Ẩn thanh công cụ (navigation bar) của máy ở dưới: vào app là immersive, không hiện thanh dưới. → `MainActivity.hideNavigationBar()` (vuốt từ dưới thì hiện tạm rồi tự ẩn; áp lại khi resume/focus), Dart gọi qua `SystemUiChannel`.
- [x] Bổ sung hiệu ứng điểm chạm (ripple/sáng lên khi bấm) cho mọi button, icon, option đang chưa có.
  - Nguyên nhân chính: card dùng `Container(decoration: color)` che mất ripple → đổi sang `Material` (DetailCard, card Chủ đề, card Bộ chỉnh âm, nhóm Cài đặt, SettingsGroup, thanh tab dưới). `AppSwitch`, `AppChip`, `SegmentedTabs`, `PrimaryButton` chuyển từ `GestureDetector` sang InkWell.
  - Splash dùng chung `AppInkRipple` (`values/app_ink_ripple.dart`) = InkRipple của màn Quét thư viện, nhanh hơn ~30%.
  - Dùng chung hiệu ứng đã có ở màn **Quét thư viện** cho tất cả, nhưng chỉnh tốc độ nhanh hơn một chút.
  - Các màn cần bổ sung rõ ràng: **Phát qua tai nghe**, **Chủ đề**, **Bộ chỉnh âm** (và các màn/option khác còn thiếu).

## Bộ chỉnh âm
- [x] Thêm thanh **"Tăng âm lượng" (Loudness Boost)** để nghe to như TikTok: dùng `AndroidLoudnessEnhancer` của `just_audio`, thanh 0 → ~+10 dB trong `equalizer_panel.dart`, nối vào `audio_handler.dart`, lưu pref. Có cảnh báo méo tiếng/hại tai khi kéo cao; test mức an toàn trên SM G996B.
  - Đã làm: `LoudnessEnhancer` gắn vào native `AudioEffectsHandler.kt` (cùng audio session với EQ, thay vì `AudioPipeline` của just_audio để không đụng hệ effect hiện có), `EqualizerService.setLoudnessGain`, pref `eq_loudness_gain_db`, thanh 0 → +10 dB (bước 0.5) ở cả sheet và màn Bộ chỉnh âm, cảnh báo khi > +6 dB, "Đặt lại" về 0. **Còn: test mức an toàn trên SM G996B.**

## Tab Khám phá
- [x] Bỏ phần header có chữ "Melo, nhạc của bạn…" và logo bên phải. → Lối vào Thống kê chuyển thành icon nhỏ cạnh tiêu đề "Khám phá thư viện" (vì đây là chỗ duy nhất mở Thống kê).

## Màn Home
- [x] Phần **Playlist dành cho bạn**: ảnh item trong list đang quá to, thu nhỏ lại. → card 160×236 → 124×196.

## Màn Cài đặt
- [x] Các option tăng thêm padding trên/dưới mỗi bên 2px (đang quá bé).
- [ ] Bổ sung **đăng nhập (authen) bằng Google**. → Code đã có sẵn (`AuthService`, nút trong thẻ tài khoản). SHA-1 debug keystore máy này `07:74:9B:…:00:AB` khớp OAuth client Android trong `google-services.json`. **Còn: test trên máy thật; thêm SHA-1 release khi có keystore release.**

## Màn Phát nhạc
- [x] Nút **thứ tự phát** và **lặp lại**: bỏ bottom sheet khi bấm. Bấm vào thì tự đổi chế độ và đổi icon luôn, không hiện bottom sheet. → Thứ tự: icon danh sách ↔ shuffle; Lặp: Tắt → Tất cả → Một bài. Có toast ngắn + haptic.

## Màn Đánh giá app (Rate app)
- [x] Thêm hiệu ứng khi mở: các ngôi sao sáng (active) lần lượt từng cái một, tối đa 5 sao. → Bấm sao trong lúc chạy sẽ dừng hiệu ứng và giữ lựa chọn.

## Bottom sheet Màu nhấn
- [x] Bổ sung đủ thành **8 màu**, bố cục **2 hàng**. → Thêm Xanh lá, Hồng phấn, Cam; màn Giao diện cũng xếp 2 hàng.

---

### Ghi chú kỹ thuật (từ lần chạy máy thật)
- Chạy: `flutter run --flavor dev -d <device>` (flavor bắt buộc).
- Cần local (không commit): `android/debug_keystore.properties`, `android/app/google-services.json`.
- Đã sửa tương thích Flutter 3.47: `RepeatMode` hide import ở `now_playing_screen.dart`, `player_mode_sheets.dart`; import Cupertino ở `app_theme.dart`.

---

# Đề xuất cải tiến thêm (Claude rà soát 2026-10-10)

Cơ sở: `flutter analyze` (9 cảnh báo), quét code `lib/`, đối chiếu `Muvik_TODO_Implementation.md`.

## A. Ưu tiên cao – nên làm trước
- [ ] **QA trên máy thật cho các mục TODO đang "chờ QA"** *(cần cắm SM G996B; chưa làm được vì chưa có thiết bị kết nối)*: ~170 mục trong `Muvik_TODO_Implementation.md` (quét thư viện P05, onboarding/setup P06, audio handler P07, shell/navbar P08…) đều ghi "chờ QA, chưa có thiết bị". Giờ đã có SM G996B, nên chạy checklist rồi tick/ghi kết quả.
  - Ưu tiên test: nhạc nền khi tắt màn hình, notification/lockscreen, rút tai nghe, 2 tiếng nhạc/2 notification khi mở player liên tiếp (P07-17), thư viện nhiều nghìn bài, quyền bị thu hồi, SD tháo/lắp (P05-15).
- [ ] **Google login**: `google_sign_in` đã có trong `pubspec`; cần đối chiếu SHA-1 debug/release trong Firebase cho package đang dùng, vì `google-services.json` do bạn cung cấp. Lỗi `CredManProvService` trong log máy thật liên quan đến phần này, kiểm tra khi làm mục Google authen.
  - Đã kiểm tra: SHA-1 debug keystore máy dev (`07:74:9B:…:00:AB`) khớp OAuth client Android; README có lệnh lấy SHA-1. **Còn: test trên máy thật + đăng ký SHA-1 release.**
- [x] **Build tự động chạy được trên máy mới**: hiện phải tự tạo `android/debug_keystore.properties` và `android/app/google-services.json` mới build được. Thêm file mẫu `debug_keystore.properties.example` và mô tả trong README, tránh người mới (hoặc CI) lỗi như lần chạy vừa rồi.
  - Đã làm: `android/debug_keystore.properties.example`; `settings.gradle.kts` tự copy sang `debug_keystore.properties` nếu thiếu (đã thử: xoá file → build tự tạo). README ghi cách lấy `google-services.json` (file này không tự tạo được).
- [ ] **Kiểm tra bản release**: chưa build `--flavor product --release` thử (ký, proguard/R8, `just_audio`/`audio_service` có bị strip không). Nên test sớm trước khi lên store.
  - Đã build được `flutter build apk --flavor product --release` (68.5 MB, R8 bật, ký bằng debug key). **Còn: cài lên máy thật để xem nhạc nền/notification có chạy không (just_audio/audio_service bị strip thì lỗi chỉ lộ lúc chạy); tạo keystore release + `key.properties`.**
  - Lưu ý máy dev: build release mất ~8 phút; nếu gặp `Could not move temporary workspace` thì chạy `cd android && ./gradlew --stop` rồi build lại.

## B. Kỹ thuật / bảo trì
- [ ] **Nâng toolchain Android** *(chặn: máy dev đang Flutter 3.38.9, chưa hỗ trợ AGP 9 — cần nâng Flutter trước, làm cùng mục `onReorderItem`)* (Flutter cảnh báo sắp bỏ hỗ trợ): Gradle 8.14 → ≥ 9.1, AGP 8.11.1 → ≥ 9.0.1, Kotlin 2.2.20 → ≥ 2.3.20. Gỡ luôn `dependency_overrides: permission_handler_android: 13.0.1` khi nâng xong (ghi chú trong `pubspec.yaml`).
- [ ] **Thay API deprecated** *(chặn: `onReorderItem` chưa có trong Flutter 3.38 của máy dev; đổi bây giờ sẽ vỡ build trên máy này)*: `onReorder` → `onReorderItem` ở `queue_sheet.dart:141` và `playlist_detail_screen.dart:149` (lưu ý `onReorderItem` đã điều chỉnh sẵn `newIndex`, nên bỏ đoạn `if (newIndex > oldIndex) newIndex -= 1` nếu có).
- [x] **`AudioDeviceType` là API experimental** (`audio_handler.dart:708-714`): bọc lại cho gọn, thêm `// ignore` có lý do hoặc fallback, theo dõi khi `just_audio` đổi API.
  - Đã làm: chỉ còn đọc ở `MuvikAudioHandler.isHeadsetDevice` (có `// ignore: experimental_member_use` + lý do); loại không biết → coi là loa ngoài.
- [x] **Dependency `dsp_base` pin `ref: main`**: dễ vỡ build khi upstream đổi. Nên pin commit/tag cụ thể (hiện chỉ khóa ở `pubspec.lock`).
  - Đã pin `ref: 2e8d22eb…` (đúng commit đang khóa trong lock) ở `pubspec.yaml` + `pubspec.lock`.
- [x] **Test**: có ~1200 dòng test cho DB/scan/queue/sleep timer/mood, nhưng chưa có test cho màn hình quan trọng (player, settings) và `audio_handler`. Thêm widget test cho player (đổi lặp lại/thứ tự phát) và golden/overflow cho chữ lớn sau khi giảm font 2px.
  - Đã thêm `test/bug_fix_rules_test.dart` (9 test): chu kỳ lặp lại (`RepeatMode.next`), `SmallerTextScaler`, Loudness (giới hạn/lưu/đặt lại), 8 màu nhấn, card "Playlist dành cho bạn" không tràn ở 1.0× và 1.3×. Chưa có widget test đầy đủ cho màn player/`audio_handler` (cần mock audio_service).
- [x] Sau khi **giảm font 2px**: chạy lại `layout_overflow_test.dart` và thử cỡ chữ hệ thống lớn để chắc không tràn. → 86/86 test pass. **Còn: xem bằng mắt trên máy thật.**

## C. UX / sản phẩm
- [x] **Accessibility**: chỉ ~41 file có `Semantics`/`tooltip`. Thêm nhãn cho icon button (play, next, yêu thích, lặp lại, ngẫu nhiên…) cho TalkBack; vùng chạm tối thiểu 48dp (liên quan mục "điểm chạm").
  - Rà lại: các icon button đều qua `AppIconButton` (tooltip + Semantics + 48dp). Bổ sung nhãn cho bộ chọn ảnh bìa playlist (chỗ duy nhất còn thiếu).
- [x] **Hiệu ứng chạm thống nhất**: hiện dùng lẫn `InkWell` (50 chỗ) và `GestureDetector` (6 chỗ, không có hiệu ứng). Làm một widget dùng chung (vd. `TapEffect`/`AppInkWell`) dựa trên hiệu ứng ở màn Quét thư viện rồi thay dần, thay vì sửa lẻ từng màn.
  - Đã làm bằng splash chung `AppInkRipple` trong theme + chuyển GestureDetector của các control dùng chung sang InkWell (xem mục Giao diện chung).
- [x] **Màn Cài đặt dùng `ListView(children: …)` thường** (equalizer, headphones, permissions, playback quality, scan library…): với list ngắn thì ổn; chỉ cần đổi sang builder nếu list có thể dài. → Giữ nguyên (list ngắn, cố định).
- [x] **Phản hồi khi đổi lặp lại/thứ tự phát** (sau khi bỏ bottom sheet): thêm toast/nhãn ngắn ("Lặp lại: một bài", "Phát ngẫu nhiên: bật") và haptic nhẹ, để người dùng biết đang ở chế độ nào.
- [x] **Trạng thái trống/lỗi**: rà các màn 0 bài, mất quyền, file lỗi để có empty state có nút hành động (Quét lại, Mở cài đặt).
  - Rà lại: thư viện/khám phá/home đã có nút Quét/Cấp quyền. Bổ sung: "Playlist không tồn tại" có nút Quay lại; lỗi tải thống kê nghệ sĩ có nút Thử lại (và không tải lại mỗi lần rebuild).
- [x] **Đa ngôn ngữ**: có 15 locale (`xml_strings`); sau khi sửa text (vd. bỏ header Khám phá, thêm text mới) nhớ cập nhật đủ key ở các ngôn ngữ, tránh hiện key trần. → Mọi key mới thêm qua `tool/strings_src.py`, `check_strings.py` báo `missing: []`.
- [ ] **Widget màn hình khóa / Android Auto / Bluetooth metadata** *(cần thiết bị thật)*: kiểm tra tên bài/ảnh bìa hiển thị đúng trên tai nghe Bluetooth và xe (nếu app hướng tới).
- [x] **Equalizer / Chủ đề / Phát qua tai nghe**: ngoài điểm chạm, kiểm tra lưu trạng thái sau khi thoát app và áp dụng lại khi mở lại.
  - Rà code: mọi setter của `SettingsController` (theme, màu nhấn, nền player, chuyển cảnh, 3 tuỳ chọn tai nghe) và `EqualizerService` (kể cả Loudness) đều ghi `PrefStore` và được nạp lại khi khởi động; EQ áp lại mỗi audio session. Test Loudness xác nhận lưu/nạp. **Còn: thử thoát/mở lại trên máy thật.**

## D. Hiệu năng (nên đo trên máy thật)
- [ ] *(cần thiết bị thật)* Mở Flutter DevTools (đã chạy được kết nối) đo: thời gian khởi động, jank khi cuộn thư viện lớn, RAM khi load nhiều artwork (đã có giới hạn cache ở P05-09, cần xác nhận thực tế).
- [ ] *(cần thiết bị thật)* Kiểm tra `IndexedStack` ở shell home không giữ quá nhiều tab nặng sống cùng lúc (lazy tabs đã có, cần đo).
