import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/jump.dart';
import '../providers/jump_provider.dart';
import '../providers/database_provider.dart';
import 'add_jump_screen.dart';

final distinctLocationsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.read(jumpServiceProvider);
  return await service.getDistinctLocations();
});

// Helper class for filter keys to ensure stable comparison
class StatisticsFilters {
  final String? location;
  final String? jumpType;
  final String? jumpMethod;
  
  StatisticsFilters({
    this.location,
    this.jumpType,
    this.jumpMethod,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatisticsFilters &&
          runtimeType == other.runtimeType &&
          location == other.location &&
          jumpType == other.jumpType &&
          jumpMethod == other.jumpMethod;
  
  @override
  int get hashCode => location.hashCode ^ jumpType.hashCode ^ jumpMethod.hashCode;
  
  Map<String, String?> toMap() => {
    'location': location,
    'jumpType': jumpType,
    'jumpMethod': jumpMethod,
  };
}

final totalJumpsProvider = FutureProvider.family<int, StatisticsFilters>((ref, filters) async {
  final service = ref.read(jumpServiceProvider);
  return await service.getTotalJumps(
    locationFilter: filters.location,
    jumpTypeFilter: filters.jumpType,
    jumpMethodFilter: filters.jumpMethod,
  );
});

final statisticsSummaryProvider = FutureProvider.family<Map<String, dynamic>, StatisticsFilters>((ref, filters) async {
  final api = ref.read(apiServiceProvider);
  return await api.getStatisticsSummary(
    locationFilter: filters.location,
    jumpTypeFilter: filters.jumpType,
    jumpMethodFilter: filters.jumpMethod,
  );
});

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String? _selectedLocationFilter;
  JumpType? _selectedJumpTypeFilter;
  JumpMethod? _selectedJumpMethodFilter;
  final MapController _mapController = MapController();
  StatisticsFilters? _cachedFilters;
  
  StatisticsFilters get _filters {
    final newFilters = StatisticsFilters(
      location: _selectedLocationFilter,
      jumpType: _selectedJumpTypeFilter?.toString().split('.').last.toLowerCase(),
      jumpMethod: _selectedJumpMethodFilter?.toString().split('.').last.toLowerCase(),
    );
    
    // Use cached filters if they're the same (stable reference for Riverpod)
    if (_cachedFilters != null && _cachedFilters == newFilters) {
      return _cachedFilters!;
    }
    
    _cachedFilters = newFilters;
    return _cachedFilters!;
  }
  
  void _centerMapOnLocations(List<dynamic> locationsWithCoords) {
    if (locationsWithCoords.isEmpty) return;
    
    final points = <LatLng>[];
    for (final loc in locationsWithCoords) {
      try {
        final lat = loc['latitude'] as num?;
        final lng = loc['longitude'] as num?;
        if (lat != null && lng != null) {
          points.add(LatLng(lat.toDouble(), lng.toDouble()));
        }
      } catch (e) {
        continue;
      }
    }
    
    if (points.isEmpty) return;
    
    double avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    double avgLng = points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
    
    _mapController.move(LatLng(avgLat, avgLng), 5.0);
  }

  void _showLocationPopup(BuildContext context, String locationName, int jumpCount, double latitude, double longitude) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  locationName,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (jumpCount > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.paragliding, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        '$jumpCount Sprünge',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.paragliding, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text(
                        '1 Sprung',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.my_location, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Koordinaten:\n${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Schließen'),
            ),
            if (_selectedLocationFilter != locationName)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _onLocationFilterChanged(locationName);
                },
                child: const Text('Filtern'),
              ),
          ],
        );
      },
    );
  }

  void _onLocationFilterChanged(String? location) {
    setState(() {
      _selectedLocationFilter = location;
      _cachedFilters = null; // Reset cache to create new filter object
    });
    ref.read(jumpNotifierProvider.notifier).setLocationFilter(location);
    // Family provider will automatically reload with new filter key
  }
  
  void _onJumpTypeFilterChanged(JumpType? type) {
    setState(() {
      _selectedJumpTypeFilter = _selectedJumpTypeFilter == type ? null : type;
      _cachedFilters = null; // Reset cache to create new filter object
    });
    // Family provider will automatically reload with new filter key
  }
  
  void _onJumpMethodFilterChanged(JumpMethod? method) {
    setState(() {
      _selectedJumpMethodFilter = _selectedJumpMethodFilter == method ? null : method;
      _cachedFilters = null; // Reset cache to create new filter object
    });
    // Family provider will automatically reload with new filter key
  }

  Future<void> _editJump(Jump jump) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddJumpScreen(jump: jump),
      ),
    );
    if (result == true) {
      ref.read(jumpNotifierProvider.notifier).refresh();
    }
  }

  Future<void> _deleteJump(Jump jump) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sprung löschen'),
        content: Text(
          'Möchten Sie den Sprung vom ${DateFormat('dd.MM.yyyy').format(jump.date)} wirklich löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(jumpNotifierProvider.notifier).deleteJump(jump.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sprung gelöscht')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Löschen: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jumpsAsync = ref.watch(jumpNotifierProvider);
    final locationsAsync = ref.watch(distinctLocationsProvider);
    final totalJumpsAsync = ref.watch(totalJumpsProvider(_filters));
    final statisticsSummaryAsync = ref.watch(statisticsSummaryProvider(_filters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik & Übersicht'),
      ),
      body: jumpsAsync.when(
        data: (allJumps) {
          // Filter jumps based on selected filters
          List<Jump> jumps = allJumps;
          if (_selectedJumpTypeFilter != null) {
            jumps = jumps.where((j) => j.jumpType == _selectedJumpTypeFilter).toList();
          }
          if (_selectedJumpMethodFilter != null) {
            jumps = jumps.where((j) => j.jumpMethod == _selectedJumpMethodFilter).toList();
          }
          
          return SingleChildScrollView(
            child: Column(
              children: [
                // Statistics Card
                Card(
                  margin: const EdgeInsets.all(16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Statistiken',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  totalJumpsAsync.when(
                                    data: (totalJumps) => Text(
                                      '$totalJumps',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    loading: () => const CircularProgressIndicator(),
                                    error: (_, __) => const Text('?'),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedLocationFilter != null
                                        ? 'Sprünge in\n${_selectedLocationFilter!}'
                                        : 'Gesamte Sprünge',
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    '${jumps.map((j) => j.location).toSet().length}',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedLocationFilter != null
                                        ? 'Sprungplatz'
                                        : 'Sprungplätze',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        // Jump Type and Method Statistics
                        statisticsSummaryAsync.when(
                          data: (summary) {
                            final jumpTypeCounts = summary['jump_type_counts'] as Map<String, dynamic>? ?? {};
                            final jumpMethodCounts = summary['jump_method_counts'] as Map<String, dynamic>? ?? {};
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (jumpTypeCounts.isNotEmpty) ...[
                                  const Text(
                                    'Sprungtypen',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: jumpTypeCounts.entries.map((entry) {
                                      final typeString = entry.key;
                                      final count = entry.value as int;
                                      JumpType? type;
                                      try {
                                        type = JumpType.values.firstWhere(
                                          (e) => e.toString().split('.').last.toLowerCase() == typeString,
                                        );
                                      } catch (e) {
                                        return const SizedBox.shrink();
                                      }
                                      final isSelected = _selectedJumpTypeFilter == type;
                                      return InkWell(
                                        onTap: () => _onJumpTypeFilterChanged(type),
                                        child: Chip(
                                          label: Text('${type.displayName}: $count'),
                                          avatar: const Icon(Icons.paragliding, size: 18),
                                          backgroundColor: isSelected 
                                              ? Theme.of(context).colorScheme.primaryContainer
                                              : null,
                                          side: isSelected
                                              ? BorderSide(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  width: 2,
                                                )
                                              : null,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (jumpMethodCounts.isNotEmpty) ...[
                                  const Text(
                                    'Sprungmethoden',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: jumpMethodCounts.entries.map((entry) {
                                      final methodString = entry.key;
                                      final count = entry.value as int;
                                      JumpMethod? method;
                                      try {
                                        method = JumpMethod.values.firstWhere(
                                          (e) => e.toString().split('.').last.toLowerCase() == methodString,
                                        );
                                      } catch (e) {
                                        return const SizedBox.shrink();
                                      }
                                      final isSelected = _selectedJumpMethodFilter == method;
                                      return InkWell(
                                        onTap: () => _onJumpMethodFilterChanged(method),
                                        child: Chip(
                                          label: Text('${method.displayName}: $count'),
                                          avatar: Icon(
                                            method == JumpMethod.PLANE 
                                                ? Icons.flight 
                                                : method == JumpMethod.HELICOPTER
                                                    ? Icons.flight_takeoff
                                                    : method == JumpMethod.BASE
                                                        ? Icons.landscape
                                                        : Icons.location_on,
                                            size: 18,
                                          ),
                                          backgroundColor: isSelected 
                                              ? Theme.of(context).colorScheme.primaryContainer
                                              : null,
                                          side: isSelected
                                              ? BorderSide(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  width: 2,
                                                )
                                              : null,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Map with jump locations
                statisticsSummaryAsync.when(
                  data: (summary) {
                    final locationsWithCoords = summary['locations_with_coords'] as List<dynamic>? ?? [];
                    if (locationsWithCoords.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    
                    // Calculate center and bounds
                    final points = <LatLng>[];
                    for (final loc in locationsWithCoords) {
                      try {
                        final lat = loc['latitude'];
                        final lng = loc['longitude'];
                        if (lat != null && lng != null) {
                          points.add(LatLng(
                            (lat as num).toDouble(),
                            (lng as num).toDouble(),
                          ));
                        }
                      } catch (e) {
                        // Skip invalid coordinates
                        continue;
                      }
                    }
                    
                    if (points.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    
                    double avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
                    double avgLng = points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
                    
                    return Card(
                      margin: const EdgeInsets.all(16.0),
                      child: Stack(
                        children: [
                          SizedBox(
                            height: 300,
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: LatLng(avgLat, avgLng),
                                initialZoom: 5.0,
                                minZoom: 3.0,
                                maxZoom: 18.0,
                                onMapReady: () {
                                  // Center map after it's ready
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    _centerMapOnLocations(locationsWithCoords);
                                  });
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.flutter_skydive_tracker',
                                  maxZoom: 19,
                                  errorTileCallback: (tile, error, stackTrace) {
                                    // Handle tile loading errors gracefully
                                  },
                                ),
                                MarkerLayer(
                                  markers: locationsWithCoords.map((loc) {
                                    try {
                                      final count = loc['count'] as int? ?? 1;
                                      final lat = loc['latitude'] as num?;
                                      final lng = loc['longitude'] as num?;
                                      final locationName = loc['location'] as String? ?? 'Unbekannt';
                                      if (lat == null || lng == null) {
                                        return null;
                                      }
                                      final markerLocationName = locationName;
                                      final markerCount = count;
                                      final markerLat = lat.toDouble();
                                      final markerLng = lng.toDouble();
                                      
                                      return Marker(
                                        point: LatLng(markerLat, markerLng),
                                        width: markerCount > 1 ? 50 : 40,
                                        height: markerCount > 1 ? 50 : 40,
                                        child: GestureDetector(
                                          onTap: () {
                                            if (mounted) {
                                              _showLocationPopup(
                                                context,
                                                markerLocationName,
                                                markerCount,
                                                markerLat,
                                                markerLng,
                                              );
                                            }
                                          },
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Icon(
                                                Icons.paragliding,
                                                color: Colors.red,
                                                size: markerCount > 1 ? 35 : 30,
                                              ),
                                              if (markerCount > 1)
                                                Positioned(
                                                  bottom: 0,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Text(
                                                      '$markerCount',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      return null;
                                    }
                                  }).whereType<Marker>().toList(),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: FloatingActionButton.small(
                              onPressed: () {
                                _centerMapOnLocations(locationsWithCoords);
                              },
                              tooltip: 'Karte zentrieren',
                              child: const Icon(Icons.center_focus_strong),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Card(
                    margin: EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (error, stack) => Card(
                    margin: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 8),
                            Text('Fehler beim Laden der Karte: $error'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: locationsAsync.when(
                  data: (locations) => DropdownButtonFormField<String>(
                    initialValue: _selectedLocationFilter,
                    decoration: const InputDecoration(
                      labelText: 'Nach Ort filtern',
                      border: OutlineInputBorder(),
                      icon: Icon(Icons.filter_list),
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Alle Orte'),
                      ),
                      ...locations.map((location) {
                        return DropdownMenuItem<String>(
                          value: location,
                          child: Text(
                            location,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: _onLocationFilterChanged,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Fehler beim Laden der Orte'),
                ),
              ),
              const SizedBox(height: 16),
              
              // Jumps List
              if (jumps.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.paragliding,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Noch keine Sprünge erfasst',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              else
                ...jumps.map((jump) {
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.paragliding),
                      title: Text(jump.location),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('dd.MM.yyyy HH:mm')
                                .format(jump.date),
                          ),
                          Text('Höhe: ${jump.altitude} m'),
                          if (jump.jumpType != null || jump.jumpMethod != null)
                            Wrap(
                              spacing: 8,
                              children: [
                                if (jump.jumpType != null)
                                  InkWell(
                                    onTap: () => _onJumpTypeFilterChanged(jump.jumpType),
                                    child: Chip(
                                      label: Text(jump.jumpType!.displayName),
                                      labelStyle: const TextStyle(fontSize: 11),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                if (jump.jumpMethod != null)
                                  InkWell(
                                    onTap: () => _onJumpMethodFilterChanged(jump.jumpMethod),
                                    child: Chip(
                                      label: Text(jump.jumpMethod!.displayName),
                                      labelStyle: const TextStyle(fontSize: 11),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                              ],
                            ),
                          if (jump.checklistCompleted)
                            const Row(
                              children: [
                                Icon(Icons.check_circle,
                                    size: 16, color: Colors.green),
                                SizedBox(width: 4),
                                Text('Checkliste abgeschlossen',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Bearbeiten'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Löschen',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editJump(jump);
                          } else if (value == 'delete') {
                            _deleteJump(jump);
                          }
                        },
                      ),
                      onTap: () => _editJump(jump),
                    ),
                  );
                }).toList(),
              const SizedBox(height: 16),
            ],
          ),
        );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Fehler: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.read(jumpNotifierProvider.notifier).refresh();
                  },
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
