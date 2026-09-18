import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_update_info.dart';

class GitHubUpdateService {
  // Replace with your GitHub username and repo name
  final String owner;
  final String repo;

  GitHubUpdateService({required this.owner, required this.repo});

  /// Checks if a newer release exists on GitHub.
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final url = Uri.parse(
        'https://api.github.com/repos/$owner/$repo/releases/latest',
      );
      final response = await http.get(
        url,
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final remoteTag = (data['tag_name'] as String? ?? '')
          .replaceFirst('v', '')
          .trim();
      final body =
          data['body'] as String? ?? 'Bug fixes and visual improvements.';

      final assets = data['assets'] as List<dynamic>? ?? [];
      // Find the asset ending with .apk
      final apkAsset = assets.firstWhere(
        (asset) => (asset['name'] as String).toLowerCase().endsWith('.apk'),
        orElse: () => null,
      );

      if (apkAsset == null) return null;

      final downloadUrl = apkAsset['browser_download_url'] as String;
      final size = apkAsset['size'] as int? ?? 0;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.trim();

      if (_isNewer(remoteTag, currentVersion)) {
        return AppUpdateInfo(
          version: remoteTag,
          downloadUrl: downloadUrl,
          releaseNotes: body,
          apkSizeBytes: size,
        );
      }
    } catch (_) {
      // Network failure or repo is private / rate limited
    }
    return null;
  }

  /// Compares semantic versioning (e.g. 1.0.2 vs 1.0.1)
  bool _isNewer(String remote, String current) {
    List<int> parse(String v) =>
        v.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final rParts = parse(remote);
    final cParts = parse(current);

    final len = rParts.length > cParts.length ? rParts.length : cParts.length;
    for (int i = 0; i < len; i++) {
      final r = i < rParts.length ? rParts[i] : 0;
      final c = i < cParts.length ? cParts[i] : 0;
      if (r > c) return true;
      if (r < c) return false;
    }
    return false;
  }

  /// Downloads the APK into cache and reports progress from 0.0 to 1.0
  Future<File> downloadApk({
    required String downloadUrl,
    required String fileName,
    required void Function(double progress, int receivedBytes, int totalBytes)
    onProgress,
  }) async {
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(downloadUrl));
    final response = await client.send(request);

    final totalBytes = response.contentLength ?? 0;
    int receivedBytes = 0;

    final tempDir = await getTemporaryDirectory();
    final apkFile = File('${tempDir.path}/$fileName');
    final sink = apkFile.openWrite();

    await response.stream.listen((chunk) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0) {
        onProgress(receivedBytes / totalBytes, receivedBytes, totalBytes);
      }
    }, cancelOnError: true).asFuture();

    await sink.flush();
    await sink.close();
    client.close();

    return apkFile;
  }
}
