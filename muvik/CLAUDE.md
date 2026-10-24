# CLAUDE.md

Guidance for Claude Code when working in this folder (the Flutter app `muvik`).

## Project

Muvik: offline local music player for Android (iOS scaffolded, not in scope). GetX for
state, routing and DI; SQLite (`sqflite`); `just_audio` + `audio_service` with one audio
handler. Same ASC base as smart_drink: `asc_common` + `dsp_base` (see `docs/base_packages.md`).

## Commands

```bash
flutter pub get
flutter run --flavor dev          # flavor is required: alpha | dev | product | claude
flutter analyze
flutter test
python build.py                   # APK menu: version bump, release notes, distribute
python tool/build/build_aab.py    # Play Store bundle (product release)
python tool/gen_strings.py        # regenerate lib/xml_strings from tool/strings_src.py
python tool/check_strings.py      # fail if a used key has no string
```

## Architecture

Layers (see README and `APP_BASE_STRUCTURE.md`):

```
Presentation (lib/presentation/)  -> screens, bottom sheets, dialogs, common components
Controllers  (lib/controller/)    -> GetX reactive state
Services     (lib/services/)      -> application logic, native channels, storage
Repository   (lib/repository/)    -> data access (CRUD/query only)
Storage      (lib/services/storage/) -> SQLite DatabaseHelper singleton, PrefStore
```

- **Startup** is in `lib/main.dart` (guarded zone -> system UI -> prefs -> dsp_base -> locale ->
  permanent services -> app). DB, library and audio are initialized later by the splash
  (`BootstrapService`).
- **Permanent** (`Get.put(..., permanent: true)`): `AppLifecycleService`, `SettingsController`,
  plus the library/playback controllers bound by the splash/shell.
- **Lifecycle**: use `AppLifecycleService.to.addResumedListener / addBackgroundListener`
  (unsubscribe in `dispose`). Do not add another `WidgetsBindingObserver`.
- **Flavors**: read them through `AppFigs` (`configs/app_figs.dart`), never `appFlavor` directly.
- **Logging**: `AppLog.info` (dev only) and `AppLog.error` (Crashlytics non-fatal). No `print`.
- **Strings**: every user-visible text is a key in `tool/strings_src.py`, used as `'key'.tr`;
  run `gen_strings.py` after editing and `check_strings.py` before building.
- **Preferences**: keys in `configs/pref_const.dart`, defaults in `pref_defaults.dart`,
  read/write only through `PrefStore`.
- **Ads** are off (`AppConfig.adsEnabled`); the manifest carries Google's sample AdMob app id.

## Local files (git-ignored, create them yourself)

- `android/app/google-services.json` - Firebase project `muvik-app`; the build fails without it.
- `android/key.properties` - only for store signing; without it release is debug-signed.
- `tool/build/build_secrets.json`, `build_auth.json` - optional notification / App Distribution secrets.

Never commit keystores, passwords, tokens or service accounts.

## Conventions

- Lints: `flutter_lints` (`analysis_options.yaml`); Dart SDK from `pubspec.yaml`.
- Flutter 3.47: Flutter now defines its own `RepeatMode`; files that use Muvik's
  `models/ui_models/repeat_mode.dart` import `flutter/material.dart` with `hide RepeatMode`.
- Models are immutable with `copyWith`; dates are ISO8601 strings and `date_key` (YYYY-MM-DD).
- Base packages are pinned by commit in `pubspec.yaml`; to update see `docs/base_packages.md`.
