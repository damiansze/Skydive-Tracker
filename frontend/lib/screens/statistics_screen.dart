import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/jump.dart';
import '../providers/jump_provider.dart';
import '../services/jump_service.dart';
import '../providers/database_provider.dart';
import 'add_jump_screen.dart';

final distinctLocationsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.read(jumpServiceProvider);
  return await service.getDistinctLocations();
});

final totalJumpsProvider = FutureProvider.family<int, String?>((ref, locationFilter) async {
  final service = ref.read(jumpServiceProvider);
  return await service.getTotalJumps(locationFilter: locationFilter);
});

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String? _selectedLocationFilter;

  void _onLocationFilterChanged(String? location) {
    setState(() {
      _selectedLocationFilter = location;
    });
    ref.read(jumpNotifierProvider.notifier).setLocationFilter(location);
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
    final totalJumpsAsync = ref.watch(totalJumpsProvider(_selectedLocationFilter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik & Übersicht'),
      ),
      body: jumpsAsync.when(
        data: (jumps) {
          return Column(
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
                    ],
                  ),
                ),
              ),
              
              // Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: locationsAsync.when(
                  data: (locations) => DropdownButtonFormField<String>(
                    value: _selectedLocationFilter,
                    decoration: const InputDecoration(
                      labelText: 'Nach Ort filtern',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.filter_list),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Alle Orte'),
                      ),
                      ...locations.map((location) {
                        return DropdownMenuItem<String>(
                          value: location,
                          child: Text(location),
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
              Expanded(
                child: jumps.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.flight_takeoff,
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
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.read(jumpNotifierProvider.notifier).refresh();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          itemCount: jumps.length,
                          itemBuilder: (context, index) {
                            final jump = jumps[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.flight_takeoff),
                                title: Text(jump.location),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('dd.MM.yyyy HH:mm')
                                          .format(jump.date),
                                    ),
                                    Text('Höhe: ${jump.altitude} m'),
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
                          },
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddJumpScreen(),
            ),
          );
          if (result == true) {
            ref.read(jumpNotifierProvider.notifier).refresh();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
