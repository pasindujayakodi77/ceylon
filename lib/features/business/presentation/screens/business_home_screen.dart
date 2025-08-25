// Patched by Refactor Pack: Repository + BLoC + Batched Analytics (UTC)

import 'package:flutter/material.dart';
import 'package:ceylon/features/business/presentation/widgets/promoted_businesses_carousel.dart';

class BusinessHomeScreen extends StatelessWidget {
  const BusinessHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: ListView(
        children: const [
          SizedBox(height: 12),
          PromotedBusinessesCarousel(title: 'Promoted businesses'),
          SizedBox(height: 24),
          // Add more sections here...
        ],
      ),
    );
  }
}
