// FILE: lib/features/journal/presentation/screens/trip_journal_screen.dart
// ignore_for_file: unused_import, unused_field, unnecessary_null_comparison
import 'dart:typed_data';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'package:ceylon/features/journal/data/journal_service.dart';

/// A modern, Material 3 Trip Journal with:
/// - date-grouped list
/// - fast add/edit via bottom sheet
/// - photo grid previews
/// - search
/// - export single/all to PDF
class TripJournalScreen extends StatefulWidget {
  const TripJournalScreen({super.key});

  @override
  State<TripJournalScreen> createState() => _TripJournalScreenState();
}

// Provide a non-destructive compatibility shim so existing code that calls
// `XFile.readAsBytesSync()` (used for quick previews) compiles. On platforms
// where the XFile has a valid local `path`, this will read bytes synchronously.
// On web or when no local path is available this will throw at runtime.
extension XFileSyncExtension on XFile {
  Uint8List readAsBytesSync() {
    final p = path;
    if (p.isNotEmpty && File(p).existsSync()) {
      return File(p).readAsBytesSync();
    }
    throw UnsupportedError(
      'XFile.readAsBytesSync() is not supported on this platform or the file path is empty.',
    );
  }
}

class _TripJournalScreenState extends State<TripJournalScreen> {
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  DateTime? _currentMonth; // null = all
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _EntryEditorSheet(
        onSaved: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _openEdit(JournalEntry entry) async {
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _EntryEditorSheet(
        entry: entry,
        onSaved: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _exportAll(List<JournalEntry> entries) async {
    final data = await JournalService.instance.buildPdf(entries);
    await Printing.sharePdf(bytes: data, filename: 'journal.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = _currentMonth == null
        ? 'All entries'
        : DateFormat('MMMM yyyy').format(_currentMonth!);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search title or note…',
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : const Text('📝 Trip Journal'),
        actions: [
          IconButton(
            tooltip: _searching ? 'Close search' : 'Search',
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _searchCtrl.clear();
            }),
          ),
          PopupMenuButton<String>(
            tooltip: 'Month',
            onSelected: (v) {
              if (v == 'all') {
                setState(() => _currentMonth = null);
              } else if (v == 'prev') {
                final m = _currentMonth ?? DateTime.now();
                setState(
                  () => _currentMonth = DateTime(m.year, m.month - 1, 1),
                );
              } else if (v == 'next') {
                final m = _currentMonth ?? DateTime.now();
                setState(
                  () => _currentMonth = DateTime(m.year, m.month + 1, 1),
                );
              } else if (v == 'this') {
                setState(
                  () => _currentMonth = DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    1,
                  ),
                );
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'this', child: Text('This month')),
              PopupMenuItem(value: 'prev', child: Text('Previous month')),
              PopupMenuItem(value: 'next', child: Text('Next month')),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'all', child: Text('All entries')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<JournalEntry>>(
        stream: JournalService.instance.streamEntries(month: _currentMonth),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _LoadingList();
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load journal:\n${snap.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final entries = snap.data ?? const [];
          final q = _searchCtrl.text.trim().toLowerCase();
          final filtered = q.isEmpty
              ? entries
              : entries
                    .where(
                      (e) =>
                          e.title.toLowerCase().contains(q) ||
                          e.note.toLowerCase().contains(q),
                    )
                    .toList();

          if (filtered.isEmpty) {
            return const _EmptyState();
          }

          // Group by date (yyyy-mm-dd)
          final byDay = <DateTime, List<JournalEntry>>{};
          for (final e in filtered) {
            final d = DateTime(e.date.year, e.date.month, e.date.day);
            byDay.putIfAbsent(d, () => []).add(e);
          }
          final days = byDay.keys.toList()
            ..sort((a, b) => b.compareTo(a)); // latest first
          final df = DateFormat('EEE, dd MMM');

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
            itemCount: days.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        monthLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export'),
                        onPressed: () => _exportAll(filtered),
                      ),
                    ],
                  ),
                );
              }
              final day = days[index - 1];
              final list = byDay[day]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                    child: Text(
                      df.format(day),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  ...list.map(
                    (e) => _EntryCard(
                      entry: e,
                      onEdit: () => _openEdit(e),
                      onDelete: () async {
                        final ok = await _confirmDelete();
                        if (ok) {
                          await JournalService.instance.deleteEntry(e.id);
                        }
                      },
                      onExport: () async {
                        final bytes = await JournalService.instance.buildPdf([
                          e,
                        ]);
                        await Printing.sharePdf(
                          bytes: bytes,
                          filename: 'entry-${e.id}.pdf',
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New entry'),
        onPressed: _openCreate,
      ),
    );
  }

  Future<bool> _confirmDelete() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text(
          'This cannot be undone. Photos will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return res ?? false;
  }
}

class _EntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  const _EntryCard({
    required this.entry,
    required this.onEdit,
    required this.onExport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhotos = entry.photos.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasPhotos) _PhotoStrip(urls: entry.photos),
              if (hasPhotos) const SizedBox(height: 10),
              Text(
                entry.title.isEmpty ? '(No title)' : entry.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (entry.note.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  entry.note,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(height: 1.25),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.edit,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tap to edit',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    tooltip: 'Export PDF',
                    onPressed: onExport,
                    icon: const Icon(Icons.picture_as_pdf),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  final List<String> urls;
  const _PhotoStrip({required this.urls});

  @override
  Widget build(BuildContext context) {
    // show up to 3 thumbnails
    final show = urls.take(3).toList();
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: show.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final u = show[i];
          return AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(u, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}

class _EntryEditorSheet extends StatefulWidget {
  final JournalEntry? entry;
  final VoidCallback? onSaved;
  const _EntryEditorSheet({this.entry, this.onSaved});

  @override
  State<_EntryEditorSheet> createState() => _EntryEditorSheetState();
}

class _EntryEditorSheetState extends State<_EntryEditorSheet> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  final _picker = ImagePicker();
  final List<XFile> _newPhotos = [];
  final List<String> _removePhotos = [];

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    if (e != null) {
      _title.text = e.title;
      _note.text = e.note;
      _date = e.date;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final list = await _picker.pickMultiImage(imageQuality: 88);
    if (list != null && list.isNotEmpty) {
      setState(() => _newPhotos.addAll(list));
    }
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final note = _note.text.trim();

    if (widget.entry == null) {
      await JournalService.instance.addEntry(
        title: title,
        note: note,
        photos: _newPhotos,
        date: _date,
      );
    } else {
      await JournalService.instance.updateEntry(
        entryId: widget.entry!.id,
        title: title,
        note: note,
        date: _date,
        addPhotos: _newPhotos,
        removePhotoUrls: _removePhotos,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.entry == null ? 'Entry added' : 'Entry updated'),
        ),
      );
      widget.onSaved?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingPhotos = widget.entry?.photos ?? const <String>[];

    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.entry == null ? 'New Journal Entry' : 'Edit Entry',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.notes),
              ),
              keyboardType: TextInputType.multiline,
              maxLines: 6,
              minLines: 4,
            ),
            const SizedBox(height: 12),
            _DateRow(
              initial: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            const SizedBox(height: 12),

            // Existing photos (allow removing)
            if (existingPhotos.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Existing photos',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: existingPhotos.map((u) {
                  final removed = _removePhotos.contains(u);
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ColorFiltered(
                          colorFilter: removed
                              ? const ColorFilter.mode(
                                  Colors.black38,
                                  BlendMode.srcATop,
                                )
                              : const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.dst,
                                ),
                          child: Image.network(
                            u,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton.filledTonal(
                          icon: Icon(
                            removed ? Icons.undo : Icons.remove_circle_outline,
                          ),
                          tooltip: removed ? 'Undo remove' : 'Remove',
                          onPressed: () {
                            setState(() {
                              if (removed) {
                                _removePhotos.remove(u);
                              } else {
                                _removePhotos.add(u);
                              }
                            });
                          },
                          iconSize: 20,
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Newly picked photos preview
            if (_newPhotos.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'New photos',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _newPhotos.asMap().entries.map((e) {
                  final i = e.key;
                  final x = e.value;
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          // Quick cross-platform preview
                          // ignore: invalid_use_of_visible_for_testing_member
                          x.readAsBytesSync(),
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton.filledTonal(
                          icon: const Icon(Icons.close),
                          tooltip: 'Remove',
                          onPressed: () =>
                              setState(() => _newPhotos.removeAt(i)),
                          iconSize: 20,
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Add photos'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final DateTime initial;
  final ValueChanged<DateTime> onChanged;
  const _DateRow({required this.initial, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, dd MMM yyyy');
    return Row(
      children: [
        const Icon(Icons.event),
        const SizedBox(width: 8),
        Text(df.format(initial)),
        const Spacer(),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_calendar),
          label: const Text('Change'),
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime(now.year - 5),
              lastDate: DateTime(now.year + 5),
            );
            if (picked != null) onChanged(picked);
          },
        ),
      ],
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: 6,
      itemBuilder: (_, i) => Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Container(
          height: 110,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 140, height: 12, color: Colors.black12),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 9,
                color: Colors.black12,
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                height: 9,
                color: Colors.black12,
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.black12,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.black12,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: Colors.black38,
            ),
            const SizedBox(height: 10),
            Text(
              'No journal entries yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the + button to add your first memory.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
