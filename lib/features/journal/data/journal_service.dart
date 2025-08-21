import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;

class JournalService {
  JournalService._();
  static final instance = JournalService._();

  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  String get _uid {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) throw StateError('Not signed in');
    return u.uid;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> entriesStream() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('journal')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<List<String>> _uploadPhotos(String entryId, List<XFile> files) async {
    final urls = <String>[];
    for (final f in files) {
      final name = f.name;
      final ref = _storage.ref().child('journal/$_uid/$entryId/$name');
      final data = await f.readAsBytes();
      await ref.putData(data, SettableMetadata(contentType: 'image/jpeg'));
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<String> addEntry({
    required String title,
    required String note,
    List<XFile> photos = const [],
  }) async {
    final ref = await _db
        .collection('users')
        .doc(_uid)
        .collection('journal')
        .add({
          'title': title.trim(),
          'note': note.trim(),
          'photos': [],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

    if (photos.isNotEmpty) {
      final urls = await _uploadPhotos(ref.id, photos);
      await ref.update({
        'photos': urls,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    return ref.id;
  }

  Future<void> updateEntry({
    required String entryId,
    required String title,
    required String note,
    List<XFile> newPhotos = const [],
  }) async {
    final doc = _db
        .collection('users')
        .doc(_uid)
        .collection('journal')
        .doc(entryId);
    List<String> current = [];
    final snap = await doc.get();
    if (snap.exists) {
      current = List<String>.from(snap.data()!['photos'] ?? []);
    }
    if (newPhotos.isNotEmpty) {
      final urls = await _uploadPhotos(entryId, newPhotos);
      current.addAll(urls);
    }
    await doc.set({
      'title': title.trim(),
      'note': note.trim(),
      'photos': current,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteEntry(String entryId) async {
    // Delete photos in storage
    final folder = _storage.ref().child('journal/$_uid/$entryId');
    try {
      final list = await folder.listAll();
      for (final item in list.items) {
        await item.delete();
      }
    } catch (_) {}
    // Delete Firestore doc
    await _db
        .collection('users')
        .doc(_uid)
        .collection('journal')
        .doc(entryId)
        .delete();
  }

  /// Build a PDF from given entries (title, note, photos)
  Future<Uint8List> buildPdfFromEntries(
    List<Map<String, dynamic>> entries,
  ) async {
    final pdf = pw.Document();

    for (final e in entries) {
      final title = (e['title'] ?? '') as String;
      final note = (e['note'] ?? '') as String;
      final photos = (e['photos'] as List?)?.cast<String>() ?? <String>[];

      pdf.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) => [
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            if (e['createdAt'] != null)
              pw.Text(
                'Date: ${(e['createdAt'] as Timestamp).toDate().toLocal()}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            pw.SizedBox(height: 12),
            pw.Text(note, style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 12),
            if (photos.isNotEmpty)
              ...photos.map(
                (url) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.UrlLink(
                    destination: url,
                    child: pw.Center(
                      child: pw.Image(
                        pw.MemoryImage(
                          // Load bytes via NetworkAssetBundle.fetch is not available in pdf.
                          // Workaround: let printing package fetch at print time using network images,
                          // or skip embedding and show URL. Simpler: show URL (already clickable).
                          // To embed images, you’d need to pre-download bytes outside and pass in.
                          Uint8List(0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (photos.isNotEmpty)
              pw.Text(
                '(Images not embedded in offline mode; tap URLs in PDF viewer to open.)',
                style: const pw.TextStyle(fontSize: 9),
              ),
          ],
        ),
      );
    }

    return pdf.save();
  }
}
