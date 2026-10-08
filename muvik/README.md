# Muvik

Offline local music player for Android (iOS project scaffolded, not in scope yet).
No account or network is needed to listen; Google sign-in is optional.

## Run

```bash
flutter pub get
flutter run --flavor dev      # Android device/emulator (flavor is required: alpha | dev | product)
flutter test                  # unit + DB tests (sqflite ffi)
flutter analyze
python tool/gen_strings.py    # regenerate lib/xml_strings from tool/strings_src.py
python tool/check_strings.py  # fail if a used key has no string
flutter build apk --flavor product --release   # store build (needs release signing, see below)
```

VS Code: `.vscode/launch.json` at the repo root has Muvik (dev / alpha / product) configurations.

### Local files you must create (git-ignored)

| File | Why |
|---|---|
| `android/app/google-services.json` | Firebase project `muvik-app` (Crashlytics, Analytics, Google sign-in client ids) |
| `android/debug_keystore.properties` | Read by dsp_base's Gradle script; keys `appCheckToken`, `appCheckKey` (16 chars), `secretToken`, `secretKey` (16 chars). Any values work while Firebase App Check is off |

## Base package: dsp_base

Muvik builds on the ASC shared base [`dsp_base`](https://github.com/asctechsoft/dsp_base_app)
(git dependency, commit pinned in `pubspec.lock`; `flutter pub upgrade dsp_base` pulls `main`).

| dsp_base piece | Used for |
|---|---|
| `commRunApp` | Entry point: PrefAssist init, base strings, device RAM class, Crashlytics error hooks, dev error overlay |
| `CommApp` | GetMaterialApp wrapper (ScreenUtil 360×800, text scale clamped 0.85–1.3) |
| `CommLocalize` | XML strings → GetX translations; chosen locale stored in `PrefComm.CONFIGURED_LOCALE_BY_USER` |
| `PrefAssist` | The SharedPreferences instance behind `PrefStore` |
| `CommFigs` / `debugLog` | Flavor flags (`IS_PROD_RELEASE`, `IS_SHOW_TEST_OPTION`); dev-only logging via `AppLog` |

Not used on purpose: ads (Muvik shows none — the manifest only carries Google's sample AdMob app id
because `google_mobile_ads` aborts without one), the 5-star `RateMe` dialog (Muvik has its own rate
flow from the design), and the `App*` widgets (screens were already built with Flutter widgets from the
Figma tokens; new code may use them). `asc_common` (Riverpod rewrite of the same base) is not used:
it needs Dart ≥ 3.13 and does not fit the GetX architecture.

Languages: CommLocalize knows 16 locales and loads the device language's folder. Muvik translates
EN and VI; `tool/gen_strings.py` writes the English text into the 14 other folders so those devices
see English (P00-09) instead of a missing-asset error. Translating one = replacing its folder's text.

## Architecture

Same layering as `APP_BASE_STRUCTURE.md`:

```
lib/
  configs/          PrefConst, PrefDefaults, AppConfig
  values/           routes, pages, theme (AppColors ThemeExtension), typography, dimensions, assets
  models/           data_models (DB rows) + ui_models (enums, value objects)
  controller/       GetX controllers (permanent: Settings, Library, Playback; route-scoped: others)
  repository/       CRUD/query only, accept a transaction executor
  services/
    storage/        DatabaseHelper (singleton + Completer), schema, PrefStore
    application/    business logic: scan, playback (single AudioHandler), queue, stats, timer, EQ, playlists, auth
    native/         MediaLibraryChannel, AudioEffectsChannel (Dart side)
  presentation/     screens, bottom sheets, dialogs, common components
  xml_strings/      values/ (EN fallback), values-vi/
android/app/src/main/kotlin/com/asctechsoft/muvik/
  MainActivity.kt          extends AudioServiceActivity
  MediaLibraryHandler.kt   MediaStore volumes, SAF folders, metadata, artwork, file format
  AudioEffectsHandler.kt   Equalizer / BassBoost / Virtualizer on the player session
```

Key decisions:

| Topic | Decision |
|---|---|
| Package / id | `muvik`, `com.asctechsoft.muvik` |
| `dsp_base` | Git dependency; `commRunApp` + `CommApp` + `CommLocalize` + `PrefAssist` (see above) |
| Audio | `just_audio` + `audio_service`: one `MuvikAudioHandler` serves UI, notification, lock screen and headset |
| Queue | Pure `PlayQueue` with entry ids (duplicates allowed), natural + shuffled order, repeat rules |
| Library | MediaStore volumes (`READ_MEDIA_AUDIO`) + SAF picked folders; identity = volume + relative path + file name |
| Stats | `ListeningTracker` counts audible time from a monotonic clock, split per local day; a play = ≥30 s or a shorter track finishing |
| Sleep timer | Deadline stored in prefs; lives next to the handler, not in a screen |
| EQ | Preset curves interpolated onto the device's real bands; unsupported effects disabled |
| Locale | VI + EN (fallback); add `values-xx/strings.xml` + one map entry to add a language |

Figma key → file → route: see [docs/screen_map.md](docs/screen_map.md).

## Known limits

- Locking the screen keeps playing; power-off or force-stop ends playback (restored paused on next launch).
- Swipe-away from Recents keeps playing while Android keeps the media service; behaviour varies by OEM.
- Google sign-in needs `AppConfig.googleServerClientId` and an OAuth client for the release SHA-1; until then the button reports "not configured" and local use is unaffected.
- `AppConfig.privacyPolicyUrl` must be set before release.
- Release signing: create `android/key.properties` + keystore (git-ignored) and wire `signingConfigs.release`.
- Gradle heap is set to 3 GB (`android/gradle.properties`) because the dev machine has limited free RAM; raise it on CI if builds are slow.
- `permission_handler` is 13.x (required by dsp_base) but `permission_handler_android` is overridden to 13.0.1: 14.x needs AGP 9 / compileSdk 37, newer than Flutter 3.38 ships. Drop the override after a Flutter upgrade.
- Text scale is clamped to 1.3× by dsp_base `CommApp` (base-wide policy).
