/// All SharedPreferences keys. Never use raw key strings elsewhere.
class PrefConst {
  PrefConst._();

  // App flow
  static const String onboardingCompleted = 'onboarding_completed';
  static const String setupCompleted = 'setup_completed';
  static const String setupStep = 'setup_step';
  static const String permissionDeferred = 'permission_deferred';
  // One rescan after DB v2 so existing songs get their genre tag.
  static const String genreBackfillDone = 'genre_backfill_done';

  // Appearance (locale: PrefComm.CONFIGURED_LOCALE_BY_USER in dsp_base)
  static const String themeMode = 'theme_mode'; // system | light | dark
  static const String accentColor = 'accent_color'; // accent key
  static const String playerBackground = 'player_background'; // blur | solid
  static const String screenTransitions = 'screen_transitions';

  // Playback modes
  static const String repeatMode = 'repeat_mode'; // off | all | one
  static const String shuffleMode = 'shuffle_mode'; // off | on

  // Equalizer
  static const String eqEnabled = 'eq_enabled';
  static const String eqPreset = 'eq_preset';
  static const String eqCustomGains = 'eq_custom_gains'; // csv of dB per band
  static const String eqBassStrength = 'eq_bass_strength'; // 0..1000
  static const String eqVirtualizerStrength = 'eq_virtualizer_strength';

  // Headphones
  static const String headphonePauseOnDisconnect =
      'headphone_pause_on_disconnect';
  static const String headphoneResumeOnConnect = 'headphone_resume_on_connect';
  static const String headphoneButtonsEnabled = 'headphone_buttons_enabled';

  // Library
  static const String songSort = 'song_sort';

  // Sleep timer
  static const String sleepDeadline = 'sleep_deadline'; // epoch ms, UTC
  static const String sleepWaitTrackEnd = 'sleep_wait_track_end';
  static const String sleepLastMinutes = 'sleep_last_minutes';

  // Rate app
  static const String rateLastPromptAt = 'rate_last_prompt_at';
  static const String rateStoreOpenedAt = 'rate_store_opened_at';

  // Search
  static const String searchHistory = 'search_history';
}
