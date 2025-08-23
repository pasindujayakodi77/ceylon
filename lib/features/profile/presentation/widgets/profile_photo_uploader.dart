import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../../../core/storage/storage_service.dart';

class ProfilePhotoUploader extends StatefulWidget {
  const ProfilePhotoUploader({super.key});

  @override
  State<ProfilePhotoUploader> createState() => _ProfilePhotoUploaderState();
}

class _ProfilePhotoUploaderState extends State<ProfilePhotoUploader> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickAndUpload(BuildContext context, String uid) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (picked == null) return; // user cancelled

      setState(() => _isUploading = true);

      final String ext = p.extension(picked.path).isNotEmpty
          ? p.extension(picked.path)
          : '.jpg';
      final String filename = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final String path = 'users/$uid/profile/$filename';

      final StorageService storage = StorageService();
      final String downloadUrl = await storage.uploadXFile(picked, path: path);

      // Save to Firestore (merge)
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'photoUrl': downloadUrl,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo uploaded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Please sign in to change your profile photo.'),
      );
    }

    final String uid = user.uid;
    final Stream<DocumentSnapshot<Map<String, dynamic>>> docStream =
        FirebaseFirestore.instance.collection('users').doc(uid).snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docStream,
      builder: (context, snapshot) {
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();
          photoUrl = data?['photoUrl'] as String?;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.grey.shade200,
                  child: ClipOval(
                    child: SizedBox(
                      width: 96,
                      height: 96,
                      child: photoUrl != null && photoUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: photoUrl,
                              fit: BoxFit.cover,
                              placeholder: (c, _) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (c, _, __) =>
                                  const Icon(Icons.account_circle, size: 96),
                            )
                          : const Icon(Icons.account_circle, size: 96),
                    ),
                  ),
                ),
                if (_isUploading)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black26,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isUploading
                  ? null
                  : () => _pickAndUpload(context, uid),
              icon: const Icon(Icons.upload_file),
              label: const Text('Change Photo'),
            ),
          ],
        );
      },
    );
  }
}
