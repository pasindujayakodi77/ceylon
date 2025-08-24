import 'package:flutter/material.dart';

class SigiriyaDetailsScreen extends StatelessWidget {
  const SigiriyaDetailsScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const SigiriyaDetailsScreen());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
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
              title: const Text('Sigiriya — Sri Lanka'),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/home/sigiriyarock.png',
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
                  Wrap(
                    spacing: 8,
                    children: const [
                      _InfoChip(icon: Icons.terrain, label: 'Lion Rock'),
                      _InfoChip(icon: Icons.museum, label: 'UNESCO nearby'),
                      _InfoChip(icon: Icons.timer, label: 'Half-day'),
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
                        'Sigiriya — Lion Rock — is an ancient rock fortress with frescoes, landscaped gardens and impressive ruins. The climb rewards visitors with panoramas and a glimpse into Sri Lanka’s ancient engineering and art.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _BulletSection(
                    title: 'Top things to do',
                    bullets: const [
                      'Climb early for frescoes, Mirror Wall and views.',
                      'Visit Pidurangala Rock for a quieter viewpoint.',
                      'Combine with Dambulla Cave Temple and spice gardens.',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _BulletSection(
                    title: 'Practical tips',
                    bullets: const [
                      'Wear non-slip shoes for steps and metal stairways.',
                      'Carry water and sun protection; limited shade on the ascent.',
                      'Guides available — check entrance fees and opening times.',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DetailCard(
                    leading: Icons.accessibility_new,
                    title: 'Safety & access',
                    content:
                        'Steep stairs and narrow walkways; not recommended for those with serious mobility issues.',
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () => _showNotImplemented(context),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Open in maps'),
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
