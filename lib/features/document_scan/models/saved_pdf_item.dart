class SavedPdfItem {
  final String id;
  final String name;
  final String storageType; // 'sandbox' or 'custom'
  final String displayLocation;
  final String pathOrUri;
  final int sizeBytes;
  final DateTime modifiedDate;

  const SavedPdfItem({
    required this.id,
    required this.name,
    required this.storageType,
    required this.displayLocation,
    required this.pathOrUri,
    required this.sizeBytes,
    required this.modifiedDate,
  });

  bool get isCustom => storageType == 'custom';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'storageType': storageType,
    'displayLocation': displayLocation,
    'pathOrUri': pathOrUri,
    'sizeBytes': sizeBytes,
    'modifiedDate': modifiedDate.toIso8601String(),
  };

  factory SavedPdfItem.fromJson(Map<String, dynamic> json) => SavedPdfItem(
    id: json['id'] as String,
    name: json['name'] as String,
    storageType: json['storageType'] as String? ?? 'sandbox',
    displayLocation: json['displayLocation'] as String? ?? 'Internal Storage',
    pathOrUri: json['pathOrUri'] as String,
    sizeBytes: json['sizeBytes'] as int? ?? 0,
    modifiedDate: DateTime.parse(json['modifiedDate'] as String),
  );
}
