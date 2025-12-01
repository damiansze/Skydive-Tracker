import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/jump.dart';
import '../providers/jump_provider.dart';
import '../providers/database_provider.dart';
import 'add_jump_screen.dart';
import 'settings_screen.dart';

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

  void _clearAllFilters() {
    setState(() {
      _selectedLocationFilter = null;
      _selectedJumpTypeFilter = null;
      _selectedJumpMethodFilter = null;
      _cachedFilters = null; // Reset cache to create new filter object
    });
    ref.read(jumpNotifierProvider.notifier).setLocationFilter(null);
    // Family providers will automatically reload with new filter key
  }

  bool get _hasActiveFilters {
    return _selectedLocationFilter != null ||
           _selectedJumpTypeFilter != null ||
           _selectedJumpMethodFilter != null;
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

  Widget _buildFreefallStatsSection(BuildContext context, List<Jump> jumps) {
    // Filter jumps with freefall stats
    final jumpsWithStats = jumps.where((j) => j.freefallStats != null && j.freefallStats!.hasData).toList();
    
    if (jumpsWithStats.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Calculate statistics safely
    final jumpsWithDuration = jumpsWithStats
        .where((j) => j.freefallStats!.freefallDurationSeconds != null)
        .toList();
    final jumpsWithVelocity = jumpsWithStats
        .where((j) => j.freefallStats!.maxVerticalVelocityMs != null)
        .toList();
    
    if (jumpsWithDuration.isEmpty && jumpsWithVelocity.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final avgFreefallDuration = jumpsWithDuration.isNotEmpty
        ? jumpsWithDuration
            .map((j) => j.freefallStats!.freefallDurationSeconds!)
            .reduce((a, b) => a + b) / jumpsWithDuration.length
        : 0.0;
    
    final avgMaxVelocity = jumpsWithVelocity.isNotEmpty
        ? jumpsWithVelocity
            .map((j) => j.freefallStats!.maxVerticalVelocityMs!)
            .reduce((a, b) => a + b) / jumpsWithVelocity.length
        : 0.0;
    
    final maxFreefallDuration = jumpsWithDuration.isNotEmpty
        ? jumpsWithDuration
            .map((j) => j.freefallStats!.freefallDurationSeconds!)
            .reduce((a, b) => a > b ? a : b)
        : 0.0;
    
    final maxVelocity = jumpsWithVelocity.isNotEmpty
        ? jumpsWithVelocity
            .map((j) => j.freefallStats!.maxVerticalVelocityMs!)
            .reduce((a, b) => a > b ? a : b)
        : 0.0;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flight_takeoff,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Freefall-Statistiken',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${jumpsWithStats.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (jumpsWithDuration.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: _buildStatRow(
                      'Ø Freefall-Dauer',
                      '${avgFreefallDuration.toStringAsFixed(1)}s',
                      Icons.timer,
                    ),
                  ),
                  Expanded(
                    child: _buildStatRow(
                      'Max. Freefall-Dauer',
                      '${maxFreefallDuration.toStringAsFixed(1)}s',
                      Icons.timer_outlined,
                    ),
                  ),
                ],
              ),
            if (jumpsWithDuration.isNotEmpty && jumpsWithVelocity.isNotEmpty)
              const SizedBox(height: 16),
            if (jumpsWithVelocity.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: _buildStatRow(
                      'Ø Max. Geschwindigkeit',
                      '${(avgMaxVelocity * 3.6).toStringAsFixed(1)} km/h',
                      Icons.speed,
                    ),
                  ),
                  Expanded(
                    child: _buildStatRow(
                      'Höchste Geschwindigkeit',
                      '${(maxVelocity * 3.6).toStringAsFixed(1)} km/h',
                      Icons.speed_outlined,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required AsyncValue<int> value,
    required String label,
    required Gradient gradient,
  }) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  value.when(
                    data: (val) => Text(
                      '$val',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    loading: () => const SizedBox(
                      height: 32,
                      width: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    error: (_, __) => const Text(
                      '?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
        // Check if this is the last jump matching current filters BEFORE deletion
        final allJumps = ref.read(jumpNotifierProvider).value ?? [];
        final filteredJumps = allJumps.where((j) {
          if (_selectedJumpTypeFilter != null && j.jumpType != _selectedJumpTypeFilter) return false;
          if (_selectedJumpMethodFilter != null && j.jumpMethod != _selectedJumpMethodFilter) return false;
          if (_selectedLocationFilter != null && j.location != _selectedLocationFilter) return false;
          return true;
        }).toList();
        
        final isLastFilteredJump = filteredJumps.length == 1 && filteredJumps.first.id == jump.id;
        
        // Delete the jump
        await ref.read(jumpNotifierProvider.notifier).deleteJump(jump.id);
        
        // If this was the last filtered jump, reset filters AFTER deletion
        // The build() method will handle showing all jumps when filters are cleared
        if (isLastFilteredJump && mounted) {
          setState(() {
            _selectedJumpTypeFilter = null;
            _selectedJumpMethodFilter = null;
            _selectedLocationFilter = null;
            _cachedFilters = null;
          });
        }
        
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
        actions: [
          if (_hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Alle Filter zurücksetzen',
              onPressed: _clearAllFilters,
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Einstellungen',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: jumpsAsync.when(
        data: (allJumps) {
          // First, check if filters need to be reset because selected values no longer exist
          bool filtersChanged = false;
          
          if (_selectedJumpTypeFilter != null) {
            final hasJumpType = allJumps.any((j) => j.jumpType == _selectedJumpTypeFilter);
            if (!hasJumpType) {
              _selectedJumpTypeFilter = null;
              filtersChanged = true;
            }
          }
          if (_selectedJumpMethodFilter != null) {
            final hasJumpMethod = allJumps.any((j) => j.jumpMethod == _selectedJumpMethodFilter);
            if (!hasJumpMethod) {
              _selectedJumpMethodFilter = null;
              filtersChanged = true;
            }
          }
          if (_selectedLocationFilter != null) {
            final hasLocation = allJumps.any((j) => j.location == _selectedLocationFilter);
            if (!hasLocation) {
              _selectedLocationFilter = null;
              filtersChanged = true;
            }
          }
          
          // Apply filters to get filtered jumps list
          List<Jump> jumps = allJumps;
          if (_selectedJumpTypeFilter != null) {
            jumps = jumps.where((j) => j.jumpType == _selectedJumpTypeFilter).toList();
          }
          if (_selectedJumpMethodFilter != null) {
            jumps = jumps.where((j) => j.jumpMethod == _selectedJumpMethodFilter).toList();
          }
          if (_selectedLocationFilter != null) {
            jumps = jumps.where((j) => j.location == _selectedLocationFilter).toList();
          }
          
          // CRITICAL: If filtered list is empty but jumps exist, reset all filters and show all jumps
          // This handles the case when the last filtered jump is deleted
          if (jumps.isEmpty && allJumps.isNotEmpty) {
            // Check if any filters are actually active
            if (_selectedJumpTypeFilter != null || _selectedJumpMethodFilter != null || _selectedLocationFilter != null) {
              // Reset all filters
              _selectedJumpTypeFilter = null;
              _selectedJumpMethodFilter = null;
              _selectedLocationFilter = null;
              _cachedFilters = null;
              filtersChanged = true;
              // IMPORTANT: Set jumps to allJumps immediately for this render
              jumps = allJumps;
            }
          }
          
          // Trigger rebuild if filters were changed
          if (filtersChanged) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {});
              }
            });
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                // Main Statistics Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          icon: Icons.paragliding,
                          iconColor: Theme.of(context).colorScheme.primary,
                          value: totalJumpsAsync,
                          label: _selectedLocationFilter != null
                              ? 'Sprünge in\n${_selectedLocationFilter!}'
                              : 'Gesamte\nSprünge',
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          icon: Icons.location_on,
                          iconColor: Colors.orange,
                          value: AsyncValue.data(jumps.map((j) => j.location).toSet().length),
                          label: _selectedLocationFilter != null
                              ? 'Sprungplatz'
                              : 'Sprung-\nplätze',
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange,
                              Colors.orange.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Freefall Statistics (if available)
                _buildFreefallStatsSection(context, jumps),
                const SizedBox(height: 20),
                // Jump Type and Method Statistics
                statisticsSummaryAsync.when(
                  data: (summary) {
                    final jumpTypeCounts = summary['jump_type_counts'] as Map<String, dynamic>? ?? {};
                    final jumpMethodCounts = summary['jump_method_counts'] as Map<String, dynamic>? ?? {};
                    
                    if (jumpTypeCounts.isEmpty && jumpMethodCounts.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Verteilung',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (jumpTypeCounts.isNotEmpty) ...[
                              Text(
                                'Sprungtypen',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
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
                                  return FilterChip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.paragliding,
                                          size: 16,
                                          color: isSelected
                                              ? Theme.of(context).colorScheme.onPrimaryContainer
                                              : null,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${type.displayName}',
                                          style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.2)
                                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '$count',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                                  : Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    selected: isSelected,
                                    onSelected: (_) => _onJumpTypeFilterChanged(type),
                                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                                    side: BorderSide(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  );
                                }).toList(),
                              ),
                              if (jumpMethodCounts.isNotEmpty) const SizedBox(height: 20),
                            ],
                            if (jumpMethodCounts.isNotEmpty) ...[
                              Text(
                                'Sprungmethoden',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
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
                                  IconData methodIcon = method == JumpMethod.PLANE 
                                      ? Icons.flight 
                                      : method == JumpMethod.HELICOPTER
                                          ? Icons.flight_takeoff
                                          : method == JumpMethod.BASE
                                              ? Icons.landscape
                                              : Icons.location_on;
                                  return FilterChip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          methodIcon,
                                          size: 16,
                                          color: isSelected
                                              ? Theme.of(context).colorScheme.onPrimaryContainer
                                              : null,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          method.displayName,
                                          style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.2)
                                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '$count',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                                  : Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    selected: isSelected,
                                    onSelected: (_) => _onJumpMethodFilterChanged(method),
                                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                                    side: BorderSide(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 20),
                
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
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              height: 320,
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
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.center_focus_strong,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                tooltip: 'Karte zentrieren',
                                onPressed: () {
                                  _centerMapOnLocations(locationsWithCoords);
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.map,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Sprungplätze',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: const SizedBox(
                      height: 320,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (error, stack) => Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      height: 320,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'Fehler beim Laden der Karte',
                                style: Theme.of(context).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                error.toString(),
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              
                // Filter Section
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.filter_list,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Filter',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                            if (_hasActiveFilters)
                              FilledButton.icon(
                                onPressed: _clearAllFilters,
                                icon: const Icon(Icons.clear_all, size: 18),
                                label: const Text('Zurücksetzen'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                                  foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        locationsAsync.when(
                          data: (locations) {
                            // Reset filter if selected location is no longer available
                            if (_selectedLocationFilter != null && !locations.contains(_selectedLocationFilter)) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _selectedLocationFilter = null;
                                  });
                                }
                              });
                            }
                            
                            return DropdownButtonFormField<String>(
                              value: _selectedLocationFilter != null && locations.contains(_selectedLocationFilter)
                                  ? _selectedLocationFilter
                                  : null,
                            decoration: InputDecoration(
                              labelText: 'Nach Ort filtern',
                              hintText: 'Alle Orte',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(
                                Icons.location_on,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            ),
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(12),
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.public,
                                      size: 20,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Alle Orte',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...locations.map((location) {
                                return DropdownMenuItem<String>(
                                  value: location,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.place,
                                        size: 20,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          location,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            onChanged: _onLocationFilterChanged,
                            );
                          },
                          loading: () => Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const LinearProgressIndicator(),
                          ),
                          error: (_, __) => Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Fehler beim Laden der Orte',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              
                // Jumps List Header
                if (jumps.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.list_alt,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sprünge',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${jumps.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              
                // Jumps List
                // Only show "No jumps" message if there are really no jumps at all
                if (allJumps.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.paragliding_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Noch keine Sprünge erfasst',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Erfasse deinen ersten Sprung mit dem + Button',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...jumps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final jump = entry.value;
                    return Container(
                      margin: EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        top: index == 0 ? 0 : 8.0,
                        bottom: index == jumps.length - 1 ? 16.0 : 0,
                      ),
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _editJump(jump),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.paragliding,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        jump.location,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('dd.MM.yyyy HH:mm').format(jump.date),
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.height,
                                            size: 14,
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${jump.altitude} m',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (jump.jumpType != null || jump.jumpMethod != null) ...[
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            if (jump.jumpType != null)
                                              InkWell(
                                                onTap: () => _onJumpTypeFilterChanged(jump.jumpType),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.secondaryContainer,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    jump.jumpType!.displayName,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (jump.jumpMethod != null)
                                              InkWell(
                                                onTap: () => _onJumpMethodFilterChanged(jump.jumpMethod),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.tertiaryContainer,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    jump.jumpMethod!.displayName,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                      if (jump.freefallStats != null && jump.freefallStats!.hasData) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.flight_takeoff,
                                                size: 16,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    if (jump.freefallStats!.freefallDurationSeconds != null)
                                                      Text(
                                                        'Freefall: ${jump.freefallStats!.freefallDurationSeconds!.toStringAsFixed(1)}s',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                          color: Theme.of(context).colorScheme.onSurface,
                                                        ),
                                                      ),
                                                    if (jump.freefallStats!.maxVerticalVelocityMs != null) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Max: ${jump.freefallStats!.maxVerticalVelocityKmh!.toStringAsFixed(1)} km/h',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                PopupMenuButton(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            size: 20,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 12),
                                          const Text('Bearbeiten'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            size: 20,
                                            color: Theme.of(context).colorScheme.error,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Löschen',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.error,
                                            ),
                                          ),
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
