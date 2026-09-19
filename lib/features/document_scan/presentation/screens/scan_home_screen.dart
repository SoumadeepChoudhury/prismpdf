import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prismpdf/core/services/crop_service.dart';
import 'package:prismpdf/core/services/github_update_service.dart';
import 'package:prismpdf/features/document_scan/models/pdf_export_result.dart';
import 'package:prismpdf/features/document_scan/presentation/screens/saved_documents_screen.dart';
import 'package:prismpdf/features/document_scan/presentation/widgets/update_dialog.dart';
import 'package:prismpdf/features/settings/presentation/screens/settings_screen.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/image_capture_service.dart';
import '../../data/pdf_service.dart';
import '../../models/scanned_page.dart';
import '../../models/compression_preset.dart';
import '../../../../core/utils/file_formatter.dart';
import '../widgets/compression_modal_sheet.dart';

class ScanHomeScreen extends StatefulWidget {
  const ScanHomeScreen({super.key});

  @override
  State<ScanHomeScreen> createState() => _ScanHomeScreenState();
}

class _ScanHomeScreenState extends State<ScanHomeScreen> {
  final ImageCaptureService _captureService = ImageCaptureService();
  final PdfService _pdfService = PdfService();

  final List<ScannedPage> _pages = [];
  bool _isExporting = false;

  final GitHubUpdateService _updateService = GitHubUpdateService(
    owner: 'SoumadeepChoudhury',
    repo: 'prismpdf',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForAppUpdate();
    });
  }

  // 1. Instantiate the service inside _ScanHomeScreenState:
  final CropService _cropService = CropService();

  // 2. Add the method to crop any specific page in the list:
  Future<void> _cropPage(int index) async {
    final originalPage = _pages[index];
    final croppedFile = await _cropService.cropImage(originalPage.file);

    if (croppedFile != null && mounted) {
      setState(() {
        _pages[index] = ScannedPage(
          id: originalPage.id,
          file: croppedFile,
          capturedAt: originalPage.capturedAt,
          rotationAngle: originalPage.rotationAngle,
        );
      });
    }
  }

  Future<void> _checkForAppUpdate() async {
    final updateInfo = await _updateService.checkForUpdate();
    if (updateInfo != null && mounted) {
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
    }
  }

  Future<void> _captureCamera() async {
    final page = await _captureService.captureFromCamera();
    if (page != null) {
      setState(() => _pages.add(page));
    }
  }

  Future<void> _pickGallery() async {
    final newPages = await _captureService.pickFromGallery();
    if (newPages.isNotEmpty) {
      setState(() => _pages.addAll(newPages));
    }
  }

  void _removePage(int index) {
    setState(() => _pages.removeAt(index));
  }

  void _openExportOptions() {
    if (_pages.isEmpty || _isExporting) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CompressionModalSheet(
        pageCount: _pages.length,
        onConfirm: (selectedPreset, fileName) =>
            _compilePdf(selectedPreset, fileName),
      ),
    );
  }

  Future<void> _compilePdf(CompressionPreset preset, String fileName) async {
    setState(() => _isExporting = true);

    try {
      final result = await _pdfService.generatePdfFromPages(
        pages: _pages,
        preset: preset,
        customFileName: fileName,
      );

      final formattedSize = FileFormatter.formatBytes(result.byteSize);

      if (!mounted) return;
      _showSuccessSheet(result, formattedSize);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showSuccessSheet(PdfExportResult result, String formattedSize) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
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
                      Icons.picture_as_pdf_rounded,
                      color: AppTheme.primarySoft,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Document Ready',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_pages.length} Pages',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primarySoft.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                formattedSize,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primarySoft,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DESTINATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.savedLocationDisplay,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            String sharePath;
                            if (result.localFile != null) {
                              sharePath = result.localFile!.path;
                            } else {
                              final tempDir = await getTemporaryDirectory();
                              final tempFile = File(
                                '${tempDir.path}/${result.fileName}',
                              );
                              await tempFile.writeAsBytes(result.bytes);
                              sharePath = tempFile.path;
                            }

                            await Share.shareXFiles([
                              XFile(sharePath, mimeType: 'application/pdf'),
                            ], text: 'Exported from QuickPDF');
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to share: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: const BorderSide(
                            color: Color(0x1F000000),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('Share'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            String targetPath;
                            if (result.localFile != null) {
                              targetPath = result.localFile!.path;
                            } else {
                              final tempDir = await getTemporaryDirectory();
                              final tempFile = File(
                                '${tempDir.path}/${result.fileName}',
                              );
                              await tempFile.writeAsBytes(result.bytes);
                              targetPath = tempFile.path;
                            }

                            final openResult = await OpenFilex.open(
                              targetPath,
                              type: 'application/pdf',
                            );

                            if (openResult.type != ResultType.done &&
                                context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not open file: ${openResult.message}',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error opening PDF: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primarySoft,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        icon: const Icon(Icons.visibility_rounded, size: 18),
                        label: const Text('Open PDF'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Prominent, soft pill Done button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.surfaceLight,
                    foregroundColor: AppTheme.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: Color(0x14000000),
                        width: 1,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPages = _pages.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent, // Keeps the root gradient visible
      extendBodyBehindAppBar: true, // Crucial for immersive gradient look
      appBar: AppBar(
        title: const Text('QuickPDF'),
        actions: [
          if (hasPages)
            TextButton(
              onPressed: () => setState(() => _pages.clear()),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: AppTheme.primarySoft,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(
              Icons.folder_copy_outlined,
              color: AppTheme.textPrimary,
            ),
            tooltip: 'Saved Documents',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedDocumentsScreen()),
              );
            },
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            icon: const Icon(
              Icons.settings_outlined,
              color: AppTheme.textPrimary,
            ),
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        // The root container defines the overall soft gradient look (Inspired by image_1.png)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.gradientStart, AppTheme.gradientEnd],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 20), // Top margin below App Bar
              Expanded(
                child: hasPages ? _buildPagesGrid() : _buildEmptyState(),
              ),
              _buildControlBar(hasPages),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.backgroundLight,
              border: Border.all(color: AppTheme.surfaceBorder, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: AppTheme.primaryGlow,
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.document_scanner_rounded, // Use soft icon style
              size: 52,
              color: AppTheme.primarySoft, // Coral color
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Ready for Your Scan',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Capture papers or select images to compile a PDF.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPagesGrid() {
    return ReorderableGridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.72,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          final movedPage = _pages.removeAt(oldIndex);
          _pages.insert(newIndex, movedPage);
        });
      },
      children: [
        for (int i = 0; i < _pages.length; i++) _buildPageCard(_pages[i], i),
      ],
    );
  }

  Widget _buildPageCard(ScannedPage page, int index) {
    return Stack(
      key: ValueKey(page.id), // Required by ReorderableGridView to track items
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.surfaceBorder, width: 1.5),
            image: DecorationImage(
              image: FileImage(page.file),
              fit: BoxFit.cover,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                spreadRadius: 0,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        // Dynamic Page Number Badge
        Positioned(
          left: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.primarySoft,
              ),
            ),
          ),
        ),
        // Remove Action
        Positioned(
          right: 10,
          top: 10,
          child: GestureDetector(
            onTap: () => _removePage(index),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ),
        // Crop button
        Positioned(
          right: 10,
          bottom: 10,
          child: GestureDetector(
            onTap: () => _cropPage(index),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight.withOpacity(0.92),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.surfaceBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.crop_rotate_rounded,
                size: 18,
                color: AppTheme.primarySoft,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlBar(bool hasPages) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 28),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(32),
        ), // Softer container
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            spreadRadius: 2,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickGallery,
                  icon: const Icon(
                    Icons.photo_library_outlined,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  label: const Text('Gallery'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _captureCamera,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGlow, // Softer background
                    foregroundColor: AppTheme.primarySoft, // Coral text
                    elevation: 0, // No shadow for camera button
                  ),
                  icon: const Icon(Icons.camera_alt_rounded, size: 20),
                  label: const Text('Camera'),
                ),
              ),
            ],
          ),
          if (hasPages) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 56, // Slightly taller button
              child: ElevatedButton(
                onPressed: _isExporting ? null : _openExportOptions,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      24,
                    ), // Max rounded button
                  ),
                ),
                child: _isExporting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Export PDF (${_pages.length} Pages)'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
