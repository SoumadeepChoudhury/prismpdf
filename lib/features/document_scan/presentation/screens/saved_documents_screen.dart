import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:prismpdf/core/services/saf_helper_service.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/storage_settings_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/file_formatter.dart';
import '../../data/document_history_service.dart';
import '../../models/saved_pdf_item.dart';

class SavedDocumentsScreen extends StatefulWidget {
  const SavedDocumentsScreen({super.key});

  @override
  State<SavedDocumentsScreen> createState() => _SavedDocumentsScreenState();
}

class _SavedDocumentsScreenState extends State<SavedDocumentsScreen> {
  final DocumentHistoryService _historyService = DocumentHistoryService();
  final StorageSettingsService _storageService = StorageSettingsService();

  List<SavedPdfItem> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    final docs = await _historyService.getAllDocuments();
    setState(() {
      _documents = docs;
      _isLoading = false;
    });
  }

  Future<void> _openPdf(SavedPdfItem item) async {
    try {
      String openPath;

      if (!item.isCustom) {
        openPath = item.pathOrUri;
      } else {
        final customUri = await _storageService.getCustomUri();
        final cachedPath = await SafHelperService.copySafFileToCache(
          treeUri: customUri,
          fileName: item.name,
          documentUri: item.pathOrUri.startsWith('content://')
              ? item.pathOrUri
              : null,
        );

        if (cachedPath != null && cachedPath.isNotEmpty) {
          openPath = cachedPath;
        } else {
          // Fallback: Launch Document URI via Android Intent
          final intent = AndroidIntent(
            action: 'android.intent.action.VIEW',
            data: item.pathOrUri,
            type: 'application/pdf',
            flags: <int>[
              Flag.FLAG_GRANT_READ_URI_PERMISSION,
              Flag.FLAG_ACTIVITY_NEW_TASK,
            ],
          );
          await intent.launch();
          return;
        }
      }

      final result = await OpenFilex.open(openPath, type: 'application/pdf');
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: ${result.message}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open document: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _sharePdf(SavedPdfItem item) async {
    try {
      String sharePath;

      if (!item.isCustom) {
        sharePath = item.pathOrUri;
      } else {
        // Stream out of SAF and into cache to bypass Scoped Storage EACCES
        final customUri = await _storageService.getCustomUri();
        final cachedPath = await SafHelperService.copySafFileToCache(
          treeUri: customUri,
          fileName: item.name,
          documentUri: item.pathOrUri.startsWith('content://')
              ? item.pathOrUri
              : null,
        );

        if (cachedPath == null || cachedPath.isEmpty) {
          throw Exception(
            'Unable to prepare file from custom folder for sharing.',
          );
        }
        sharePath = cachedPath;
      }

      await Share.shareXFiles([
        XFile(sharePath, mimeType: 'application/pdf'),
      ], text: 'QuickPDF: ${item.name}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(SavedPdfItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete PDF?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'This will permanently delete "${item.name}" from your ${item.isCustom ? "custom folder" : "device storage"}. This action cannot be undone.',
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final wasDeleted = await _historyService.deleteDocument(item);
      await _loadDocuments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasDeleted
                  ? 'Permanently deleted "${item.name}"'
                  : 'Removed "${item.name}" from library',
            ),
            backgroundColor: wasDeleted
                ? const Color(0xFF2E7D32)
                : AppTheme.primarySoft,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Saved Documents'),
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
              : _documents.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  itemCount: _documents.length,
                  itemBuilder: (context, index) =>
                      _buildDocumentCard(_documents[index]),
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: const Icon(
              Icons.picture_as_pdf_outlined,
              size: 48,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Documents Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'PDFs compiled with QuickPDF will appear here.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(SavedPdfItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceBorder),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _openPdf(item),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGlow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: AppTheme.primarySoft,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _openPdf(item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Location badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.isCustom
                              ? AppTheme.primarySoft.withOpacity(0.12)
                              : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.displayLocation,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: item.isCustom
                                ? AppTheme.primarySoft
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        FileFormatter.formatBytes(item.sizeBytes),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(item.modifiedDate),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.share_rounded,
              size: 18,
              color: AppTheme.textSecondary,
            ),
            tooltip: 'Share',
            onPressed: () => _sharePdf(item),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 19,
              color: Colors.redAccent,
            ),
            tooltip: 'Remove',
            onPressed: () => _confirmDelete(item),
          ),
        ],
      ),
    );
  }
}
