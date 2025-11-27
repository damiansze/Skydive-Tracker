import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/jump.dart';
import '../services/jump_service.dart';
import 'add_jump_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final JumpService _jumpService = JumpService();
  List<Jump> _jumps = [];
  List<String> _locations = [];
  String? _selectedLocationFilter;
  bool _isLoading = true;
  int _totalJumps = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final jumps = await _jumpService.getAllJumps(
      locationFilter: _selectedLocationFilter,
    );
    final locations = await _jumpService.getDistinctLocations();
    final totalJumps = await _jumpService.getTotalJumps(
      locationFilter: _selectedLocationFilter,
    );

    setState(() {
      _jumps = jumps;
      _locations = locations;
      _totalJumps = totalJumps;
      _isLoading = false;
    });
  }

  void _onLocationFilterChanged(String? location) {
    setState(() {
      _selectedLocationFilter = location;
    });
    _loadData();
  }

  Future<void> _editJump(Jump jump) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddJumpScreen(jump: jump),
      ),
    );
    if (result == true) {
      _loadData();
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
        await _jumpService.deleteJump(jump.id);
        await _loadData();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik & Übersicht'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                                Text(
                                  '$_totalJumps',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _selectedLocationFilter != null
                                      ? 'Sprünge in\n$_selectedLocationFilter'
                                      : 'Gesamte Sprünge',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '${_locations.length}',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('Sprungplätze'),
                              ],
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
                  child: DropdownButtonFormField<String>(
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
                      ..._locations.map((location) {
                        return DropdownMenuItem<String>(
                          value: location,
                          child: Text(location),
                        );
                      }),
                    ],
                    onChanged: _onLocationFilterChanged,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Jumps List
                Expanded(
                  child: _jumps.isEmpty
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
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          itemCount: _jumps.length,
                          itemBuilder: (context, index) {
                            final jump = _jumps[index];
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
                                    Text('Höhe: ${jump.altitude} ft'),
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
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddJumpScreen(),
            ),
          ).then((_) => _loadData());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
