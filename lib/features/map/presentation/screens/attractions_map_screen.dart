import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class AttractionsMapScreen extends StatelessWidget {
  const AttractionsMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> attractions = [
      {'name': 'Sigiriya Rock', 'location': LatLng(7.9570, 80.7603)},
      {'name': 'Temple of the Tooth', 'location': LatLng(7.2936, 80.6417)},
      {'name': 'Galle Fort', 'location': LatLng(6.0261, 80.2170)},
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
                    final lat = attraction['location'].latitude;
                    final lng = attraction['location'].longitude;
                    final label = Uri.encodeComponent(attraction['name']);
                    final url = Uri.parse(
                      "https://www.google.com/maps/search/?api=1&query=$lat,$lng($label)",
                    );
                    launchUrl(url, mode: LaunchMode.externalApplication);
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
