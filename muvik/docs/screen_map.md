# Muvik — Figma key → code → route

Figma keys are kept exactly as in the business spec (§1.3), typos included.

| Figma key | File | Route / overlay | States handled | Checklist |
|---|---|---|---|---|
| sc_splash | `presentation/screen_splash/splash_screen.dart` | `/splash` | loading (finite), init error + Retry | P06-02 |
| sc_onBrg_01..03 | `presentation/screens_onboarding/onboarding_screen.dart` | `/onboarding` (PageView, no navbar) | page index kept, Skip/Back/Continue/Start | P06-04..07 |
| sc_step_01 | `presentation/screens_setup/step_permission.dart` | `/setup` step 0 | denied → Retry/Later, permanently denied → Open settings | P06-09/10 |
| sc_step_02 | `presentation/screens_setup/step_sources.dart` | `/setup` step 1 | no selection → CTA disabled, scan progress/cancel/error | P06-11/12 |
| sc_step_03 | `presentation/screens_setup/step_result.dart` | `/setup` step 2 | 0 songs → Choose again / Rescan / Enter app | P06-13/14 |
| sc_navibar | `presentation/screen_home/home_shell.dart` | `/home` (IndexedStack, 4 tabs) | lazy tabs, re-tap scrolls to top, Back → Home tab | P08-01 |
| sc_home | `presentation/screen_dashboard/dashboard_tab.dart` | tab 0 | greeting by hour, no history, empty library | P08-05..10 |
| (Thư viện, no Figma key; `ic_not_truy_cap` = empty/no-permission) | `presentation/screen_library/library_tab.dart` | tab 1 | empty, no permission banner, loading | P09 |
| (album/artist/folder/list detail) | `presentation/screen_library/song_list_screen.dart` | `/songs` | empty, source unavailable | P09-02..05 |
| sc_kham_pha | `presentation/screen_explore/explore_tab.dart` | tab 2 | empty library CTA | P11 |
| Sc_thong_ke_tuan / thang / nam | `presentation/screen_statistics/statistics_screen.dart` | `/statistics` (from Explore) | loading, error + retry, no data | P16 |
| Sc_dialog_tuan / sc_dialog_thang / Sc_dialoh_nam | `presentation/dialogs/period_picker_dialogs.dart` | dialog | draft, Apply/Cancel/X, future disabled | P16-13..16 |
| sc_cat_dat | `presentation/screens_settings/settings_tab.dart` | tab 3 | settings rows | P14-01 |
| sc_quet_thu_vien | `presentation/screens_settings/scan_library_screen.dart` | `/settings/scan` | running/partial/error/cancelled | P14-02/03 |
| sc_hen_gio_tat | `presentation/screens_settings/sleep_timer_screen.dart` | `/settings/sleep-timer` | invalid input, active countdown | P13-01 |
| sc_bo_chinh_am | `presentation/screens_settings/equalizer_screen.dart` + `common_components/equalizer_panel.dart` | `/settings/equalizer` | unsupported device / effect | P14-05..08 |
| sc_dat_lai_bo_chinh_am | `presentation/dialogs/app_dialogs.dart#confirmResetEqualizer` | dialog | pending | P14-09 |
| sc_chat_luong_phat | `presentation/screens_settings/playback_quality_screen.dart` | `/settings/quality` | no song, unknown metadata | P14-10 |
| sc_phat_qua_tai_nghe | `presentation/screens_settings/headphones_screen.dart` | `/settings/headphones` | — | P14-11 |
| sc_theme | `presentation/screens_settings/theme_screen.dart` | `/settings/theme` | — | P14-12 |
| (Màu nhấn sheet) | `presentation/bottom_sheets/accent_sheet.dart` | sheet | draft until Save | P14-13 |
| (Quyền truy cập) | `presentation/screens_settings/permissions_screen.dart` | `/settings/permissions` | granted/denied/blocked | P14-14 |
| sc_gioi_thieu | `presentation/screens_settings/about_screen.dart` | `/settings/about` | policy URL missing | P14-15 |
| sc_feedback | `presentation/screens_settings/feedback_screen.dart` | `/settings/feedback` | validation, no email app | P14-16..18 |
| sc_rate_app | `presentation/dialogs/rate_app_dialog.dart` | dialog | store unavailable | P14-19/20 |
| Sc_phat_nhac | `presentation/screen_player/now_playing_screen.dart` | `/player` | loading, no duration (seek locked) | P12-01/02 |
| sc_bthShet_short (shuffle/repeat) | `presentation/bottom_sheets/player_mode_sheets.dart` | sheet | applied immediately | P12-03/04 |
| (Yêu thích sheet) | `presentation/bottom_sheets/player_mode_sheets.dart#showFavoriteSheet` | sheet | — | P12-05 |
| Sc_bthSheet_phattiep / sc_bthShet_next | `presentation/bottom_sheets/queue_sheet.dart` | sheet | empty queue, undo remove | P12-06 |
| Sc_delete_danh_sach_cho | `presentation/dialogs/app_dialogs.dart#confirmClearQueue` | dialog | — | P12-07 |
| sc_bthShet_add | `presentation/bottom_sheets/add_to_playlist_sheet.dart` | sheet | duplicates reported | P12-08 |
| sc_bthShet_tao_playlist | `presentation/screens_playlist/playlist_form_screen.dart` | `/playlist/form` | validation, discard changes | P10-01/02 |
| (EQ sheet) | `presentation/bottom_sheets/equalizer_sheet.dart` | sheet | — | P12-09 |
| Sc_bthsheet_hen_gio_tat / sc_bthShet_hen_gio | `presentation/bottom_sheets/sleep_timer_sheet.dart` | sheet | active timer | P12-10 |
| Sc_dung_phat_nhac | `presentation/dialogs/app_dialogs.dart#confirmStopPlayback` | dialog (player ⋮ menu only) | — | P12-11 |
| Sc_bo_khoi_thu_vien | `presentation/dialogs/app_dialogs.dart#confirmRemoveFromLibrary` | dialog | — | P18-01 |
| Sc_delete_cho (xóa playlist) | `presentation/dialogs/app_dialogs.dart#confirmDeletePlaylist` | dialog | — | P10-07 |
| (song ⋮ menu) | `presentation/bottom_sheets/song_actions_sheet.dart` | sheet | unavailable song | spec §9.2 |
| sc_bthShet_bai_tiep (sort) | `presentation/bottom_sheets/sort_sheet.dart` | sheet | draft until Apply | P09-06 |
| Sc_noti_01 / Sc_noti_02 / sc_noti_03 | OS media notification via `services/application/audio_handler.dart` (audio_service) | system | — | P17 |

## Missing / differing source assets (P00-07)

- No mockup for `sc_navibar`, `Sc_dung_phat_nhac`, `Sc_bo_khoi_thu_vien`, the Library tab and `sc_rate_app` as screens; they were built from the spec text and the shared dialog style. `img_rate_app` exists as an illustration only.
- Mockups show the working name **"Melo"**; the app uses **Muvik** everywhere (P00-01).
- Mockups `sc_step_01/02/03` show a bottom navigation bar and step 3 shows a theme choice; the spec (§1.4) forbids both, so setup has no navbar and step 3 shows the library result.
- `sc_chat_luong_phat` mockup offers "Cân bằng / Tiết kiệm pin"; the spec forbids fake quality options, so the screen shows the real file properties and "Gốc" only.
- `sc_kham_pha` mood chips (Êm dịu / Tập trung / Sôi động) filter by the song's genre tag with fixed keyword rules (`lib/utils/mood_rules.dart`, P11-04). Genre is read at scan time (DB v2); existing libraries are rescanned once in the background after the upgrade.
- `sc_thong_ke_*` mockups show a 5-tab bar with "Thống kê"; the app keeps 4 tabs and opens Statistics from Explore.
- Folder names `image_sư_dung` / `scream_new` differ from the checklist (`image_su_dung` / `screen_new`); assets were converted to ASCII snake_case WebP under `assets/images/webp/`.
