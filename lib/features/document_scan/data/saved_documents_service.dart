import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/saved_pdf_item.dart';

class SavedDocumentsService {
  /// Scans internal app storage for all compiled PDF files.
  Future<List<SavedPdfItem>> getInternalPdfs() async {
    final docDir = await getApplicationDocumentsDirectory();
    final entities = docDir.listSync(followLinks: false);

    final List<SavedPdfItem> pdfs = [];

    for (final entity in entities) {
      if (entity is File && p.extension(entity.path).toLowerCase() == '.pdf') {
        try {
          final stat = entity.statSync();
          final fileName = p.basename(entity.path);

          pdfs.add(
            SavedPdfItem(
              id: 'sandbox_${stat.modified.millisecondsSinceEpoch}_$fileName',
              name: fileName,
              storageType: 'sandbox',
              displayLocation: 'Internal Storage',
              pathOrUri: entity.path,
              sizeBytes: stat.size,
              modifiedDate: stat.modified,
            ),
          );
        } catch (_) {
          // Skip file if inaccessible
        }
      }
    }

    // Sort newest to oldest
    pdfs.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));
    return pdfs;
  }

  /// Deletes a PDF file from internal storage.
  Future<bool> deleteInternalPdf(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
