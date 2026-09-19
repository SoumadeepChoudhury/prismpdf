import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import '../theme/app_theme.dart';

class CropService {
  final ImageCropper _cropper = ImageCropper();

  /// Opens the freehand cropper for a given image file.
  /// Returns the cropped [File], or null if canceled.
  Future<File?> cropImage(File imageFile) async {
    final croppedFile = await _cropper.cropImage(
      sourcePath: imageFile.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 95,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Document',
          toolbarColor: AppTheme.primarySoft,
          toolbarWidgetColor: Colors.white,
          statusBarColor: AppTheme.primarySoft,
          activeControlsWidgetColor: AppTheme.primarySoft,
          backgroundColor: AppTheme.backgroundLight,
          cropFrameColor: AppTheme.primarySoft,
          cropGridColor: AppTheme.primarySoft.withOpacity(0.5),
          cropFrameStrokeWidth: 2,
          cropGridStrokeWidth: 1,
          showCropGrid: true,
          // Unlocks unrestricted corner & border dragging
          lockAspectRatio: false,
          initAspectRatio: CropAspectRatioPreset.original,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ],
    );

    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }
}
