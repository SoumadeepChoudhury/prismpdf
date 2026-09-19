import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:saf/saf.dart';
import '../../../../core/services/github_update_service.dart';
import '../../../../core/services/storage_settings_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../document_scan/presentation/widgets/update_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageSettingsService _storageService = StorageSettingsService();
  final Saf _saf = Saf();

  // Configure with your GitHub repository details
  final GitHubUpdateService _updateService = GitHubUpdateService(
    owner: 'SoumadeepChoudhury',
    repo: 'prismpdf',
  );

  String _displayPath = '';
  bool _isCustom = false;
  bool _isLoading = true;

  String _appVersion = '1.0.0';
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _openFolderInFileManager() async {
    final customUri = await _storageService.getCustomUri();

    if (customUri == null || customUri.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Default internal storage is sandboxed by Android. Choose a "Custom Folder" to browse it directly in Files.',
          ),
          backgroundColor: AppTheme.primarySoft,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    try {
      // 1. Match ONLY the base folder ID (e.g. 'primary%3APrismPdf' or 'primary:QuickPDF')
      // and ignore all subsequent /document/ or /tree/ garbage
      final idMatch = RegExp(
        r'(?:tree|document)/([^/]+)',
      ).firstMatch(customUri);
      final String folderId = idMatch != null
          ? idMatch.group(1)!
          : 'primary%3AQuickPDF';

      // 2. Build the pure Android Tree URI and Tree-Document URI
      final String cleanTreeUri =
          'content://com.android.externalstorage.documents/tree/$folderId';
      final String validDocumentUri = '$cleanTreeUri/document/$folderId';

      // 3. Heal SharedPreferences so the corrupted repeated string is wiped permanently
      final display = await _storageService.getDisplayPath();
      await _storageService.setCustomDirectory(
        uri: cleanTreeUri,
        displayName: display,
      );

      debugPrint('CLEAN URI LAUNCHED: $validDocumentUri');

      // 4. Fire the intent directly into that folder
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: validDocumentUri,
        type: 'vnd.android.document/directory',
        flags: <int>[
          Flag.FLAG_GRANT_READ_URI_PERMISSION,
          Flag.FLAG_GRANT_WRITE_URI_PERMISSION,
          Flag.FLAG_ACTIVITY_NEW_TASK,
          0x00000080, // FLAG_GRANT_PREFIX_URI_PERMISSION
        ],
      );

      await intent.launch();
    } catch (e) {
      debugPrint(
        'Primary intent failed ($e). Attempting fallback tree launch...',
      );

      // Fallback: If an OEM Files app rejects nested document routing, launch the clean tree root
      try {
        final idMatch = RegExp(
          r'(?:tree|document)/([^/]+)',
        ).firstMatch(customUri);
        final String folderId = idMatch != null
            ? idMatch.group(1)!
            : 'primary%3AQuickPDF';

        final fallbackIntent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data:
              'content://com.android.externalstorage.documents/tree/$folderId',
          flags: <int>[
            Flag.FLAG_GRANT_READ_URI_PERMISSION,
            Flag.FLAG_ACTIVITY_NEW_TASK,
          ],
        );
        await fallbackIntent.launch();
      } catch (fallbackError) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file manager: $fallbackError'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    final display = await _storageService.getDisplayPath();
    final customUri = await _storageService.getCustomUri();
    final packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      _displayPath = display;
      _isCustom = customUri != null;
      _appVersion = packageInfo.version;
      _isLoading = false;
    });
  }

  Future<void> _pickFolder() async {
    try {
      final dir = await _saf.pickDirectory();
      if (dir == null) return;

      final decoded = Uri.decodeFull(dir.uri.toString());
      final folderName = decoded.contains(':')
          ? decoded.split(':').last.replaceAll('/', '')
          : 'Selected Folder';

      await _storageService.setCustomDirectory(
        uri: dir.uri.toString(),
        displayName: folderName.isEmpty ? 'Custom Folder' : folderName,
      );

      final updatedPath = await _storageService.getDisplayPath();
      final customUri = await _storageService.getCustomUri();

      if (!mounted) return;
      setState(() {
        _displayPath = updatedPath;
        _isCustom = customUri != null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save location set to: $_displayPath'),
          backgroundColor: AppTheme.primarySoft,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to set directory: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _resetFolder() async {
    await _storageService.resetToDefault();
    final updatedPath = await _storageService.getDisplayPath();

    if (!mounted) return;
    setState(() {
      _displayPath = updatedPath;
      _isCustom = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reset to default app storage')),
    );
  }

  Future<void> _manualCheckForUpdates() async {
    if (_isCheckingUpdate) return;

    setState(() => _isCheckingUpdate = true);

    try {
      final updateInfo = await _updateService.checkForUpdate();

      if (!mounted) return;

      if (updateInfo != null) {
        // Show update download sheet
        showModalBottomSheet(
          context: context,
          isDismissible: false,
          enableDrag: false,
          backgroundColor: Colors.transparent,
          builder: (context) => UpdateModalSheet(
            updateInfo: updateInfo,
            updateService: _updateService,
          ),
        );
      } else {
        // Already on the latest version
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text('PrismPDF is up to date (v$_appVersion)'),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to connect to GitHub releases.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.gradientStart, AppTheme.gradientEnd],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primarySoft),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  children: [
                    // Storage Section
                    const Text(
                      'STORAGE PREFERENCES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildStorageCard(),

                    const SizedBox(height: 24),

                    // Updates Section
                    const Text(
                      'SOFTWARE UPDATES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildUpdatesCard(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStorageCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGlow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.folder_outlined,
                  color: AppTheme.primarySoft,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PDF Output Directory',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isCustom
                          ? 'Custom Selected Folder'
                          : 'Default Application Storage',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isCustom
                            ? AppTheme.primarySoft
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openFolderInFileManager,
              borderRadius: BorderRadius.circular(16),
              splashColor: AppTheme.primarySoft.withOpacity(0.08),
              highlightColor: AppTheme.primarySoft.withOpacity(0.04),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayPath,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isCustom
                                ? 'Tap to open in Files app'
                                : 'Sandboxed app storage (tap for details)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _isCustom
                                  ? AppTheme.primarySoft
                                  : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGlow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isCustom
                            ? Icons.open_in_new_rounded
                            : Icons.info_outline_rounded,
                        size: 18,
                        color: AppTheme.primarySoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _pickFolder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primarySoft,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    icon: const Icon(Icons.drive_file_move_rounded, size: 18),
                    label: const Text('Change Folder'),
                  ),
                ),
              ),
              if (_isCustom) ...[
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _resetFolder,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(
                        color: Color(0x1F000000),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGlow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: AppTheme.primarySoft,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GitHub Releases',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Installed Version: v$_appVersion',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _isCheckingUpdate ? null : _manualCheckForUpdates,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primarySoft,
                side: const BorderSide(color: AppTheme.primarySoft, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: _isCheckingUpdate
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primarySoft,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                _isCheckingUpdate
                    ? 'Checking for updates...'
                    : 'Check for Updates',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
