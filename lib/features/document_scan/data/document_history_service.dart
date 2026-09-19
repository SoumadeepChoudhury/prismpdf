import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:prismpdf/core/services/saf_helper_service.dart';
import 'package:prismpdf/core/services/storage_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_pdf_item.dart';

class DocumentHistoryService {
  static const String _keyDocumentHistory = 'quickpdf_saved_documents_ledger';
  final StorageSettingsService _storageService = StorageSettingsService();

  Future<SharedPreferences> _getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs;
  }

  /// Physically deletes the PDF file from disk and removes it from the ledger.
  Future<bool> deleteDocument(SavedPdfItem item) async {
    bool fileDeleted = false;

    if (item.storageType == 'sandbox') {
      // Internal sandbox: File.delete() works directly here
      try {
        final file = File(item.pathOrUri);
        if (await file.exists()) {
          await file.delete();
          fileDeleted = true;
        }
      } catch (e) {
        debugPrint('Sandbox delete error: $e');
      }
    } else {
      // Custom SAF folder: Call native DocumentsContract
      final customUri = await _storageService.getCustomUri();
      fileDeleted = await SafHelperService.deleteDocument(
        treeUri: customUri,
        fileName: item.name,
        documentUri: item.pathOrUri.startsWith('content://')
            ? item.pathOrUri
            : null,
      );

      // Fallback: Attempt POSIX deletion if storage access allows
      if (!fileDeleted && customUri != null) {
        try {
          final resolvedFolder = StorageSettingsService.resolveToNativePath(
            customUri,
          );
          final file = File('$resolvedFolder/${item.name}');
          if (await file.exists()) {
            await file.delete();
            fileDeleted = true;
          }
        } catch (_) {}
      }
    }

    // Remove from the history ledger
    final prefs = await _getPrefs();
    final items = await getAllDocuments();
    items.removeWhere((doc) => doc.id == item.id || doc.name == item.name);

    final encodedList = items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_keyDocumentHistory, encodedList);

    return fileDeleted;
  }

  /// Registers a newly created PDF into the tracked registry.
  Future<void> registerDocument({
    required String fileName,
    required String storageType,
    required String displayLocation,
    required String pathOrUri,
    required int sizeBytes,
  }) async {
    final prefs = await _getPrefs();
    final items = await getAllDocuments();

    final newItem = SavedPdfItem(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      name: fileName,
      storageType: storageType,
      displayLocation: displayLocation,
      pathOrUri: pathOrUri,
      sizeBytes: sizeBytes,
      modifiedDate: DateTime.now(),
    );

    // Keep unique by path/URI and place newest first
    items.removeWhere(
      (item) => item.pathOrUri == pathOrUri || item.name == fileName,
    );
    items.insert(0, newItem);

    final encodedList = items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_keyDocumentHistory, encodedList);
  }

  /// Retrieves all QuickPDF documents (both custom folder & internal sandbox).
  Future<List<SavedPdfItem>> getAllDocuments() async {
    final prefs = await _getPrefs();
    final rawList = prefs.getStringList(_keyDocumentHistory) ?? [];

    List<SavedPdfItem> tracked = rawList
        .map((str) {
          try {
            return SavedPdfItem.fromJson(
              jsonDecode(str) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<SavedPdfItem>()
        .toList();

    // Auto-discover any sandbox PDFs not yet registered
    final internalDir = await getApplicationDocumentsDirectory();
    if (await internalDir.exists()) {
      final physicalFiles = internalDir.listSync().whereType<File>().where(
        (f) => p.extension(f.path).toLowerCase() == '.pdf',
      );

      for (final file in physicalFiles) {
        final alreadyTracked = tracked.any((t) => t.pathOrUri == file.path);
        if (!alreadyTracked) {
          final stat = file.statSync();
          tracked.add(
            SavedPdfItem(
              id: 'sandbox_${stat.modified.millisecondsSinceEpoch}',
              name: p.basename(file.path),
              storageType: 'sandbox',
              displayLocation: 'Internal Storage',
              pathOrUri: file.path,
              sizeBytes: stat.size,
              modifiedDate: stat.modified,
            ),
          );
        }
      }
    }

    // Verify sandbox files still exist physically on disk
    tracked.removeWhere((item) {
      if (item.storageType == 'sandbox') {
        return !File(item.pathOrUri).existsSync();
      }
      return false;
    });

    tracked.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));
    return tracked;
  }
}
