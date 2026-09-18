import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/compression_preset.dart';

class ImageCompressionService {
  /// Compresses raw image bytes according to the provided [preset].
  Future<Uint8List> compressBytes({
    required Uint8List rawBytes,
    required CompressionPreset preset,
  }) async {
    final compressedBytes = await FlutterImageCompress.compressWithList(
      rawBytes,
      quality: preset.quality,
      minWidth: preset.maxDimension,
      minHeight: preset.maxDimension,
      format: CompressFormat.jpeg,
    );

    return compressedBytes;
  }
}
