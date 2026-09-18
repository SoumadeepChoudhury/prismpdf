import 'dart:io';

class ScannedPage {
  final String id;
  final File file;
  final DateTime capturedAt;
  final int rotationAngle; // 0, 90, 180, 270

  const ScannedPage({
    required this.id,
    required this.file,
    required this.capturedAt,
    this.rotationAngle = 0,
  });

  ScannedPage copyWith({
    String? id,
    File? file,
    DateTime? capturedAt,
    int? rotationAngle,
  }) {
    return ScannedPage(
      id: id ?? this.id,
      file: file ?? this.file,
      capturedAt: capturedAt ?? this.capturedAt,
      rotationAngle: rotationAngle ?? this.rotationAngle,
    );
  }
}
