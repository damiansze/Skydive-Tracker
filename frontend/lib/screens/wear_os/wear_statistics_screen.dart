import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/jump.dart';
import '../../providers/jump_provider.dart';
import '../../widgets/wear_os/wear_scaffold.dart';

/// Statistics screen optimized for WearOS
class WearStatisticsScreen extends ConsumerWidget {
  const WearStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jumpsAsync = ref.watch(jumpNotifierProvider);

    return WearScaffold(
      title: 'Statistik',
      showBackButton: true,
      body: jumpsAsync.when(
        data: (jumps) => _buildStatistics(context, jumps),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, size: 32, color: Colors.red),
              const SizedBox(height: 8),
              Text('Fehler: $e', style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics(BuildContext context, List<Jump> jumps) {
    if (jumps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.paragliding,
              size: 32,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 4),
            const Text(
              'Keine Sprünge',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      );
    }

    // Calculate statistics
    final totalJumps = jumps.length;
    final uniqueLocations = jumps.map((j) => j.location).toSet().length;
    final avgAltitude = jumps.map((j) => j.altitude).reduce((a, b) => a + b) ~/ jumps.length;
    
    // Freefall stats
    final jumpsWithFreefall = jumps.where((j) => 
        j.freefallStats != null && j.freefallStats!.freefallDurationSeconds != null).toList();
    final avgFreefallDuration = jumpsWithFreefall.isNotEmpty
        ? jumpsWithFreefall.map((j) => j.freefallStats!.freefallDurationSeconds!).reduce((a, b) => a + b) / jumpsWithFreefall.length
        : 0.0;
    
    // Most recent jump
    final recentJump = jumps.first;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      children: [
        // Main stats in circular cards - smaller
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCircularStat(
              context,
              value: '$totalJumps',
              label: 'Sprünge',
              color: Colors.blue,
            ),
            _buildCircularStat(
              context,
              value: '$uniqueLocations',
              label: 'Orte',
              color: Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        // Additional stats - compact
        WearCard(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              _buildStatRow(
                Icons.height,
                'Ø Höhe',
                '$avgAltitude m',
              ),
              if (jumpsWithFreefall.isNotEmpty)
                _buildStatRow(
                  Icons.timer,
                  'Ø Freefall',
                  '${avgFreefallDuration.toStringAsFixed(1)}s',
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        
        // Jump type distribution
        _buildJumpTypeDistribution(context, jumps),
        const SizedBox(height: 4),
        
        // Recent jump - compact
        WearCard(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              const Icon(Icons.history, size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${DateFormat('dd.MM.yy').format(recentJump.date)} • ${recentJump.location}',
                      style: const TextStyle(fontSize: 9),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircularStat(
    BuildContext context, {
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.7)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(icon, size: 10, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 9)),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildJumpTypeDistribution(BuildContext context, List<Jump> jumps) {
    final typeCounts = <JumpType, int>{};
    for (final jump in jumps) {
      if (jump.jumpType != null) {
        typeCounts[jump.jumpType!] = (typeCounts[jump.jumpType!] ?? 0) + 1;
      }
    }

    if (typeCounts.isEmpty) return const SizedBox.shrink();

    return WearCard(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Typen',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 2,
            runSpacing: 2,
            children: typeCounts.entries.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${entry.key.displayName}: ${entry.value}',
                  style: const TextStyle(fontSize: 7),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Simple card widget for WearOS
class WearCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const WearCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}

