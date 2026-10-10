# Muvik – Danh sách bug / chỉnh sửa cần fix

Ngày ghi: 2026-10-10 · Trạng thái: `[ ]` chưa làm, `[x]` xong

## Giao diện chung
- [ ] Giảm font chữ toàn app xuống 2px.
- [ ] Ẩn thanh công cụ (navigation bar) của máy ở dưới: vào app là immersive, không hiện thanh dưới.
- [ ] Bổ sung hiệu ứng điểm chạm (ripple/sáng lên khi bấm) cho mọi button, icon, option đang chưa có.
  - Dùng chung hiệu ứng đã có ở màn **Quét thư viện** cho tất cả, nhưng chỉnh tốc độ nhanh hơn một chút.
  - Các màn cần bổ sung rõ ràng: **Phát qua tai nghe**, **Chủ đề**, **Bộ chỉnh âm** (và các màn/option khác còn thiếu).

## Bộ chỉnh âm
- [ ] Thêm thanh **"Tăng âm lượng" (Loudness Boost)** để nghe to như TikTok: dùng `AndroidLoudnessEnhancer` của `just_audio`, thanh 0 → ~+10 dB trong `equalizer_panel.dart`, nối vào `audio_handler.dart`, lưu pref. Có cảnh báo méo tiếng/hại tai khi kéo cao; test mức an toàn trên SM G996B.

## Tab Khám phá
- [ ] Bỏ phần header có chữ "Melo, nhạc của bạn…" và logo bên phải.

## Màn Home
- [ ] Phần **Playlist dành cho bạn**: ảnh item trong list đang quá to, thu nhỏ lại.

## Màn Cài đặt
- [ ] Các option tăng thêm padding trên/dưới mỗi bên 2px (đang quá bé).
- [ ] Bổ sung **đăng nhập (authen) bằng Google**.

## Màn Phát nhạc
- [ ] Nút **thứ tự phát** và **lặp lại**: bỏ bottom sheet khi bấm. Bấm vào thì tự đổi chế độ và đổi icon luôn, không hiện bottom sheet.

## Màn Đánh giá app (Rate app)
- [ ] Thêm hiệu ứng khi mở: các ngôi sao sáng (active) lần lượt từng cái một, tối đa 5 sao.

## Bottom sheet Màu nhấn
- [ ] Bổ sung đủ thành **8 màu**, bố cục **2 hàng**.

---

### Ghi chú kỹ thuật (từ lần chạy máy thật)
- Chạy: `flutter run --flavor dev -d <device>` (flavor bắt buộc).
- Cần local (không commit): `android/debug_keystore.properties`, `android/app/google-services.json`.
- Đã sửa tương thích Flutter 3.47: `RepeatMode` hide import ở `now_playing_screen.dart`, `player_mode_sheets.dart`; import Cupertino ở `app_theme.dart`.

---

# Đề xuất cải tiến thêm (Claude rà soát 2026-10-10)

Cơ sở: `flutter analyze` (9 cảnh báo), quét code `lib/`, đối chiếu `Muvik_TODO_Implementation.md`.

## A. Ưu tiên cao – nên làm trước
- [ ] **QA trên máy thật cho các mục TODO đang "chờ QA"**: ~170 mục trong `Muvik_TODO_Implementation.md` (quét thư viện P05, onboarding/setup P06, audio handler P07, shell/navbar P08…) đều ghi "chờ QA, chưa có thiết bị". Giờ đã có SM G996B, nên chạy checklist rồi tick/ghi kết quả.
  - Ưu tiên test: nhạc nền khi tắt màn hình, notification/lockscreen, rút tai nghe, 2 tiếng nhạc/2 notification khi mở player liên tiếp (P07-17), thư viện nhiều nghìn bài, quyền bị thu hồi, SD tháo/lắp (P05-15).
- [ ] **Google login**: `google_sign_in` đã có trong `pubspec`; cần đối chiếu SHA-1 debug/release trong Firebase cho package đang dùng, vì `google-services.json` do bạn cung cấp. Lỗi `CredManProvService` trong log máy thật liên quan đến phần này, kiểm tra khi làm mục Google authen.
- [ ] **Build tự động chạy được trên máy mới**: hiện phải tự tạo `android/debug_keystore.properties` và `android/app/google-services.json` mới build được. Thêm file mẫu `debug_keystore.properties.example` và mô tả trong README, tránh người mới (hoặc CI) lỗi như lần chạy vừa rồi.
- [ ] **Kiểm tra bản release**: chưa build `--flavor product --release` thử (ký, proguard/R8, `just_audio`/`audio_service` có bị strip không). Nên test sớm trước khi lên store.

## B. Kỹ thuật / bảo trì
- [ ] **Nâng toolchain Android** (Flutter cảnh báo sắp bỏ hỗ trợ): Gradle 8.14 → ≥ 9.1, AGP 8.11.1 → ≥ 9.0.1, Kotlin 2.2.20 → ≥ 2.3.20. Gỡ luôn `dependency_overrides: permission_handler_android: 13.0.1` khi nâng xong (ghi chú trong `pubspec.yaml`).
- [ ] **Thay API deprecated**: `onReorder` → `onReorderItem` ở `queue_sheet.dart:141` và `playlist_detail_screen.dart:149` (lưu ý `onReorderItem` đã điều chỉnh sẵn `newIndex`, nên bỏ đoạn `if (newIndex > oldIndex) newIndex -= 1` nếu có).
- [ ] **`AudioDeviceType` là API experimental** (`audio_handler.dart:708-714`): bọc lại cho gọn, thêm `// ignore` có lý do hoặc fallback, theo dõi khi `just_audio` đổi API.
- [ ] **Dependency `dsp_base` pin `ref: main`**: dễ vỡ build khi upstream đổi. Nên pin commit/tag cụ thể (hiện chỉ khóa ở `pubspec.lock`).
- [ ] **Test**: có ~1200 dòng test cho DB/scan/queue/sleep timer/mood, nhưng chưa có test cho màn hình quan trọng (player, settings) và `audio_handler`. Thêm widget test cho player (đổi lặp lại/thứ tự phát) và golden/overflow cho chữ lớn sau khi giảm font 2px.
- [ ] Sau khi **giảm font 2px**: chạy lại `layout_overflow_test.dart` và thử cỡ chữ hệ thống lớn để chắc không tràn.

## C. UX / sản phẩm
- [ ] **Accessibility**: chỉ ~41 file có `Semantics`/`tooltip`. Thêm nhãn cho icon button (play, next, yêu thích, lặp lại, ngẫu nhiên…) cho TalkBack; vùng chạm tối thiểu 48dp (liên quan mục "điểm chạm").
- [ ] **Hiệu ứng chạm thống nhất**: hiện dùng lẫn `InkWell` (50 chỗ) và `GestureDetector` (6 chỗ, không có hiệu ứng). Làm một widget dùng chung (vd. `TapEffect`/`AppInkWell`) dựa trên hiệu ứng ở màn Quét thư viện rồi thay dần, thay vì sửa lẻ từng màn.
- [ ] **Màn Cài đặt dùng `ListView(children: …)` thường** (equalizer, headphones, permissions, playback quality, scan library…): với list ngắn thì ổn; chỉ cần đổi sang builder nếu list có thể dài.
- [ ] **Phản hồi khi đổi lặp lại/thứ tự phát** (sau khi bỏ bottom sheet): thêm toast/nhãn ngắn ("Lặp lại: một bài", "Phát ngẫu nhiên: bật") và haptic nhẹ, để người dùng biết đang ở chế độ nào.
- [ ] **Trạng thái trống/lỗi**: rà các màn 0 bài, mất quyền, file lỗi để có empty state có nút hành động (Quét lại, Mở cài đặt).
- [ ] **Đa ngôn ngữ**: có 15 locale (`xml_strings`); sau khi sửa text (vd. bỏ header Khám phá, thêm text mới) nhớ cập nhật đủ key ở các ngôn ngữ, tránh hiện key trần.
- [ ] **Widget màn hình khóa / Android Auto / Bluetooth metadata**: kiểm tra tên bài/ảnh bìa hiển thị đúng trên tai nghe Bluetooth và xe (nếu app hướng tới).
- [ ] **Equalizer / Chủ đề / Phát qua tai nghe**: ngoài điểm chạm, kiểm tra lưu trạng thái sau khi thoát app và áp dụng lại khi mở lại.

## D. Hiệu năng (nên đo trên máy thật)
- [ ] Mở Flutter DevTools (đã chạy được kết nối) đo: thời gian khởi động, jank khi cuộn thư viện lớn, RAM khi load nhiều artwork (đã có giới hạn cache ở P05-09, cần xác nhận thực tế).
- [ ] Kiểm tra `IndexedStack` ở shell home không giữ quá nhiều tab nặng sống cùng lúc (lazy tabs đã có, cần đo).
