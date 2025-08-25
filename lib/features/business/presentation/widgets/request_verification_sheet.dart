import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ceylon/features/business/data/business_analytics_service.dart';

/// Multi-step verification sheet:
/// 0) owner details
/// 1) document upload (with resume best-effort)
/// 2) submit / status
class RequestVerificationSheet extends StatefulWidget {
  final String businessId;
  const RequestVerificationSheet({super.key, required this.businessId});

  @override
  State<RequestVerificationSheet> createState() =>
      _RequestVerificationSheetState();
}

class _ResumeStore {
  final SharedPreferences prefs;
  static const _k = 'verif_pending_uploads';
  _ResumeStore(this.prefs);

  List<String> list() => prefs.getStringList(_k) ?? [];
  Future<void> add(String v) async {
    final l = list();
    l.add(v);
    await prefs.setStringList(_k, l);
  }

  Future<void> remove(String v) async {
    final l = list();
    l.remove(v);
    await prefs.setStringList(_k, l);
  }
}

class _RequestVerificationSheetState extends State<RequestVerificationSheet> {
  int _step = 0;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _docUrl;
  double _progress = 0.0;
  // upload task reference removed (not needed directly)
  _ResumeStore? _store;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    // record that user opened verification flow (guarded for tests)
    try {
      BusinessAnalyticsService.instance.recordEvent(
        widget.businessId,
        'verification_started',
      );
    } catch (_) {}
    SharedPreferences.getInstance().then((p) {
      _store = _ResumeStore(p);
      _tryResume();
    });
  }

  Future<void> _tryResume() async {
    final pending = _store?.list() ?? [];
    if (pending.isEmpty) return;
    // if there's a pending item, offer to resume automatically when file exists
    for (final entry in pending) {
      final parts = entry.split('::');
      if (parts.length != 2) continue;
      final refPath = parts[0];
      final local = parts[1];
      final f = File(local);
      if (await f.exists()) {
        // attempt resume by re-uploading to same ref
        _uploadFile(File(local), refPath: refPath, storeKey: entry);
        return;
      }
    }
  }

  Future<void> _pickAndStartUpload() async {
    final picker = ImagePicker();
    final XFile? xf = await picker.pickImage(source: ImageSource.gallery);
    if (xf == null) return;
    final f = File(xf.path);
    final bytes = await f.length();
    if (bytes > 10 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File must be < 10MB')));
      return;
    }
    final ext = xf.name.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'pdf'].contains(ext)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unsupported file type (jpg/png/pdf)')),
      );
      return;
    }

    final ref = FirebaseStorage.instance.ref().child(
      'verifications/${widget.businessId}/${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    final key = '${ref.fullPath}::${f.path}';
    await _store?.add(key);
    await _uploadFile(f, refPath: ref.fullPath, storeKey: key);
  }

  Future<void> _uploadFile(
    File f, {
    required String refPath,
    required String storeKey,
  }) async {
    setState(() {
      _working = true;
      _progress = 0.0;
    });
    try {
      final ref = FirebaseStorage.instance.ref().child(refPath);
      final task = ref.putFile(f);

      final sub = task.snapshotEvents.listen((s) {
        setState(() {
          _progress = s.totalBytes == 0 ? 0 : s.bytesTransferred / s.totalBytes;
        });
      });

      await task.whenComplete(() {});
      final url = await ref.getDownloadURL();
      await _store?.remove(storeKey);
      await sub.cancel();
      setState(() {
        _docUrl = url;
        _progress = 1.0;
      });
      try {
        await BusinessAnalyticsService.instance.recordEvent(
          widget.businessId,
          'verification_document_uploaded',
        );
      } catch (_) {}
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() {
        _working = false;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_docUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a verification document')),
      );
      return;
    }
    setState(() => _working = true);

    final now = FieldValue.serverTimestamp();
    final reqRef = FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessId)
        .collection('verification_requests')
        .doc();

    await reqRef.set({
      'businessId': widget.businessId,
      'ownerName': _name.text.trim(),
      'ownerPhone': _phone.text.trim(),
      'ownerEmail': _email.text.trim(),
      'documentUrl': _docUrl,
      'status': 'pending',
      'createdAt': now,
    });

    // mark on business doc
    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessId)
        .set({
          'verificationRequestedAt': now,
          'verificationStatus': 'pending',
        }, SetOptions(merge: true));

    try {
      await BusinessAnalyticsService.instance.recordEvent(
        widget.businessId,
        'verification_requested',
      );
    } catch (_) {}

    setState(() {
      _working = false;
      _step = 2;
    });
  }

  Widget _stepOwner() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              'Step 1 — Owner details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v ?? '').contains('@') ? null : 'Enter a valid email',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate())
                      setState(() => _step = 1);
                  },
                  child: const Text('Next'),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepUpload() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text(
            'Step 2 — Upload document',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (_docUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const Text('Document uploaded'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _progress),
                  const SizedBox(height: 8),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Pick & upload document'),
                onPressed: _working ? null : _pickAndStartUpload,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _step = 0),
                child: const Text('Back'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _working ? null : _submitRequest,
                child: const Text('Submit for verification'),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepWaiting() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hourglass_top,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            'Verification requested',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Our team will verify your documents. Typical ETA: 2-3 business days.',
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_step == 0)
      body = _stepOwner();
    else if (_step == 1)
      body = _stepUpload();
    else
      body = _stepWaiting();

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            top: 12,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: body,
        ),
      ),
    );
  }
}
