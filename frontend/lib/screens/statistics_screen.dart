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

final totalJumpsProvider = FutureProvider.family<int, Map<String, String?>>((ref, filters) async {
  final service = ref.read(jumpServiceProvider);
  return await service.getTotalJumps(
    locationFilter: filters['location'],
    jumpTypeFilter: filters['jumpType'],
    jumpMethodFilter: filters['jumpMethod'],
  );
});

final statisticsSummaryProvider = FutureProvider.family<Map<String, dynamic>, Map<String, String?>>((ref, filters) async {
  final api = ref.read(apiServiceProvider);
  return await api.getStatisticsSummary(
    locationFilter: filters['location'],
    jumpTypeFilter: filters['jumpType'],
    jumpMethodFilter: filters['jumpMethod'],
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
  
  Map<String, String?> get _filters => {
    'location': _selectedLocationFilter,
    'jumpType': _selectedJumpTypeFilter?.toString().split('.').last.toLowerCase(),
    'jumpMethod': _selectedJumpMethodFilter?.toString().split('.').last.toLowerCase(),
  };
  
  void _centerMapOnLocations(List<dynamic> locationsWithCoords) {
    if (locationsWithCoords.isEmpty) return;
    
    final points = locationsWithCoords.map((loc) {
      return LatLng(
        loc['latitude'] as double,
        loc['longitude'] as double,
      );
    }).toList();
    
    double avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    double avgLng = points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
    
    _mapController.move(LatLng(avgLat, avgLng), 5.0);
  }

  void _onLocationFilterChanged(String? location) {
    setState(() {
      _selectedLocationFilter = location;
    });
    ref.read(jumpNotifierProvider.notifier).setLocationFilter(location);
  }
  
  void _onJumpTypeFilterChanged(JumpType? type) {
    setState(() {
      _selectedJumpTypeFilter = _selectedJumpTypeFilter == type ? null : type;
    });
  }
  
  void _onJumpMethodFilterChanged(JumpMethod? method) {
    setState(() {
      _selectedJumpMethodFilter = _selectedJumpMethodFilter == method ? null : method;
    });
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
                            Column(
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
                                Text(
                                  _selectedLocationFilter != null
                                      ? 'Sprünge in\n$_selectedLocationFilter'
                                      : 'Gesamte Sprünge',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            locationsAsync.when(
                              data: (locations) => Column(
                                children: [
                                  Text(
                                    '${locations.length}',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text('Sprungplätze'),
                                ],
                              ),
                              loading: () => const Column(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 8),
                                  Text('Sprungplätze'),
                                ],
                              ),
                              error: (_, __) => const Column(
                                children: [
                                  Icon(Icons.error),
                                  SizedBox(height: 8),
                                  Text('Sprungplätze'),
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
                    final points = locationsWithCoords.map((loc) {
                      return LatLng(
                        loc['latitude'] as double,
                        loc['longitude'] as double,
                      );
                    }).toList();
                    
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
                                    final count = loc['count'] as int? ?? 1;
                                    return Marker(
                                      point: LatLng(
                                        loc['latitude'] as double,
                                        loc['longitude'] as double,
                                      ),
                                      width: count > 1 ? 50 : 40,
                                      height: count > 1 ? 50 : 40,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(
                                            Icons.paragliding,
                                            color: Colors.red,
                                            size: count > 1 ? 35 : 30,
                                          ),
                                          if (count > 1)
                                            Positioned(
                                              bottom: 0,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '$count',
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
                                    );
                                  }).toList(),
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
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
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
