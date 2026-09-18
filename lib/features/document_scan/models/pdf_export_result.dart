import 'dart:io';
import 'dart:typed_data';

class PdfExportResult {
  final String fileName;
  final String savedLocationDisplay;
  final int byteSize;
  final Uint8List bytes;
  final File? localFile;

  const PdfExportResult({
    required this.fileName,
    required this.savedLocationDisplay,
    required this.byteSize,
    required this.bytes,
    this.localFile,
  });
}
