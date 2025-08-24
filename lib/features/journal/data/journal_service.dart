// FILE: lib/features/journal/data/journal_service.dart
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

/// Data model for a journal entry.
class JournalEntry {
  final String id;
  final String title;
  final String note;
  final List<String> photos;
  final DateTime date; // user-facing date for the entry
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const JournalEntry({
    required this.id,
    required this.title,
    required this.note,
    required this.photos,
    required this.date,
    this.createdAt,
    this.updatedAt,
  });

  factory JournalEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    DateTime toDt(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.now();
    }

    return JournalEntry(
      id: d.id,
      title: (m['title'] ?? '').toString(),
      note: (m['note'] ?? '').toString(),
      photos: (m['photos'] as List?)?.cast<String>() ?? const [],
      date: toDt(m['date']),
      createdAt: m['createdAt'] != null ? toDt(m['createdAt']) : null,
      updatedAt: m['updatedAt'] != null ? toDt(m['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'note': note,
      'photos': photos,
      'date': Timestamp.fromDate(date),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    }..removeWhere((k, v) => v == null);
  }
}

class JournalService {
  JournalService._();
  static final JournalService instance = JournalService._();

  final _db = FirebaseFirestore.instance;

  FirebaseStorage get _storage {
    const customBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
    if (customBucket.isNotEmpty) {
      return FirebaseStorage.instanceFor(bucket: customBucket);
    }
    return FirebaseStorage.instance;
  }

  String get _uid {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      throw StateError('Not signed in');
    }
    return u.uid;
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(_uid).collection('journal');

  /// Stream entries for current user for a month or all (if [month] is null).
  Stream<List<JournalEntry>> streamEntries({DateTime? month}) {
    final Query<Map<String, dynamic>> base = _col.orderBy(
      'date',
      descending: true,
    );
    final query = month == null
        ? base
        : base
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime(month.year, month.month, 1),
                ),
              )
              .where(
                'date',
                isLessThan: Timestamp.fromDate(
                  DateTime(month.year, month.month + 1, 1),
                ),
              );
    return query.snapshots().map(
      (s) => s.docs.map(JournalEntry.fromDoc).toList(),
    );
  }

  /// Create an entry (optionally with photos). Returns new entryId.
  Future<String> addEntry({
    required String title,
    required String note,
    List<XFile> photos = const [],
    DateTime? date,
  }) async {
    final ref = await _col.add({
      'title': title,
      'note': note,
      'photos': [],
      'date': Timestamp.fromDate(date ?? DateTime.now()),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (photos.isNotEmpty) {
      final urls = await _uploadPhotos(ref.id, photos);
      await ref.update({
        'photos': FieldValue.arrayUnion(urls),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    return ref.id;
  }

  /// Update fields; add more photos; optionally remove some existing photo URLs.
  Future<void> updateEntry({
    required String entryId,
    String? title,
    String? note,
    DateTime? date,
    List<XFile> addPhotos = const [],
    List<String> removePhotoUrls = const [],
  }) async {
    final updates = <String, dynamic>{
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (date != null) 'date': Timestamp.fromDate(date),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (removePhotoUrls.isNotEmpty) {
      updates['photos'] = FieldValue.arrayRemove(removePhotoUrls);
    }
    await _col.doc(entryId).update(updates);
    if (addPhotos.isNotEmpty) {
      final urls = await _uploadPhotos(entryId, addPhotos);
      await _col.doc(entryId).update({
        'photos': FieldValue.arrayUnion(urls),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> deleteEntry(String entryId) async {
    // delete storage files under this entry
    try {
      final prefix = 'users/$_uid/journal/$entryId/';
      final result = await _storage.ref(prefix).listAll();
      for (final i in result.items) {
        await i.delete();
      }
    } catch (_) {
      // ignore storage errors; user might have had no photos
    }
    await _col.doc(entryId).delete();
  }

  /// Uploads photos under users/{uid}/journal/{entryId}/`<filename>`
  Future<List<String>> _uploadPhotos(String entryId, List<XFile> photos) async {
    final out = <String>[];
    for (final x in photos) {
      final name = _filenameFromXFile(x);
      final ref = _storage.ref('users/$_uid/journal/$entryId/$name');
      final bytes = await x.readAsBytes();
      final task = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await task.ref.getDownloadURL();
      out.add(url);
    }
    return out;
  }

  String _filenameFromXFile(XFile x) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ext = _safeExt(x.name);
    return '$ts$ext';
  }

  String _safeExt(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1) return '.jpg';
    final ext = name.substring(dot).toLowerCase();
    const allowed = ['.jpg', '.jpeg', '.png', '.webp', '.heic'];
    return allowed.contains(ext) ? ext : '.jpg';
  }

  /// Build a simple PDF for a set of entries (in memory).
  Future<Uint8List> buildPdf(List<JournalEntry> entries) async {
    final pdf = pw.Document();
    final df = DateFormat('EEE, dd MMM yyyy');

    for (final e in entries) {
      pdf.addPage(
        pw.Page(
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                e.title.isEmpty ? '(No title)' : e.title,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                df.format(e.date),
                style: const pw.TextStyle(fontSize: 12),
              ),
              if (e.note.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text(e.note, style: const pw.TextStyle(fontSize: 12)),
              ],
              if (e.photos.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text(
                  'Photos:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: e.photos
                      .map((u) => pw.UrlLink(child: pw.Text(u), destination: u))
                      .toList(),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '(Open links to view images.)',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return pdf.save();
  }
}
