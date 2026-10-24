/// Static app configuration.
class AppConfig {
  AppConfig._();

  static const String appName = 'Muvik';
  static const String supportEmail = 'contact.support@asctechsoft.com';
  static const String androidPackage = 'com.asctechsoft.muvik';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackage';

  /// Muvik shows no ads yet. While false, startup runs only the Firebase part
  /// of dsp_base (no AdMob init, no GDPR/UMP consent form for EEA users). Turn
  /// it on together with real ad unit ids and the real AdMob app id in
  /// AndroidManifest.xml.
  static const bool adsEnabled = false;

  // Playback rules
  static const Duration previousRestartThreshold = Duration(seconds: 3);
  static const Duration qualifyingListen = Duration(seconds: 30);
  static const Duration snapshotThrottle = Duration(seconds: 5);
  static const Duration statsCheckpoint = Duration(seconds: 15);

  // Playlist
  static const int playlistNameMaxLength = 80;
  static const int playlistDescriptionMaxLength = 300;

  // Sleep timer
  static const int sleepMinMinutes = 1;
  static const int sleepMaxMinutes = 12 * 60;
  static const List<int> sleepPresets = [15, 30, 45, 60];

  // Rate prompt cooldown
  static const Duration ratePromptCooldown = Duration(days: 14);

  // Library scan
  static const int scanBatchSize = 300;
  static const int artworkCacheEntries = 150;
  static const int artworkSizePx = 256;

  // Search
  static const Duration searchDebounce = Duration(milliseconds: 250);
  static const int searchHistoryMax = 10;
}
