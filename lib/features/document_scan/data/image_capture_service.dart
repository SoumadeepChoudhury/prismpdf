import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/scanned_page.dart';

class ImageCaptureService {
  final ImagePicker _picker = ImagePicker();

  /// Captures a single document page using the camera.
  Future<ScannedPage?> captureFromCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
    );

    if (photo == null) return null;

    return ScannedPage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      file: File(photo.path),
      capturedAt: DateTime.now(),
    );
  }

  /// Imports one or more document photos directly from the gallery.
  Future<List<ScannedPage>> pickFromGallery() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 92);

    if (images.isEmpty) return [];

    return images.map((img) {
      return ScannedPage(
        id: '${DateTime.now().microsecondsSinceEpoch}_${img.name}',
        file: File(img.path),
        capturedAt: DateTime.now(),
      );
    }).toList();
  }
}
