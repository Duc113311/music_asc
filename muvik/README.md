# Muvik

Offline local music player for Android (iOS project scaffolded, not in scope yet).
No account or network is needed to listen; Google sign-in is optional.

## Run

```bash
flutter pub get
flutter run --flavor dev      # Android device/emulator (flavor is required: alpha | dev | product | claude)
flutter test                  # unit + DB tests (sqflite ffi)
flutter analyze
python tool/gen_strings.py    # regenerate lib/xml_strings from tool/strings_src.py
python tool/check_strings.py  # fail if a used key has no string
python build.py               # APK menu: version bump, release notes, Firebase App Distribution
python build.py dev release   # same, flavor + build type given
python tool/build/build_aab.py   # Play Store bundle (product release)
```

VS Code: `.vscode/launch.json` at the repo root has the six Muvik configurations (NoAds / Dev /
Product x Debug / Release) and `.vscode/tasks.json` the build tasks.

### Local files you must create (git-ignored)

| File | Why |
|---|---|
| `android/app/google-services.json` | Firebase project `muvik-app` (Crashlytics, Analytics, Google sign-in client ids). Download it from the Firebase console (Project settings → Android app `com.asctechsoft.muvik`); the build fails without it. Google sign-in only works when the machine's SHA-1 (`keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android`) is registered there |
| `android/key.properties` | Only for store signing (`keyAlias`, `keyPassword`, `storeFile`, `storePassword`). Without it release builds are signed with the debug key |

No other local file is needed; a fresh clone builds with just `google-services.json`.

## Base packages: asc_common + dsp_base

Muvik builds on the same ASC shared base as smart_drink: [`asc_common`](https://github.com/asctechsoft/asc_common)
(UI primitives, XML localization, typed prefs, flavor flags, logging) and
[`dsp_base`](https://github.com/asctechsoft/dsp_base_app) (Firebase, AdMob, consent). Both are git
dependencies pinned to a commit in `pubspec.yaml` `ref:`. Details, update procedure, startup order
and the lifecycle hub are in [`docs/base_packages.md`](docs/base_packages.md).

| Base piece | Used for |
|---|---|
| `DspBase` / `DspFirebaseService` / `DspCrashlytics` | Startup (`main.dart`), Crashlytics error hooks, `AppLog.error` |
| `DspAnalytics` | `RouteAnalytics`: one `screen_view` per named route |
| `AscLocale` | XML strings → GetX translations (`AppLocalize` adds Muvik's EN/VI policy) |
| `AscBuildFlavor` | `AppFigs` flavor flags (`alpha`, `dev`, `product`, `claude`) |

Not used on purpose: ads (`AppConfig.adsEnabled = false`; the manifest only carries Google's sample
AdMob app id because `google_mobile_ads` aborts without one), the `asc_common` in-app review wrapper
(Muvik has its own rate flow from the design), and the `App*` widgets (screens were already built
with Flutter widgets from the Figma tokens; new code may use them).

Languages: Muvik translates EN and VI (`AppLocaleConfig.supportedLocales`); any other device language
resolves to English. `tool/gen_strings.py` still writes the English text into the other
`values-*` folders so a future language only needs its folder's text replaced and its `Locale`
added to `AppLocaleConfig`.

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
| Base packages | Git dependencies `asc_common` + `dsp_base`, pinned by commit, same as smart_drink (see `docs/base_packages.md`) |
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
- Release signing: create `android/key.properties` + keystore (git-ignored); `app/build.gradle.kts` picks it up for release builds and falls back to the debug key without it.
- Gradle heap is set to 3 GB (`android/gradle.properties`) because the dev machine has limited free RAM; raise it on CI if builds are slow.
- `compileSdk` is pinned to 37 because `permission_handler_android` 14 (via asc_common) needs it; the old 13.0.1 override is gone.
- Text scale: `MuvikApp` clamps the system font scale to 0.85-1.3 (the policy the previous base applied), then `SmallerTextScaler` shrinks every font by 2 px.
