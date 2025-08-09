import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ceylon/features/trip_templates/presentation/screens/trip_templates_screen.dart';
import 'package:ceylon/features/trip_templates/presentation/screens/template_qr_import_screen.dart';

class ItineraryBuilderScreen extends StatefulWidget {
  const ItineraryBuilderScreen({super.key});

  @override
  State<ItineraryBuilderScreen> createState() => _ItineraryBuilderScreenState();
}

class _ItineraryBuilderScreenState extends State<ItineraryBuilderScreen> {
  final _title = TextEditingController();
  final List<TextEditingController> _days = [TextEditingController()];
  bool _saving = false;

  void _addDayField() {
    setState(() => _days.add(TextEditingController()));
  }

  Future<void> _saveItinerary() async {
    setState(() => _saving = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final List<String> dayPlans = _days
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('itineraries')
        .add({
          'title': _title.text.trim(),
          'days': dayPlans,
          'created_at': FieldValue.serverTimestamp(),
        });

    setState(() => _saving = false);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📝 Build Itinerary")),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Trip Title'),
                  ),
                  const SizedBox(height: 24),
                  ..._days.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Day ${index + 1} Plan',
                        ),
                      ),
                    );
                  }),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.library_books),
                        label: const Text('Trip Templates'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TripTemplatesScreen(),
                            ),
                          );
                        },
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Import from QR'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TemplateQrImportScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _addDayField,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Day"),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveItinerary,
                    child: const Text("Save Itinerary"),
                  ),
                ],
              ),
            ),
    );
  }
}
