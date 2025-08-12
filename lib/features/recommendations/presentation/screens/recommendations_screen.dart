import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:ceylon/core/ai/gemini_recommender.dart';
import 'package:ceylon/features/business/presentation/screens/business_detail_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _interests = <String>{'beach', 'history'};
  String _travelerType = 'couple';
  int _budget = 0; // LKR per activity, 0 = no budget
  bool _loading = false;
  List<Map<String, dynamic>> _results = [];
  Position? _pos;

  Future<void> _getLocation() async {
    final p = await GeminiRecommender.instance.getCurrentPosition();
    setState(() => _pos = p);
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _results = [];
    });

    // Load a pool (adjust region/categories if needed)
    final pool = await GeminiRecommender.instance.fetchAttractionsPool(
      limit: 60,
    );

    final res = await GeminiRecommender.instance.recommend(
      pool: pool,
      travelerType: _travelerType,
      interests: _interests.toList(),
      budgetLkr: _budget,
      days: 3,
      userLat: _pos?.latitude,
      userLng: _pos?.longitude,
      languageCode: 'en',
    );

    setState(() {
      _results = res.take(15).toList();
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  Widget build(BuildContext context) {
    final chips = [
      'beach',
      'history',
      'wildlife',
      'hiking',
      'food',
      'culture',
      'tea',
      'train',
      'waterfall',
      'temple',
      'surf',
      'snorkel',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('🤖 AI Recommendations')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Traveler type'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final t in ['solo', 'couple', 'family', 'group'])
                ChoiceChip(
                  label: Text(t),
                  selected: _travelerType == t,
                  onSelected: (_) => setState(() => _travelerType = t),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Interests'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in chips)
                FilterChip(
                  label: Text(c),
                  selected: _interests.contains(c),
                  onSelected: (v) => setState(() {
                    v ? _interests.add(c) : _interests.remove(c);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Budget (LKR): '),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _budget,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('No limit')),
                  DropdownMenuItem(value: 2000, child: Text('≤ 2,000')),
                  DropdownMenuItem(value: 5000, child: Text('≤ 5,000')),
                  DropdownMenuItem(value: 10000, child: Text('≤ 10,000')),
                ],
                onChanged: (v) => setState(() => _budget = v ?? 0),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.my_location),
                label: Text(_pos == null ? 'Use location' : 'Location ✓'),
                onPressed: _getLocation,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _loading ? null : _run,
            icon: const Icon(Icons.auto_awesome),
            label: Text(_loading ? 'Finding…' : 'Get AI Picks'),
          ),

          const SizedBox(height: 16),
          if (_results.isEmpty && !_loading)
            const Text(
              'No results yet. Choose interests and tap Get AI Picks.',
            ),

          for (final r in _results)
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('attractions')
                  .doc(r['id'] as String)
                  .get(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(minHeight: 1),
                  );
                }
                final m = snap.data!.data();
                if (m == null) return const SizedBox.shrink();

                final name = (m['name'] ?? '') as String;
                final photo = (m['photo'] ?? '') as String? ?? '';
                final city = (m['city'] ?? '') as String? ?? '';
                final rating = (m['avg_rating'] as num?)?.toDouble();
                final reason = (r['reason'] ?? '') as String;
                final score = (r['score'] as num?)?.toDouble() ?? 0;

                return Card(
                  child: ListTile(
                    leading: photo.isEmpty
                        ? const Icon(Icons.place)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              photo,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                    title: Text(name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (city.isNotEmpty) Text(city),
                        if (rating != null)
                          Text('⭐ ${rating.toStringAsFixed(1)}'),
                        const SizedBox(height: 4),
                        Text(
                          reason,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Score',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          score.toStringAsFixed(0),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    onTap: () {
                      // If you attach businesses to attractions differently, adapt this:
                      // For now, open a detail only if you have a business doc per attraction.
                      // Or route to your existing place detail screen.
                      // Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessDetailScreen(businessId: ???)));
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
