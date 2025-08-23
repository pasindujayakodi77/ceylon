// FILE: lib/core/storage/storage_service.dart
// Production-ready Firebase Storage helper.
// Features:
// - Uses default FirebaseStorage.instance unless compile-time env FIREBASE_STORAGE_BUCKET is set
// - Upload XFile or File with MIME detection (via `mime` package)
// - Delete by path
// Example paths:
//   users/{uid}/profile/<timestamp>.jpg
//   public/attractions/<id>.jpg

import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

// Set at compile time (dart-define) if you want a custom bucket
// e.g. --dart-define=FIREBASE_STORAGE_BUCKET=gs://my-custom-bucket
const String _customBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

class StorageService {
  // Singleton
  StorageService._(this._storage);

  factory StorageService() {
    final FirebaseStorage storage = _customBucket.isNotEmpty
        ? FirebaseStorage.instanceFor(bucket: _customBucket)
        : FirebaseStorage.instance;
    return StorageService._(storage);
  }

  final FirebaseStorage _storage;

  /// Upload an [XFile] to [path] and return the download URL.
  /// Example path: users/{uid}/profile/<timestamp>.jpg
  Future<String> uploadXFile(
    XFile xfile, {
    required String path,
    SettableMetadata? metadata,
  }) async {
    try {
      final Uint8List bytes = await xfile.readAsBytes();
      final String? detected = _detectMime(xfile.path, headerBytes: bytes);
      final SettableMetadata meta =
          metadata ?? SettableMetadata(contentType: detected);

      final Reference ref = _storage.ref().child(path);
      final UploadTask task = ref.putData(bytes, meta);
      await task;
      return await ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  /// Upload a [File] to [path] and return the download URL.
  Future<String> uploadFile(
    File file, {
    required String path,
    SettableMetadata? metadata,
  }) async {
    try {
      final String mimeType =
          _detectMime(file.path) ?? 'application/octet-stream';
      final SettableMetadata meta =
          metadata ?? SettableMetadata(contentType: mimeType);

      final Reference ref = _storage.ref().child(path);
      final UploadTask task = ref.putFile(file, meta);
      await task;
      return await ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete the object at [path]
  Future<void> deleteAt(String path) async {
    final Reference ref = _storage.ref().child(path);
    await ref.delete();
  }

  /// Derive a filename from an XFile instance (best-effort)
  static String filenameFromXFile(XFile x) {
    if (x.path.isNotEmpty) return p.basename(x.path);
    if (x.name.isNotEmpty) return x.name;
    return 'file_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Helper to detect mime type using file path first then header bytes
  String? _detectMime(String? path, {Uint8List? headerBytes}) {
    try {
      if (path != null && path.isNotEmpty) {
        final String? m = lookupMimeType(path, headerBytes: headerBytes);
        if (m != null) return m;
      }
      if (headerBytes != null) {
        final String? m = lookupMimeType('', headerBytes: headerBytes);
        if (m != null) return m;
      }
    } catch (_) {}
    return null;
  }
}
