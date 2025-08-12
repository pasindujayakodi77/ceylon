import 'package:ceylon/design_system/tokens.dart';
import 'package:ceylon/features/itinerary/data/itinerary_adapter.dart'
    as adapter;
import 'package:ceylon/features/itinerary/data/itinerary_repository.dart';
import 'package:ceylon/features/itinerary/presentation/widgets/itinerary_day_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ItineraryViewScreen extends StatefulWidget {
  final String itineraryId;

  const ItineraryViewScreen({super.key, required this.itineraryId});

  @override
  State<ItineraryViewScreen> createState() => _ItineraryViewScreenState();
}

class _ItineraryViewScreenState extends State<ItineraryViewScreen> {
  late final ItineraryRepository _repository;
  bool _isLoading = true;
  adapter.Itinerary? _itinerary;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = Provider.of<ItineraryRepository>(context, listen: false);
    _loadItinerary();
  }

  Future<void> _loadItinerary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final itinerary = await _repository.getItineraryById(widget.itineraryId);

      setState(() {
        _itinerary = itinerary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load itinerary: $e';
        _isLoading = false;
      });
    }
  }

  void _viewPlace(adapter.ItineraryItem item) {
    if (item.placeId != null && item.placeId!.isNotEmpty) {
      // Navigate to place details
      if (mounted && context.mounted) {
        Navigator.pushNamed(
          context,
          '/place-details',
          arguments: item, // Pass the itinerary item as argument
        );
      }
    }
  }

  void _shareItinerary() {
    if (_itinerary == null) return;

    final buffer = StringBuffer();

    buffer.writeln('🗺️ ${_itinerary!.title}');
    buffer.writeln('📍 ${_itinerary!.destination}');
    buffer.writeln('📅 ${_itinerary!.startDate} - ${_itinerary!.endDate}');
    buffer.writeln('\n--- ITINERARY ---\n');

    for (int i = 0; i < _itinerary!.days.length; i++) {
      final day = _itinerary!.days[i];
      buffer.writeln('DAY ${i + 1}: ${day.dayName} (${day.formattedDate})');

      if (day.note != null && day.note!.isNotEmpty) {
        buffer.writeln('📝 Notes: ${day.note}');
      }

      if (day.items.isEmpty) {
        buffer.writeln('  No activities planned');
      } else {
        // Sort items by time
        final sortedItems = [...day.items]
          ..sort((a, b) {
            final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
            final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
            return aMinutes.compareTo(bMinutes);
          });

        for (final item in sortedItems) {
          final timeStr =
              '${item.startTime.hour.toString().padLeft(2, '0')}:${item.startTime.minute.toString().padLeft(2, '0')}';
          buffer.write('  $timeStr - ${item.title}');

          if (item.durationMinutes > 0) {
            if (item.durationMinutes < 60) {
              buffer.write(' (${item.durationMinutes} min)');
            } else {
              final hours = item.durationMinutes ~/ 60;
              final minutes = item.durationMinutes % 60;
              if (minutes == 0) {
                buffer.write(' ($hours hr)');
              } else {
                buffer.write(' ($hours hr $minutes min)');
              }
            }
          }

          buffer.writeln();

          if (item.note != null && item.note!.isNotEmpty) {
            buffer.writeln('    Note: ${item.note}');
          }
        }
      }

      buffer.writeln();
    }

    buffer.writeln('Created with Ceylon - Your Travel Companion');

    Share.share(buffer.toString());
  }

  Future<void> _exportToMaps() async {
    if (_itinerary == null || _itinerary!.days.isEmpty) return;

    // Collect all places that have coordinates
    final places = <_MapLocation>[];

    for (int i = 0; i < _itinerary!.days.length; i++) {
      for (final item in _itinerary!.days[i].items) {
        if (item.latitude != null && item.longitude != null) {
          places.add(
            _MapLocation(
              name: item.title,
              lat: item.latitude!,
              lng: item.longitude!,
            ),
          );
        }
      }
    }

    if (places.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No places with coordinates found in this itinerary'),
        ),
      );
      return;
    }

    final options = ['Google Maps', 'Apple Maps', 'Copy Coordinates'];

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(CeylonTokens.spacing16),
                child: Text(
                  'Export ${places.length} Places to Maps',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(),
              ...options.map(
                (option) => ListTile(
                  leading: Icon(
                    option == 'Google Maps'
                        ? Icons.map
                        : option == 'Apple Maps'
                        ? Icons.pin_drop
                        : Icons.content_copy,
                  ),
                  title: Text(option),
                  onTap: () {
                    Navigator.pop(context);
                    _openInMaps(option, places);
                  },
                ),
              ),
              const SizedBox(height: CeylonTokens.spacing8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openInMaps(String mapType, List<_MapLocation> places) async {
    if (places.isEmpty) return;

    try {
      switch (mapType) {
        case 'Google Maps':
          if (places.length == 1) {
            // Single location
            final place = places.first;
            final url =
                'https://www.google.com/maps/search/?api=1&query=${place.lat},${place.lng}';
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
          } else {
            // Multiple locations - open first place then add waypoints
            final origin = places.first;
            final waypoints = places
                .skip(1)
                .map((p) => '${p.lat},${p.lng}')
                .join('|');
            final url =
                'https://www.google.com/maps/dir/?api=1&origin=${origin.lat},${origin.lng}&destination=${places.last.lat},${places.last.lng}&waypoints=$waypoints&travelmode=driving';
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
          }
          break;

        case 'Apple Maps':
          if (places.length == 1) {
            // Single location
            final place = places.first;
            final url =
                'https://maps.apple.com/?q=${place.name}&ll=${place.lat},${place.lng}';
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
          } else {
            // Apple Maps doesn't support multiple waypoints in URL scheme as easily
            // So we'll just open the first location
            final place = places.first;
            final url =
                'https://maps.apple.com/?q=${place.name}&ll=${place.lat},${place.lng}';
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Apple Maps opened with the first location only. Add other locations manually.',
                  ),
                  duration: Duration(seconds: 5),
                ),
              );
            }
          }
          break;

        case 'Copy Coordinates':
          final coordsText = places
              .map((p) => '${p.name}: ${p.lat}, ${p.lng}')
              .join('\n');
          await Clipboard.setData(ClipboardData(text: coordsText));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coordinates copied to clipboard')),
            );
          }
          break;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to open maps: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Itinerary...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Itinerary Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(CeylonTokens.spacing24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                const SizedBox(height: CeylonTokens.spacing16),
                Text(
                  'Error Loading Itinerary',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: CeylonTokens.spacing8),
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: CeylonTokens.spacing24),
                ElevatedButton(
                  onPressed: _loadItinerary,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_itinerary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Itinerary Not Found')),
        body: const Center(
          child: Text('Could not find the requested itinerary.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Itinerary Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: _exportToMaps,
            tooltip: 'Export to Maps',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareItinerary,
            tooltip: 'Share Itinerary',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              if (mounted && context.mounted) {
                Navigator.pushNamed(
                  context,
                  '/itineraries/${widget.itineraryId}/edit',
                );
              }
            },
            tooltip: 'Edit Itinerary',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with trip info
          Container(
            padding: const EdgeInsets.all(CeylonTokens.spacing16),
            color: colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _itinerary!.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: CeylonTokens.spacing4),
                Row(
                  children: [
                    Icon(Icons.place, size: 16, color: colorScheme.primary),
                    const SizedBox(width: CeylonTokens.spacing4),
                    Expanded(
                      child: Text(
                        _itinerary!.destination,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: colorScheme.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CeylonTokens.spacing8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: CeylonTokens.spacing4),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${_itinerary!.startDate} - ${_itinerary!.endDate}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: CeylonTokens.spacing8),
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: CeylonTokens.spacing4),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${_itinerary!.days.length} ${_itinerary!.days.length == 1 ? 'day' : 'days'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Days list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(CeylonTokens.spacing16),
              itemCount: _itinerary!.days.length,
              itemBuilder: (context, index) {
                final day = _itinerary!.days[index];
                return ItineraryDayWidget(
                  day: day,
                  dayNumber: index + 1,
                  onItemTap: _viewPlace,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLocation {
  final String name;
  final double lat;
  final double lng;

  _MapLocation({required this.name, required this.lat, required this.lng});
}
