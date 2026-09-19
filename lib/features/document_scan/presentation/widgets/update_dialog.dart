import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../../../../core/models/app_update_info.dart';
import '../../../../core/services/github_update_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/file_formatter.dart';

class UpdateModalSheet extends StatefulWidget {
  final AppUpdateInfo updateInfo;
  final GitHubUpdateService updateService;

  const UpdateModalSheet({
    super.key,
    required this.updateInfo,
    required this.updateService,
  });

  @override
  State<UpdateModalSheet> createState() => _UpdateModalSheetState();
}

class _UpdateModalSheetState extends State<UpdateModalSheet> {
  bool _isDownloading = false;
  double _progress = 0.0;
  int _receivedBytes = 0;
  String? _errorMessage;

  Future<void> _startDownloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
    });

    try {
      final fileName = 'QuickPDF_v${widget.updateInfo.version}.apk';
      final file = await widget.updateService.downloadApk(
        downloadUrl: widget.updateInfo.downloadUrl,
        fileName: fileName,
        onProgress: (progress, received, total) {
          setState(() {
            _progress = progress;
            _receivedBytes = received;
          });
        },
      );

      if (!mounted) return;

      // Launch native Android installer
      final result = await OpenFilex.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done && mounted) {
        setState(() {
          _errorMessage = 'Could not launch installer: ${result.message}';
          _isDownloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Download failed: $e';
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedTotal = FileFormatter.formatBytes(
      widget.updateInfo.apkSizeBytes,
    );
    final formattedReceived = FileFormatter.formatBytes(_receivedBytes);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGlow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primarySoft.withOpacity(0.3),
                  ),
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: AppTheme.primarySoft,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Available',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Version ${widget.updateInfo.version} • $formattedTotal',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primarySoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Changelog Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "WHAT'S NEW",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.updateInfo.releaseNotes.isEmpty
                      ? 'Performance improvements and bug fixes.'
                      : widget.updateInfo.releaseNotes,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
          if (_isDownloading) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 8,
                backgroundColor: AppTheme.surfaceLight,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primarySoft,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(_progress * 100).toInt()}% downloaded',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '$formattedReceived / $formattedTotal',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          if (!_isDownloading)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(
                          color: Color(0x1F000000),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Later'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _startDownloadAndInstall,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primarySoft,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Update Now'),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
