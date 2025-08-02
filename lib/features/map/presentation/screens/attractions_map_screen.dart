import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

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
        .doc(widget.attraction['name']) // name as ID
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
    final loc = widget.attraction['location'];
    final name = Uri.encodeComponent(widget.attraction['name']);
    final directionUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=${loc.latitude},${loc.longitude}($name)",
    );

    return Padding(
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
        ],
      ),
    );
  }
}
