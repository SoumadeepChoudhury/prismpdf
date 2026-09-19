import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageSettingsService {
  static const String _keyCustomUri = 'custom_save_directory_uri';
  static const String _keyDisplayName = 'custom_save_display_name';

  /// Converts an Android SAF URI into a physical POSIX filesystem path.
  static String resolveToNativePath(String rawPath) {
    if (!rawPath.startsWith('content://')) {
      return rawPath;
    }

    final decoded = Uri.decodeFull(rawPath);

    // Matches volume prefix and folder (e.g. primary:QuickPDF)
    final match = RegExp(
      r'(?:tree|document)/([^:]+):?(.*)$',
    ).firstMatch(decoded);
    if (match != null) {
      final storageId = match.group(1);
      var subPath = match.group(2) ?? '';

      // Strip trailing document tokens if present
      if (subPath.contains('/document/')) {
        subPath = subPath.split('/document/').first;
      }

      if (storageId == 'primary') {
        final resolved = '/storage/emulated/0/$subPath';
        return resolved.replaceAll(RegExp(r'/+'), '/');
      } else {
        final resolved = '/storage/$storageId/$subPath';
        return resolved.replaceAll(RegExp(r'/+'), '/');
      }
    }

    return rawPath;
  }

  /// Forces disk-sync reload so updates don't read stale cache
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
