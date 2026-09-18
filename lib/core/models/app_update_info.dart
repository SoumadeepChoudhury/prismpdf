class AppUpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;
  final int apkSizeBytes;

  const AppUpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.apkSizeBytes,
  });
}
