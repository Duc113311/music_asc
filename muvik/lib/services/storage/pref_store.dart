import 'package:dsp_base/convenience_imports.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Typed access to the SharedPreferences instance owned by dsp_base
/// [PrefAssist] (initialized by `commRunApp`). Callers always pass a key from
/// PrefConst and a default from PrefDefaults, so missing keys never fall back
/// to PrefAssist's implicit ''/0/false.
class PrefStore {
  PrefStore._();

  /// Idempotent; tests call it after `SharedPreferences.setMockInitialValues`.
  static Future<void> init() => PrefAssist.init();

  static SharedPreferences get _p {
    final p = PrefAssist.pref;
    if (p == null) {
      throw StateError('PrefStore.init() must complete before use');
    }
    return p;
  }

  static bool getBool(String key, bool fallback) => _p.getBool(key) ?? fallback;
  static int getInt(String key, int fallback) => _p.getInt(key) ?? fallback;
  static double getDouble(String key, double fallback) =>
      _p.getDouble(key) ?? fallback;
  static String getString(String key, String fallback) =>
      _p.getString(key) ?? fallback;
  static List<String> getStringList(String key, List<String> fallback) =>
      _p.getStringList(key) ?? fallback;

  static Future<void> setBool(String key, bool value) => _p.setBool(key, value);
  static Future<void> setInt(String key, int value) => _p.setInt(key, value);
  static Future<void> setDouble(String key, double value) =>
      _p.setDouble(key, value);
  static Future<void> setString(String key, String value) =>
      _p.setString(key, value);
  static Future<void> setStringList(String key, List<String> value) =>
      _p.setStringList(key, value);
  static Future<void> remove(String key) => _p.remove(key);
}
