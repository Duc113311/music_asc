# Shared base: asc_common + dsp_base

Muvik and smart_drink (Aqua Mind) build on the **same two ASC packages**, so a fix
or a new helper in the base reaches both apps.

| Package | Repo | What it gives the app |
|---|---|---|
| `asc_common` | `asctechsoft/asc_common` | UI primitives (`AppText`, `AppTouchable`, `AppSwitch`, `BottomSafeArea`...), XML localization (`AscLocale`), typed prefs (`AscPrefs`), `AscBuildFlavor`, `AscLogger`, permissions, device info, connectivity, in-app review, share |
| `dsp_base` | `asctechsoft/dsp_base_app` | `DspBase` bootstrap: Firebase (core, Crashlytics, Analytics, App Check, Remote Config), AdMob services/views, UMP/GDPR consent |

Both are **git dependencies pinned to a commit** in `pubspec.yaml`
(`asc_common` `ref: 96a4c3b`, `dsp_base` `ref: 2692ce3`). smart_drink points at
the same repos through a path/submodule; the commits must match when you want
identical behavior.

## Updating the base

1. Pick the new commit on `main` of the package (or tag it).
2. Change `ref:` in `pubspec.yaml`, run `flutter pub get`.
3. `flutter analyze` and `flutter test`, then run the app on a device.
4. Bump the same ref in smart_drink so both apps stay aligned.

Never use `ref: main` in an app: an upstream push would change the build silently.

## What Muvik takes from each package

| Base API | Where in Muvik |
|---|---|
| `AscBuildFlavor` | `configs/app_figs.dart` (`AppFigs.isAlpha/isDev/isProduct/isClaude/isShowTestOption`) |
| `AscLocale` | `configs/locale_config.dart` (supported locales, pref keys) and `utils/app_localize.dart` (policy: EN + VI real text, everything else English) |
| `DspBase`, `DspFirebaseService`, `DspCrashlytics`, `DspAnalytics`, `DspRemoteConfigRepository` | `main.dart` startup, `utils/app_log.dart`, `utils/route_analytics.dart` |

Not used on purpose: AdMob services and consent. `AppConfig.adsEnabled` is `false`, so
startup only runs the Firebase half of `DspBase` and EEA users get no consent form. To
turn ads on: set it to `true`, add real ad unit ids, and replace the sample AdMob app id
in `AndroidManifest.xml`.

## Startup and lifecycle

```
main()
  runZonedGuarded                       uncaught error -> DspCrashlytics.recordError(fatal)
    WidgetsFlutterBinding.ensureInitialized
    _bootstrap()
      orientation (portrait) + edge-to-edge + hide navigation bar
      PrefStore.init()                  SharedPreferences
      _startDspBase()                   Firebase + Crashlytics + Remote Config
                                        (+ consent/AdMob when adsEnabled); cut off after 6 s,
                                        never throws: listening works offline
      initializeDateFormatting
      AppLocalize.ensureConfigured()    saved locale -> device locale -> English
      AppLocalize.loadTranslations()    XML -> GetX `.tr`
      Get.put(AppLifecycleService)      permanent
      Get.put(SettingsController)       permanent
    runApp(MuvikApp)                    GetMaterialApp, routingCallback = RouteAnalytics
      splash -> BootstrapService (DB, library, audio) -> onboarding/setup/home
```

`AppLifecycleService` is the single `WidgetsBindingObserver`:

| State | Service does | Listeners (subscribe with `addResumedListener` / `addBackgroundListener`) |
|---|---|---|
| resumed | re-hide the navigation bar; Crashlytics breadcrumb | `HomeShell`: library refresh on resume, nudge refresh |
| paused / detached | Crashlytics breadcrumb | `HomeShell`: flush listening stats before the OS may kill the process |

Screens unsubscribe in `dispose`. New code that needs a lifecycle hook should subscribe
here instead of mixing in its own `WidgetsBindingObserver`.

## Build and release automation

| What | How |
|---|---|
| Run | `flutter run --flavor dev` (flavors: `alpha` no ads, `dev`, `product`, `claude`), or the VS Code launch configs |
| APK + version bump + release notes + Firebase App Distribution + notification | `python build.py` (menu) or `python build.py dev release` |
| Play Store bundle | `python tool/build/build_aab.py` |
| Strings check | `python build.py check-strings` |
| Store signing | create `android/key.properties` (git-ignored); without it release builds use the debug key |

Version: `pubspec.yaml` `version: x.y.z+N` gives the build number `N`;
`build_version.txt` (git-ignored) holds `minor(N)`, bumped on every build;
the name is `1.N.minor`. Same scheme as smart_drink.

Optional secrets (never committed): `ASC_TELEGRAM_BOT_TOKEN`, `ASC_TELEGRAM_CHAT_ID`,
`ASC_EMAIL_TO`, `ASC_EMAIL_FROM`, `ASC_EMAIL_PASSWORD`, `ASC_TESTER_EMAILS` as environment
variables, or the same keys in `tool/build/build_secrets.json`. Firebase App Distribution
uses `build_auth.json` (service account) or the logged-in `firebase` CLI. Missing values
only skip that step.
