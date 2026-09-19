package com.example.quickpdf

import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.quickpdf.app/saf_helper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "deleteFile") {
                val treeUriStr = call.argument<String>("treeUri")
                val fileName = call.argument<String>("fileName")
                val docUriStr = call.argument<String>("documentUri")

                var deleted = false

                // 1. Attempt delete via direct document URI if available
                if (!docUriStr.isNullOrEmpty()) {
                    try {
                        val docUri = Uri.parse(docUriStr)
                        deleted = DocumentsContract.deleteDocument(contentResolver, docUri)
                    } catch (_: Exception) {}
                }

                // 2. If not deleted, query tree children by filename and delete directly
                if (!deleted && !treeUriStr.isNullOrEmpty() && !fileName.isNullOrEmpty()) {
                    try {
                        val treeUri = Uri.parse(treeUriStr)
                        val treeId = DocumentsContract.getTreeDocumentId(treeUri)
                        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, treeId)
                        val projection = arrayOf(
                            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                            DocumentsContract.Document.COLUMN_DISPLAY_NAME
                        )

                        val cursor = contentResolver.query(childrenUri, projection, null, null, null)
                        cursor?.use { c ->
                            val idCol = c.getColumnIndex(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
                            val nameCol = c.getColumnIndex(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                            while (c.moveToNext()) {
                                val name = c.getString(nameCol)
                                if (name != null && name.equals(fileName, ignoreCase = true)) {
                                    val docId = c.getString(idCol)
                                    val fileUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)
                                    deleted = DocumentsContract.deleteDocument(contentResolver, fileUri)
                                    if (deleted) break
                                }
                            }
                        }
                    } catch (_: Exception) {}
                }

                result.success(deleted)
            } else {
                result.notImplemented()
            }
        }
    }
}