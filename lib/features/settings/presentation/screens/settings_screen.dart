import 'package:flutter/material.dart';
import 'package:saf/saf.dart';
import '../../../../core/services/storage_settings_service.dart';
import '../../../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageSettingsService _storageService = StorageSettingsService();
  final Saf _saf = Saf();

  String _displayPath = '';
  bool _isCustom = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDirectoryInfo();
  }

  Future<void> _loadDirectoryInfo() async {
    setState(() => _isLoading = true);
    final display = await _storageService.getDisplayPath();
    final customUri = await _storageService.getCustomUri();

    setState(() {
      _displayPath = display;
      _isCustom = customUri != null;
      _isLoading = false;
    });
  }

  Future<void> _pickFolder() async {
    try {
      // Native SAF picker with persistent read/write permissions
      final dir = await _saf.pickDirectory();
      if (dir == null) return; // User canceled

      // Extract a clean folder name from URI (e.g. "primary:PrismPdf" -> "PrismPdf")
      final decoded = Uri.decodeFull(dir.uri.toString());
      final folderName = decoded.contains(':')
          ? decoded.split(':').last.replaceAll('/', '')
          : 'Selected Folder';

      await _storageService.setCustomDirectory(
        uri: dir.uri.toString(),
        displayName: folderName.isEmpty ? 'Custom Folder' : folderName,
      );

      await _loadDirectoryInfo();

      if (!mounted) return;
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
    await _loadDirectoryInfo();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reset to default app storage')),
    );
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
                    const Text(
                      'Storage Preferences',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.surfaceBorder,
                          width: 1.5,
                        ),
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
                                          ? 'Custom Folder'
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
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.surfaceBorder),
                            ),
                            child: Text(
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
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height:
                                      52, // Increased from 48 to allow proper line clearance
                                  child: ElevatedButton.icon(
                                    onPressed: _pickFolder,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primarySoft,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 0,
                                      ), // Clears clipping padding
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        height: 1.2, // Clean baseline alignment
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.drive_file_move_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Change Folder'),
                                  ),
                                ),
                              ),
                              if (_isCustom) ...[
                                const SizedBox(width: 10),
                                SizedBox(
                                  height: 52, // Matched height
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
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
