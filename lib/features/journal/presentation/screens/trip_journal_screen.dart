import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:ceylon/features/journal/data/journal_service.dart';

class TripJournalScreen extends StatefulWidget {
  const TripJournalScreen({super.key});

  @override
  State<TripJournalScreen> createState() => _TripJournalScreenState();
}

class _TripJournalScreenState extends State<TripJournalScreen> {
  final _picker = ImagePicker();
  bool _exporting = false;
  List<String> _selectedIds = []; // for selective export

  Future<void> _openCreateOrEdit({
    DocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final titleCtrl = TextEditingController(text: doc?.data()?['title'] ?? '');
    final noteCtrl = TextEditingController(text: doc?.data()?['note'] ?? '');
    List<XFile> picked = [];

    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 46,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  doc == null ? 'New Journal Entry' : 'Edit Journal Entry',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                minLines: 3,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final files = await _picker.pickMultiImage(
                        imageQuality: 85,
                      );
                      if (files != null && files.isNotEmpty) {
                        picked.addAll(files);
                        setSheet(() {}); // refresh preview count
                      }
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Add Photos'),
                  ),
                  const SizedBox(width: 12),
                  if (picked.isNotEmpty) Text('${picked.length} selected'),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final title = titleCtrl.text.trim();
                        final note = noteCtrl.text.trim();
                        if (title.isEmpty && note.isEmpty && picked.isEmpty)
                          return;

                        if (doc == null) {
                          await JournalService.instance.addEntry(
                            title: title,
                            note: note,
                            photos: picked,
                          );
                        } else {
                          await JournalService.instance.updateEntry(
                            entryId: doc.id,
                            title: title.isEmpty
                                ? (doc.data()?['title'] ?? '')
                                : title,
                            note: note.isEmpty
                                ? (doc.data()?['note'] ?? '')
                                : note,
                            newPhotos: picked,
                          );
                        }

                        if (mounted) Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Saved')),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    titleCtrl.dispose();
    noteCtrl.dispose();
  }

  Future<void> _deleteEntry(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('This will remove the note and photos. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await JournalService.instance.deleteEntry(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('🗑 Deleted')));
      }
    }
  }

  Future<void> _exportSelectedToPdf(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs,
  ) async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select entries to export')));
      return;
    }
    setState(() => _exporting = true);
    try {
      final chosen = allDocs
          .where((d) => _selectedIds.contains(d.id))
          .map((d) => d.data()..['createdAt'] = d['createdAt'])
          .toList();
      final bytes = await JournalService.instance.buildPdfFromEntries(chosen);
      await Printing.sharePdf(bytes: bytes, filename: 'trip_journal.pdf');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📓 Trip Journal'),
        actions: [
          if (_exporting)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: JournalService.instance.entriesStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No entries yet'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _openCreateOrEdit(),
                    icon: const Icon(Icons.add),
                    label: const Text('New Entry'),
                  ),
                ],
              ),
            );
          }

          final docs = snap.data!.docs;

          return Column(
            children: [
              // Export toolbar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    Expanded(child: Text('${_selectedIds.length} selected')),
                    OutlinedButton.icon(
                      onPressed: _exporting
                          ? null
                          : () => _exportSelectedToPdf(docs),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Export PDF'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() => _selectedIds.clear()),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final data = d.data();
                    final title = (data['title'] ?? 'Untitled') as String;
                    final note = (data['note'] ?? '') as String;
                    final photos =
                        (data['photos'] as List?)?.cast<String>() ?? [];
                    final createdAt = (data['createdAt'] as Timestamp?)
                        ?.toDate();

                    final selected = _selectedIds.contains(d.id);

                    return InkWell(
                      onLongPress: () {
                        setState(() {
                          if (selected) {
                            _selectedIds.remove(d.id);
                          } else {
                            _selectedIds.add(d.id);
                          }
                        });
                      },
                      onTap: () {
                        // quick toggle selection on tap when exporting; otherwise edit
                        if (_selectedIds.isNotEmpty) {
                          setState(() {
                            if (selected) {
                              _selectedIds.remove(d.id);
                            } else {
                              _selectedIds.add(d.id);
                            }
                          });
                        } else {
                          _openCreateOrEdit(doc: d);
                        }
                      },
                      child: Card(
                        color: selected ? Colors.blue.shade50 : null,
                        elevation: 1.5,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (createdAt != null)
                                    Text(
                                      createdAt
                                          .toLocal()
                                          .toString()
                                          .split('.')
                                          .first,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                              if (note.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  note,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (photos.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 90,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: photos.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 6),
                                    itemBuilder: (_, idx) => ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        photos[idx],
                                        width: 120,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _openCreateOrEdit(doc: d),
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Edit'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => _deleteEntry(d.id),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Delete'),
                                  ),
                                  const Spacer(),
                                  Checkbox(
                                    value: selected,
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _selectedIds.add(d.id);
                                        } else {
                                          _selectedIds.remove(d.id);
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
        onPressed: () => _openCreateOrEdit(),
      ),
    );
  }
}
