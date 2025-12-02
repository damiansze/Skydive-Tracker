import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/wear_os/wear_scaffold.dart';
import 'wear_add_jump_screen.dart';
import 'wear_statistics_screen.dart';
import 'wear_profile_screen.dart';
import 'wear_settings_screen.dart';

/// Home screen for WearOS with circular menu
class WearHomeScreen extends ConsumerWidget {
  const WearHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = (size.width < size.height ? size.width : size.height) * 0.32;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Center logo/title
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.paragliding,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Skydive',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Top - New Jump
            _buildMenuButton(
              context,
              position: Offset(centerX - 28, centerY - radius - 28),
              icon: Icons.add,
              label: 'Sprung',
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WearAddJumpScreen()),
              ),
            ),
            
            // Right - Statistics
            _buildMenuButton(
              context,
              position: Offset(centerX + radius - 28, centerY - 28),
              icon: Icons.bar_chart,
              label: 'Stats',
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WearStatisticsScreen()),
              ),
            ),
            
            // Bottom - Profile/Achievements
            _buildMenuButton(
              context,
              position: Offset(centerX - 28, centerY + radius - 28),
              icon: Icons.emoji_events,
              label: 'Profil',
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WearProfileScreen()),
              ),
            ),
            
            // Left - Settings
            _buildMenuButton(
              context,
              position: Offset(centerX - radius - 28, centerY - 28),
              icon: Icons.settings,
              label: 'Settings',
              color: Colors.grey,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WearSettingsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required Offset position,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WearButton(
            onPressed: onTap,
            backgroundColor: color,
            size: 56,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

