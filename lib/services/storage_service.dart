import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<int> getInt(String key, int fallback) async =>
      await _prefs.getInt(key) ?? fallback;

  Future<bool> getBool(String key, bool fallback) async =>
      await _prefs.getBool(key) ?? fallback;

  Future<String?> getString(String key) => _prefs.getString(key);
  Future<List<String>> getStringList(String key) async =>
      await _prefs.getStringList(key) ?? <String>[];

  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  Future<void> setString(String key, String value) => _prefs.setString(key, value);
  Future<void> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);
}
