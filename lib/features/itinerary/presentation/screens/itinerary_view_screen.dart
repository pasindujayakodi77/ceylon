// FILE: lib/features/itinerary/presentation/screens/itinerary_view_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/itinerary_day_widget.dart';

class ItineraryViewScreen extends StatelessWidget {
  final String itineraryId;
  const ItineraryViewScreen({super.key, required this.itineraryId});

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _doc => FirebaseFirestore.instance
      .collection('users')
      .doc(_uid)
      .collection('itineraries')
      .doc(itineraryId);

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, dd MMM');

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _doc.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final d = snap.data!;
        final name = (d['name'] ?? 'My Trip').toString();
        final start = (d['startDate'] as Timestamp).toDate();
        final dayCount = (d['dayCount'] as num?)?.toInt() ?? 1;

        return Scaffold(
          appBar: AppBar(title: Text('🧭 $name')),
          body: PageView.builder(
            itemCount: dayCount,
            controller: PageController(viewportFraction: 0.98),
            itemBuilder: (_, i) {
              final dayIndex = i + 1;
              final date = DateTime(
                start.year,
                start.month,
                start.day,
              ).add(Duration(days: i));
              return Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        children: [
                          Chip(label: Text('Day $dayIndex')),
                          const SizedBox(width: 8),
                          Text(df.format(date)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ItineraryDayWidget(
                        itineraryId: itineraryId,
                        dayIndex: dayIndex,
                        date: date,
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
