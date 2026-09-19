import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SafHelperService {
  static const MethodChannel _channel = MethodChannel(
    'com.quickpdf.app/saf_helper',
  );

  /// Physically deletes a document from an external SAF folder using DocumentsContract.
  static Future<bool> deleteDocument({
    required String? treeUri,
    required String fileName,
    String? documentUri,
  }) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('deleteFile', {
        'treeUri': treeUri,
        'fileName': fileName,
        'documentUri': documentUri,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Native SAF delete error: $e');
      return false;
    }
  }
}
