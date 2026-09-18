import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:saf/saf.dart';
import '../../../../core/services/storage_settings_service.dart';
import '../models/compression_preset.dart';
import '../models/pdf_export_result.dart';
import '../models/scanned_page.dart';
import 'image_compression_service.dart';

class PdfService {
  final ImageCompressionService _compressionService;
  final StorageSettingsService _storageService;
  final Saf _saf = Saf();

  PdfService({
    ImageCompressionService? compressionService,
    StorageSettingsService? storageService,
  }) : _compressionService = compressionService ?? ImageCompressionService(),
       _storageService = storageService ?? StorageSettingsService();

  Future<PdfExportResult> generatePdfFromPages({
    required List<ScannedPage> pages,
    CompressionPreset preset = CompressionPreset.balanced,
    String? customFileName,
  }) async {
    if (pages.isEmpty) {
      throw ArgumentError('Cannot generate PDF: page collection is empty.');
    }

    final doc = pw.Document();

    for (final page in pages) {
      final rawBytes = await page.file.readAsBytes();
      final Uint8List optimizedBytes = await _compressionService.compressBytes(
        rawBytes: rawBytes,
        preset: preset,
      );

      final image = pw.MemoryImage(optimizedBytes);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
            );
          },
        ),
      );
    }

    final Uint8List pdfBytes = await doc.save();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = customFileName != null && customFileName.trim().isNotEmpty
        ? '${customFileName.trim().replaceAll(RegExp(r'[^\w\s\.-]'), '_')}.pdf'
        : 'PrismPDF_$timestamp.pdf';

    final customUri = await _storageService.getCustomUri();

    // Case 1: Custom Folder Selected -> Save ONLY to the custom SAF folder
    if (customUri != null && customUri.isNotEmpty) {
      await _saf.writeFileBytes(
        customUri,
        fileName,
        'application/pdf',
        pdfBytes,
      );

      final displayFolder = await _storageService.getDisplayPath();

      return PdfExportResult(
        fileName: fileName,
        savedLocationDisplay: '$displayFolder/$fileName',
        byteSize: pdfBytes.lengthInBytes,
        bytes: pdfBytes,
        localFile: null,
      );
    }

    // Case 2: Default Selected -> Save ONLY to internal app documents
    final localDir = await getApplicationDocumentsDirectory();
    final localFilePath = p.join(localDir.path, fileName);
    final localPdfFile = File(localFilePath);
    await localPdfFile.writeAsBytes(pdfBytes);

    return PdfExportResult(
      fileName: fileName,
      savedLocationDisplay: localFilePath,
      byteSize: pdfBytes.lengthInBytes,
      bytes: pdfBytes,
      localFile: localPdfFile,
    );
  }
}
