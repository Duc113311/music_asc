/// Default value for every key in [PrefConst].
class PrefDefaults {
  PrefDefaults._();

  static const bool onboardingCompleted = false;
  static const bool setupCompleted = false;
  static const int setupStep = 0;
  static const bool permissionDeferred = false;

  static const String themeMode = 'system';
  static const String accentColor = 'lavender';

  static const String repeatMode = 'off';
  static const String shuffleMode = 'off';

  static const bool eqEnabled = false;
  static const String eqPreset = 'normal';
  static const String eqCustomGains = '';
  static const int eqBassStrength = 0;
  static const int eqVirtualizerStrength = 0;

  static const bool headphonePauseOnDisconnect = true;
  static const bool headphoneResumeOnConnect = false;
  static const bool headphoneButtonsEnabled = true;

  static const String songSort = 'title_asc';

  static const int sleepDeadline = 0;
  static const bool sleepWaitTrackEnd = false;
  static const int sleepLastMinutes = 30;

  static const int rateLastPromptAt = 0;
  static const int rateStoreOpenedAt = 0;

  static const List<String> searchHistory = [];
}
