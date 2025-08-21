import 'package:flutter/material.dart';
import 'package:ceylon/features/trip_templates/data/trip_template_service.dart';

class TripTemplateViewScreen extends StatefulWidget {
  final String templateId;
  const TripTemplateViewScreen({super.key, required this.templateId});

  @override
  State<TripTemplateViewScreen> createState() => _TripTemplateViewScreenState();
}

class _TripTemplateViewScreenState extends State<TripTemplateViewScreen> {
  Map<String, dynamic>? _template;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await TripTemplateService.instance.getTemplate(widget.templateId);
    setState(() {
      _template = t;
      _loading = false;
    });
  }

  Future<void> _import() async {
    if (_template == null) return;
    await TripTemplateService.instance.importTemplateToMyItinerary(_template!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Imported to My Itineraries')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_template == null) {
      return const Scaffold(body: Center(child: Text('Template not found')));
    }

    final days = (_template!['days'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(_template!['name'] ?? '')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_template!['description'] != null)
            Text(_template!['description']),
          const SizedBox(height: 16),
          for (final day in days)
            Card(
              child: ListTile(
                title: Text('Day ${day['day']}: ${day['title']}'),
                subtitle: Text((day['items'] as List?)?.join(', ') ?? ''),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.download),
        label: const Text('Import'),
        onPressed: _import,
      ),
    );
  }
}
