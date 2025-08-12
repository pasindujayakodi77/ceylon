import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttractionsFilterScreen extends StatefulWidget {
  const AttractionsFilterScreen({super.key});

  @override
  State<AttractionsFilterScreen> createState() =>
      _AttractionsFilterScreenState();
}

class _AttractionsFilterScreenState extends State<AttractionsFilterScreen> {
  final _searchCtrl = TextEditingController();

  // Adjust these to your dataset
  final List<String> _categories = const [
    'all',
    'beach',
    'temple',
    'nature',
    'heritage',
    'wildlife',
    'city',
  ];

  String _category = 'all';
  double _minRating = 0.0;

  // Build the Firestore query based on current filters
  Query _buildQuery() {
    Query q = FirebaseFirestore.instance.collection('attractions');

    if (_category != 'all') {
      q = q.where('category', isEqualTo: _category);
    }

    // Only add rating filter if user actually moved it above 0.0
    if (_minRating > 0) {
      q = q.where('avg_rating', isGreaterThanOrEqualTo: _minRating);
    }

    // Order by rating desc so the best appears on top
    // (Firestorm may ask you to create a composite index when combining where+order)
    q = q.orderBy('avg_rating', descending: true);

    return q;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _buildQuery();

    return Scaffold(
      appBar: AppBar(title: const Text('🔎 Find Attractions')),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _category = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Min Rating'),
                          Slider(
                            value: _minRating,
                            min: 0,
                            max: 5,
                            divisions: 10, // half-star steps
                            label: _minRating.toStringAsFixed(1),
                            onChanged: (v) => setState(() => _minRating = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Search by name',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),

          const Divider(height: 0),

          // Results list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('No attractions found.'));
                }

                // Map to plain objects
                final items = snap.data!.docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  // Extract lat/lng from GeoPoint if available
                  double? lat;
                  double? lng;
                  if (d['location'] != null && d['location'] is GeoPoint) {
                    lat = (d['location'] as GeoPoint).latitude;
                    lng = (d['location'] as GeoPoint).longitude;
                  }
                  return {
                    'id': doc.id,
                    'name': d['name'] ?? doc.id,
                    'desc': d['desc'] ?? '',
                    'photo': d['photo'] ?? '',
                    'avg_rating': (d['avg_rating'] is num)
                        ? (d['avg_rating'] as num).toDouble()
                        : null,
                    'review_count': d['review_count'] ?? 0,
                    'category': d['category'] ?? 'other',
                    'lat': lat ?? d['lat'] ?? 0.0,
                    'lng': lng ?? d['lng'] ?? 0.0,
                    'location': d['location'],
                  };
                }).toList();

                // Client-side search by name (cheap and fast)
                final qText = _searchCtrl.text.trim().toLowerCase();
                final filtered = qText.isEmpty
                    ? items
                    : items
                          .where(
                            (p) => (p['name'] as String).toLowerCase().contains(
                              qText,
                            ),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No results for your search.'),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (_, i) {
                    final p = filtered[i];
                    return ListTile(
                      leading: p['photo'] != ''
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                p['photo'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.photo, size: 40),
                      title: Text(p['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((p['avg_rating']) != null)
                            Text(
                              "⭐ ${p['avg_rating']} (${p['review_count']})",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.amber,
                              ),
                            ),
                          Text(
                            p['desc'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Category: ${p['category']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        // Return a plain map with coords + data
                        Navigator.pop(context, {
                          'name': p['name'],
                          'desc': p['desc'],
                          'photo': p['photo'],
                          'lat': p['location']?['latitude'] ?? p['lat'] ?? 0.0,
                          'lng': p['location']?['longitude'] ?? p['lng'] ?? 0.0,
                          'avg_rating': p['avg_rating'],
                          'review_count': p['review_count'],
                          'category': p['category'],
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
