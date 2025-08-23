import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class FirebaseStorageHelper {
  /// Safely gets a download URL from Firebase Storage with error handling
  static Future<String?> safeGetDownloadURL(String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('Firebase Storage error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error getting download URL: $e');
      return null;
    }
  }

  /// Safely uploads a file to Firebase Storage with error handling
  static Future<String?> safeUploadFile(
    String path,
    dynamic file,
    void Function(double)? onProgress,
  ) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);

      final uploadTask = ref.putFile(file);

      if (onProgress != null) {
        // Listen for state changes, errors, and completion of the upload
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // Wait for the upload to complete
      await uploadTask;

      // Get and return the download URL
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('Firebase Storage upload error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }
}
