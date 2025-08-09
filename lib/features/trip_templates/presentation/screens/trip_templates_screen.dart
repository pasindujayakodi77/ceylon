import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ceylon/features/trip_templates/data/trip_template_service.dart';
import 'trip_template_view_screen.dart';

class TripTemplatesScreen extends StatefulWidget {
  const TripTemplatesScreen({super.key});

  @override
  State<TripTemplatesScreen> createState() => _TripTemplatesScreenState();
}

class _TripTemplatesScreenState extends State<TripTemplatesScreen> {
  List<Map<String, dynamic>> _templates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await TripTemplateService.instance.listTemplates();
    setState(() {
      _templates = list;
      _loading = false;
    });
  }

  void _shareTemplate(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Share via QR Code'),
        content: QrImageView(data: id, version: QrVersions.auto, size: 200.0),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Templates')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _templates.length,
              itemBuilder: (_, i) {
                final t = _templates[i];
                return Card(
                  child: ListTile(
                    title: Text(t['name'] ?? 'Untitled'),
                    subtitle: Text(t['description'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.qr_code),
                      onPressed: () => _shareTemplate(t['id']),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TripTemplateViewScreen(templateId: t['id']),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
