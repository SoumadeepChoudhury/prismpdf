import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageSettingsService {
  static const String _keyCustomUri = 'custom_save_directory_uri';
  static const String _keyDisplayName = 'custom_save_display_name';

  Future<SharedPreferences> _getSyncedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs;
  }

  /// Returns the human-readable folder name for the UI.
  Future<String> getDisplayPath() async {
    final prefs = await _getSyncedPrefs();
    final name = prefs.getString(_keyDisplayName);
    if (name != null && name.trim().isNotEmpty) {
      return name;
    }
    final defaultDir = await getApplicationDocumentsDirectory();
    return defaultDir.path;
  }

  /// Returns the saved SAF URI string, if any.
  Future<String?> getCustomUri() async {
    final prefs = await _getSyncedPrefs();
    final uri = prefs.getString(_keyCustomUri);
    return (uri != null && uri.trim().isNotEmpty) ? uri : null;
  }

  /// Saves the picked directory URI and a sanitized label permanently.
  Future<void> setCustomDirectory({
    required String uri,
    required String displayName,
  }) async {
    final prefs = await _getSyncedPrefs();
    await prefs.setString(_keyCustomUri, uri);
    await prefs.setString(_keyDisplayName, displayName);
  }

  /// Resets back to internal app storage.
  Future<void> resetToDefault() async {
    final prefs = await _getSyncedPrefs();
    await prefs.remove(_keyCustomUri);
    await prefs.remove(_keyDisplayName);
  }
}
