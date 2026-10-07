# Flutter App Base Structure — Full Architecture Reference

> **Purpose:** Copy-paste base for new Flutter apps built with the same stack. Replace domain names, swap Firebase project config when needed. Everything else replicates as-is.
> **Stack:** Flutter + GetX + SQLite (sqflite) + SharedPreferences + Native Channels + AI Gateway
> **Sections marked `[FIREBASE]`:** keep if Firebase is needed, remove if not.

---

## 1. Tech Stack

| Layer | Package | Purpose |
|---|---|---|
| State / DI / Routing | `get` (GetX) | Controllers, reactive state, named routes |
| Local DB | `sqflite` | SQLite, singleton helper, versioned migrations |
| Preferences | `shared_preferences` | Flags, primitives, user settings |
| Localization | XML strings (custom loader) | 60+ languages, XML-based |
| Charts | `fl_chart` | History/analytics charts |
| HTTP | `http` | AI gateway REST + SSE streaming |
| Health | `health` | HealthConnect / HealthKit sync (opt-in) |
| Notifications | Native `MethodChannel` | Platform alarms, ongoing notification |
| Home Widget | Native `MethodChannel` | Android/iOS home screen widget |
| Auth `[FIREBASE]` | `firebase_auth` + `google_sign_in` | Anonymous for AI quota, Google for user login |
| SVG | `flutter_svg` | Icons, illustrations |
| Fonts | PlusJakartaSans | 400/500/600/700/italic |
| Shared UI | Local path dep `dsp_base` | `AppText`, `AppBox`, localization, ads, GDPR |

---

## 2. Directory Structure

```
lib/
├── main.dart                          # Entry point, app boot, bindings
├── configs/
│   ├── pref_const.dart                # ALL SharedPreferences key strings (no literals elsewhere)
│   ├── pref_defaults.dart             # Default value for every pref key
│   └── ai_gateway_config.dart         # AI gateway URL, timeout, max chars
├── values/
│   ├── route_name.dart                # All route path constants
│   ├── app_pages.dart                 # GetPage list (routes + bindings)
│   ├── app_theme.dart                 # ThemeData light + dark
│   ├── app_colors.dart                # Full color palette + gradients
│   └── onboarding_theme.dart          # Onboarding-specific design tokens
├── models/
│   ├── data_models/                   # DB-backed models (toMap / fromMap / copyWith)
│   │   ├── user_profile.dart
│   │   ├── drink_record.dart          # main entity — swap for your domain
│   │   ├── daily_summary.dart         # aggregated daily totals
│   │   └── reminder_schedule.dart
│   └── ui_models/                     # Enums and UI-only value objects
│       ├── drink_type.dart
│       ├── activity_level.dart
│       ├── weather_condition.dart
│       ├── reminder_mode.dart
│       ├── chat_message.dart
│       └── chat_card.dart
├── controller/                        # GetX controllers
│   ├── auth_controller.dart           # [permanent][FIREBASE] Firebase auth state
│   ├── settings_controller.dart       # [permanent] theme, language, units
│   ├── user_profile_controller.dart   # [permanent] profile + daily goal
│   ├── today_controller.dart          # [permanent] today's data + widget sync + lifecycle
│   ├── history_controller.dart        # [permanent] chart data
│   ├── reminder_controller.dart       # [permanent] reminder schedule + native sync
│   ├── avatar_controller.dart         # [permanent] avatar selection
│   ├── onboarding_controller.dart     # [route-scoped] onboarding wizard state
│   ├── chat_controller.dart           # [route-scoped] AI chat screen
│   ├── languages_controller.dart      # [route-scoped] language picker
│   └── streak_controller.dart         # [route-scoped] streak screen
├── repository/                        # Raw DB access (CRUD only, no business logic)
│   ├── drink_repository.dart
│   └── user_repository.dart
├── services/
│   ├── storage/
│   │   ├── database_helper.dart       # Singleton SQLite opener + migration runner
│   │   └── schema.dart                # ALL CREATE TABLE / index / migration SQL strings
│   ├── application/                   # Business logic services (called by controllers)
│   │   ├── drink_data_service.dart    # Transactional drink writes + summary upsert
│   │   ├── ai_chat_service.dart       # AI gateway HTTP client (stream + non-stream)
│   │   ├── chat_quota_service.dart    # Per-day free quota (SharedPreferences)
│   │   └── health_sync_service.dart   # Mirror drinks into HealthConnect/HealthKit
│   ├── native/                        # Platform channel wrappers (Dart side only)
│   │   ├── notification_channel.dart
│   │   └── widget_channel.dart
│   └── feedback_service.dart
├── utils/
│   ├── date_utils.dart                # todayKey(), formatDateKey()
│   ├── water_calculation.dart         # Domain formula — swap for your app
│   ├── unit_converter.dart            # ml↔oz, kg↔lb, cm↔in, time format
│   ├── extensions.dart
│   ├── toast_utils.dart
│   ├── loading_utils.dart
│   ├── share_utils.dart
│   └── language_names.dart
└── presentation/
    ├── common_components/             # Reusable widgets (no business logic here)
    │   ├── primary_button.dart
    │   ├── primary_bottom_sheet.dart
    │   ├── primary_dialog.dart
    │   ├── progress_ring.dart
    │   ├── wheel_picker.dart
    │   ├── ruler_picker.dart
    │   ├── circular_time_picker.dart
    │   ├── toggle_selector.dart
    │   ├── selectable_option_tile.dart
    │   ├── custom_switch.dart
    │   ├── coach_mark.dart
    │   ├── stagger_reveal.dart
    │   ├── app_touchable.dart
    │   ├── auth_loading_overlay.dart
    │   ├── onboarding_progress_bar.dart
    │   ├── onboarding_step_header.dart
    │   └── bottom_safe_area.dart
    ├── screen_splash/
    ├── screens_onboarding/            # One file per step
    ├── screen_home/                   # Shell: IndexedStack + bottom nav
    ├── screen_today/
    ├── screen_history/
    ├── screen_streak/
    ├── screen_avatar/
    ├── screens_chat/
    ├── screens_reminder/
    └── screens_settings/

assets/
├── images/webp/
├── images/svg/
├── images/png/
├── audio/
└── fonts/PlusJakartaSans-{Regular,Medium,SemiBold,Bold,Italic}.ttf

lib/xml_strings/
├── values/strings.xml                 # en_US (fallback)
├── values-vi/strings.xml
└── values-XX/...                      # 16 locales total

android/app/src/main/kotlin/
├── MainActivity.kt
├── NotificationHandler.kt             # MethodChannel implementation
└── WidgetProvider.kt

ios/Runner/
├── AppDelegate.swift
└── NotificationHandler.swift
```

---

## 3. App Startup Lifecycle

```
main()
  └─ commRunApp(WaterNudgeApp, onBindingInitialized: callback)
        ├─ SystemChrome: portrait lock + edge-to-edge mode
        ├─ Firebase.initializeApp()          [FIREBASE] — wrapped in try/catch
        ├─ initializeDateFormatting()        — intl locale data
        ├─ _ensureLocaleConfigured()         — saved pref → device → en_US
        └─ CommLocalize.loadTranslations()   — XML strings into GetX translations

WaterNudgeApp.build()
  └─ CommApp (GetMaterialApp wrapper from dsp_base)
        ├─ theme: AppTheme.dark
        ├─ darkTheme: AppTheme.dark    ← both slots pinned dark
        ├─ themeMode: ThemeMode.dark   ← prevents system flip
        ├─ locale: CommLocalize.getAppLocale()
        ├─ supportedLocales: CommLocalize.supportedLocales
        ├─ localizationsDelegates: GlobalMaterial/Widgets/Cupertino
        ├─ initialRoute: RouteName.splash
        ├─ initialBinding: BindingsBuilder
        │     ├─ Get.put(AuthController,         permanent: true)  [FIREBASE]
        │     ├─ Get.put(SettingsController,      permanent: true)
        │     ├─ Get.put(UserProfileController,   permanent: true)
        │     ├─ Get.put(TodayController,         permanent: true)
        │     ├─ Get.put(HistoryController,       permanent: true)
        │     ├─ Get.put(ReminderController,      permanent: true)
        │     └─ Get.put(AvatarController,        permanent: true)
        └─ getPages: AppPages.pages

SplashScreen.initState → _navigate()
  └─ Future.wait([
        Future.delayed(2 seconds),
        _waitForProfile(UserProfileController)   ← polls isLoading, max 20s
     ])
  └─ SharedPreferences.getBool('onboarding_completed')
        ├─ true  → Get.offAllNamed(RouteName.home)
        └─ false → Get.offAllNamed(RouteName.onboardingLanguage)
```

---

## 4. Locale Detection (`_ensureLocaleConfigured`)

```dart
void _ensureLocaleConfigured() {
  // 1. Try saved language pref
  final saved = PrefAssist.getString(PrefConst.language);
  if (saved.isNotEmpty) {
    final locale = _parseLocale(saved);
    if (CommLocalize.supportedLocales.contains(locale)) {
      CommLocalize.setAppLocale(locale);
      return;
    }
  }
  // 2. Device system locale → find best supported match
  final systemLocale = CommLocalize.getSystemLocale();
  final best = CommLocalize.supportedLocales
      .firstWhere((l) => l.languageCode == systemLocale?.languageCode,
                  orElse: () => const Locale('en', 'US'));
  CommLocalize.setAppLocale(best);
  // 3. Persist so next boot skips detection
  PrefAssist.setString(PrefConst.language, _encodeLocale(best));
}
```

---

## 5. Routing

### `lib/values/route_name.dart` — string constants only
```dart
class RouteName {
  static const String splash                  = '/splash';
  static const String onboardingLanguage      = '/onboarding/language';
  static const String welcome                 = '/welcome';
  static const String onboardingGender        = '/onboarding/gender';
  static const String onboardingHeight        = '/onboarding/height';
  static const String onboardingWeight        = '/onboarding/weight';
  static const String onboardingWeather       = '/onboarding/weather';
  static const String onboardingWakeup        = '/onboarding/wakeup';
  static const String onboardingNap           = '/onboarding/nap';
  static const String onboardingBedtime       = '/onboarding/bedtime';
  static const String onboardingBuildingSchedule = '/onboarding/building';
  static const String onboardingDailyGoal     = '/onboarding/daily-goal';
  static const String home                    = '/home';
  static const String addDrink                = '/add_drink';
  static const String reminderSettings        = '/reminder_settings';
  static const String streak                  = '/streak';
  static const String avatarSelection         = '/avatar_selection';
  static const String chatBot                 = '/chat_bot';
  static const String themeSelection          = '/theme_selection';
  static const String languageSelection       = '/language_selection';
  static const String feedback                = '/feedback';
  static const String premium                 = '/premium';
  static const String widgetPreview           = '/widget_preview';
}
```

### `lib/values/app_pages.dart` — GetPage list
```dart
class AppPages {
  AppPages._();

  static final pages = [
    // No binding — splash uses only permanent controllers
    GetPage(name: RouteName.splash, page: () => const SplashScreen()),

    // Route-scoped controller created once, shared across all onboarding steps
    GetPage(
      name: RouteName.welcome,
      page: () => const WelcomeScreen(),
      binding: BindingsBuilder(() => Get.put(OnboardingController())),
    ),
    GetPage(name: RouteName.onboardingGender,  page: () => const GenderScreen()),
    GetPage(name: RouteName.onboardingHeight,  page: () => const HeightScreen()),
    // ... more onboarding steps (no binding — reuse OnboardingController)

    // Home: fade-in from splash to avoid hard cut
    GetPage(
      name: RouteName.home,
      page: () => const HomeScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 350),
    ),

    // Chat: own controller, disposed on back
    GetPage(
      name: RouteName.chatBot,
      page: () => const ChatBotScreen(),
      binding: BindingsBuilder(() => Get.put(ChatController())),
    ),
  ];
}
```

### Navigation primitives
```dart
Get.toNamed(RouteName.addDrink);          // push
Get.back();                               // pop
Get.offNamed(RouteName.nextStep);         // replace current
Get.offAllNamed(RouteName.home);          // clear stack + push
```

---

## 6. Controller Lifecycle Patterns

### Permanent vs route-scoped

| Scope | How registered | Lifetime |
|---|---|---|
| Permanent | `Get.put(..., permanent: true)` in `initialBinding` | Forever |
| Route-scoped | `Get.put(...)` inside `GetPage.binding` | Until route popped |

### Standard controller shape
```dart
class FooController extends GetxController {
  static FooController get to => Get.find();  // convenience accessor

  // Reactive state
  final RxString value    = ''.obs;
  final RxBool isLoading  = false.obs;
  final RxList<Foo> items = <Foo>[].obs;

  // Workers — must be disposed
  late final Worker _worker;
  Worker? _optionalWorker;

  @override
  void onInit() {
    super.onInit();
    _worker = ever(someOtherCtrl.value, (_) => react());
    loadData();
  }

  @override
  void onClose() {
    _worker.dispose();
    _optionalWorker?.dispose();
    super.onClose();
  }
}
```

### Cross-controller access
```dart
// Permanent controllers — always safe
final settings = Get.find<SettingsController>();

// Route-scoped — guard before access
if (Get.isRegistered<HistoryController>()) {
  Get.find<HistoryController>().loadData();
}

// React to another controller's reactive value
_worker = ever(
  Get.find<UserProfileController>().profile,
  (_) => loadTodayData(),
);
```

### App lifecycle observation
```dart
// On the controller that needs foreground/background events (TodayController)
class TodayController extends GetxController with WidgetsBindingObserver {
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }
}
```

---

## 7. Database Layer

### Singleton helper — `lib/services/storage/database_helper.dart`
```dart
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;
  Completer<Database>? _initCompleter;  // blocks concurrent init

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<Database>();
    try {
      _database = await _initDatabase();
      _initCompleter!.complete(_database!);
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      '$dbPath/${DbSchema.dbName}',
      version: DbSchema.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(DbSchema.createUserProfile);
    await db.execute(DbSchema.createDrinkRecord);
    await db.execute(DbSchema.createDrinkRecordIndex);
    await db.execute(DbSchema.createDailySummary);
    await db.execute(DbSchema.createReminderSchedule);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(DbSchema.migrationV2AddOriginalAmount);
      await db.execute(DbSchema.migrationV2BackfillOriginalAmount);
    }
    // if (oldVersion < 3) { await db.execute(DbSchema.migrationV3...); }
  }
}
```

### Schema — `lib/services/storage/schema.dart`
```dart
class DbSchema {
  static const String dbName    = 'app_name.db';     // change per app
  static const int    dbVersion = 2;                  // bump on every schema change

  // Table name constants (referenced in both DDL and query code)
  static const String tableUserProfile      = 'user_profile';
  static const String tableDrinkRecord      = 'drink_record';
  static const String tableDailySummary     = 'daily_summary';
  static const String tableReminderSchedule = 'reminder_schedule';

  // CREATE TABLE statements
  static const String createUserProfile = '''
    CREATE TABLE $tableUserProfile (
      id                INTEGER PRIMARY KEY DEFAULT 1,
      gender            TEXT    NOT NULL DEFAULT 'female',
      weight            REAL    NOT NULL DEFAULT 60,
      weight_unit       TEXT    NOT NULL DEFAULT 'kg',
      height            REAL    NOT NULL DEFAULT 165,
      height_unit       TEXT    NOT NULL DEFAULT 'cm',
      age               INTEGER NOT NULL DEFAULT 25,
      wake_up_time      TEXT    NOT NULL DEFAULT '07:00',
      bed_time          TEXT    NOT NULL DEFAULT '22:00',
      daily_goal_ml     INTEGER NOT NULL DEFAULT 2000,
      volume_unit       TEXT    NOT NULL DEFAULT 'ml',
      activity_level    TEXT    NOT NULL DEFAULT 'sedentary',
      weather_condition TEXT    NOT NULL DEFAULT 'normal',
      created_at        TEXT    NOT NULL,
      updated_at        TEXT    NOT NULL
    )
  ''';

  static const String createDrinkRecord = '''
    CREATE TABLE $tableDrinkRecord (
      id                 INTEGER PRIMARY KEY AUTOINCREMENT,
      amount_ml          INTEGER NOT NULL,
      original_amount_ml INTEGER NOT NULL DEFAULT 0,
      drink_type         TEXT    NOT NULL DEFAULT 'water',
      timestamp          TEXT    NOT NULL,
      date_key           TEXT    NOT NULL      -- 'YYYY-MM-DD', indexed for fast day queries
    )
  ''';

  static const String createDrinkRecordIndex =
    'CREATE INDEX idx_drink_record_date_key ON $tableDrinkRecord (date_key)';

  static const String createDailySummary = '''
    CREATE TABLE $tableDailySummary (
      date_key    TEXT    PRIMARY KEY,
      total_ml    INTEGER NOT NULL DEFAULT 0,
      goal_ml     INTEGER NOT NULL DEFAULT 2000,
      drink_count INTEGER NOT NULL DEFAULT 0,
      updated_at  TEXT    NOT NULL
    )
  ''';

  static const String createReminderSchedule = '''
    CREATE TABLE $tableReminderSchedule (
      id               INTEGER PRIMARY KEY AUTOINCREMENT,
      mode             TEXT    NOT NULL DEFAULT 'standard',
      time             TEXT    NOT NULL DEFAULT '08:00',
      label            TEXT    NOT NULL DEFAULT '',
      enabled          INTEGER NOT NULL DEFAULT 1,
      interval_minutes INTEGER NOT NULL DEFAULT 90,
      repeat_days      TEXT    NOT NULL DEFAULT '1,2,3,4,5'
    )
  ''';

  // Migrations — additive only, never DROP in migration
  static const String migrationV2AddOriginalAmount =
    'ALTER TABLE $tableDrinkRecord ADD COLUMN original_amount_ml INTEGER NOT NULL DEFAULT 0';

  static const String migrationV2BackfillOriginalAmount =
    'UPDATE $tableDrinkRecord SET original_amount_ml = amount_ml WHERE original_amount_ml = 0';
}
```

### Data model pattern
```dart
class DrinkRecord {
  final int?     id;
  final int      amountMl;
  final double   originalAmountMl;   // volume in user's unit before hydration factor
  final String   drinkType;
  final DateTime timestamp;
  final String   dateKey;            // 'YYYY-MM-DD' — derived at construction

  DrinkRecord({
    this.id,
    required this.amountMl,
    double? originalAmountMl,
    this.drinkType = 'water',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now(),
       originalAmountMl = originalAmountMl ?? amountMl.toDouble(),
       dateKey = AppDateUtils.formatDateKey(timestamp ?? DateTime.now());

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'amount_ml':          amountMl,
    'original_amount_ml': originalAmountMl.round(),
    'drink_type':         drinkType,
    'timestamp':          timestamp.toIso8601String(),
    'date_key':           dateKey,
  };

  factory DrinkRecord.fromMap(Map<String, dynamic> m) => DrinkRecord(
    id:               m['id'] as int?,
    amountMl:         m['amount_ml'] as int,
    originalAmountMl: (m['original_amount_ml'] as int?)?.toDouble(),
    drinkType:        m['drink_type'] as String? ?? 'water',
    timestamp:        DateTime.parse(m['timestamp'] as String),
  );

  DrinkRecord copyWith({int? amountMl, String? drinkType}) => DrinkRecord(
    id: id, amountMl: amountMl ?? this.amountMl,
    drinkType: drinkType ?? this.drinkType, timestamp: timestamp,
  );
}
```

---

## 8. Repository Layer

Pure CRUD — one method per DB operation, no business logic, no transactions.

```dart
class DrinkRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> insertDrinkRecord(DrinkRecord r) async {
    try {
      final db = await _db.database;
      return db.insert(DbSchema.tableDrinkRecord, r.toMap());
    } catch (e, st) {
      debugPrint('DrinkRepository.insert: $e\n$st');
      rethrow;
    }
  }

  Future<int> updateDrinkRecord(DrinkRecord r) async {
    final db = await _db.database;
    return db.update(DbSchema.tableDrinkRecord, r.toMap(),
        where: 'id = ?', whereArgs: [r.id]);
  }

  Future<int> deleteDrinkRecord(int id) async {
    final db = await _db.database;
    return db.delete(DbSchema.tableDrinkRecord,
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DrinkRecord>> getDrinkRecordsByDate(String dateKey) async {
    final db = await _db.database;
    final rows = await db.query(DbSchema.tableDrinkRecord,
        where: 'date_key = ?', whereArgs: [dateKey], orderBy: 'timestamp DESC');
    return rows.map(DrinkRecord.fromMap).toList();
  }

  Future<int> getTotalMlByDate(String dateKey) async {
    final db = await _db.database;
    final r = await db.rawQuery(
      'SELECT SUM(amount_ml) as total FROM ${DbSchema.tableDrinkRecord} WHERE date_key = ?',
      [dateKey],
    );
    return (r.first['total'] as int?) ?? 0;
  }

  Future<void> upsertDailySummary(DailySummary s) async {
    final db = await _db.database;
    await db.insert(DbSchema.tableDailySummary, s.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
```

---

## 9. Service Layer (Application)

Business logic: transactions, derived aggregates, cross-repo coordination.

```dart
class DrinkDataService {
  final DrinkRepository _repo = DrinkRepository();
  final DatabaseHelper  _db   = DatabaseHelper();

  // Transactional: insert record + update summary atomically
  Future<int> addDrink({
    required int amountMl,
    double? originalAmountMl,
    String drinkType = 'water',
    int goalMl = 2000,
  }) async {
    final record = DrinkRecord(
      amountMl: amountMl,
      originalAmountMl: originalAmountMl,
      drinkType: drinkType,
    );
    final db = await _db.database;
    late int id;
    await db.transaction((txn) async {
      id = await txn.insert(DbSchema.tableDrinkRecord, record.toMap());
      await _updateDailySummaryInTxn(txn, record.dateKey, goalMl);
    });
    return id;
  }

  // Summary is always consistent with records because it's updated in same txn
  Future<void> _updateDailySummaryInTxn(
    Transaction txn, String dateKey, int goalMl,
  ) async {
    final totalResult = await txn.rawQuery(
      'SELECT SUM(amount_ml) as t, COUNT(*) as c '
      'FROM ${DbSchema.tableDrinkRecord} WHERE date_key = ?',
      [dateKey],
    );
    final total  = (totalResult.first['t'] as int?) ?? 0;
    final count  = (totalResult.first['c'] as int?) ?? 0;
    final summary = DailySummary(
      dateKey: dateKey, totalMl: total, goalMl: goalMl, drinkCount: count,
    );
    await txn.insert(DbSchema.tableDailySummary, summary.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<DrinkRecord>> getTodayRecords() =>
      _repo.getDrinkRecordsByDate(AppDateUtils.todayKey());

  Future<int> getTodayTotal() =>
      _repo.getTotalMlByDate(AppDateUtils.todayKey());

  Future<int> deleteRecord(int id, String dateKey, int goalMl) async {
    final db = await _db.database;
    late int result;
    await db.transaction((txn) async {
      result = await txn.delete(DbSchema.tableDrinkRecord,
          where: 'id = ?', whereArgs: [id]);
      await _updateDailySummaryInTxn(txn, dateKey, goalMl);
    });
    return result;
  }
}
```

---

## 10. SharedPreferences Pattern

### `lib/configs/pref_const.dart` — all keys, no literals elsewhere
```dart
class PrefConst {
  // App state
  static const String onboardingCompleted = 'onboarding_completed';
  static const String isRated             = 'is_rated';

  // Settings
  static const String themeMode       = 'theme_mode';
  static const String language        = 'language';
  static const String volumeUnit      = 'volume_unit';
  static const String weightUnit      = 'weight_unit';
  static const String heightUnit      = 'height_unit';

  // Reminder
  static const String reminderEnabled   = 'reminder_enabled';
  static const String reminderMode      = 'reminder_mode';      // standard | interval | custom
  static const String intervalMinutes   = 'interval_minutes';
  static const String sleepTimeStart    = 'sleep_time_start';   // bed time
  static const String sleepTimeEnd      = 'sleep_time_end';     // wake time
  static const String napEnabled        = 'nap_enabled';
  static const String napTimeStart      = 'nap_time_start';
  static const String napTimeEnd        = 'nap_time_end';
  static const String repeatDays        = 'repeat_days';         // '1,2,3,4,5'
  static const String soundEffect       = 'sound_effect';
  static const String soundEffectEnabled = 'sound_effect_enabled';
  static const String vibrateEnabled    = 'vibrate_enabled';
  static const String smartNotification = 'smart_notification';

  // Notification
  static const String notificationOngoingEnabled = 'notification_ongoing_enabled';
  static const String isFullScreenIntentEnabled  = 'is_full_screen_intent_enabled';

  // AI Chat quota
  static const String chatFreeUsedDate  = 'chat_free_used_date';
  static const String chatFreeUsedCount = 'chat_free_used_count';

  // Feature / UX tracking
  static const String selectedAvatar        = 'selected_avatar';
  static const String coachMarkHomeSeen     = 'coach_mark_home_seen';
  static const String streakDialogShownDate = 'streak_dialog_shown_date';

  // Health Connect (Android)
  static const String healthConnectEnabled = 'health_connect_enabled';
}
```

### `lib/configs/pref_defaults.dart` — all defaults
```dart
class PrefDefaults {
  static const bool   onboardingCompleted    = false;
  static const String themeMode              = 'system';
  static const bool   reminderEnabled        = true;
  static const String reminderMode           = 'standard';
  static const String soundEffect            = 'mixkit_water_bubble';
  static const bool   vibrateEnabled         = true;
  static const bool   soundEffectEnabled     = true;
  static const bool   smartNotification      = true;
  static const String volumeUnit             = 'ml';
  static const String weightUnit             = 'kg';
  static const String heightUnit             = 'cm';
  static const String language               = 'en';
  static const int    intervalMinutes        = 90;
  static const String sleepTimeStart         = '23:00';  // bed
  static const String sleepTimeEnd           = '06:00';  // wake
  static const bool   napEnabled             = true;
  static const String napTimeStart           = '12:30';
  static const String napTimeEnd             = '13:30';
  static const String repeatDays             = '1,2,3,4,5';
  static const int    maxReminderAlarms      = 500;
  static const bool   notificationOngoingEnabled = true;
  static const bool   healthConnectEnabled   = false;
  static const String selectedAvatar         = 'human_1';
  static const int    chatFreeQuestionsPerDay = 5;
}
```

### Usage pattern in controllers
```dart
final prefs = await SharedPreferences.getInstance();
// Always: key from PrefConst + fallback from PrefDefaults
final enabled = prefs.getBool(PrefConst.reminderEnabled) ?? PrefDefaults.reminderEnabled;
await prefs.setString(PrefConst.language, newLang);
```

---

## 11. Onboarding Flow

### Screen sequence
```
/onboarding/language     → pick language  (LanguagesController, route-scoped)
/welcome                 → intro          ← OnboardingController created here
/onboarding/gender       ┐
/onboarding/height       │  same OnboardingController persists across these
/onboarding/weight       │  (GetX keeps it alive because it's already put)
/onboarding/weather      │
/onboarding/wakeup       │
/onboarding/nap          │
/onboarding/bedtime      ┘
/onboarding/building     → request notification permission, build schedule
/onboarding/daily-goal   → show result → Get.offAllNamed('/home')
```

### OnboardingController pattern
```dart
class OnboardingController extends GetxController {
  static const int totalSteps = 7;
  final RxInt currentStep = 0.obs;

  // Collected fields — all Rx for live display in step headers
  final RxString gender     = ''.obs;
  final RxDouble height     = 165.0.obs;
  final RxString heightUnit = 'cm'.obs;
  final RxDouble weight     = 60.0.obs;
  final RxString weightUnit = 'kg'.obs;
  final RxString wakeUpTime = '07:00'.obs;
  final RxString bedTime    = '22:00'.obs;
  final RxBool   napEnabled = true.obs;
  final RxString napStart   = '12:30'.obs;
  final RxString napEnd     = '13:30'.obs;
  final RxInt    intervalMinutes = 90.obs;
  final RxInt    dailyGoalMl    = 2000.obs;
  final RxString volumeUnit     = 'ml'.obs;

  void nextStep() { if (currentStep.value < totalSteps) currentStep.value++; }
  void prevStep() { if (currentStep.value > 0) currentStep.value--; }

  // Convert values in-place when user toggles unit
  void updateWeightUnit(String unit) {
    if (unit == weightUnit.value) return;
    weight.value = unit == 'kg' ? weight.value / 2.20462 : weight.value * 2.20462;
    weightUnit.value = unit;
  }

  // Called from BuildingScheduleScreen — completes the entire flow
  Future<void> completeOnboarding() async {
    try {
      // 1. Save profile to DB
      final profile = UserProfile(gender: gender.value, weight: weight.value, ...);
      await Get.find<UserProfileController>().saveProfile(profile);

      // 2. Sync units to SettingsController + SharedPreferences
      await Get.find<SettingsController>().setVolumeUnit(volumeUnit.value);
      await Get.find<SettingsController>().setWeightUnit(weightUnit.value);

      // 3. Write all prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PrefConst.onboardingCompleted, true);
      await prefs.setBool(PrefConst.reminderEnabled, true);
      await prefs.setString(PrefConst.reminderMode, ReminderMode.interval.name);
      await prefs.setInt(PrefConst.intervalMinutes, intervalMinutes.value);
      await prefs.setString(PrefConst.sleepTimeStart, bedTime.value);
      await prefs.setString(PrefConst.sleepTimeEnd, wakeUpTime.value);
      await prefs.setBool(PrefConst.napEnabled, napEnabled.value);
      await prefs.setString(PrefConst.napTimeStart, napStart.value);
      await prefs.setString(PrefConst.napTimeEnd, napEnd.value);
      await prefs.setBool(PrefConst.notificationOngoingEnabled, true);
      await prefs.setString(PrefConst.soundEffect, PrefDefaults.soundEffect);
      await prefs.setBool(PrefConst.vibrateEnabled, true);

      // 4. Start notifications
      await NotificationChannel.startOngoingNotification();
      await NotificationChannel.syncReminders(_deriveScheduleTimes());

      // 5. Show result then home
      Get.offAllNamed(RouteName.onboardingDailyGoal);
      // daily-goal screen calls: Get.offAllNamed(RouteName.home)
    } catch (e, st) {
      debugPrint('completeOnboarding failed: $e\n$st');
      Get.snackbar('Error', 'Setup failed. Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // Derive reminder times from wake/bed/interval for native scheduling
  List<Map<String, int>> _deriveScheduleTimes() {
    final wake = _parseHHmm(wakeUpTime.value);
    final bed  = _parseHHmm(bedTime.value);
    final interval = intervalMinutes.value;
    // Generate times from wake to bed at interval spacing
    final times = <Map<String, int>>[];
    var current = wake;
    final end = bed > wake ? bed : bed + 24 * 60;
    while (current <= end) {
      times.add({'hour': (current ~/ 60) % 24, 'minute': current % 60});
      current += interval;
    }
    return times.isEmpty ? [{'hour': 8, 'minute': 0}] : times;
  }
}
```

---

## 12. Home Screen — IndexedStack + Lazy Tabs

```dart
class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); }

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Deferred build — only tab 0 (Today) builds on entry.
  // Other tabs build on first tap to avoid painting 4 screens at once.
  final Set<int> _built = {0};

  final _screens = const [
    TodayScreen(),            // tab 0
    HistoryScreen(),          // tab 1
    ReminderSettingsPage(),   // tab 2
    SettingsScreen(),         // tab 3
  ];

  void _select(int index) {
    setState(() {
      _currentIndex = index;
      _built.add(index);  // mark as built so IndexedStack renders it
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,   // content draws under the nav bar gradient
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (var i = 0; i < _screens.length; i++)
            _built.contains(i) ? _screens[i] : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}
```

**Key points:**
- `IndexedStack` keeps all built tabs alive (state preserved on switch)
- `_built` set defers renders until first visit — prevents launch jank
- `extendBody: true` + `SafeArea` in each tab = nav bar overlap is content-controlled

---

## 13. Today Screen Data Flow

```
TodayController.onInit()
  ├─ addObserver(this)              ← lifecycle
  ├─ _profileWorker = ever(profile) ← re-run on goal/profile change
  └─ _checkPendingWaterAndReload()
        ├─ _checkHealthPrivacyPolicyRequest()   ← HealthConnect can request policy view
        ├─ date change since last load? → loadTodayData()
        ├─ checkPendingAddWater()     ← drinks from notification button
        │     └─ pending? → addDrink(...) for each → loadTodayData()
        └─ else → loadTodayData()

loadTodayData()
  ├─ drinkService.getTodayTotal()     → currentIntakeMl
  ├─ drinkService.getTodayRecords()   → todayRecords
  ├─ _loadStreak()                    → streakDays (60-day lookback)
  ├─ _updateNextReminder()            → nextReminderTime, reminderCountdown
  ├─ updateWidget()                   → push to native home screen widget
  ├─ _ensureOngoingNotification()     → start persistent status bar item
  └─ _ensureDailyNotifications()      → sync alarm schedule to native

addDrink(amountMl, drinkType)
  ├─ drinkService.addDrink()          → returns recordId
  ├─ HealthSyncService.onDrinkAdded() ← opt-in mirror to HealthConnect
  ├─ loadTodayData()
  ├─ _refreshHistoryIfNeeded()        ← update HistoryController if registered
  └─ goalReachedEvent++ if crossed    ← triggers celebration widget
```

---

## 14. Native Platform Channels

### Pattern — static class wrapping MethodChannel
```dart
class NotificationChannel {
  static const _ch = MethodChannel('com.company.appname/notifications');

  static Future<void> syncReminders(List<Map<String, int>> times) async {
    try {
      await _ch.invokeMethod('syncReminders', {'times': times});
    } on PlatformException catch (e) {
      debugPrint('NotificationChannel.syncReminders: $e');
    }
  }

  static Future<void> cancelDailyNotification() async =>
    _ch.invokeMethod('cancelDailyNotification');

  static Future<void> startOngoingNotification() async =>
    _ch.invokeMethod('startOngoingNotification');

  static Future<void> updateOngoingData({
    required int currentMl,
    required int goalMl,
    required String lastDrinkText,
  }) async {
    try {
      await _ch.invokeMethod('updateOngoingData', {
        'currentMl': currentMl, 'goalMl': goalMl, 'lastDrinkText': lastDrinkText,
      });
    } catch (_) {}
  }

  // Returns drinks added via notification action button (consumed on read)
  static Future<List<Map>> checkPendingAddWater() async {
    final result = await _ch.invokeMethod('checkPendingAddWater');
    return (result as List?)?.cast<Map>() ?? [];
  }

  // HealthConnect can start app to show privacy policy — check and consume
  static Future<bool> consumeShowPrivacyPolicy() async {
    return (await _ch.invokeMethod<bool>('consumeShowPrivacyPolicy')) ?? false;
  }
}
```

### Widget channel
```dart
class WidgetChannel {
  static const _ch = MethodChannel('com.company.appname/widget');

  static Future<void> updateWidgetData({
    required int currentMl,
    required int goalMl,
    required String nextReminderTime,
    required List<Map<String, String>> recentDrinks,
    required String volumeUnit,
    required Map<String, String> labels,  // pre-localized in Dart
  }) async {
    try {
      await _ch.invokeMethod('updateWidget', {
        'currentMl': currentMl, 'goalMl': goalMl,
        'nextReminderTime': nextReminderTime,
        'recentDrinks': recentDrinks,
        'volumeUnit': volumeUnit,
        'labels': labels,  // native never touches localization system
      });
    } catch (_) {}  // widget is best-effort, never crash app
  }
}
```

---

## 15. Reminder System

### Three reminder modes

| Mode | Description |
|---|---|
| `interval` | Generate times every N minutes from wake to bed; skip nap window |
| `standard` | Fixed labeled slots (morning/afternoon/night) toggled individually |
| `custom` | User-added arbitrary times stored in `reminder_schedule` table |

### Sync flow — called on every data/settings change
```dart
Future<void> syncNativeSchedule() async {
  if (!enabled.value) {
    await NotificationChannel.cancelDailyNotification();
    return;
  }
  final times = _buildScheduleTimes();  // List<{hour, minute}>
  await NotificationChannel.syncReminders(times);
  // Native side replaces ALL alarms atomically
}
```

### Interval time generation with overnight handling
```dart
List<Map<String, int>> _buildIntervalTimes() {
  final wakeTotal = _parseHHmm(sleepTimeEnd.value);   // wake time in minutes
  final bedTotal  = _parseHHmm(sleepTimeStart.value); // bed time in minutes
  final interval  = intervalMinutes.value;

  final times = <Map<String, int>>[];
  var current = wakeTotal;
  // If bed < wake (e.g. wake 6am, bed 1am next day), extend past midnight
  final end = bedTotal > wakeTotal ? bedTotal : bedTotal + 24 * 60;

  while (current <= end && times.length < PrefDefaults.maxReminderAlarms) {
    final minuteOfDay = current % (24 * 60);
    if (!_inNapWindow(minuteOfDay)) {
      times.add({'hour': (current ~/ 60) % 24, 'minute': current % 60});
    }
    current += interval;
  }
  return times;
}
```

---

## 16. Localization

### Boot-time load
```dart
// main.dart, inside onBindingInitialized
await CommLocalize.loadTranslations("lib/xml_strings", "strings.xml");
```

### XML format
```xml
<!-- lib/xml_strings/values/strings.xml -->
<resources>
  <string name="add_drink">Add drink</string>
  <string name="remaining_hm">%1$s h %2$s m remaining</string>
  <string name="today">Today</string>
</resources>
```

### Usage
```dart
'add_drink'.tr
'remaining_hm'.trParams({'args1': h.toString(), 'args2': m.toString()})
```

### pubspec.yaml — register every locale folder as asset
```yaml
flutter:
  assets:
    - lib/xml_strings/values/
    - lib/xml_strings/values-vi/
    - lib/xml_strings/values-zh-rCN/
    - lib/xml_strings/values-ar/
    # ... one entry per locale folder
```

### Language change at runtime
```dart
CommLocalize.setAppLocale(newLocale);
Get.updateLocale(newLocale);
await prefs.setString(PrefConst.language, _encodeLocale(newLocale));
```

---

## 17. Firebase Authentication `[FIREBASE]`

Remove this section + firebase_* deps when app has no Firebase.

```dart
class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final FirebaseAuth _auth         = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final Rx<User?> user             = Rx<User?>(null);
  final RxBool isLoading           = false.obs;

  // Guard: isAnonymous=true when signed in for AI quota only
  // "isLoggedIn" means real account (shows profile UI, logout button)
  bool get isLoggedIn => user.value != null && !(user.value!.isAnonymous);
  String get displayName => user.value?.displayName ?? '';
  String get email       => user.value?.email ?? '';
  String? get photoUrl   => user.value?.photoURL;

  @override
  void onInit() {
    super.onInit();
    user.bindStream(_auth.authStateChanges()); // reactive — auto-updates
  }

  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;
      final auth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: auth.accessToken, idToken: auth.idToken,
      );
      await _auth.signInWithCredential(cred);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    isLoading.value = true;
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } finally {
      isLoading.value = false;
    }
  }
}
```

---

## 18. AI Chat Integration

### Config
```dart
// lib/configs/ai_gateway_config.dart
class AiGatewayConfig {
  static final Uri chatEndpoint  = Uri.parse('https://your-gateway.com/v1/chat');
  static const int maxPromptChars = 2000;
  static const int maxHistoryTurns = 20;
  static const Duration timeout   = Duration(seconds: 30);
}
```

### Service — streaming SSE
```dart
class AiChatService {
  // Streaming: yields partial cards as they arrive
  Stream<AiChatEvent> sendStream(List<ChatMessage> history) async* {
    final token = await _getFirebaseToken();        // [FIREBASE]
    final request = http.Request('POST', AiGatewayConfig.chatEndpoint);
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Content-Type']  = 'application/json';
    request.body = jsonEncode({'messages': history.map((m) => m.toJson()).toList()});
    final response = await request.send().timeout(AiGatewayConfig.timeout);
    if (response.statusCode == 401) {
      // Token expired — force refresh once
      final fresh = await _getFirebaseToken(forceRefresh: true);
      throw AiChatException(AiChatException.codeAuth);
    }
    if (response.statusCode != 200) {
      throw AiChatException(AiChatException.codeBadResponse);
    }
    await for (final line in response.stream.transform(utf8.decoder).transform(LineSplitter())) {
      if (!line.startsWith('data: ')) continue;
      final data = jsonDecode(line.substring(6));
      yield AiChatEvent.fromJson(data);
    }
  }
}

class AiChatException implements Exception {
  static const String codeNetwork    = 'network_unreachable';
  static const String codeAuth       = 'auth_failed';
  static const String codeBadResponse = 'bad_response';
  final String code;
  final bool retryable;
  final int? retryAfterSeconds;
  final String? rateScope;  // 'minute' | 'day'
  const AiChatException(this.code, {this.retryable = false,
      this.retryAfterSeconds, this.rateScope, String detail = ''});
}
```

### Quota — per-day free limit (no server, just prefs)
```dart
class ChatQuotaService {
  static const int perDay = 5;

  Future<int> remainingToday() async {
    final prefs = await SharedPreferences.getInstance();
    final usedDate  = prefs.getString(PrefConst.chatFreeUsedDate) ?? '';
    final usedCount = prefs.getInt(PrefConst.chatFreeUsedCount) ?? 0;
    if (usedDate != AppDateUtils.todayKey()) return perDay;  // new day
    return (perDay - usedCount).clamp(0, perDay);
  }

  Future<int> consume() async {
    final prefs   = await SharedPreferences.getInstance();
    final today   = AppDateUtils.todayKey();
    final stored  = prefs.getString(PrefConst.chatFreeUsedDate) ?? '';
    final count   = stored == today ? (prefs.getInt(PrefConst.chatFreeUsedCount) ?? 0) : 0;
    final newCount = count + 1;
    await prefs.setString(PrefConst.chatFreeUsedDate, today);
    await prefs.setInt(PrefConst.chatFreeUsedCount, newCount);
    return (perDay - newCount).clamp(0, perDay);
  }
}
```

### ChatController — streaming UI pattern
```dart
class ChatController extends GetxController {
  final RxList<ChatMessage> messages   = <ChatMessage>[].obs;
  final RxBool isSending   = false.obs;
  final RxBool isStreaming  = false.obs;
  final RxInt  freeRemaining = ChatQuotaService.perDay.obs;

  static const Duration _frameInterval = Duration(milliseconds: 50); // ~20fps

  @override
  void onInit() { super.onInit(); refreshQuota(); }

  @override
  void onClose() { _service.dispose(); super.onClose(); }

  Future<void> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || isSending.value) return;
    if (freeRemaining.value <= 0) { await refreshQuota(); if (freeRemaining.value <= 0) return; }
    final capped = text.length > AiGatewayConfig.maxPromptChars
        ? text.substring(0, AiGatewayConfig.maxPromptChars) : text;
    messages.add(ChatMessage.user(capped));
    await _request();
  }

  Future<void> _request() async {
    isSending.value = true; isStreaming.value = false;
    int? index; var lastPaint = DateTime.fromMillisecondsSinceEpoch(0);
    try {
      await for (final event in _service.sendStream(messages)) {
        final isFirst = index == null;
        if (!isFirst && DateTime.now().difference(lastPaint) < _frameInterval) continue;
        lastPaint = DateTime.now();
        final bubble = ChatMessage.assistant(event.partial, card: event.card);
        if (isFirst) { index = messages.length; messages.add(bubble); isStreaming.value = true; }
        else { messages[index!] = bubble; }
        if (event.done) break;
      }
      freeRemaining.value = await _quota.consume();
    } on AiChatException catch (e) {
      final error = ChatMessage.assistant(_messageFor(e), errorCode: e.code);
      if (index == null) messages.add(error); else messages[index!] = error;
    } finally {
      isStreaming.value = false; isSending.value = false;
    }
  }
}
```

---

## 19. Theming

### `lib/values/app_theme.dart`
```dart
class AppTheme {
  // Dark (pinned — the only active theme)
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    fontFamily: 'PlusJakartaSans',
    brightness: Brightness.dark,
    colorSchemeSeed: AppColors.primary,
    scaffoldBackgroundColor: AppColors.gradientBgStart,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBg, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
    ),
  );

  // Light (available, not currently pinned)
  static ThemeData get light => ThemeData(/* ... */);
}
```

---

## 20. Date Key Convention

All date-based queries use `'YYYY-MM-DD'` string — not timestamps, not integers.

```dart
class AppDateUtils {
  static String todayKey() => formatDateKey(DateTime.now());

  static String formatDateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}
```

- Models store `dateKey` derived from `timestamp` **at construction time**
- DB column `date_key TEXT NOT NULL` with `CREATE INDEX` on it
- Queries use `WHERE date_key = ?` — faster than parsing ISO strings

---

## 21. Streak Calculation

No separate streak table — computed from `daily_summary` on demand.

```dart
Future<void> _loadStreak() async {
  final today = DateTime.now();
  final summaries = await _drinkService.getSummariesBetween(
    AppDateUtils.formatDateKey(today.subtract(const Duration(days: 60))),
    AppDateUtils.formatDateKey(today),
  );
  summaries.sort((a, b) => b.dateKey.compareTo(a.dateKey));  // newest first

  int streak = 0;
  var checkDate = today;
  for (final summary in summaries) {
    if (summary.dateKey != AppDateUtils.formatDateKey(checkDate)) break; // gap
    if (summary.totalMl <= 0) break;                                      // no intake
    streak++;
    checkDate = checkDate.subtract(const Duration(days: 1));
  }
  streakDays.value = streak;
}
```

---

## 22. Unit Conversion

All conversions in `lib/utils/unit_converter.dart`:

```dart
class UnitConverter {
  // Volume
  static double mlToOz(double ml)   => ml * 0.033814;
  static double ozToMl(double oz)   => oz / 0.033814;

  // Weight
  static double kgToLb(double kg)   => kg * 2.20462;
  static double lbToKg(double lb)   => lb / 2.20462;

  // Height
  static double cmToIn(double cm)   => cm / 2.54;
  static double inToCm(double inch) => inch * 2.54;

  // Time format
  static bool deviceUses24h() { /* MediaQuery/intl check */ }
  static String formatTime(String hhmm) {
    if (deviceUses24h()) return hhmm;
    // Convert HH:mm to h:mm AM/PM
  }
}
```

Onboarding converts value in-place when unit toggles (`updateWeightUnit`, `updateHeightUnit`, `updateVolumeUnit`), storing the canonical unit beside the converted value.

---

## 23. Common UI Components

| Component | Pattern |
|---|---|
| `PrimaryButton` | Full-width CTA, loading spinner, disabled state |
| `PrimaryBottomSheet` | Draggable modal bottom sheet, consistent padding + handle |
| `PrimaryDialog` | Alert/confirm dialog wrapper |
| `WheelPicker` | CupertinoPicker-style number/option wheel |
| `RulerPicker` | Horizontal sliding ruler for continuous values |
| `CircularTimePicker` | Analog clock face time selector |
| `ToggleSelector` | Segmented control (2–4 options) |
| `SelectableOptionTile` | List item with radio/check selection state |
| `CustomSwitch` | Styled toggle (not system-default) |
| `ProgressRing` | Circular arc showing progress % |
| `StaggerReveal` | Staggered entry animation for list items |
| `CoachMark` | First-run tooltip overlay with backdrop |
| `AppTouchable` | Ripple wrapper with `HitTestBehavior.opaque` (fix for gesture dead zones) |
| `OnboardingProgressBar` | Segmented step indicator |
| `OnboardingStepHeader` | Title + subtitle block for onboarding screens |
| `BottomSafeArea` | `SafeArea(top: false)` shorthand |
| `AuthLoadingOverlay` | Full-screen loading overlay for auth ops |

---

## 24. Coding Conventions

| Rule | Detail |
|---|---|
| Reactive state | `RxType` with `.obs`; read `.value`; mutate `.value =` |
| Reactive UI | `Obx(() => ...)` for small subtrees; `GetBuilder` for explicit rebuilds |
| Data models | `copyWith` — never mutate in place |
| Date storage | ISO8601 for `timestamp`; `'YYYY-MM-DD'` for `date_key` |
| Error handling | Repository: `try/catch + debugPrint + rethrow`. Controller: catch → set error state |
| Pref keys | Always `PrefConst.*` + `PrefDefaults.*` — never raw strings |
| Route strings | Always `RouteName.*` — never `/home` literals in controllers |
| Colors | Always `AppColors.*` — never `Color(0xFF...)` in widgets |
| Controller init | Never call `Get.find` in constructor — only in `onInit` or later |
| Optional access | `Get.isRegistered<T>()` before `Get.find<T>()` for route-scoped controllers |
| Workers | Always `dispose()` in `onClose()` |
| Widget update | Always best-effort (`try/catch`) — never let widget channel crash the app |
| Linting | `package:flutter_lints/flutter.yaml` |

---

## 25. pubspec.yaml

```yaml
name: waternudge           # snake_case — change per new app
version: 1.0.0+1

environment:
  sdk: ^3.9.2

dependencies:
  flutter: { sdk: flutter }
  get:
  sqflite: ^2.4.2
  fl_chart: ^0.70.2
  flutter_svg: ^2.2.3
  intl: ^0.20.2
  permission_handler: ^12.0.1
  path_provider: ^2.1.5
  share_plus: ^12.0.1
  fluttertoast: ^9.0.0
  in_app_review: ^2.0.10
  shared_preferences: ^2.3.5
  country_flags: ^3.0.0
  device_region: ^1.1.1
  flutter_slidable: ^3.1.1
  dsp_base: { path: ./dsp_base }   # local shared package
  firebase_core: any               # [FIREBASE]
  firebase_auth: any               # [FIREBASE]
  cloud_firestore: any             # [FIREBASE]
  google_sign_in: ^6.2.2           # [FIREBASE]
  package_info_plus: any
  audioplayers: ^6.6.0
  image_picker: ^1.1.2
  http: ^1.6.0
  health: ^13.3.1
  url_launcher: ^6.3.2

dev_dependencies:
  flutter_launcher_icons: ^0.14.4
  flutter_test: { sdk: flutter }
  pedantic_mono: any

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/png/logo_app_v4.png"
  min_sdk_android: 21
  remove_alpha_ios: true

flutter:
  uses-material-design: true
  assets:
    - assets/images/webp/
    - assets/images/svg/
    - assets/images/png/
    - assets/images/cup_type/
    - assets/images/menu/
    - assets/audio/
    - lib/xml_strings/values/
    - lib/xml_strings/values-vi/
    - lib/xml_strings/values-zh-rCN/
    # ... one entry per locale folder
  fonts:
    - family: PlusJakartaSans
      fonts:
        - { asset: assets/fonts/PlusJakartaSans-Regular.ttf,  weight: 400 }
        - { asset: assets/fonts/PlusJakartaSans-Medium.ttf,   weight: 500 }
        - { asset: assets/fonts/PlusJakartaSans-SemiBold.ttf, weight: 600 }
        - { asset: assets/fonts/PlusJakartaSans-Bold.ttf,     weight: 700 }
        - { asset: assets/fonts/PlusJakartaSans-Italic.ttf,   style: italic }
```

---

## 26. Common Commands

```bash
flutter run                           # run on connected device
flutter test                          # all tests
flutter test test/widget_test.dart    # single file
flutter analyze                       # static analysis
dart format .                         # format all
flutter pub get                       # after pubspec changes
flutter build apk --release           # Android release APK
flutter build ios --release           # iOS release
dart run flutter_launcher_icons       # regenerate app icons after changing image
```

---

## 27. Checklist When Starting New App

| Item | Action |
|---|---|
| `pubspec.yaml: name` | Change from `waternudge` to new app name |
| Package imports | Update all `package:waternudge/...` → `package:newapp/...` |
| `DbSchema.dbName` | New `.db` filename |
| `DbSchema.dbVersion` | Reset to 1 (new DB, no existing users to migrate) |
| DB tables | Replace domain tables; keep singleton + Completer + migration pattern |
| Data models | Replace `DrinkRecord`, `DailySummary` with your entities |
| `UserProfile` fields | Adapt to your user data |
| `WaterCalculation` | Replace with your domain formula |
| `PrefConst` / `PrefDefaults` | Update keys/defaults for your settings |
| `RouteName` + `AppPages` | Replace with your screens and bindings |
| `OnboardingController` fields | Replace collected data fields for your flow |
| Onboarding steps | Add/remove `GetPage` entries + controller fields |
| `MethodChannel` names | `com.company.appname/notifications` + `/widget` — match native |
| `AiGatewayConfig.chatEndpoint` | Point to your gateway |
| `AppColors` + `AppTheme` | Adapt palette to new brand |
| Font family | Replace PlusJakartaSans if using different font |
| `xml_strings/values/strings.xml` | Replace with your string keys |
| `initialBinding` in `main.dart` | Update permanent controllers list |
| Firebase config `[FIREBASE]` | New `google-services.json` + `GoogleService-Info.plist` |
| App icons | Replace `logo_app_v4.png`, run `dart run flutter_launcher_icons` |
| Notification channel ID | Match new `MethodChannel` name in native code |
| Bundle ID / package name | Update in `android/app/build.gradle` + `ios/Runner.xcodeproj` |
