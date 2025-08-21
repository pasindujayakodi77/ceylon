import 'package:ceylon/design_system/tokens.dart';
import 'package:ceylon/features/itinerary/data/itinerary_adapter.dart'
    as adapter;
import 'package:ceylon/features/itinerary/data/itinerary_repository.dart';
import 'package:ceylon/features/itinerary/presentation/screens/itinerary_builder_screen_new.dart';
import 'package:ceylon/features/itinerary/presentation/screens/itinerary_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ItineraryListScreen extends StatefulWidget {
  const ItineraryListScreen({super.key});

  @override
  State<ItineraryListScreen> createState() => _ItineraryListScreenState();
}

class _ItineraryListScreenState extends State<ItineraryListScreen> {
  late final ItineraryRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = Provider.of<ItineraryRepository>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Itineraries'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: StreamBuilder<List<adapter.Itinerary>>(
        stream: _repository.getItineraries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: CeylonTokens.spacing16),
                  Text(
                    'Failed to load itineraries',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: CeylonTokens.spacing8),
                  Text(
                    'Error: ${snapshot.error}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final itineraries = snapshot.data ?? [];

          if (itineraries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: CeylonTokens.spacing16),
                  Text(
                    'No itineraries yet',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: CeylonTokens.spacing8),
                  Text(
                    'Create your first itinerary to start planning your trip',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: CeylonTokens.spacing24),
                  FilledButton.icon(
                    onPressed: () => _createNewItinerary(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Itinerary'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(CeylonTokens.spacing16),
            itemCount: itineraries.length,
            itemBuilder: (context, index) {
              final itinerary = itineraries[index];
              return _ItineraryCard(
                itinerary: itinerary,
                onTap: () => _viewItinerary(context, itinerary.id),
                onEdit: () => _editItinerary(context, itinerary.id),
                onDelete: () => _deleteItinerary(context, itinerary.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewItinerary(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _createNewItinerary(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Provider(
          create: (_) => ItineraryRepository(),
          child: const ItineraryBuilderScreen(),
        ),
      ),
    );
  }

  void _viewItinerary(BuildContext context, String itineraryId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Provider(
          create: (_) => ItineraryRepository(),
          child: ItineraryViewScreen(itineraryId: itineraryId),
        ),
      ),
    );
  }

  void _editItinerary(BuildContext context, String itineraryId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Provider(
          create: (_) => ItineraryRepository(),
          child: ItineraryBuilderScreen(itineraryId: itineraryId),
        ),
      ),
    );
  }

  Future<void> _deleteItinerary(
    BuildContext context,
    String itineraryId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Itinerary'),
        content: const Text(
          'Are you sure you want to delete this itinerary? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.deleteItinerary(itineraryId);
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Itinerary deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete itinerary: $e')),
          );
        }
      }
    }
  }
}

class _ItineraryCard extends StatelessWidget {
  final adapter.Itinerary itinerary;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItineraryCard({
    required this.itinerary,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: CeylonTokens.spacing16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CeylonTokens.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(CeylonTokens.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      itinerary.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (itinerary.description != null) ...[
                const SizedBox(height: CeylonTokens.spacing8),
                Text(
                  itinerary.description!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: CeylonTokens.spacing12),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: CeylonTokens.spacing4),
                  Text(
                    itinerary.destination,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: CeylonTokens.spacing4),
                  Text(
                    '${itinerary.formattedStartDate} - ${itinerary.formattedEndDate}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CeylonTokens.spacing8),
              Row(
                children: [
                  Icon(
                    Icons.event_note,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: CeylonTokens.spacing4),
                  Text(
                    '${itinerary.days.length} day${itinerary.days.length != 1 ? 's' : ''}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: CeylonTokens.spacing16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: CeylonTokens.spacing4),
                  Text(
                    'Created ${DateFormat('MMM d').format(itinerary.createdAt)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
