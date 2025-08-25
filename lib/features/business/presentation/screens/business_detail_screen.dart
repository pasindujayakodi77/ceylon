// Patched by Refactor Pack: Repository + BLoC + Batched Analytics (UTC)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ceylon/features/business/data/business_repository.dart';
import 'package:ceylon/features/business/data/business_models.dart';
import 'package:ceylon/features/business/data/business_analytics_service.dart';
import 'package:ceylon/features/business/presentation/widgets/business_feedback_sheet.dart';

class BusinessDetailScreen extends StatefulWidget {
  final String businessId;
  const BusinessDetailScreen({super.key, required this.businessId});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  Business? _biz;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = BusinessRepository(
        FirebaseFirestore.instance,
        FirebaseAuth.instance,
      );
      _biz = await repo.getBusinessById(widget.businessId);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: '000'); // TODO: wire real phone
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      await BusinessAnalyticsService.instance.recordCall(widget.businessId);
    }
  }

  Future<void> _directions() async {
    final uri = Uri.parse(
      'https://maps.google.com/?q=6.9271,79.8612',
    ); // TODO: wire real coords
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      await BusinessAnalyticsService.instance.recordDirections(
        widget.businessId,
      );
    }
  }

  Future<void> _website() async {
    final uri = Uri.parse('https://example.com'); // TODO: wire real url
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      await BusinessAnalyticsService.instance.recordWebsite(widget.businessId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null)
      return Scaffold(body: Center(child: Text('Error: $_error')));
    if (_biz == null)
      return const Scaffold(body: Center(child: Text('Business not found')));
    final b = _biz!;
    return Scaffold(
      appBar: AppBar(title: Text(b.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (b.photoUrl != null && b.photoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(b.photoUrl!, height: 180, fit: BoxFit.cover),
            ),
          const SizedBox(height: 12),
          if (b.description != null) Text(b.description!),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: _call,
                icon: const Icon(Icons.call),
                label: const Text('Call'),
              ),
              OutlinedButton.icon(
                onPressed: _directions,
                icon: const Icon(Icons.directions),
                label: const Text('Directions'),
              ),
              OutlinedButton.icon(
                onPressed: _website,
                icon: const Icon(Icons.link),
                label: const Text('Website'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final ok = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) => BusinessFeedbackSheet(businessId: b.id),
              );
              if (ok == true && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thanks for your feedback!')),
                );
              }
            },
            child: const Text('Send Feedback'),
          ),
        ],
      ),
    );
  }
}
