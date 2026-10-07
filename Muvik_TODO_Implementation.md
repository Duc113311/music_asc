# Muvik — Checklist xây dựng app từ đầu đến hoàn thiện

**Phiên bản:** 1.0 • 07/10/2026  
**Nguồn:** `APP_BASE_STRUCTURE (1).md`, nghiệp vụ Muvik mục 1.3 và Design System đã thống nhất.  
**Cách dùng:** làm theo thứ tự; mỗi dòng là một việc. Chỉ đánh dấu `[x]` khi đã chạy và kiểm tra kết quả. Mỗi giai đoạn có điều kiện hoàn thành. Android là bản triển khai đầu tiên; iOS có checklist riêng cuối file.

## 0. Chốt phạm vi và nguyên tắc

- [ ] P00-01 Chốt tên hiển thị Muvik, tên project `muvik`, applicationId/bundleId thuộc đơn vị phát hành; không dùng ID mẫu.
- [ ] P00-02 Chốt 4 tab: Trang chủ, Thư viện, Khám phá, Cài đặt. Thống kê là màn riêng mở từ Khám phá.
- [ ] P00-03 Chốt luồng cài mới: Splash → 3 onboarding → 3 setup → Trang chủ; onboarding/setup không có navbar.
- [ ] P00-04 Chốt nghe nhạc local không cần tài khoản/mạng; Google login là tùy chọn trong Settings.
- [ ] P00-05 Chốt Settings gồm Tài khoản, Tiện ích, Âm thanh, Giao diện, Ứng dụng; không thêm lại nhóm Thư viện nhạc/Phát nhạc.
- [ ] P00-06 Lập bảng đối chiếu key Figma → file Dart → route/overlay → trạng thái → checklist; giữ nguyên key nguồn dù có lỗi chính tả.
- [ ] P00-07 Kiểm kê thư mục `screen_new`, `image_su_dung`; ghi màn/asset thiếu trước khi code, không giả định đã được đính kèm đầy đủ.
- [ ] P00-08 Chốt phạm vi bản đầu: không AI, Health, cloud sync, widget màn hình chính, IAP hoặc ads nếu chưa có yêu cầu riêng.
- [ ] P00-09 Chốt EN là fallback, VI là ngôn ngữ đầu tiên cùng EN; thiết kế hỗ trợ global và thêm locale về sau.
- [ ] P00-10 Ghi rõ giới hạn: khóa màn hình vẫn nghe được; tắt nguồn/force-stop không thể cam kết tiếp tục phát.

**Hoàn thành khi:** phạm vi thống nhất với bảng 1.3, không có màn/tính năng tự thêm ngoài danh sách.

## 1. Tạo project và môi trường

- [ ] P01-01 Kiểm tra Flutter/Dart, Android SDK, JDK và thiết bị bằng `flutter doctor -v`; xử lý lỗi trước khi tạo app.
- [ ] P01-02 Tạo app bằng `flutter create --org <domain_nguoc_cua_don_vi> --platforms=android,ios muvik` hoặc chỉ Android nếu chưa làm iOS.
- [ ] P01-03 Khởi tạo Git, `.gitignore`, README và nhánh phát triển; không commit keystore, mật khẩu hoặc dữ liệu tài khoản.
- [ ] P01-04 Đổi tên hiển thị, namespace/applicationId và bundleId; kiểm tra không còn import/tên WaterNudge.
- [ ] P01-05 Chạy project trắng trên điện thoại thật; xác nhận mở được app và hot reload hoạt động.
- [ ] P01-06 Thêm `dsp_base` bằng local path đúng như mẫu; xác nhận có mã nguồn và phiên bản tương thích.
- [ ] P01-07 Kiểm tra `CommApp`, `commRunApp`, `AppText`, `AppBox`, `CommLocalize`; nếu thiếu package, ghi rõ phương án adapter tương đương, không import đường dẫn giả.
- [ ] P01-08 Thêm GetX, sqflite, SharedPreferences, intl, flutter_svg, fl_chart và các dependency cần thiết; kiểm tra API hiện tại, commit lockfile.
- [ ] P01-09 Chọn một engine audio duy nhất sau thử nghiệm phát local/background/media controls; dùng audio handler chung, không tạo engine thứ hai cho notification.
- [ ] P01-10 Kiểm tra khả năng scan MediaStore/SAF, URI audio, metadata và EQ; chọn plugin hoặc native channel dựa trên thử nghiệm thực tế.
- [ ] P01-11 Thêm package/adapter mở URL/email, thông tin phiên bản, đánh giá app; Firebase Auth/Google chỉ thêm cho login.
- [ ] P01-12 Loại bỏ dependency nghiệp vụ uống nước, Health, AI gateway, chat quota, Firestore nếu không dùng.
- [ ] P01-13 Bật flutter_lints; chạy `flutter pub get`, `flutter analyze`; sửa lỗi của project nền.

**Hoàn thành khi:** app trắng build được và thử nghiệm audio/URI/background chứng minh stack khả thi trước khi dựng toàn bộ UI.

## 2. Dựng cấu trúc thư mục theo file mẫu

Giữ tên tầng như mẫu: `controller/` số ít, `repository/`, `services/application/`, `services/native/`, `presentation/`. Không chuyển sang cấu trúc khác giữa chừng.

```text
lib/
  main.dart
  configs/             pref_const.dart, pref_defaults.dart, app_config.dart
  values/              route_name.dart, app_pages.dart, app_theme.dart,
                       app_colors.dart, app_typography.dart, app_dimensions.dart,
                       onboarding_theme.dart
  models/
    data_models/       song.dart, music_source.dart, playlist.dart,
                       playlist_song.dart, playback_session.dart,
                       listening_segment.dart, daily_summary.dart,
                       playback_snapshot.dart, excluded_item.dart
    ui_models/         repeat_mode.dart, shuffle_mode.dart, scan_state.dart,
                       period_type.dart, audio_preset.dart, app_error.dart
  controller/          settings_controller.dart, library_controller.dart,
                       playback_controller.dart, auth_controller.dart,
                       onboarding_controller.dart, setup_controller.dart,
                       search_controller.dart, playlist_detail_controller.dart,
                       statistics_controller.dart, feedback_controller.dart
  repository/          song_repository.dart, source_repository.dart,
                       playlist_repository.dart, listening_repository.dart,
                       playback_repository.dart, exclusion_repository.dart
  services/
    storage/           database_helper.dart, schema.dart
    application/       bootstrap_service.dart, library_scan_service.dart,
                       library_data_service.dart, playlist_service.dart,
                       playback_service.dart, audio_handler.dart,
                       listening_stats_service.dart, sleep_timer_service.dart,
                       equalizer_service.dart, auth_service.dart
    native/            media_library_channel.dart, audio_effects_channel.dart
    feedback_service.dart
  utils/               date_utils.dart, duration_formatter.dart,
                       metadata_fallback.dart, toast_utils.dart,
                       loading_utils.dart, language_names.dart
  presentation/
    common_components/
    screen_splash/
    screens_onboarding/
    screens_setup/
    screen_home/       Shell IndexedStack và navbar
    screen_dashboard/ Tab Trang chủ
    screen_library/
    screen_explore/
    screen_player/
    screen_statistics/
    screen_search/
    screens_playlist/
    screens_settings/
    bottom_sheets/
    dialogs/
  xml_strings/         values/strings.xml, values-vi/strings.xml
assets/
  images/png/
  images/webp/
  images/svg/
  fonts/
test/
integration_test/
```

Tên file trên là cấu trúc triển khai đề xuất, không phải mã nguồn đã tồn tại. Album/nghệ sĩ có thể suy ra từ song trước; không buộc thêm bảng riêng. Native media service do plugin quản lý nếu chọn plugin đủ chức năng.

- [ ] P02-01 Tạo các thư mục và file nền theo cây trên; chưa cần tạo file rỗng cho tính năng chưa triển khai.
- [ ] P02-02 Tạo `PrefConst` và `PrefDefaults`; mọi pref đều có key/default tập trung.
- [ ] P02-03 Khai báo onboardingCompleted, setupCompleted, setupStep, themeMode, accentColor, language, repeatMode, shuffleMode, EQ và headphone settings.
- [ ] P02-04 Dùng SQLite cho queue/snapshot/dữ liệu nhiều dòng; không nhét toàn thư viện vào preferences.
- [ ] P02-05 Tạo RouteName/AppPages và bindings; không dùng route literal trong widget/controller.
- [ ] P02-06 Đăng ký Settings/Library/Playback permanent; Auth chỉ khi bật login; Search/Stats/Form/Setup route-scoped.
- [ ] P02-07 Đặt engine audio trong service/handler độc lập vòng đời màn; controller chỉ quan sát và gửi lệnh.
- [ ] P02-08 Dispose workers, stream subscriptions, timers và lifecycle observer đúng scope; không dispose player khi Back.
- [ ] P02-09 Viết lỗi có code/type; repository rethrow, service quyết định nghiệp vụ, controller đổi trạng thái UI.
- [ ] P02-10 Giữ business logic khỏi common components; repository chỉ CRUD/query, service điều phối transaction.

**Hoàn thành khi:** mỗi tầng có trách nhiệm rõ, route hoạt động và đổi màn không tạo bản sao controller/player.

## 3. Design System và tài nguyên

- [ ] P03-01 Nhập toàn bộ token dark/light từ `Muvik_Design_System.docx` vào AppColors/ThemeExtension.
- [ ] P03-02 Tạo AppTheme.light/dark và ThemeMode.system; bỏ cấu hình pin cả hai theme thành dark của mẫu.
- [ ] P03-03 Đăng ký font Be Vietnam Pro 400/500/600/700; fallback hệ thống cho ngôn ngữ chưa hỗ trợ.
- [ ] P03-04 Tạo typography, spacing, radius, icon sizes và motion constants; không rải số/màu ở từng màn.
- [ ] P03-05 Chuẩn hóa asset tên ASCII snake_case; ánh xạ asset → màn; giữ bản gốc ngoài bundle nếu quá nặng.
- [ ] P03-06 Thêm logo không chữ, splash, ba onboarding, ba setup, ảnh fallback và background đúng theme.
- [ ] P03-07 Nén ảnh phù hợp, kiểm tra PNG alpha và kích thước; không đóng gói nhạc minh họa vào thư viện thật.
- [ ] P03-08 Khai báo assets/fonts/XML locale trong pubspec; kiểm tra đường dẫn và chữ hoa/thường.
- [ ] P03-09 Tạo PrimaryButton với normal/pressed/disabled/loading và chống bấm lặp.
- [ ] P03-10 Tạo AppIconButton/Touchable vùng chạm tối thiểu 48 × 48.
- [ ] P03-11 Tạo Input/SearchField/TextArea với focus, error, disabled và keyboard safe area.
- [ ] P03-12 Tạo radio/checkbox/switch, chip và segmented tabs; nhãn đọc được bằng screen reader.
- [ ] P03-13 Tạo SongTile, PlaylistCard, AlbumCard, SettingsTile, EmptyState, ErrorState, LoadingState.
- [ ] P03-14 Tạo PrimaryBottomSheet/PrimaryDialog/Toast; toast không che mini player/navbar.
- [ ] P03-15 Tạo MiniPlayer dùng stream của player chung; chiều cao có thể tăng theo font.
- [ ] P03-16 Tạo XML strings EN/VI cho toàn bộ label, lỗi, toast và dialog; không hardcode nội dung UI.
- [ ] P03-17 Làm trang preview component trong debug; xem đủ dark/light và chữ lớn trước khi dựng màn.

**Hoàn thành khi:** component tái sử dụng hiển thị đúng hai theme, asset không lỗi và UI không có mã màu rời rạc.

## 4. Database và dữ liệu local

- [ ] P04-01 Tạo DatabaseHelper singleton có Completer chống mở DB đồng thời; tên `muvik.db`, schema khởi đầu version 1.
- [ ] P04-02 Tạo bảng songs: ID ổn định, source ID, URI/media ID, metadata, duration, size, artwork reference, availability và favorite.
- [ ] P04-03 Tạo music_sources: URI/source type/display name, enabled, quyền truy cập và trạng thái scan.
- [ ] P04-04 Tạo playlists và playlist_songs; unique playlist + song, lưu thứ tự; xóa playlist không xóa song/file.
- [ ] P04-05 Tạo excluded_items để lưu bài/nguồn đã bỏ khỏi thư viện, không thêm lại khi scan.
- [ ] P04-06 Tạo playback snapshot và queue entries với entry ID riêng; hỗ trợ cùng một bài xuất hiện nhiều lần trong queue.
- [ ] P04-07 Tạo playback_sessions và listening_segments; session lưu lượt, segment lưu thời gian nghe theo ngày.
- [ ] P04-08 Tạo daily_summary làm cache aggregate có thể rebuild; không cộng distinct song theo ngày để ra distinct cả tháng.
- [ ] P04-09 Thêm index/unique cho identity nguồn + media, playlist_song, session/segment date_key.
- [ ] P04-10 Lưu timestamp UTC, date_key YYYY-MM-DD và offset/múi giờ tại thời điểm segment; chốt quy tắc kỳ local.
- [ ] P04-11 Viết model immutable với toMap/fromMap/copyWith, enum mapping và fallback metadata.
- [ ] P04-12 Viết CRUD/query repository với whereArgs; transaction do application service điều phối.
- [ ] P04-13 Cho repository nhận transaction executor khi cần; không dùng DB ngoài transaction trong cùng nghiệp vụ.
- [ ] P04-14 Viết migration tăng version, bảo toàn dữ liệu; không dùng DROP/reset để sửa schema của bản đã phát hành.
- [ ] P04-15 Thêm fixture debug riêng; release không hiện bài hát/dữ liệu thống kê giả.
- [ ] P04-16 Kiểm tra transaction thêm playlist và flush session; lỗi giữa chừng không lưu nửa dữ liệu.

**Hoàn thành khi:** dữ liệu giữ nguyên sau restart, không trùng identity, migration không làm mất playlist/lịch sử.

## 5. Quyền truy cập và quét nhạc

- [ ] P05-01 Triển khai MediaLibraryChannel/adapter: quyền audio, chọn nguồn, liệt kê tệp, đọc metadata/artwork.
- [ ] P05-02 Phân biệt MediaStore và SAF; kiểm tra quyền theo phiên bản Android/API được hỗ trợ, không xin quyền rộng không cần thiết.
- [ ] P05-03 Với SAF, lưu persistable URI permission khi hệ thống cho phép; không biến content URI thành đường dẫn giả.
- [ ] P05-04 Chọn tất cả chỉ áp dụng nguồn đã được cấp quyền; không hiểu là toàn bộ bộ nhớ không được phép.
- [ ] P05-05 Tạo scan state idle/scanning/success/partial/error/cancelled và stream tiến độ/số tệp.
- [ ] P05-06 Chống scan đồng thời; thao tác quét lại đang chạy hiển thị trạng thái hiện tại.
- [ ] P05-07 Quét theo batch ngoài UI thread; upsert theo stable identity, tránh trùng giữa các nguồn chồng nhau.
- [ ] P05-08 Đọc tên bài/nghệ sĩ/album/duration/size/artwork; thiếu title dùng tên file, thiếu artist/album dùng nhãn fallback.
- [ ] P05-09 Bỏ tệp không đọc được/không hỗ trợ có báo cáo; giới hạn artwork cache để tránh hết RAM.
- [ ] P05-10 Chỉ đánh dấu tệp mất sau scan thành công đầy đủ của nguồn đó; scan lỗi/hủy/thu hồi quyền không xóa hàng loạt.
- [ ] P05-11 Giữ favorite, playlist và history khi refresh metadata; bài unavailable vẫn có tham chiếu hợp lý.
- [ ] P05-12 Áp dụng exclusion trước khi upsert vào thư viện hiển thị; không tự thêm lại bài người dùng đã bỏ.
- [ ] P05-13 Khi hủy scan, giữ dữ liệu hợp lệ đã có và báo kết quả chưa hoàn tất; không ghi setup thành công giả.
- [ ] P05-14 Khi app resume, kiểm tra nguồn/quyền và refresh nhẹ; không tự chạy full scan mỗi lần đổi tab.
- [ ] P05-15 Kiểm tra 0 bài, nhiều nghìn bài, tên Unicode, thẻ SD tháo/lắp, nguồn trùng và quyền bị thu hồi.

**Hoàn thành khi:** scan lại không trùng, mất nguồn không làm mất dữ liệu và content URI phát được trên máy thật.

## 6. Bootstrap Splash Onboarding và Setup

- [ ] P06-01 Khởi tạo prefs/DB/theme/locale/audio theo thứ tự; auth lỗi không chặn bootstrap nghe local.
- [ ] P06-02 Splash `sc_splash`: logo đúng UI, loading hữu hạn và lỗi khởi tạo có Thử lại; không polling vô hạn.
- [ ] P06-03 Định tuyến: chưa onboarding → onboarding; đã onboarding/chưa setup → setup; đã hoàn tất → shell.
- [ ] P06-04 Tạo `sc_onBrg_01` với hình, tiêu đề, mô tả, dots, Bỏ qua/Tiếp tục.
- [ ] P06-05 Tạo `sc_onBrg_02` với Quay lại/Tiếp tục và giữ chỉ số trang.
- [ ] P06-06 Tạo `sc_onBrg_03` với Bắt đầu; không có navbar.
- [ ] P06-07 Bỏ qua hoặc kết thúc onboarding đều lưu onboardingCompleted rồi mở setup, không bỏ qua quyền/nguồn.
- [ ] P06-08 Setup controller tồn tại đủ ba bước, lưu tiến độ cần khôi phục khi app bị đóng.
- [ ] P06-09 `sc_step_01`: Cho phép → yêu cầu quyền/system picker; cấp thành công → bước 2.
- [ ] P06-10 Xử lý từ chối: Thử lại/Để sau; không hỏi lại được thì Mở cài đặt; không ép user login.
- [ ] P06-11 `sc_step_02`: danh sách nguồn, chọn từng/chọn tất cả, Quét nhạc; chưa chọn thì disable CTA.
- [ ] P06-12 Hiển thị scan progress/loading/error/cancel; thành công hoặc kết quả partial đã xác nhận → bước 3.
- [ ] P06-13 `sc_step_03`: tổng bài/album/nghệ sĩ/thư mục, Bắt đầu nghe; không tự phát.
- [ ] P06-14 Kết quả 0 bài có Chọn lại thư mục/Quét lại/Vào ứng dụng; từ chối quyền vẫn có đường vào app trống.
- [ ] P06-15 Ghi setupCompleted khi hoàn tất hoặc chủ động vào app; dùng offAll để Back không quay về wizard.
- [ ] P06-16 Kiểm tra reinstall, restart từng bước, cấp quyền rồi restart và quay lại từ system settings.

**Hoàn thành khi:** đủ 1 splash + 3 onboarding + 3 setup, không navbar, luôn có đường tiếp tục hợp lệ.

## 7. Playback engine và hàng chờ

Làm phần này trước khi nối UI player. Mọi nguồn lệnh đều đi vào cùng PlaybackService/AudioHandler.

- [ ] P07-01 Triển khai một audio handler phục vụ UI, background, notification, lockscreen và tai nghe.
- [ ] P07-02 Tạo state currentSong/queue/currentEntry/position/duration/playing/processing/repeat/shuffle.
- [ ] P07-03 Tạo lệnh loadQueue/play/pause/seek/next/previous/stop và stream trạng thái chung.
- [ ] P07-04 Khi bấm bài trong danh sách, snapshot danh sách tại thời điểm bấm và chọn entry đúng; đổi filter không tự đổi queue.
- [ ] P07-05 Nối URI/file source thực tế; loading hiển thị rõ, lệnh tới liên tục được tuần tự hóa/hủy stale request.
- [ ] P07-06 Seek clamp 0..duration; preview khi kéo, thả mới seek; duration chưa biết thì khóa tua.
- [ ] P07-07 Previous: >3 giây về đầu; ≤3 giây về bài trước; xử lý entry đầu theo repeat mode.
- [ ] P07-08 Repeat off/all/one; Next chủ động vẫn chuyển bài, repeat-one chỉ áp dụng khi bài kết thúc tự nhiên.
- [ ] P07-09 Shuffle giữ current entry, tạo thứ tự phần chờ và history để Previous hợp lý; tắt shuffle khôi phục thứ tự xác định.
- [ ] P07-10 Add next/add end/reorder/remove queue dùng entry ID, không dùng song ID duy nhất để thao tác vị trí.
- [ ] P07-11 Xóa phần chờ giữ current entry; reorder không ngắt bài đang phát.
- [ ] P07-12 Bài lỗi/unavailable báo lỗi ngắn và chuyển bài phù hợp; queue toàn lỗi dừng sau số lần thử hữu hạn.
- [ ] P07-13 Queue hết và repeat off → dừng tự nhiên; UI không hiển thị đang phát giả.
- [ ] P07-14 Lưu snapshot định kỳ có throttle và khi pause/stop/lifecycle; restore ở trạng thái paused, không tự phát khi mở app.
- [ ] P07-15 Phân biệt Pause/Stop/Back: Pause giữ phiên/vị trí; Stop kết thúc phiên và lưu; Back chỉ đóng màn.
- [ ] P07-16 Khi bài current bị bỏ khỏi thư viện, giữ file gốc; xác định dừng/chuyển bài và cập nhật mọi UI đồng bộ.
- [ ] P07-17 Kiểm tra mở player liên tiếp/đổi tab không tạo hai tiếng nhạc hoặc hai notification.

**Hoàn thành khi:** có thể phát local từ service và thao tác queue/repeat/shuffle đúng trước khi hoàn thiện giao diện.

## 8. Shell và Trang chủ

- [ ] P08-01 `screen_home` làm shell IndexedStack + lazy tabs, navbar `sc_navibar`; giữ state/scroll khi đổi tab.
- [ ] P08-02 Dành vùng an toàn cho navbar và mini player; phần cuối danh sách không bị che.
- [ ] P08-03 Mini player chỉ hiện khi có current song; ảnh/title/position/play/pause/next đồng bộ player.
- [ ] P08-04 Bấm mini player → `Sc_phat_nhac`; Back về đúng tab nguồn.
- [ ] P08-05 `sc_home`: lời chào theo sáng/trưa/chiều/tối, cập nhật khi resume/qua mốc giờ.
- [ ] P08-06 Khối Nhạc của bạn hiển thị current/restored song; Tiếp tục nghe gửi play trên queue hiện tại.
- [ ] P08-07 Khi chưa từng nghe, khối trên hiện gợi ý chọn nhạc; không gắn bài minh họa giả.
- [ ] P08-08 Playlist dành cho bạn dùng playlist local/quy tắc local; card → chi tiết, play → queue snapshot.
- [ ] P08-09 Nghe gần đây lấy session thật, menu bài dùng sheet chung; Xem tất cả → danh sách local.
- [ ] P08-10 Search/icon/menu có action thật; thêm empty/loading/error và refresh khi thư viện thay đổi.

**Hoàn thành khi:** Home dùng dữ liệu thật, resume đúng bài/vị trí và không mất state khi đổi tab.

## 9. Thư viện Search và chi tiết danh sách

- [ ] P09-01 Dựng tab Thư viện với Bài hát/Album/Nghệ sĩ/Thư mục và số lượng thực từ DB.
- [ ] P09-02 Bài hát → danh sách đầy đủ; chọn hàng → queue đúng danh sách; overflow → action sheet.
- [ ] P09-03 Album → lưới/danh sách → album detail; hiển thị nghệ sĩ/tổng bài và Play/Shuffle.
- [ ] P09-04 Nghệ sĩ → artist detail với bài/album liên quan, không gom mọi unknown thành nghệ sĩ có thật.
- [ ] P09-05 Thư mục → danh sách nguồn → folder detail; trạng thái mất quyền/unavailable rõ ràng.
- [ ] P09-06 Sort A–Z/Z–A/mới thêm/thời lượng theo lựa chọn đã chốt; lưu sort và có tie-break ổn định.
- [ ] P09-07 Tạo search route-scoped, debounce và chống kết quả request cũ ghi đè request mới.
- [ ] P09-08 Search local theo bài/nghệ sĩ/album/playlist; chuẩn hóa hoa thường và tìm tiếng Việt không dấu.
- [ ] P09-09 Search có clear, loading, không kết quả, hủy/back và focus keyboard hợp lý.
- [ ] P09-10 Tối ưu list lazy loading/query phân trang; không decode artwork lớn cho mọi hàng cùng lúc.
- [ ] P09-11 Các màn danh sách đều có mini player khi có bài, safe area và trạng thái trống/lỗi.

**Hoàn thành khi:** mọi card/icon Thư viện có đích đến và query/sort đúng dữ liệu local.

## 10. Playlist và Yêu thích

- [ ] P10-01 Tạo form playlist: tên trim, không rỗng, giới hạn chiều dài rõ; chọn cover hoặc fallback.
- [ ] P10-02 Bấm Tạo playlist từ Thư viện → form → lưu → detail mới, cập nhật list.
- [ ] P10-03 Thêm một/nhiều bài → chọn playlist hoặc tạo mới; unique playlist + song, bài trùng báo rõ.
- [ ] P10-04 Playlist detail: cover/title/count/duration, Play/Shuffle, danh sách và menu.
- [ ] P10-05 Sửa tên/cover/reorder bài; lưu transaction, Back có thay đổi mở Bỏ thay đổi.
- [ ] P10-06 Bỏ bài khỏi playlist chỉ xóa membership; không xóa file/thư viện.
- [ ] P10-07 Xóa playlist có confirm; không xóa file và không phá queue snapshot đang nghe.
- [ ] P10-08 Yêu thích là danh sách hệ thống dựa trên favorite; thêm/bỏ cập nhật Home/Library/Player đồng thời.
- [ ] P10-09 Playlist chứa bài unavailable vẫn hiện trạng thái; play bỏ qua hợp lý, không crash.
- [ ] P10-10 Kiểm tra tên dài/emoji, 0 bài, thêm trùng, restart và scan lại giữ nguyên playlist.

**Hoàn thành khi:** tạo → thêm → phát → sửa → xóa hoạt động hoàn chỉnh và file gốc an toàn.

## 11. Khám phá

- [ ] P11-01 `sc_kham_pha`: hiển thị album/playlist/bài từ thư viện thiết bị, không gọi nhạc online.
- [ ] P11-02 Gợi ý Nghe lại/Ít nghe/Ngẫu nhiên dựa trên history thật và rule local đơn giản.
- [ ] P11-03 Card gợi ý → danh sách chi tiết; play tạo queue snapshot từ tập kết quả.
- [ ] P11-04 Mood/filter nếu có UI phải có quy tắc local rõ; không suy đoán AI nếu chưa có dữ liệu/tag.
- [ ] P11-05 Gần đây thêm vào dùng thời điểm phát hiện/tệp phù hợp, không reset mọi bài thành mới sau scan lại.
- [ ] P11-06 Nút Thống kê → màn thống kê, không tạo tab thứ năm.
- [ ] P11-07 Search dùng màn chung; dữ liệu trống có CTA Quét nhạc/Chọn nguồn.

**Hoàn thành khi:** toàn bộ khám phá dùng local và mọi vùng bấm có luồng thật.

## 12. Màn Đang phát và bottom sheets

- [ ] P12-01 `Sc_phat_nhac`: header/back/queue, ảnh bìa, title/artist, progress, duration và controls đúng UI.
- [ ] P12-02 Play/Pause/Next/Previous/seek gửi lệnh chung; thể hiện loading/error/current state.
- [ ] P12-03 Shuffle → sheet Theo thứ tự/Ngẫu nhiên, áp dụng và đổi icon ngay.
- [ ] P12-04 Repeat → sheet Tắt/Lặp tất cả/Lặp một bài, áp dụng ngay.
- [ ] P12-05 Favorite → sheet Thêm vào/Bỏ Yêu thích; không chỉ đổi tim mà không lưu DB.
- [ ] P12-06 `Sc_bthSheet_phattiep`: current song, upcoming list, chọn bài, drag reorder, remove entry.
- [ ] P12-07 Xóa phần chờ → `Sc_delete_danh_sach_cho`; xác nhận giữ current song.
- [ ] P12-08 Thêm vào playlist → sheet chọn playlist; Tạo mới → form chung → thêm thành công.
- [ ] P12-09 EQ → sheet cùng dữ liệu Settings; Chi tiết → `sc_bo_chinh_am`.
- [ ] P12-10 Hẹn giờ → `Sc_bthsheet_hen_gio_tat`; chọn mốc/bắt đầu/hủy; Tùy chỉnh → full screen.
- [ ] P12-11 Menu Dừng phát → `Sc_dung_phat_nhac`; Back/Pause không mở dialog này.
- [ ] P12-12 Nếu UI có lời bài hát: sheet TXT/LRC local, Chọn file lời, parser/timing và empty state; không tải mạng.
- [ ] P12-13 Sheet dismiss không tự áp dụng bản nháp; thao tác áp dụng ngay phải phản ánh trạng thái thật.
- [ ] P12-14 Kiểm tra các option dưới player đúng vị trí, không mất nhãn khi font lớn và không bị navigation gesture che.

**Hoàn thành khi:** tất cả option đã chốt có sheet/đích đến và đồng bộ với mini player.

## 13. Hẹn giờ tắt nhạc

- [ ] P13-01 `sc_hen_gio_tat`: 15/30/45/60 phút, tùy chỉnh giờ/phút, đợi hết bài, dự kiến giờ dừng và CTA.
- [ ] P13-02 Validate thời lượng >0 và giới hạn hợp lý; không cho bắt đầu với giá trị rỗng/sai.
- [ ] P13-03 SleepTimerService thuộc audio/background service, không đặt timer chỉ trong widget/controller route.
- [ ] P13-04 Lưu deadline và tùy chọn, tính countdown từ deadline; không chỉ trừ mỗi giây dựa trên UI tick.
- [ ] P13-05 Đến hạn dừng hoặc đánh dấu stop-at-track-end; đợi hết bài chỉ chờ current entry tại hạn, không repeat vô hạn.
- [ ] P13-06 Timer ưu tiên hơn repeat/autoplay; pause không tự kéo dài deadline.
- [ ] P13-07 Sửa/hủy timer thay thế timer cũ, cập nhật Settings/sheet/player thống nhất.
- [ ] P13-08 Restore deadline nếu service còn phiên hợp lệ; deadline hết hạn phải xử lý ngay, không khởi động lại thời lượng cũ.
- [ ] P13-09 Kiểm tra background/khóa máy/đổi giờ máy/next khi đang chờ hết bài; ghi quy tắc xử lý rõ.

**Hoàn thành khi:** timer hoạt động khi khóa màn hình và không bị repeat vượt qua.

## 14. Settings và các màn con

- [ ] P14-01 `sc_cat_dat`: đủ nhóm theo 1.3 và khu vực Google login; dữ liệu giá trị hiện tại đúng prefs/service.
- [ ] P14-02 Tiện ích → Quét nhạc `sc_quet_thu_vien`: nguồn chọn, scan progress, tổng bài/album/nghệ sĩ và kết quả lỗi.
- [ ] P14-03 Thêm/chọn/bỏ nguồn qua picker phù hợp; scan lại dùng service chung, không xóa file.
- [ ] P14-04 Tiện ích → Hẹn giờ mở màn P13 và hiển thị giá trị đang chạy ở Settings.
- [ ] P14-05 Âm thanh → EQ `sc_bo_chinh_am`: enable/preset/sliders/bass/surround theo capability thiết bị.
- [ ] P14-06 AudioEffectsChannel/adapter dùng audio session thực; UI điều chỉnh tạo tác động thật, không chỉ lưu số.
- [ ] P14-07 EQ áp dụng lại khi đổi audio session/bài; preset tùy chỉnh đồng bộ sheet và full screen.
- [ ] P14-08 Thiết bị không hỗ trợ hiệu ứng nào thì disable có lý do; không hứa hỗ trợ giả.
- [ ] P14-09 Đặt lại EQ → `Sc_dat_lai_bo_chinh_am`; reset thông số mặc định đã định nghĩa và áp dụng thật.
- [ ] P14-10 `sc_chat_luong_phat`: format/bitrate/sample rate của file nếu đọc được; unknown có fallback; không giả nâng chất lượng.
- [ ] P14-11 `sc_phat_qua_tai_nghe`: các option đúng ảnh UI, ngắt tai nghe pause; tự tiếp tục khi kết nối lại chỉ khi người dùng bật.
- [ ] P14-12 Giao diện → `sc_theme`: Sáng/Tối/Hệ thống; lưu và đổi ngay, không restart player.
- [ ] P14-13 Màu nhấn → sheet preview/chọn/áp dụng; đảm bảo onPrimary tương phản theo màu chọn.
- [ ] P14-14 Quyền truy cập → trạng thái thực + Mở cài đặt; quay lại cập nhật và hướng dẫn chọn nguồn nếu cần.
- [ ] P14-15 Giới thiệu → tên/phiên bản/build, chính sách, hỗ trợ và điểm mở Feedback.
- [ ] P14-16 Feedback `sc_feedback`: loại phản hồi nếu có, nội dung, email tùy chọn, validate và mở email composer.
- [ ] P14-17 Gửi đến `contact.support@asctechsoft.com`; compose kèm phiên bản/thiết bị tối thiểu, không tự đính kèm thư viện nhạc.
- [ ] P14-18 Nếu không có email app: thông báo + sao chép địa chỉ; không báo Đã gửi khi chỉ mở composer.
- [ ] P14-19 Rate dialog `sc_rate_app`: sao, Đánh giá/Để sau/đóng; mọi số sao đều được mở store, không chặn đánh giá thấp.
- [ ] P14-20 Lưu thời điểm nhắc rate/cooldown; chỉ lưu đã mở yêu cầu, không giả biết user đã đánh giá thành công.

**Hoàn thành khi:** mỗi hàng Settings dẫn tới chức năng thật; EQ và chất lượng phản ánh khả năng/file thực.

## 15. Google login tùy chọn

- [ ] P15-01 Thiết lập Firebase project/config riêng cho Muvik nếu dùng Firebase Auth; cấu hình signing/OAuth đúng bản debug/release.
- [ ] P15-02 AuthService xử lý Google/Firebase, AuthController quan sát trạng thái; không đăng nhập anonymous chỉ để nghe nhạc.
- [ ] P15-03 Settings → Google login screen/flow đúng UI, loading chống double tap và cho hủy.
- [ ] P15-04 Thành công hiện tên/email/avatar; ảnh mạng lỗi có avatar fallback.
- [ ] P15-05 Phân biệt user hủy, mất mạng, cấu hình sai và provider lỗi; thông báo dễ hiểu, không in token ra log.
- [ ] P15-06 Đăng xuất có xác nhận, giữ toàn bộ local playlist/history/settings và tiếp tục nghe.
- [ ] P15-07 Bootstrap/auth timeout không chặn app offline; session hết hạn không khóa thư viện.
- [ ] P15-08 Không thêm sync/backup nhạc vào login; nếu bổ sung sau phải có scope và consent riêng.
- [ ] P15-09 Kiểm tra login/logout offline, đổi tài khoản và restart với tài khoản cũ.

**Hoàn thành khi:** login có ích cho danh tính, hoàn toàn độc lập nghiệp vụ nghe local.

## 16. Thống kê và ba dialog lịch

- [ ] P16-01 ListeningStatsService quan sát engine playing + ready; chỉ ghi elapsed nghe thật, không dựa vào position delta khi tua.
- [ ] P16-02 Đếm lượt khi nghe ≥30 giây hoặc hết tự nhiên bài ngắn hơn; một session chỉ qualifying một lần.
- [ ] P16-03 Pause/resume không tạo lượt mới; replay/auto repeat tạo session mới theo quy tắc; chống callback duplicate.
- [ ] P16-04 Tách segment khi qua ngày theo local timezone; một session có thể có nhiều segment nhưng lượt chỉ ghi một lần.
- [ ] P16-05 Flush theo checkpoint/throttle và tại pause/stop/end; hỗ trợ recovery không cộng trùng và giới hạn mất dữ liệu khi process crash.
- [ ] P16-06 Background/lockscreen được tính; pause/buffering/tua không cộng thời gian nghe.
- [ ] P16-07 Query tổng thời gian, lượt, distinct song, top song/artist và chuỗi chart từ dữ liệu thật.
- [ ] P16-08 Dữ liệu 0 có empty state; comparison kỳ trước 0 không chia cho 0 hoặc hiện % vô nghĩa.
- [ ] P16-09 `Sc_thong_ke_tuan`: 7 ngày Thứ hai–Chủ nhật, tổng số/top list đúng khoảng [start,end).
- [ ] P16-10 `Sc_thong_ke_thang`: ngày 1–cuối tháng, đúng tháng 28/29/30/31 ngày.
- [ ] P16-11 `Sc_thong_ke_nam`: 12 tháng, aggregate chính xác, top list theo năm.
- [ ] P16-12 Chạm cột chart → giá trị/ngày/tháng; chọn card/top bài → danh sách tương ứng, không để button vô tác dụng.
- [ ] P16-13 `Sc_dialog_tuan`: calendar, chạm ngày chọn cả tuần, mũi tên đổi tháng; Áp dụng/Hủy.
- [ ] P16-14 `sc_dialog_thang`: 12 tháng, mũi tên đổi năm, highlight tháng; Áp dụng/Hủy.
- [ ] P16-15 `Sc_dialoh_nam`: grid năm, chuyển nhóm năm, highlight năm; Áp dụng/Hủy.
- [ ] P16-16 Dialog dùng draft period; Hủy không đổi kỳ cũ; áp dụng mới query và cập nhật label.
- [ ] P16-17 Disable kỳ tương lai nếu chưa có dữ liệu; quy tắc kỳ hiện tại đến thời điểm hiện tại nhất quán.
- [ ] P16-18 Đổi Tuần/Tháng/Năm giữ anchor date rồi tính kỳ tương ứng; back/forward đi đúng độ dài kỳ.
- [ ] P16-19 Kiểm tra năm nhuận, tuần qua năm, múi giờ đổi, nghe qua nửa đêm và cùng bài nghe nhiều ngày.

**Hoàn thành khi:** chart/card/list/dialog khớp dữ liệu, không nhân đôi lượt và không cộng thời gian tua/pause.

## 17. Notification màn khóa và tai nghe

- [ ] P17-01 Cấu hình background audio/media session và foreground media service theo stack/API Android hiện tại.
- [ ] P17-02 Khai báo manifest/service/permissions cần cho media playback; kiểm tra quy tắc notification theo Android version, không sao chép alarm uống nước.
- [ ] P17-03 `Sc_noti_01`: thông báo media thu gọn metadata/cover/action hệ điều hành hỗ trợ.
- [ ] P17-04 `Sc_noti_02`: mở rộng có Previous/Play-Pause/Next và tiến độ theo khả năng OS.
- [ ] P17-05 `sc_noti_03`: lockscreen controls cùng media session; không tự vẽ một app overlay giả trên màn khóa.
- [ ] P17-06 Tap notification mở player/current song; xử lý cold start và intent tránh mở nhiều route.
- [ ] P17-07 Mọi action gửi chung handler, trạng thái cập nhật ngược UI ngay khi resume.
- [ ] P17-08 Xử lý audio focus: pause/duck khi cuộc gọi/ứng dụng khác; resume chỉ theo chính sách phù hợp, không phát bất ngờ.
- [ ] P17-09 Ngắt tai nghe/Bluetooth noisy event pause; nút tai nghe gửi Play/Pause/Next/Previous đúng phiên.
- [ ] P17-10 Kiểm tra khóa máy, background lâu, swipe app khỏi recent, OEM battery restrictions và service bị hệ thống thu hồi.
- [ ] P17-11 Stop xóa/trả notification về trạng thái phù hợp; không để notification cũ chỉ vào bài không còn.
- [ ] P17-12 Tắt nguồn/force-stop dừng; khi mở lại restore paused, không tự phát ngoài yêu cầu.

**Hoàn thành khi:** máy thật phát khi khóa màn hình; next/pause từ OS đồng bộ app, không có player/notification kép.

## 18. Dialog toast và trạng thái dùng chung

- [ ] P18-01 Nối `Sc_bo_khoi_thu_vien` từ menu bài/nguồn: confirm lưu exclusion, giữ file và cập nhật mọi danh sách.
- [ ] P18-02 Hoàn thiện dialog xóa queue, dừng phát, reset EQ, xóa playlist, bỏ thay đổi và đăng xuất.
- [ ] P18-03 Confirm có pending/loading để không thực hiện hai lần; thất bại giữ trạng thái cũ và cho thử lại.
- [ ] P18-04 Chuẩn hóa toast: đã thêm/bỏ yêu thích, thêm playlist, đã tồn tại, timer bắt đầu/hủy, quét xong/partial và lỗi phát.
- [ ] P18-05 Gộp/throttle lỗi lặp; không hiện hàng chục toast khi queue nhiều file lỗi.
- [ ] P18-06 Mọi màn có loading/empty/error/content theo dữ liệu; retry chỉ chạy lại thao tác liên quan.
- [ ] P18-07 Permission denied/file unavailable/network auth error có nội dung riêng, không gom thành Lỗi không xác định.
- [ ] P18-08 Back dismiss overlay trước, sau đó route; action sheet không xếp chồng không kiểm soát.
- [ ] P18-09 Đối chiếu toàn bộ nút trong ảnh UI; không để placeholder/onTap rỗng trong release.

**Hoàn thành khi:** tất cả overlay có điểm mở và kết quả rõ, không có toast thành công giả hoặc lỗi lặp vô hạn.

## 19. Kiểm thử nghiệp vụ và tích hợp

Ưu tiên test nghiệp vụ rủi ro và chạy trên thiết bị thật; không chỉ kiểm tra widget có hiển thị.

- [ ] P19-01 Unit test scan identity/dedup, exclusion và partial scan không xóa nguồn mất quyền.
- [ ] P19-02 Unit test playlist uniqueness, transaction rollback và xóa playlist không xóa song/file.
- [ ] P19-03 Unit test queue entry duplicate, reorder, clear upcoming, Previous 3 giây và repeat/shuffle.
- [ ] P19-04 Unit test stats threshold 30 giây, bài ngắn, pause/resume, seek, repeat và callback lặp.
- [ ] P19-05 Unit test kỳ tuần/tháng/năm, leap year, midnight segment và distinct song theo cả kỳ.
- [ ] P19-06 Unit test sleep timer deadline/stop-at-end/repeat precedence/hủy/restore.
- [ ] P19-07 Test DB migration và recovery snapshot trên dữ liệu đã lưu.
- [ ] P19-08 Integration cài mới → onboarding → setup grant → scan → Home → chọn bài → background.
- [ ] P19-09 Integration deny/deny permanently/Để sau → app trống → Settings cấp lại → scan thành công.
- [ ] P19-10 Integration playlist create/add/play/edit/delete, song favorites cập nhật mọi màn.
- [ ] P19-11 Integration notification/lockscreen/headset/call interruption với app foreground/background.
- [ ] P19-12 Integration timer trên màn khóa; kiểm tra audio dừng thật, không chỉ đổi UI.
- [ ] P19-13 Integration stats Tuần/Tháng/Năm, chart tap, dialog Apply/Cancel và top list.
- [ ] P19-14 Integration theme/light/dark/system, accent, EQ, permission, rate và email composer.
- [ ] P19-15 Integration Google cancel/error/success/logout; mất mạng vẫn nghe local.
- [ ] P19-16 Kiểm tra restart/process recreation, SD tháo/lắp, file đã bị app khác xóa và queue toàn lỗi.
- [ ] P19-17 QA màn nhỏ/lớn, font lớn, tên dài, EN/VI, keyboard, screen reader và safe area.
- [ ] P19-18 Kiểm tra thư viện lớn: thời gian scan/query, scroll FPS, RAM artwork và battery background.
- [ ] P19-19 Chạy `dart format .`, `flutter analyze`, `flutter test`; ghi thiết bị/API/version và lỗi còn lại.

**Hoàn thành khi:** các luồng nghiệm thu ở tài liệu nghiệp vụ đều pass; lỗi có mức độ/biện pháp rõ, không còn blocker.

## 20. Đóng gói Android và phát hành

- [ ] P20-01 Loại bỏ fixture/debug menu/log nhạy cảm, thay icon/adaptive icon đúng brand và kiểm tra splash release.
- [ ] P20-02 Chốt versionName/versionCode, signing release và cấu hình build; lưu secrets ngoài Git.
- [ ] P20-03 Kiểm tra Google login bằng chữ ký release và Play App Signing phù hợp trước khi phát hành.
- [ ] P20-04 Kiểm tra manifest merge, quyền thực tế, target/min SDK và foreground media playback theo yêu cầu phát hành hiện hành.
- [ ] P20-05 Hoàn thiện privacy policy, quyền âm thanh, account deletion nếu mô hình tài khoản yêu cầu; khai báo dữ liệu đúng implementation.
- [ ] P20-06 Kiểm tra link store/rate/support và các trang chính sách không còn URL mẫu.
- [ ] P20-07 Build APK release để QA (`flutter build apk --release`), AAB phát hành (`flutter build appbundle --release`).
- [ ] P20-08 Cài bản release sạch và nâng cấp từ bản trước; kiểm tra migration/quyền/scan/background/auth.
- [ ] P20-09 Chuẩn bị screenshot EN/light/dark phù hợp, mô tả app nghe local và danh sách chức năng thật.
- [ ] P20-10 Đưa internal testing, thu lỗi và sửa; kiểm tra yêu cầu testing/phát hành hiện hành trước khi production.
- [ ] P20-11 Chốt checklist không còn blocker, tag Git release và lưu hướng dẫn build/release.
- [ ] P20-12 Sau phát hành theo dõi crash/ANR/phản hồi/khả năng audio theo thiết bị; có kế hoạch hotfix.

**Hoàn thành khi:** release cài/chạy được, đủ luồng thực trên thiết bị và hồ sơ store phản ánh đúng chức năng.

## 21. iOS nếu nằm trong phạm vi phát hành

Không mặc định iOS đọc toàn bộ thư viện file như Android. Phải thử import/system document picker và quyền trước khi coi hai nền tảng tương đương.

- [ ] P21-01 Chốt nguồn nhạc iOS: document picker/import local, sandbox và khả năng thư viện media theo quyền/nền tảng.
- [ ] P21-02 Triển khai nguồn iOS adapter với bookmark/copy sandbox nếu cần; không dùng path Android.
- [ ] P21-03 Cấu hình audio background mode, AVAudioSession, Now Playing và remote commands qua handler chung.
- [ ] P21-04 Kiểm tra headphone/phone call/background/lockscreen và timer trên iPhone thật.
- [ ] P21-05 EQ theo capability iOS, disable option không hỗ trợ và không quảng cáo tính năng Android-only.
- [ ] P21-06 Cấu hình OAuth/bundle/signing, privacy/account rules phù hợp bản iOS hiện hành.
- [ ] P21-07 QA toàn bộ luồng local, dark/light, source import, restart và dữ liệu thống kê.
- [ ] P21-08 Build release, TestFlight và hồ sơ App Store; không đánh dấu iOS hoàn tất chỉ vì Android pass.

## 22. Ma trận nghiệm thu cuối cùng

| Luồng | Đường đi cần pass | Checklist |
|---|---|---|
| Cài mới | Splash → 3 onboarding → 3 setup → Home | P06 |
| Quét lại | Settings → nguồn → scan → thư viện không trùng | P05, P14 |
| Nghe nhạc | Danh sách → Player → Back → đổi tab → mini player | P07, P08, P12 |
| Playlist | Tạo → thêm → phát → sửa → xóa; file gốc giữ nguyên | P10 |
| Khám phá | Gợi ý local → list → phát; nút Thống kê hoạt động | P11 |
| Thống kê | Tuần/Tháng/Năm → lịch → chọn → Apply/Cancel | P16 |
| Timer | Settings hoặc player → bắt đầu → khóa máy → dừng | P13 |
| OS controls | Notification/lockscreen/headset → next/pause → mở app | P17 |
| Settings | EQ/quality/headphone/theme/accent/permission/about | P14 |
| Tài khoản | Login/hủy/lỗi/logout; local vẫn nghe được | P15 |
| Feedback và rate | Compose đúng email/store; không báo thành công giả | P14 |
| Ngoại lệ | Quyền mất, file lỗi, 0 bài, font lớn, queue toàn lỗi | P05, P07, P18, P19 |
| Release | Bản ký thật + nâng cấp + store requirements | P20 |

## 23. Quy tắc báo cáo tiến độ

- Đánh dấu theo ID nhiệm vụ, không đánh dấu cả giai đoạn chỉ vì đã dựng giao diện.
- Mỗi mục hoàn tất ghi commit/ảnh hoặc kết quả test; mục bị chặn ghi lý do và dependency.
- Luồng quan trọng phải chạy end-to-end bằng dữ liệu thật trước khi coi màn hoàn thiện.
- Sau mỗi giai đoạn cập nhật README, ma trận screen→route và các quyết định kiến trúc đã chốt.
- Thứ tự ưu tiên: nền tảng → dữ liệu/scan → setup → playback → shell/library/player → playlist/explore → settings/stats/OS → QA/release. Có thể làm UI song song sau khi contract service ổn định, nhưng không bỏ qua nghiệm thu.
