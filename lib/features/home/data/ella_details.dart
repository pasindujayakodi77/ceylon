import 'package:flutter/material.dart';

/// Modernized Ella details using a SliverAppBar, chips, cards and reusable sections.
class EllaDetailsScreen extends StatelessWidget {
  const EllaDetailsScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const EllaDetailsScreen());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            backgroundColor: theme.colorScheme.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => _showNotImplemented(context),
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () => _showNotImplemented(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Ella — Train Ride'),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/home/ellatrainride.jpg',
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black45],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // quick info chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _InfoChip(icon: Icons.schedule, label: '6–8 hrs'),
                      _InfoChip(icon: Icons.traffic, label: 'Kandy → Ella'),
                      _InfoChip(icon: Icons.terrain, label: 'Scenic Views'),
                      _InfoChip(
                        icon: Icons.calendar_month,
                        label: 'Dec–Mar: best',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        'The train journey to Ella is one of Sri Lanka’s most celebrated scenic rail experiences. Winding through tea plantations, misty hills and dramatic viaducts (including the Nine Arch Bridge), the ride offers panoramic views and memorable photo opportunities.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _BulletSection(
                    title: 'Top highlights',
                    bullets: const [
                      'Nine Arch Bridge — iconic viaduct and photo spot.',
                      'Sweeping tea-estate vistas and terraced hillsides.',
                      'Local station stops with markets and tea vendors.',
                      'Open carriage doors on some trains for immersive views.',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _BulletSection(
                    title: 'Train tips',
                    bullets: const [
                      'Book reserved seats in advance for busy periods.',
                      'Arrive early to secure window seats and luggage space.',
                      'Bring snacks, water and a light jacket for cooler moments.',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DetailCard(
                    leading: Icons.info_outline,
                    title: 'Ticketing & classes',
                    content:
                        '1st, 2nd and 3rd class options — 1st class is more comfortable; 3rd class is lively and local.',
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showNotImplemented(context),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Open in maps'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => _showNotImplemented(context),
                        child: const Icon(Icons.directions_train),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _showNotImplemented(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Not implemented in demo.')));
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white70),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    );
  }
}

class _BulletSection extends StatelessWidget {
  final String title;
  final List<String> bullets;

  const _BulletSection({required this.title, required this.bullets});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...bullets.map(
          (b) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(b, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData leading;
  final String title;
  final String content;

  const _DetailCard({
    required this.leading,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(leading, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(content, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}
