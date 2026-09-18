import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageSettingsService {
  static const String _keyCustomUri = 'custom_save_directory_uri';
  static const String _keyDisplayName = 'custom_save_display_name';

  /// Returns the human-readable folder name for the UI.
  Future<String> getDisplayPath() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyDisplayName);
    if (name != null && name.isNotEmpty) {
      return name;
    }
    final defaultDir = await getApplicationDocumentsDirectory();
    return defaultDir.path;
  }

  /// Returns the saved SAF URI string, if any.
  Future<String?> getCustomUri() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCustomUri);
  }

  /// Saves the picked directory URI and a sanitized label.
  Future<void> setCustomDirectory({
    required String uri,
    required String displayName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomUri, uri);
    await prefs.setString(_keyDisplayName, displayName);
  }

  /// Resets back to internal app storage.
  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCustomUri);
    await prefs.remove(_keyDisplayName);
  }
}
