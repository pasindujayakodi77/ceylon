import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class AttractionsMapScreen extends StatelessWidget {
  const AttractionsMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> attractions = [
      {
        'name': 'Sigiriya Rock',
        'location': LatLng(7.9570, 80.7603),
        'photo':
            'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f0/Sigiriya_rock.jpg/800px-Sigiriya_rock.jpg',
        'desc': 'Ancient rock fortress with murals and lion stairs.',
      },
      {
        'name': 'Temple of the Tooth',
        'location': LatLng(7.2936, 80.6417),
        'photo':
            'https://upload.wikimedia.org/wikipedia/commons/thumb/3/32/Temple_of_the_Tooth.jpg/800px-Temple_of_the_Tooth.jpg',
        'desc':
            'Sacred Buddhist site housing the relic of the tooth of Buddha.',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("📍 Nearby Attractions")),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(7.8731, 80.7718), // center of Sri Lanka
          zoom: 7.5,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.ceylon',
          ),
          MarkerLayer(
            markers: attractions.map((attraction) {
              return Marker(
                width: 80,
                height: 80,
                point: attraction['location'],
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) =>
                          _AttractionDetails(attraction: attraction),
                    );
                  },
                  child: Column(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 36,
                        color: Colors.red,
                      ),
                      Text(
                        attraction['name'],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AttractionDetails extends StatefulWidget {
  final Map<String, dynamic> attraction;
  const _AttractionDetails({required this.attraction});

  @override
  State<_AttractionDetails> createState() => _AttractionDetailsState();
}

class _AttractionDetailsState extends State<_AttractionDetails> {
  bool _isFavorite = false;
  double _rating = 4.0;
  bool _submitting = false;
  final _comment = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(widget.attraction['name'])
        .get();

    setState(() => _isFavorite = doc.exists);
  }

  Future<void> _toggleFavorite() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(widget.attraction['name']);

    if (_isFavorite) {
      await favRef.delete();
    } else {
      await favRef.set({
        'name': widget.attraction['name'],
        'desc': widget.attraction['desc'],
        'photo': widget.attraction['photo'],
        'location': {
          'lat': widget.attraction['location'].latitude,
          'lng': widget.attraction['location'].longitude,
        },
        'saved_at': FieldValue.serverTimestamp(),
      });
    }

    setState(() => _isFavorite = !_isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.attraction['location'].latitude;
    final lng = widget.attraction['location'].longitude;
    final name = Uri.encodeComponent(widget.attraction['name']);
    final directionUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng($name)",
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.attraction['name'],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Image.network(
            widget.attraction['photo'],
            height: 160,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 12),
          Text(widget.attraction['desc'], textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.directions),
            label: const Text("Get Directions"),
            onPressed: () =>
                launchUrl(directionUrl, mode: LaunchMode.externalApplication),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            label: Text(
              _isFavorite ? "Remove from Favorites" : "Save to Favorites",
            ),
            onPressed: _toggleFavorite,
          ),
          const SizedBox(height: 16),

          // 🔽 Review Section
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            "Leave a Review",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          RatingBar.builder(
            initialRating: _rating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemBuilder: (context, _) =>
                const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (rating) => _rating = rating,
          ),
          TextField(
            controller: _comment,
            decoration: const InputDecoration(
              labelText: 'Write your experience',
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _submitting
                ? null
                : () async {
                    setState(() => _submitting = true);
                    final uid = FirebaseAuth.instance.currentUser!.uid;
                    final userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .get();
                    final userName = userDoc.data()?['name'] ?? 'Anonymous';

                    await FirebaseFirestore.instance
                        .collection('places')
                        .doc(widget.attraction['name'])
                        .collection('reviews')
                        .add({
                          'userId': uid,
                          'name': userName,
                          'rating': _rating,
                          'comment': _comment.text.trim(),
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                    // Save under user's personal reviews for easy access
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('my_reviews')
                        .doc(
                          widget.attraction['name'],
                        ) // using place name as review key
                        .set({
                          'place': widget.attraction['name'],
                          'photo': widget.attraction['photo'],
                          'rating': _rating,
                          'comment': _comment.text.trim(),
                          'updated_at': FieldValue.serverTimestamp(),
                        });

                    setState(() => _submitting = false);
                    _comment.clear();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Review submitted')),
                    );
                  },
            child: const Text("Submit Review"),
          ),
          const SizedBox(height: 16),

          // 🔽 Show all reviews
          const Divider(),
          const Text(
            "Recent Reviews",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('places')
                .doc(widget.attraction['name'])
                .collection('reviews')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final docs = snapshot.data!.docs;

              if (docs.isEmpty) return const Text("No reviews yet.");

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final isMyReview =
                      data['userId'] == FirebaseAuth.instance.currentUser!.uid;
                  return ListTile(
                    title: Text(data['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RatingBarIndicator(
                          rating: data['rating']?.toDouble() ?? 0,
                          itemBuilder: (context, _) =>
                              const Icon(Icons.star, color: Colors.amber),
                          itemSize: 18.0,
                        ),
                        Text(data['comment']),
                        if (isMyReview)
                          Row(
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text(
                                  "Edit",
                                  style: TextStyle(fontSize: 12),
                                ),
                                onPressed: () => _editReview(doc.id, data),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text(
                                  "Delete",
                                  style: TextStyle(fontSize: 12),
                                ),
                                onPressed: () => _deleteReview(doc.id),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _deleteReview(String reviewId) async {
    final confirmed = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Review"),
        content: const Text("Are you sure you want to delete this review?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.attraction['name'])
          .collection('reviews')
          .doc(reviewId)
          .delete();
    }
  }

  void _editReview(String reviewId, Map<String, dynamic> data) {
    final tempController = TextEditingController(text: data['comment']);
    double tempRating = data['rating']?.toDouble() ?? 4.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: [
            const Text(
              "Edit Your Review",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RatingBar.builder(
              initialRating: tempRating,
              minRating: 1,
              allowHalfRating: true,
              itemCount: 5,
              itemBuilder: (_, __) =>
                  const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (r) => tempRating = r,
            ),
            TextField(
              controller: tempController,
              decoration: const InputDecoration(labelText: 'Your comment'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('places')
                    .doc(widget.attraction['name'])
                    .collection('reviews')
                    .doc(reviewId)
                    .update({
                      'rating': tempRating,
                      'comment': tempController.text,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
